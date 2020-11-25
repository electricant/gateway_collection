#!/usr/bin/env perl
use v5.12;
use warnings;

use POSIX;
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

	my $timestamp = time();
	my $temp_read = $decoded->{'temp'};
	my $rhum_read = $decoded->{'rhum'};
	my $filename = $decoded->{'ID'} . ".csv";
	my $temp_path = TEMP_DIR . '/' . $filename;
	my $save_path = SAVE_DIR . '/' . $filename;

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

