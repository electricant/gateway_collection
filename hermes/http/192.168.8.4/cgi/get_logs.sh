#!/bin/dash
#
PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"

NUM_LINES=20

# Tell the client to close the connection. We do not suport keep-alive.
echo "Connection: close"
echo "Date: " $(env TZ=GMT date '+%a, %d %b %Y %T %Z')
echo "Content-type: text/plain; charset=utf-8\n"

case "$QUERY_STRING" in
	dropped)
		sudo dmesg -T | grep "iptables-dropped" | tail -n $NUM_LINES
		;;
	bulk)
		sudo dmesg -T | grep "iptables-bulk" | tail -n $NUM_LINES
		;;
	clear-logs)
		sudo dmesg --clear
		;;
	*)
esac
exit 0
