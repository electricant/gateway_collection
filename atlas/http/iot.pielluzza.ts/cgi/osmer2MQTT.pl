#!/usr/bin/env -S perl -I ./
#
# This script fetches the real-time weather data from https://www.osmer.fvg.it/home.php,
# available at https://dev.meteo.fvg.it/ and publishes it using MQTT
#
use v5.12;
use warnings;

use POSIX;
use utf8;
use Net::MQTT::Simple;
use LWP::Simple; # perl-libwww perl-lwp-protocol-https
use XML::LibXML; # perl-xml-libxml
use Data::Dumper;

# Load configuration file
BEGIN { require "./config.pl"; }
our $MQTT_BROKER;

###
# Main
###

# List of URLs to query for data and their topic
my %osmer_urls = ( 'https://dev.meteo.fvg.it/xml/stazioni/BGG.xml' => 'pielluzza/sensors/osmerFVG_bgg',
                   'https://dev.meteo.fvg.it/xml/stazioni/TRI.xml' => 'pielluzza/sensors/osmerFVG_tri' );

my $mqtt = Net::MQTT::Simple->new($MQTT_BROKER);

foreach my $url (keys %osmer_urls)
{
	my $msg = fetchURL($url);
	say 'Publishing to: ' . $osmer_urls{$url};
	$mqtt->retain($osmer_urls{$url} => $msg);
}

###
# This function receives an URL as a parameter, fetches it and returns the
# weather data in JSON format, ready to be sent using MQTT
###
sub fetchURL {
	my $content = get($_[0]);
	die "Can't GET weather data." if (! defined $content);

	my $dom = XML::LibXML->load_xml(string => $content);

	say $dom->findvalue('/data/meteo_data/station_name'), ' ', $dom->findvalue('/data/meteo_data/observation_time');
	my $json_payload = "{\n";
	$json_payload .= '"temp": ' . $dom->findvalue('/data/meteo_data/t180') . ",\n";
	$json_payload .= '"rhum": ' . $dom->findvalue('/data/meteo_data/rh') . ",\n";
	$json_payload .= '"pres": ' . $dom->findvalue('/data/meteo_data/press') . ",\n";
	$json_payload .= '"wind": "' . $dom->findvalue('/data/meteo_data/v10') . '/'
		. $dom->findvalue('/data/meteo_data/vmax') . '"';
	$json_payload .= "\n}";
	say $json_payload;
	
	return $json_payload;
}

