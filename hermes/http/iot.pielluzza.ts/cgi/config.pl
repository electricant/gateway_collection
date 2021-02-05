#
# Configuration file for the IoT backend
#

# URL for the MQTT broker to listen to
use constant MQTT_BROKER => 'localhost';

# MQTT topic to subsribe to for logging purposes
use constant MQTT_LOG_TOPIC => 'pielluzza/sensors/+';

# Directory where the sensor readings are saved
# Each sensor will have its own filename called <ID>.csv inside here
use constant SAVE_DIR => '/srv/http/iot.pielluzza.ts/data';

# Minimum sampling interval (in minutes) to save data into SAVE_DIR
use constant SAVE_INTERVAL_MIN => 30;

# Temporary directory used to store data before writing it to SAVE_DIR
use constant TEMP_DIR => '/tmp';

1; # Do not remove this. Otherwhise this file will not work as expected.
# https://stackoverflow.com/questions/5964594/perl-constant-require
