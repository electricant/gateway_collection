#!/bin/bash
#
#

echo -e "Content-Type: text/plain\r\n"

cat /var/lib/misc/dnsmasq.leases

echo -e "\nConnected clients:"
echo -----------------------
sudo iw dev wlp0s29f7u2 station dump | grep -i '[0-9A-F]\{2\}\(:[0-9A-F]\{2\}\)\{5\}'

