#!/bin/dash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

echo "Content-type: text/plain; charset=utf-8"
echo ""

case "$QUERY_STRING" in
	json)
		printf '{\n\t"uptime": "'
		uptime | xargs echo -n
		printf '",\n'
		
		printf '\t"CPU": {\n'
		printf '\t\t"frequency": "'
		awk '{printf "%uMHz", $1/1000}' \
			/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
		printf '",\n'
		printf '\t\t"temperature": "'
		awk '{printf "%3.2f°C", $1/1000}'\
		     	/sys/class/thermal/thermal_zone0/temp	
		printf '"\n\t},\n'
		
		printf '\t"memory": {\n'
		free=$(free -h)
		printf '\t\t"mem-total": '
		echo -n $free | awk '{ print "\"" $8 "\"," }'
		printf '\t\t"mem-used": '
		echo -n $free | awk '{ print "\"" $9 "\"," }'
		printf '\t\t"mem-free": '
		echo -n $free | awk '{ print "\"" $10 "\"" }'
		printf '\t}\n'

		printf '}\n'
		;;
	*)
		echo --------------------
		echo " Uptime:"
		echo --------------------
		uptime

		echo #empty line
		echo --------------------
		echo " Memory:"
		echo --------------------
		free -h

		echo #empty line
		echo --------------------
		echo " CPU:"
		echo --------------------
		awk '{printf "%3.2f°C", $1/1000}'\
		     	/sys/class/thermal/thermal_zone0/temp
		awk '{printf " @ %uMHz\n", $1/1000}' \
			/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq

		echo #empty
		echo --------------------
		echo " Traffic Shaping:"
		echo --------------------
		echo "* DOWNLOAD (eth0)":
		tc -s qdisc ls dev eth0 | awk '{print "\t",$0;}'
		echo "* UPLOAD (eth1)":
		tc -s qdisc ls dev eth1 | awk '{print "\t",$0;}'
esac

exit 0
