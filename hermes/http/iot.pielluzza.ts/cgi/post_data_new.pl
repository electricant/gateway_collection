#!/usr/bin/env perl
use v5.12;
use warnings;

use POSIX;
use utf8;
use CGI;
use Data::Dumper;

use constant SAVE_DIR => '/srv/http/iot.pielluzza.ts/data';

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

      # Close all standard filehandles to tell the server we are done
      for my $handle (*STDIN, *STDOUT, *STDERR) {
            open($handle, "+<", "/dev/null") || die "can't reopen $handle to /dev/null: $!";
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
# It decodes the json data received and sends it to a file.
# This code expects a JSON message of the kind:
# {
#    "ID"   : "<node name>",
#    "temp" : <temp_celsius>,
#    "rhum" : <humidity_percent>
# }
# ID is used as the file name where the data is stored as CSV.
###
sub forked_task {
	use JSON;
	
	my $decoded = decode_json(scalar $query->param('POSTDATA'));
	#print Dumper($decoded);
	#print Dumper(keys %{$decoded});
	#print Dumper(values %{$decoded});

	my $filename = SAVE_DIR . "/" . $decoded->{'ID'} . ".csv";
	open(my $fh, '>>', $filename)	or die "Could not open file '$filename'";

	# Output data as CSV:
	# 	UNIX epoch,Human date and time,temperature,humidity
	print $fh time() . ',' . strftime("%a_%F_%X", gmtime()) . ',';
	print $fh "$decoded->{'temp'},$decoded->{'rhum'}\n";

	close $fh;
}

