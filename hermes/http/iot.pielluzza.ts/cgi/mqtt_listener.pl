#!/usr/bin/env -S perl -I ./
use v5.12;
use warnings;

use JSON;
use POSIX;
use utf8;
use Net::MQTT::Simple;
#use Data::Dumper;

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
# MQTT_LOG_TOPIC has to be treated like a function in this scenario. See:
# https://perldoc.perl.org/constant#CAVEATS
$mqtt->run(
	MQTT_LOG_TOPIC() => \&topic_cb,
);

###
# This code is responsible for decoding the various messages and send the data
# to te required file(s).
#
# Each topic has the following form:
# 	<whatever>/nodename
#
# It expects a JSON message of the following kind:+
# {
#    "temp" : <temp_celsius>,
#    "rhum" : <humidity_percent>
# }
#
# nodename is used as the filename for storing the data as CSV.
###
sub topic_cb {
	my($topic, $message) = @_;
	print "[$topic] $message\n";
	
	my $decoded = decode_json($message);
	#print Dumper($decoded);
	#print Dumper(keys %{$decoded});
	#print Dumper(values %{$decoded});

	my $timestamp = time();
	my $temp_read = $decoded->{'temp'};
	my $rhum_read = $decoded->{'rhum'};
	my $filename =  ($topic =~ m/.*\/(.*)/)[0] . ".csv";
	my $temp_path = TEMP_DIR . '/' . $filename;
	my $save_path = SAVE_DIR . '/' . $filename;

	if ($rhum_read > 100)
	{
		print "Invalid data received.\n";
		return; # do not save
	}

	# Read first measurement from temporary file and extract timestamp
	my $fh = undef; # Filehandle
	my $first_timestamp = $timestamp; # If $temp_path does not exist then
	                                  # this is the first timestamp
	if (-e $temp_path)
	{
		open($fh, '<', $temp_path) or die "Could not open file '$filename'";
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
		open($fh, '>>', $save_path)
			or die "Could not open file '$filename'";
		print $fh $csvstr;
		truncate($temp_path, 0);
	}
	
	open($fh, '>>', $temp_path) or die "Could not open file '$filename'";
	print $fh $csvstr;
	close $fh;
}

