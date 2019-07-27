#!/bin/dash
#
# Script to test if some services are active and output their status in
# JSON format.
# More info on JSON here: https://www.w3schools.com/js/js_json_intro.asp
#

# Setup environment path
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

# Check for services and save their status in a variable.
# When $? is 0 then the service is active. Otherwhise it is not active.
systemctl is-active --quiet pdnsd
pdnsd_status=$?
systemctl is-active --quiet dhcpd4
dhcpd_status=$?
systemctl is-active --quiet traffic_shaping
traffic_shaping_status=$?
systemctl is-active --quiet iptables
iptables_status=$?

# If all services above are active then the overall status is good
overall_status=$((pdnsd_status + dhcpd_status + traffic_shaping_status \
	+ iptables_status))

# Output the data
echo "Content-type: application/json; charset=utf-8"
echo ""
echo "{\"overall\" : $overall_status, \"pdnsd\" : $pdnsd_status," \
     "\"dhcpd\" : $dhcpd_status, \"iptables\" : $iptables_status," \
     "\"traffic_shaping\" : $traffic_shaping_status}"

