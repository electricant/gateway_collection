#!/bin/bash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

# max-age is in seconds, set it to 24h
MAX_AGE=$((24*60*60))

# HTTP headers
echo "Content-type: text/html"
echo "Cache-Control: max-age=$MAX_AGE"
echo ""

# Webpage header
cat header.html

# Actual content
echo '<div class="content-wrapper">'

echo '<h2>Overall Status</h2>'
echo '<button class="pure-button tooltip">'
echo '<i id="statusIcon" class="fa fa-spinner"></i>'
echo '<span id="statusTooltip" class="tooltiptext">Loading...</span></button>'

echo '<h3>Uptime</h3>'
echo '<p>'$(uptime)'</p>'

echo '<h3>Memory</h3>'
free -h | \
      awk '/Mem/{print "<p>RAM: " $2 "B used: " $3 "B free: " $4 "B</p>"}'
df -h | \
      awk '/mmcblk0p1/{print "<p>SD card: " $2 "B used: " $3 "B ("$5")</p>"}'

echo '<h2>Internet Connection</h2>'
gb_day=4 # TODO: compute this value from GB/month and days between renewal
start_day=23

now_day=$(date +%d)
now_mo=$(date +%-m)
now_yr=$(date +%Y)
now_ts=$(date --date="$now_yr-$now_mo-$now_day" +%s) 

if [ $start_day -gt $now_day ]
then
	((start_mo=$now_mo-1))
else
	start_mo=$now_mo
fi

if [ $start_mo -eq 0 ]
then
	((start_yr=$now_yr-1))
	start_mo=12
else
	start_yr=$now_yr
fi

start_ts=$(date --date="$start_yr-$start_mo-$start_day" +%s) 
# https://stackoverflow.com/questions/4946785/how-to-find-the-difference-in-days-between-two-dates
((days_diff=(($now_ts-$start_ts) / (60*60*24)) ))
echo '<p>Target today: '
echo "scale=2; ($days_diff+1)*$gb_day" | bc -q
echo ' GB</p>'
echo '<p><a href="http://192.168.8.1/html/statistic.html">[Statistics]</a></p>'

echo '<h2>Network Topology</h2>'
echo '<table style="width:600px;text-align:center;font-family:monospace;">'
echo '<tr><td>'
echo '<i class="fas fa-broadcast-tower"></i>'
echo '<br/><b>Huawei E3372</b><br/>'
echo '<a href="http://192.168.8.1">[192.168.8.1]</a>'
echo '</td><td>'
echo '<i class="fab fa-usb"></i>'
echo '<br/> <==> </td><td>'
echo '<i class="fab fa-raspberry-pi"></i>'
echo '<br/><b>Raspberry Pi</b><br/>'
echo '<a href="http://192.168.8.4">[192.168.8.4]</a>'
echo '</td><td>'
echo '<i class="fas fa-ethernet"></i>'
echo '<br/> <==> </td><td>'
echo '<i class="fas fa-wifi"></i>'
echo '<br/><b>Wi-Fi</b><br/>'
echo '<a href="http://192.168.8.5">[192.168.8.5]</a>'
echo '</td></tr><tr><td> <!-- empty --> </td><td> <!-- empty --> </td>'
echo '<td><a href="http://iot.pielluzza.ts">[IoT dashboard]</a></td>'
echo '</tr></table></div>'

# Footer
echo '</body></html>'
exit 0
