#!/bin/bash
#
# Display data usage and the number of days since last reset
#
echo -e "Content-Type: text/plain\r\n"

sudo iptables -nvxL | ./traffic.awk

now=$(date +%s)
last_reset=$(cat /usr/share/mini-httpd/last_reset)
# there are 86400 seconds in a day
diff=$(( ($now - $last_reset) / 86400))
echo Last reset $diff days ago: $(date -d @$last_reset).

exit 0
