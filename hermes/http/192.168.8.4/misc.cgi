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

echo '<h2>Traffic shaping</h2>'
echo '<pre style="font-size: 14px; width:600px">'
echo "* DOWNLOAD (eth0)":
tc -s qdisc ls dev eth0 | awk '{print "\t",$0;}'
echo "* UPLOAD (lte0)":
tc -s qdisc ls dev lte0 | awk '{print "\t",$0;}'
echo '</pre>'
echo '</div>'

echo '<h2>Bulk traffic</h2>'
echo '<table><tr>'
echo '<th>Timestamp</th>'
echo '<th>Source</th>'
echo '<th>Destination</th>'
echo '<th>Protocol</th>'
echo '</tr>'
journalctl -re | grep bulk | head -n 15 | \
	perl -n -e '/(\w+ \d+ \d+:\d+:\d+).*SRC=([\d.]+).*DST=([\d.]+).*PROTO=(\w+).*SPT=(\d+).*DPT=(\d+)/g && print "<tr><td>$1</td><td>$2:$5</td><td>$3:$6</td><td>$4</td></tr>"'
echo '</table>'

echo '<h2>Dropped / Rejected traffic</h2>'
echo '<table><tr>'
echo '<th>Timestamp</th>'
echo '<th>Source</th>'
echo '<th>Destination</th>'
echo '<th>Protocol</th>'
echo '</tr>'
journalctl -re | grep -E "dropped|rejected" | head -n 15 | \
      perl -n -e '/(\w+ \d+ \d+:\d+:\d+).*SRC=([\d.]+).*DST=([\d.]+).*PROTO=(\w+).*SPT=(\d+).*DPT=(\d+)/g && print "<tr><td>$1</td><td>$2:$5</td><td>$3:$6</td><td>$4</td></tr>"'
echo '</table>'

# Footer
echo '</body></html>'
exit 0

