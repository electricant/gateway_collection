#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use CGI;
use JSON;
use Data::Dumper;

###
# Main
###
my $query = CGI->new;

# header() returns the Content-type: header.
# You can provide your own MIME type if you choose,
# otherwise it defaults to text/html.
# See also: https://metacpan.org/pod/CGI#Creating-a-standard-http-header
print $query->header();

print "<html><head>
		<title>Hello!</title>
	</head><body>\n";
print "<h1>Hello, world</h1>\n";
print "<h2>Query:</h2>\n";
print Dumper($query->param('POSTDATA'));
print "<h2>JSON:</h2>\n";
my $decoded = decode_json($query->param('POSTDATA'));
print Dumper($decoded);
print "<p>Message was from: " . $decoded->{'ID'} . "</p>\n";
print "</body>\n"
