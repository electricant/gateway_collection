#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use CGI;
use File::ReadBackwards;

# Load configuration file
BEGIN { require "./config.pl"; }

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

my @sensors = $query->param('keywords');

# Filenames are in the form <node name>.csv. TEMP_DIR contains the latest data,
# but SAVE_DIR has the complete list of nodes.
# If no sensor has been specified in the request, return data for all of them.
my @files = (@sensors) ? map { "$_.csv" } @sensors : list_dir_files(SAVE_DIR); 

my $isFirst = 1; # JSON requires no comma at the end of the last element
foreach (@files) {
	next if (($_ eq '.') || ($_ eq '..'));
	
	my $bw = File::ReadBackwards->new(TEMP_DIR . "/$_") or next;
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
exit(0);

# List all files inside the specified directory
sub list_dir_files
{
	opendir(my $dir, $_[0]) or die "Could not open '$_[0]': $!\n";
	my @files = readdir($dir);
	closedir($dir);
	return @files;
}

