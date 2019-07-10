#!/bin/bash
#
# Script that controls the device. Commands are sent through GET requests.
# Allowed commands are:
# connect/disconnect - Connects/disconnects to the mobile network
# halt - shuts down the device
# reset_counters - clear data usage counters
#

echo -e "Content-Type: text/html\r\n\r\n"
echo '<html>'
echo '<head><title>'
echo Executing: $1
echo '</title></head>'
echo '<body>'

if [ "$1" = "halt" ]; then
	sudo halt
elif [ "$1" = "connect" ]; then
	sudo sv start /etc/service/internet
elif [ "$1" = "disconnect" ]; then
	sudo sv stop /etc/service/internet
elif [ "$1" = "reset_counters" ]; then
	date +%s >/usr/share/mini-httpd/last_reset
	sudo iptables -Z	
else
	echo Command not recognized: $1
	echo '</body></html>'
	exit 1
fi

echo '<p>'
echo $1 complete.
echo '<p></body></html>'

exit 0
