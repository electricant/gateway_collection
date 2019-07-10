#!/bin/bash
#
# Script with some commands to control the device.
# Basically just reboot and shutdown

echo "Content-type: text/plain"
echo ""

case "$QUERY_STRING" in
	"reboot")
		echo Riavvio del sistema in corso...
		sudo shutdown -r now
		;;
	"shutdown")
		echo Spegnimento in corso...
		sudo shutdown -h now
		;;
	*) echo Unrecognized command: $QUERY_STRING
		;;
esac
