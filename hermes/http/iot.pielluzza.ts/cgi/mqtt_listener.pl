#!/usr/bin/env -S perl -I ./
use v5.12;
use warnings;

use JSON;
use POSIX;
use utf8;
use Net::MQTT::Simple;
use Data::Dumper;

# Load configuration file
BEGIN { require "./config.pl"; }

###
# Main
###
my $mqtt = Net::MQTT::Simple->new(MQTT_BROKER);

# Setup MQTT listener that runs forever
# 
# Dispatch table syntax taken from here:
# https://stackoverflow.com/questions/7237746/how-do-you-create-a-callback-function-dispatch-table-in-perl-using-hashes
#
# MQTT_LOG_TOPIC & MQTT_FORWARD_TOPIC have to be treated like a function in this
# scenario. See: https://perldoc.perl.org/constant#CAVEATS
$mqtt->run(
	MQTT_LOG_TOPIC()     => \&topic_cb,
	MQTT_FORWARD_TOPIC() => \&forwardMsg,
);

###
# Helper function to write a record into a specified recfile, containing the
# sensor data (appending the record to the existing content).
# Sensor data is passed to write_to_recfile in the form of a dictionary where
# the key is the name/description of what the associated value represents.
# Key-value pairs are stored in the recfile as they appear in the dictionary.
#
# This function requires the following parameters:
#	filename  - name of the file where the record will be written to
#	timestamp - unix timestamp for when the reading appeared
#	readings  - dictionary with the sensor readings
#
# More info about recfiles are available here:
#	https://www.gnu.org/software/recutils/
#	https://www.gnu.org/software/recutils/manual/
###
sub write_to_recfile
{
	my($filename, $timestamp, %readings) = @_;

	open(my $fh, '>>', $filename)
		or die "Could not open file '$filename': $!.";

	say $fh "timestamp: $timestamp";
	say $fh "date: " . strftime("%a_%F_%X", localtime($timestamp));
	while(my($k, $v) = each %readings)
	{
		say $fh "$k: $v";
	}
	print $fh "\n"; # Newline ends a record
	close $fh;
}

###
# This code is responsible for decoding the various messages and sending the
# data to the required file(s).
#
# Each topic has the following form:
# 	<whatever>/nodename
#
# It expects a JSON message of the following kind:
# {
#    "temp" : <temp_celsius>,
#    "rhum" : <humidity_percent>,
#    "pres" : <ambient_pressure>,
#    "qual" : <air quality index>
# }
# All field are optional except temp.
#
# nodename is used as the filename for storing the data as CSV.
###
sub topic_cb {
	my($topic, $message) = @_;
	say "[topic_cb] $topic -> $message";
	
	my $decoded = decode_json($message);
	#print Dumper($decoded);
	#print Dumper(keys %{$decoded});
	#print Dumper(values %{$decoded});

	my $timestamp = time();
	my $filename =  ($topic =~ m/.*\/(.*)/)[0] . ".csv";
	my $temp_path = TEMP_DIR . '/' . $filename;
	my $save_path = SAVE_DIR . '/' . $filename;

	# Old logic and new logic will coexist for a while. To support many
	# different sensors, each with its own capabilities, recfiles will be used
	# in place of CSV files. This allows for greater flexibility and gives us a
	# set of tried and tested command line tools to operate on those files
	# The idea is to place each value received from the json message into a
	# filed with the associated value.
	my $first_timestamp = $timestamp; # If $temp_path does not exist then
	                                  # this is the first timestamp
	if (-e ($temp_path . ".rec"))
	{
		open(my $fh, '<', $temp_path . ".rec")
			or die "Could not open file '$temp_path': $!.";
		$first_timestamp = $1 if(readline($fh) =~ /timestamp: (\d+)/);
		close $fh;
	}

	# If timestamp delta is greater or equal than SAVE_INTERVAL_MIN then save
	# the last reading to $save_path and empty $temp_path
	if (($timestamp - $first_timestamp) >= (SAVE_INTERVAL_MIN * 60))
	{
		truncate("$temp_path.rec", 0);
		# see: https://stackoverflow.com/questions/25950359/decoding-and-using-json-data-in-perl
		write_to_recfile("$save_path.rec", $timestamp, %{$decoded});
	}

	write_to_recfile("$temp_path.rec", $timestamp, %{$decoded});

	# NOTE: this is the old logic to save sensor data in CSV files.
	#       To be removed starting from 2022.
	my $temp_read = $decoded->{'temp'};
	my $rhum_read = $decoded->{'rhum'};
	
	if ($rhum_read > 100)
	{
		warn "Invalid data received";
		return; # do not save
	}

	# Read first measurement from temporary file and extract timestamp
	$first_timestamp = $timestamp; # If $temp_path does not exist then
	                                  # this is the first timestamp
	if (-e $temp_path)
	{
		open(my $fh, '<', $temp_path) or die "Could not open file '$filename'";
		my @firstline = split(',', readline($fh));
		$first_timestamp = $firstline[0];
	}
	
	# Formatted output data as CSV:
	# 	UNIX epoch,Human date and time,temperature,humidity
	my $csvstr = "$timestamp," . strftime("%a_%F_%X", localtime($timestamp)) .
		",$temp_read,$rhum_read\n";
	
	# If timestamp delta is greater or equal than SAVE_INTERVAL_MIN then save
	# to $save_path and empty $temp_path
	if (($timestamp - $first_timestamp) >= (SAVE_INTERVAL_MIN * 60))
	{
		open(my $fh, '>>', $save_path)
			or die "Could not open file '$filename'";
		print $fh $csvstr;
		truncate($temp_path, 0);
	}
	
	open(my $fh, '>>', $temp_path) or die "Could not open file '$temp_path'";
	print $fh $csvstr;
	close $fh;
}

###
# This function read a json config file that acts as a forward table for
# MQTT topics and messages. The goal is to forward a message from one topic to
# another. This is useful for example for remote thermostats to receive a
# temperature from a room that it's not the one they are located into.
###
sub forwardMsg {
	my($topic, $message) = @_;
	say "[forwardMsg] $topic -> $message";
	
	# Store the last modified time for the forward file as a state variable
	# Its value will be kept upon different function invocation
	state $lastMtime = 0;
	# Also the forward table is kept as a state, since we do not want to
	# reload it every time this function is called, but only when modified
	state @forwardTable;

	# Return if the config file does not exist or cannot be read
	my $fh;
	if(!open($fh, '<:unix', FORWARD_FILE)) {
		warn "Could not open " . FORWARD_FILE . ". Forwarding aborted";
     		return;	     
	}

	# Reload forwarding config file if needed.
	my $modtime = (stat($fh))[9];
	if ($modtime > $lastMtime) {
		read($fh, my $content, -s $fh);
		@forwardTable = @{decode_json($content)};
		$lastMtime = $modtime;
	}

	# Actual forwarding logic
	foreach (@forwardTable) {
		my %hash = %{$_};

		if ($hash{'decision-topic'} eq $topic) {
			$mqtt->publish($hash{'relay-topic'} => $message);
			say "$topic forwarded to $hash{'relay-topic'}";
		}
	}
}

