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
our $MQTT_BROKER;
our %LOG_TOPICS;
our $FORWARD_FILE;
our $MQTT_FORWARD_TOPIC;

###
# Main
###
$| = 1; # Disable output buffering (for logging purposes)

my $mqtt = Net::MQTT::Simple->new($MQTT_BROKER);

# Subscribe on each topic to be logged according to the config file
foreach my $topic (keys %LOG_TOPICS)
{
	$mqtt->subscribe($topic, \&topic_cb);
	say "Subscribed to: $topic";
}

# Setup MQTT listener that runs forever
# 
# Dispatch table syntax taken from here:
# https://stackoverflow.com/questions/7237746/how-do-you-create-a-callback-function-dispatch-table-in-perl-using-hashes
$mqtt->run(
	$MQTT_FORWARD_TOPIC => \&forwardMsg,
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
# All fields are optional except for 'temp'.
#
# nodename is used as the filename for storing the data.
#
# See also: https://stackoverflow.com/questions/25950359/decoding-and-using-json-data-in-perl
###
sub topic_cb {
	my($topic, $message) = @_;
	$message =~ s/\r?\n//g;
	say "[topic_cb] $topic -> $message";

	# Read configuration for this specific topic
	#print Dumper($LOG_TOPICS{$topic});
	my $temp_path = $LOG_TOPICS{$topic}->{'short_data'};
	my $save_path = $LOG_TOPICS{$topic}->{'long_data'};
	my $save_interval = $LOG_TOPICS{$topic}->{'save_interval'};
	#print Dumper([$temp_path, $save_path, $save_interval]);
	
	my $decoded = decode_json($message);
	#print Dumper($decoded);
	#print Dumper(keys %{$decoded});
	#print Dumper(values %{$decoded});

	# https://perldoc.perl.org/functions/time
	# Returns the number of non-leap seconds since whatever time the system considers to be the epoch
	my $timestamp = time();

	# To allow for different sensors, each with its own capabilities, recfiles
	# have been used. This gives us a set of tried and tested command line tools
	# to operate on those files. Each value received from the json message is
	# placed into a field named the same way as in the json message.
	my $first_timestamp = $timestamp; # If $temp_path does not exist then
	                                  # this is the first timestamp
	if (-e $temp_path)
	{
		open(my $fh, '<', $temp_path)
			or die "Could not open file '$temp_path': $!.";
		$first_timestamp = $1 if(readline($fh) =~ /timestamp: (\d+)/);
		close $fh;
	}

	# If timestamp delta is greater or equal than SAVE_INTERVAL_MIN then save
	# the last reading to $save_path and empty $temp_path
	if (($timestamp - $first_timestamp) >= ($save_interval * 60))
	{
		truncate($temp_path, 0);
		write_to_recfile($save_path, $timestamp, %{$decoded});
	}

	write_to_recfile($temp_path, $timestamp, %{$decoded});
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
	if(!open($fh, '<:unix', $FORWARD_FILE)) {
		warn "Could not open " . $FORWARD_FILE . ". Forwarding aborted";
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

