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
start_day=23   # day of month the data cap renews
total_gb=120   # data cap per billing cycle, in GB

# "Today" as bare calendar fields (unpadded -> no octal traps in arithmetic)
now_day=$(date +%-d)
now_mo=$(date +%-m)
now_yr=$(date +%Y)

# Month/year on which the current cycle started
if [ "$now_day" -ge "$start_day" ]; then
	start_mo=$now_mo
	start_yr=$now_yr
else
	start_mo=$((now_mo - 1))
	start_yr=$now_yr
	if [ "$start_mo" -eq 0 ]; then
		start_mo=12
		start_yr=$((now_yr - 1))
	fi
fi

# Anchor every timestamp to UTC midnight. UTC has no DST, so the second
# differences stay exact multiples of 86400 and integer division never
# loses a day across the spring-forward / fall-back transitions.
start_ts=$(date --date="$start_yr-$start_mo-$start_day 00:00 UTC" +%s)
now_ts=$(date   --date="$now_yr-$now_mo-$now_day 00:00 UTC"       +%s)
next_ts=$(date  --date="$start_yr-$start_mo-$start_day 00:00 UTC +1 month" +%s)

total_days=$(( (next_ts - start_ts) / 86400 ))        # 28..31 for this cycle
days_elapsed=$(( (now_ts - start_ts) / 86400 + 1 ))   # incl. today

target=$(echo "scale=1; $total_gb * $days_elapsed / $total_days" | bc -l)

echo "<p>Target today: $target GB</p>"
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
