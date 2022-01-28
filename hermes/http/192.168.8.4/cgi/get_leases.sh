#!/bin/bash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

echo "Content-type: text/html"
echo ""

echo '<table style="width:100%; text-align:center">'
echo '<tr>'
echo '<th>Expiry</th><th>MAC Address</th><th>IP Address</th><th>Host Name</th>'
echo '</tr>'
cat /tmp/dnsmasq.leases | \
	awk 'NF > 2 {print "<tr><td>" strftime("%d %b %Y %T",$1) "</td><td>" $2 \
		"</td><td>" $3 "</td><td>" $4 "</td></tr>"}'
echo '</table>'
