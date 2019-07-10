#!/bin/bash
#
# Script to restart all the services that make up the proxy functionality

echo "Content-type: text/plain"
echo ""

case "$QUERY_STRING" in
	"restart")
		sudo systemctl restart wifi_connect 2>&1
		retval=$?
		if [ "$retval" -ne "0" ]; then
			echo $retval
			exit $retval
		fi

		echo 0
		;;
	"status")
		systemctl status wifi_connect | grep -q running || (printf FAIL; kill $$)
		printf OK
		;;
	*)
		echo Unrecognized command: $QUERY_STRING
		;;
esac
