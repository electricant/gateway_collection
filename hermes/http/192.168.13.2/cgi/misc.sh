#!/bin/dash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

echo "Content-type: text/plain; charset=utf-8"
echo ""

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
awk '{printf "%3.2f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp
awk '{printf " @ %uMHz\n", $1/1000}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq

echo #empty
echo --------------------
echo " Traffic Shaping:"
echo --------------------
echo eth0:
tc -s -d qdisc ls dev eth0
echo eth1:
tc -s -d qdisc ls dev eth1

exit 0
