#!/bin/bash
#
# Script with some commands to control the device.
# Accepted commands are:
#  fortia_status    -> Retrieve the status of the authenticator service
#                      0 means "running", 1 means "stopped"
#  fortia_restart   -> Restart the authenticator service
#  fortia_log       -> Return the log file for the authenticator service
#

#
# GLOBAL VARIABLES
#

# General purpose logfile. It mus exist and be readable
LOGFILE="/var/log/devctl.log"

#
# ACTUAL CODE
#
echo "Content-type: text/plain"
echo ""

# the command is the first entry before '='
command=$(echo $QUERY_STRING | awk 'BEGIN { FS = "=" } ; { print $1 }')
# parameter follows '='. Must be decoded
param=$(echo $QUERY_STRING | awk 'BEGIN { FS = "="  } ; { print $2 }' | sed -e 's/%20/ /g' -e 's/%21/!/g')

case "$command" in
	"fortia_status") 
		systemctl status wifi_connect | grep -q running
		echo $?
		;;
	"fortia_restart")
		sudo systemctl restart wifi_connect
		echo OK
		;;
	"fortia_log") 
		echo "## Service status:"
		sudo systemctl -l status wifi_connect
		echo ""
		echo "## fortia.log:"
		cat /var/log/fortia.log
		;;
	"log")
		echo $(date +"%b %d %T") $REMOTE_ADDR $REMOTE_HOST: $param >>$LOGFILE
		if [[ $? == 0 ]]; then
			echo OK
		else
			echo FAIL
		fi
		;;
	"get_log")
		cat $LOGFILE
		;;
	"clear_log")
		echo "" >$LOGFILE
		if [[ $? == 0 ]]; then
                        echo OK
                else
                        echo FAIL
                fi
		;;
	"misc_stats")
		uptime
		echo ""
		free -h
		echo -ne "\nHard disk temperature: "
		sudo smartctl -a /dev/sda | awk '/Temperature_Celsius/ { printf "%u", $10 }'
		echo "°C"
		;;
	"squid_status")
		squidclient -p 3129 mgr:info
		;;
	"timers")
		systemctl list-timers -all
		;;
	"proxy_status")
		sudo systemctl -l status socks_proxy
		echo ""
		sudo systemctl -l status http_proxy
		;;
	*) echo Unrecognized command: $QUERY_STRING
		;;
esac
