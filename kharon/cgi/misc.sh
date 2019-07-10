#!/bin/bash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

echo "Content-type: text/plain"
echo ""

echo --------------------
echo " DHCP Leases:"
echo --------------------
cat /var/lib/misc/dnsmasq.leases

echo #empty line
echo --------------------
echo " Uptime:"
echo --------------------
uptime

echo #empty line
echo --------------------
echo " Memory:"
echo --------------------
free

echo #empty line
echo --------------------
echo " CPU:"
echo --------------------
awk '{printf "%3.2f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp
awk '{printf " @ %uMHz\n", $1/1000}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq
exit 0
