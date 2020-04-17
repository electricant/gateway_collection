#!/bin/dash
#
# Script to test if the most important services are up and running and if the
# device is connected to the internet. The status is output in JSON format.
#

# Setup environment path
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

echo "Connection: close" # We do not support keep-alive
echo "Date: " $(env TZ=GMT date '+%a, %d %b %Y %T %Z')
echo "Content-type: application/json; charset=utf-8\n"

# Check for services and save their status in a variable.
# When $? is 0 then the service is active. Otherwhise it is not active.
ps -C unbound >/dev/null
dns_status=$?

ps -C dhcpd >/dev/null 
dhcpd_status=$?

systemctl is-active --quiet iptables 
iptables_status=$?

# The same as above, just for checking internet connectivity
ping -q -c 1 -W 0.15 ipol.ml >/dev/null 2>&1
internet_status=$?

# If all services above are active then the overall status is good
overall_status=$((dns_status + dhcpd_status + iptables_status + \
	            internet_status))

# Output headers and data
echo "{\n\t\"overall\": $overall_status, \"dns_server\": $dns_status," \
     "\"dhcpd\": $dhcpd_status, \"iptables\": $iptables_status," \
     "\"internet_status\": $internet_status\n}"
