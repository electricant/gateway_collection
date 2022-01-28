#!/bin/bash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

# max-age is in seconds, set it to 24h
MAX_AGE=$((24*60*60))

# HTTP headers
echo "Content-type: text/html"
echo "Cache-Control: max-age=$MAX_AGE"
echo "Date: " $(env TZ=GMT date '+%a, %d %b %Y %T %Z')
echo ""

# Webpage header
cat header.html

# Actual content
echo '<div class="content-wrapper">'

echo '<h2>Hardware</h2>'
echo '<h3>Uptime</h3>'
echo '<p>'$(uptime)'</p>'
echo '<h3>Memory</h3>'
free -h | \
	awk '/Mem/ { print "<p>Total: " $2 "B used: " $3 "B free: " $4 "B</p>" }'
echo '<h3>CPU</h3>'
awk '{printf "<p>%3.1f°C", $1/1000}' \
	/sys/class/thermal/thermal_zone0/temp
awk '{printf " @ %uMHz</p>\n", $1/1000}' \
	/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq

echo '<h2>Traffic shaping</h2>'
echo '<pre style="font-size: 14px; width:600px">'
echo "* DOWNLOAD (eth0)":
tc -s qdisc ls dev eth0 | awk '{print "\t",$0;}'
echo "* UPLOAD (eth1)":
tc -s qdisc ls dev eth1 | awk '{print "\t",$0;}'
echo '</pre>'

echo '<h2>Bulk traffic</h2>'
echo '<iframe class="termsize" src="/cgi/get_logs.sh?bulk"></iframe>'

echo '<h2>Dropped packets</h2>'
echo '<iframe class="termsize" src="/cgi/get_logs.sh?dropped"></iframe>'

echo '</div>'

# Footer
echo '</body></html>'
exit 0
