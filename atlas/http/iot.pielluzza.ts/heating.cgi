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

# Load configuration file
BEGIN { require "./cgi/config.pl"; }

sub print_header
{
	say '<!DOCTYPE html>';
	say '<html><head>';
	say '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>';
	say '<meta name="viewport" content="width=device-width, initial-scale=1">';
	say '<title>Pielluzza IoT Dashboard | Heating</title>';

	say '<script src="js/mqttws31.min.js"></script>';
	say '<script src="js/heating.js"></script>';
	say '<link rel="stylesheet" href="css/mvp.css"/>';
	#<!-- <link href="css/style.css" rel="stylesheet" type="text/css"> -->
	say '</head>';
	
	say '<body>';
	say '<header><nav>';
	say '<a href="/" style="font-size: 18px">';
	say '<img alt="logo" src="favicon.ico" height="18" style="margin:0">Pielluzza IoT Dashboard</a>';
	say '<ul>';
	say '<li><a href="/index.html">&#x1F4CA; Dashboard</a></li>';
	say '<li><a href="/heating.html">&#x1F525; Heating</a></li>';
	say '</ul>';
	say '</nav></header>';
}

sub put_thermostat
{
	my ( $heater, $relay ) = @_;
	say "<details id=\"det-$heater\">";
	say "<summary>$heater</summary>";
	say "<p>Status: <ph id=\"stat-$heater\">unknown</ph></p>";
	say "<p>Relay: $relay (status: <ph id=\"rly-$relay\">?</ph>)</p>";
	say '<p>Temperature <input id="inTemp" type="text" ' .
		'style="display:inline; width:5em" placeholder="ex. 17.0">';
	say '<button type="button" style="padding:0 0.5rem; margin-left:0.5rem"' .
		" onclick=\"sendTemp('$heater')\">Apply</button></p>";
	say '<p>Mode: <button type="button" ' .
		'style="padding:0 0.5rem; margin-left:0.5rem;"' .
		" onclick=\"sendMode('A', '$heater')\">AUTO</button>";
	say '<button type="button" ' .
		'style="padding:0 0.5rem; margin-left:0.5rem;"' .
		" onclick=\"sendMode('0', '$heater')\">OFF</button></p>";
	say '</details>';
}

print "Content-type:text/html\r\n\r\n";

print_header();

say '<main>';
say '<div>' .
	'<img style="max-width: max-content; width:100%" ' .
		'src="dog_heat.gif"/>'.
    '</div>';

say '<div id="sec-heaters">';
say '<h2>Heating nodes</h2>';

# Enumerate thermostats and put them in the webpage
my $forward_json = path(FORWARD_FILE)->slurp;
my @fw = @{decode_json($forward_json)};

foreach (@fw) {
	# The topic strings are in the form:
	# 	'pielluzza/heating/cece-test/decision'
	# 	'pielluzza/relay/cece-test/enable'
	# So we split on '/' and extract the 3rd (index = 2) element
	my $heater = (split '/', $_->{'decision-topic'})[2];
	my $relay = (split '/', $_->{'relay-topic'})[2];

	put_thermostat($heater, $relay);
}

say '</div>';
say '</main>';

say '</body>';
say '</html>';

