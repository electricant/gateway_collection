#!/bin/sh -e
#
# This script connects the device to internet.
#
LOGFILE=/usr/share/mini-httpd/status/connection.log

echo Connecting... >$LOGFILE
# Modem setup
usb_modeswitch -v 12d1 -p 1446 -P 1436 -J -R >>$LOGFILE 2>&1
# connect
echo Waiting 15 seconds for carrier... >>$LOGFILE
sleep 15
wvdial >>$LOGFILE 2>&1 &
wvdial_pid=$!

# Connecting destroys resolv.conf restore it
sleep 60
echo 127.0.0.1 > /etc/resolv.conf
echo DNS servers restored >>$LOGFILE

# wait for wvdial to exit
wait $wvdial_pid

