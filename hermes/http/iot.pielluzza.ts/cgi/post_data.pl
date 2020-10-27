#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use CGI;
use JSON;
use Data::Dumper;
use POSIX qw(strftime);

use constant SAVE_DIR => '/srv/http/iot.pielluzza.ts/data';

###
# Main
###
my $query = CGI->new;

# See also: https://metacpan.org/pod/CGI#Creating-a-standard-http-header
print $query->header(-type => 'text/plain', -charset => 'utf-8');

my $decoded = decode_json(scalar $query->param('POSTDATA'));
#print Dumper($decoded);
#print Dumper(keys %{$decoded});
#print Dumper(values %{$decoded});

# This code expects a JSON message of the kind:
# {
#    "ID"   : "<node name>",
#    "temp" : <temp_celsius>,
#    "rhum" : <humidity_percent>
# }
#
# ID is used as the file name where the data is stored as CSV
my $filename = SAVE_DIR . "/" . $decoded->{'ID'} . ".csv";
open(my $fh, '>>', $filename)	or die "Could not open file '$filename'";

print $fh time() . ',';
print $fh strftime("%a_%F_%R", gmtime()) . ',';
print $fh "$decoded->{'temp'},";
print $fh "$decoded->{'rhum'}\n";

close $fh;

print "Thanks, $decoded->{'ID'}.\n";
