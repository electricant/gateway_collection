#!/bin/bash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

echo "Content-type: text/plain; charset=utf-8"
echo ""

systemctl is-active dhcpd4
