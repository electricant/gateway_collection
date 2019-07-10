#!/bin/bash
#
# Save or reload iptables configuration
#
RULES_FILE="/etc/iptables.rules"

# use a rule to test wether or not iptables is already configured
iptables -t nat -C POSTROUTING -o ppp0 -j MASQUERADE &>/dev/null
retval=$?
if [[ $retval == 1 ]]; then
	# reload configuration
	echo "Iptables configuration reloaded."
	iptables-restore -c <$RULES_FILE	
else
	# save counters
	echo "Counters saved."
	iptables-save -c >$RULES_FILE
fi
