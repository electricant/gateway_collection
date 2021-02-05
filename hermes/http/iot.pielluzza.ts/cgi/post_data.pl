#!/usr/bin/env -S perl -I ./
use v5.12;
use warnings;

use utf8;
use CGI;
#use Data::Dumper;

# Load configuration file
BEGIN { require "./config.pl"; }

###
# Main
###
my $query = CGI->new;

# See also: https://metacpan.org/pod/CGI#Creating-a-standard-http-header
print $query->header(-type => 'text/plain', -charset => 'utf-8');

# Fork into a new process to do time consuming stuff.
# This lets the sending device close the connection and go to sleep earlier
my $pid = fork();
if( $pid == 0 ) {
	# Inside here lives the child process

	# Close all standard filehandles to tell the http server we are done
      for my $handle (*STDIN, *STDOUT, *STDERR) {
            open($handle, "+<", "/dev/null")
			or die "can't reopen $handle to /dev/null: $!";
      } #docstore.mik.ua/orelly/perl4/cook/ch17_18.htm

      # Create a new session for our code to run
      POSIX::setsid();

	# Run our task and exit
	forked_task();
	exit(0);
}

print "Thanks.\n";
exit(0);

###
# This function is run inside the forked process and does all the heavy-lifting.
#
# The new default behaviour is to use MQTT instead of HTTP.
# This function acts as a proxy.
#
# It expects a JSON message of the kind:
# {
#    "ID"   : "<node name>",
#    "temp" : <temp_celsius>,
#    "rhum" : <humidity_percent>
# }
# 
# It decodes the message and then forwards the data to the topic:
#  pielluzza/sensors/<node name>
#
###
sub forked_task {
	use JSON;
	
	my $decoded = decode_json(scalar $query->param('POSTDATA'));
	#print Dumper($decoded);
	#print Dumper(keys %{$decoded});
	#print Dumper(values %{$decoded});

	my $temp_read = $decoded->{'temp'};
	my $rhum_read = $decoded->{'rhum'};
	my $nodename = $decoded->{'ID'};

	if ($rhum_read > 100)
	{
		die "Invalid data received.";
	}
	
	use Net::MQTT::Simple MQTT_BROKER;
	retain "pielluzza/sensors/$nodename"
		=> "{\"temp\" : $temp_read, \"rhum\" : $rhum_read}";
}

