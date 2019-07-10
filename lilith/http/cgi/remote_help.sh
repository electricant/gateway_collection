#!/bin/bash
#
# Script with some commands to control the device.
# Basically just reboot and shutdown

echo "Content-type: text/plain"
echo ""

case "$QUERY_STRING" in
	"start")
		sudo systemctl start remote_help
		;;
	"stop")
		sudo systemctl stop remote_help
		;;
	"status")
		systemctl status remote_help | grep -q running || (printf STOPPED; kill $$)
		printf RUNNING
		;;
	*) echo Unrecognized command: $QUERY_STRING
		;;
esac
