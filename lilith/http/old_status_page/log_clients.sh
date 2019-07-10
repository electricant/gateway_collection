#!/bin/bash
#
# Script that keeps a list of the number of clients, updated each hour.
# The list is in the form: hour number
#

LOGFILE="/var/log/num_clients.log"

# delete the oldest line in file if too long. Need to move the file to edit it
# see: http://stackoverflow.com/questions/1759448/why-doesnt-tail-work-to-truncate-log-files
tail -n 23 $LOGFILE >$LOGFILE.tmp
mv $LOGFILE.tmp $LOGFILE

hour=$(date +%H)
clients=$(iw dev wlp0s29f7u2 station dump | grep Station | wc -l)

echo $hour $clients >>$LOGFILE
