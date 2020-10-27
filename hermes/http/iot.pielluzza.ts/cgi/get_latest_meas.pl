#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use CGI;
use File::ReadBackwards;

###
# Constant definitions
###
use constant SAVE_DIR => '/srv/http/iot.pielluzza.ts/data';

###
# Main
###
my $query = CGI->new;

# See also: https://metacpan.org/pod/CGI#Creating-a-standard-http-header
print $query->header(-type => 'text/json', -charset => 'utf-8');

# This code returns a json message with the latest measurements for each sensor.
# The JSON message is of the kind:
# {
# 	"<node name>" : {
#    		"timestamp" : <unix timestamp>,
#    		"temp"      : <temp_celsius>,
#    		"rhum"      : <humidity_percent>
#    	},
# 	"<another node>" : {
# 		 ...
# 	}
# }

print "{\n";

# Filenames are in the form <node name>.csv. So scan SAVE_DIR to list them
opendir(my $savedir, SAVE_DIR) or die $!;
my @files = readdir($savedir);
closedir($savedir);

my $isFirst = 1; # JSON requires no comma at the end of the last element
foreach (@files) {
	next if (($_ eq '.') || ($_ eq '..'));
	
	my $bw = File::ReadBackwards->new(SAVE_DIR . '/' . $_) or die $!;
	my $lastline = $bw->readline();
	$bw->close();

	chomp($lastline);	
	my ($timestamp, undef, $temp, $hum) = split(",", $lastline);
	my $nodename = $_;
	$nodename =~ s/.csv//;
	
	if ($isFirst) {
		$isFirst = undef;
	} else {
		print ",\n";
	}

	print "\"$nodename\" : {\n";
	print "\"timestamp\" : $timestamp,\n";
	print "\"temp\" : $temp,\n";
	print "\"rhum\" : $hum\n";
	print "}";
}

print "\n}\n";