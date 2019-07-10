#!/bin/bash
#
# Script that outputs the device's logs
#

echo "Content-type: text/plain; charset=utf-8"
echo ""

# the command is the first entry before '='
command=$(echo $QUERY_STRING | awk 'BEGIN { FS = "=" } ; { print $1 }')

case "$command" in
	"fortia") 
		sudo systemctl status wifi_connect
		;;
	"misc")
		uptime
		echo ""
		free -h
		echo -ne "\nHard disk temperature: "
		sudo smartctl -a /dev/sda | awk '/Temperature_Celsius/ { printf "%u", $10 }'
		echo -ne "°C"
		;;
	"proxy")
		echo "● squid stats"
		squid_stats=$(squidclient -p 3129 mgr:info | sed -e 's/^[ \t]*//')
		echo "$squid_stats" | grep "Number of clients"
		echo "$squid_stats" | grep "Hits as"
		echo "$squid_stats" | grep Storage
		echo ""
		sudo systemctl -n5 status socks_proxy
		echo ""	
		sudo systemctl -n5 status http_proxy
		;;
	"timers")
		systemctl list-timers -all
		;;
	*) echo Unrecognized command: $QUERY_STRING
		;;
esac
