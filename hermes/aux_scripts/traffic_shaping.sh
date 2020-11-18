#!/bin/bash
#
# Script to setup traffic shaping for this device.

# Exit when any command fails
set -e

# Speed and RTT definitions for CAKE (see man tc-cake for more information)
SPEED_DOWN="15Mbit"
SPEED_UP="14Mbit"
RTT="60ms"

# Priomap definition for tc-prio. When dequeueing, band 0 is tried first and
# only if it did not deliver a packet does PRIO try band 1, and so onwards.
# Maximum reliability packets should therefore go to band 0.
# See https://linux.die.net/man/8/tc-prio or man tc-prio for more info
PRIOMAP="1 1 1 1  1 1 1 1  0 0 0 0  1 1 1 1"

#
# Function to setup traffic shaping queues for the given device.
# A prio queue with two bands is used as the root to differentiate maximum
# reliability traffic from the rest. Maximum reliability traffic is delivered
# using tc-codel while the rest of the traffic is shaped using tc-cake to avoid
# starvation.
#
# Parameters:
#  $1 -> interface shaping is applied to
#  $2 -> speed limit for the interface
#  $3 -> additional parameters for cake, such as 'ingress'
#
tc_setup () {
	# Reset interface just to be safe (ignoring errors)
	tc qdisc del dev $1 root || true

	tc qdisc add dev $1 root handle 1: prio bands 2 priomap $PRIOMAP
	# bfifo limit is calculated assuming <5ms latency and 10Mbit/s rate
	tc qdisc add dev $1 parent 1:1 handle 10: bfifo limit 48Kb
	tc qdisc add dev $1 parent 1:2 handle 20: cake bandwidth $2 rtt $RTT \
		ethernet $3
	# send packets marked as 10 to the maximum reliability queue
	tc filter add dev $1 parent 1: protocol ip prio 1 handle 10 fw flowid 1:1
}

# Download goes out of eth0, tell cake we are shaping ingress packets
tc_setup eth0 $SPEED_DOWN "ingress dual-dsthost"
# Upload is the data going out of eth1 (from LAN to internet)
tc_setup eth1 $SPEED_UP dual-srchost

# Apply iptables rules for priority: first we identify high priority and
# best-effort services, then mark the rest as bulk.
iptables -t mangle -F POSTROUTING

# Low-latency high priority services & packets are marked as 10
if iptables -t mangle -N NO_SHAPE ; then
	iptables -t mangle -A NO_SHAPE -j MARK --set-mark 10
	iptables -t mangle -A NO_SHAPE -j ACCEPT # skip other rules
fi

# VOIP traffic that is not already marked falls into this chain
if iptables -t mangle -N SET_EF ; then
	iptables -t mangle -A SET_EF -j DSCP --set-dscp-class EF
	iptables -t mangle -A SET_EF -j ACCEPT # skip other rules
fi

# Traffic to be marked as BULK falls into this chain
if iptables -t mangle -N SET_BULK ; then
	iptables -t mangle -A SET_BULK -j DSCP --set-dscp-class CS1
	iptables -t mangle -A SET_BULK -j ACCEPT # skip other rules
fi

# Local network transfers (and local multicast) must not be shaped
iptables -t mangle -A POSTROUTING -s 127.0.0.0/8 -d 127.0.0.0/8 -j ACCEPT
iptables -t mangle -A POSTROUTING -s 192.168.0.0/16 -d 192.168.0.0/16 \
	-j NO_SHAPE
iptables -t mangle -A POSTROUTING -s 192.168.0.0/16 -d 239.0.0.0/8 \
	-j NO_SHAPE
# TCP control packets that do not carry data are maximum prio
iptables -t mangle -A POSTROUTING -p tcp \
	--tcp-flags URG,ACK,PSH,RST,SYN,FIN ACK -m length --length 40:64 \
	-j NO_SHAPE
# Do not shape icmp
iptables -t mangle -A POSTROUTING -p icmp -j NO_SHAPE
# DNS requests to/from this host are maximum priority
iptables -t mangle -A POSTROUTING -m owner --uid-owner unbound -j NO_SHAPE
# Better not delay NTP
iptables -t mangle -A POSTROUTING -p udp --dport 123 -j NO_SHAPE
iptables -t mangle -A POSTROUTING -p udp --sport 123 -j NO_SHAPE

# Mark VOIP as EF
iptables -t mangle -A POSTROUTING -p udp -m multiport --dports 8200,1853 \
	-j SET_EF -m comment --comment "VOIP, GoToMeeting"
iptables -t mangle -A POSTROUTING -p udp -m multiport --sports 8200,1853 \
	-j SET_EF -m comment --comment "VOIP, GoToMeeting"
iptables -t mangle -A POSTROUTING -p udp -m multiport --sports 3478:3481 \
	-j SET_EF -m comment --comment "Skype, Microsoft Teams"
iptables -t mangle -A POSTROUTING -p udp -m multiport --dports 3478:3481 \
	-j SET_EF -m comment --comment "Skype, Microsoft Teams"

# Short HTTP(S) connections are best-effort. Accept them straight away
iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT
iptables -t mangle -A POSTROUTING -p tcp -m multiport --sports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT

# Leave alone all the packets that already have a TOS/DSCP class set.
# NOTE: DSCP is a subset/extension of TOS, no need to match it.
iptables -t mangle -A POSTROUTING -m tos ! --tos 0 -j ACCEPT

# Everything else is sent to bulk. Log the packets used to start the connection
# just to make sure we are not delaying traffic that should not belong here.
iptables -t mangle -A POSTROUTING -m state --state NEW -m limit --limit 5/min \
	-j LOG --log-prefix "iptables-bulk: "
iptables -t mangle -A POSTROUTING -j SET_BULK
