#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

#use Data::Dumper;
use CGI;
use File::ReadBackwards;

###
# Constant definitions
###
use constant SAVE_DIR => '/srv/http/iot.pielluzza.ts/data';
use constant HOURS_PER_WEEK => 168;
use constant NUM_LINES => 2*HOURS_PER_WEEK;

###
# Main
###
my $query = CGI->new;

# This script assumes to be invoked with a single parameter containing the
# node name. If the nodename is empty 'test' is used.
my @keywords = $query->keywords();
my $nodename = $keywords[0];

if (not defined $nodename) { $nodename = 'test'; }

# See also: https://metacpan.org/pod/CGI#Creating-a-standard-http-header
print $query->header(-type => 'text/csv', -charset => 'utf-8',
                     -attachment => "week_$nodename.csv",
		         -expires => '+30min');

# Filenames are in the form <node name>.csv.
my $bw = File::ReadBackwards->new(SAVE_DIR . '/' . "$nodename.csv") or die $!;

print "Timestamp,Human Date,Temperature,Humidity\n"; # csv header

for (my $i = 0; $i < NUM_LINES; $i++) {
	my $lastline = $bw->readline();
	
	if (defined $lastline) {
		print $lastline if ($lastline =~ /^\d+/); # do not print comments
	} else {
		last; # quit the loop we have read all the file
	}
}
$bw->close();
