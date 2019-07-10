#!/usr/bin/perl
use strict;

# Turn off buffering to STDOUT
$| = 1;

# Read from STDIN
while (<>) {
	my @elems = split; # splits $_ on whitespace by default

	# The URL is the first whitespace-separated element.
	my $url = $elems[0];

	# show a fancy message if not authenticated
	if ($url =~ m#^http://192\.168\.65\.254:1000/fgtauth\?.*#i) {
		$url = "http://lilith.int6.it/noauth";
	}# elsif ($url =~ /.js/ && int(rand(100)) == 0) {
	#	$url = "http://192.168.6.1/scherzo-salvo/inject.js";
	#}
	print "$url\n";
}
