#
# Configuration file for the IoT backend
#
use Readonly;

# URL for the MQTT broker to listen to
Readonly our $MQTT_BROKER => 'localhost';

# Directory where the sensor readings are saved.
# TODO: make my and do not export (will be used below)
Readonly our $SAVE_DIR => '/srv/http/iot.pielluzza.ts/data';

# Temporary directory used to store data before writing it to SAVE_DIR
# TODO: make my and do not export (will be used below)
Readonly our $TEMP_DIR => '/tmp';

# Topics to log. Logging is performed using two files:
#  - One for short-term storage
#  - One for long-term storage
# The short-term storage stores data for a fixed amount of time (in minutes)
# after which such data is consolidated into long-term storage (limited only
# by the size of your hard drive).
# The data format is based on recfiles: https://en.wikipedia.org/wiki/Recfiles
Readonly our %LOG_TOPICS => (
	'pielluzza/sensors/osmerFVG_bgg' => {
		'short_data'    => $TEMP_DIR . '/osmerFVG_bgg.rec',
		'long_data'     => $SAVE_DIR . '/osmerFVG_bgg.rec',
		'save_interval' => 30,
	},
	'pielluzza/sensors/osmerFVG_tri' => {
		'short_data'    => $TEMP_DIR . '/osmerFVG_tri.rec',
		'long_data'     => $SAVE_DIR . '/osmerFVG_tri.rec',
		'save_interval' => 30,
	},
	'pielluzza/sensors/cece-soggiorno' => {
		'short_data'    => $TEMP_DIR . '/cece-soggiorno.rec',
		'long_data'     => $SAVE_DIR . '/cece-soggiorno.rec',
		'save_interval' => 30,
	},
	'pielluzza/heating/cece-soggiorno/status' => {
		'short_data'    => $TEMP_DIR . '/cece-soggiorno_heating.rec',
		'long_data'     => '/dev/null', # Throw it away
		'save_interval' => 1440, # 1 day
	},
);

# mqtt topic to subsribe to for forwarding purposes
Readonly our $MQTT_FORWARD_TOPIC => 'pielluzza/heating/+/decision';

# JSON file where the forward table for the thermostat-relay association is
# stored. Its content is of the type:
# [
#   {
#     "decision-topic" : ".../.../...",
#     "relay-topic"    : ".../.../..."
#   },
#   ...
# ]
Readonly our $FORWARD_FILE => $SAVE_DIR . '/forward.conf.json';

1; # Do not remove this. Otherwhise this file will not work as expected.
# https://stackoverflow.com/questions/5964594/perl-constant-require
