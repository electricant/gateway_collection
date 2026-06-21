#!/usr/bin/perl -T

# see https://metacpan.org/release/CHROMATIC/Modern-Perl-1.03/view/lib/Modern/Perl.pm
#use Modern::Perl;
use strict;
use warnings;
use feature 'say';

use JSON;
use utf8;
use Data::Dumper;
use Path::Tiny;
use POSIX qw(strftime);
use lib '.';
use RecSQL;

# Load configuration file
BEGIN { require "./cgi/config.pl"; }
our $FORWARD_FILE;

sub print_header
{
	say '<!DOCTYPE html>';
	say '<html><head>';
	say '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>';
	say '<meta name="viewport" content="width=device-width, initial-scale=1">';
	say '<title>Pielluzza IoT Dashboard</title>';

	say '<script src="js/mqttws31.min.js"></script>';
	say '<script src="js/heating.js"></script>';
	say '<script src="https://cdn.anychart.com/releases/8.10.0/js/anychart-bundle.min.js"></script>';

	say '<link rel="stylesheet" href="css/mvp.css"/>';
	#<!-- <link href="css/style.css" rel="stylesheet" type="text/css"> -->
	say '</head>';
	
	say '<body>';
	say '<header><nav>';
	say '<a href="/" style="font-size: 18px">';
	say '<img alt="logo" src="favicon.ico" height="18" style="margin:0">Pielluzza IoT Dashboard</a>';
	say '<ul>';
	say '<li><a href="/index.html">&#x1F4CA; Dashboard</a></li>';
	say '<li><a href="/heating.cgi">&#x1F525; Heating</a></li>';
	say '</ul>';
	say '</nav></header>';
}

sub put_chart
{
	my $filename = '/srv/http/iot.pielluzza.ts/data/cece-soggiorno.rec';
	my $ts = time() - (7 * 24 * 60 * 60);

	my $recdb = RecSQL->from_file($filename);
	my $records = $recdb->select("*", sub { $_[0]->get('timestamp') >= $ts });

	say '<script>';
	say 'var temperature = [';

	foreach my $record (@$records) {
		print '["' . $record->{timestamp} . '", ' . $record->{temp} . ', ' . $record->{rhum} . "],\n";
	}
	say '];';

	say 'anychart.onDocumentReady(function() {' .
        		'var chart = anychart.line();' .
			'chart.xGrid().enabled(true);' .
			'chart.yGrid().enabled(true);' .
			'chart.xAxis().labels().rotation(90);' .
        		'chart.line(temperature).name("Temperature").stroke("red");' .
        		'chart.container("container");' .
        		'chart.draw();' .
	    '});';
	say '</script>';
}

###
# Page generation begins here
###
print "Content-type:text/html\r\n\r\n";

print_header();

say '<main>';
say '<div id="container"></div>';

# Enumerate thermostats and put them in the webpage
my $forward_json = path($FORWARD_FILE)->slurp;
my @fw = @{decode_json($forward_json)};

foreach (@fw) {
	# The topic strings are in the form:
	# 	'pielluzza/heating/cece-test/decision'
	# 	'pielluzza/relay/cece-test/enable'
	# So we split on '/' and extract the 3rd (index = 2) element
	my $heater = (split '/', $_->{'decision-topic'})[2];
	my $relay = (split '/', $_->{'relay-topic'})[2];
}

say '</main>';

put_chart();

say '</body>';
say '</html>';

