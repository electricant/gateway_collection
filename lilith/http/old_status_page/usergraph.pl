#!/usr/bin/perl
#
# Perl scrpit that parses the log with the number of users per hour and returns
# an HTML formatted graph
use strict; use warnings;  # always
use POSIX qw(strftime);

# File where the user records are stored
my $LOGFILE="/var/log/num_clients.log";
# SPread FACTOR: increases the separation between the minimum and maximum values
# when computing the percentage
my $SPREAD_FACTOR=1.5;

# Parse the file: find maximum and fill the arrays
open(my $fh, '<:encoding(UTF-8)', $LOGFILE)
	or die "Could not open the logfile for reading";

my @users = (0) x 24; # The users are sampled every hour
my $maxValue = 0;

while (my $row = <$fh>) {
	my ($hour, $number) = split(" ", $row);
	
	$users[$hour] = $number;
	
	if ($number > $maxValue) {
		$maxValue = $number;
	}
}

close($fh);

# Output the data
print "Content-type:text/html\r\n\r\n";
print '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">';
print '<html>';
print '<head>';
print '<link href="/bargraph.css" rel="stylesheet" type="text/css">';
print '</head>';
print '<body>';
print '<div class="graph" X-label="Time" Y-label="Clients"> <span></span>';

my $time_now = strftime("%H", localtime());
my $time = 0;
foreach my $num (@users) {
	my $percent = sprintf("%3.1f", 100*(($num/$maxValue)**$SPREAD_FACTOR));

	if ($time == $time_now) {
		print '<span class="now" ';
	} else {
		print '<span ';
	}
	print 'style="height: '.$percent.'%" bar-label="'.$time.'" bar-value="'.$num.'"></span>';

	$time++;
}
print '</div></body></html>';
