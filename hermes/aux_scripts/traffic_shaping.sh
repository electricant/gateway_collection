#!/bin/bash
#
# Setup traffic shaping for this device.
# The classes are simple as I'm am intrested to keep interactivity high by
# limiting the maximum throughput

# exit when any command fails
set -e

# Speed and RTT definitions for CAKE (see man tc-cake for more information)
SPEED_DOWN="12Mbit"
SPEED_UP="10Mbit"
RTT="60ms"

# see https://linux.die.net/man/8/tc-prio
PRIOMAP="1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 1"

# Reset interfaces just to be safe (ignoring errors)
tc qdisc del dev eth0 root || true
tc qdisc del dev eth1 root || true

# Download is the data going out from eth0
# Use prio classful queue with two bands
# (one for low latency and one for target throughput)
tc qdisc add dev eth0 root handle 1: prio bands 2 priomap $PRIOMAP
tc qdisc add dev eth0 parent 1:1 handle 10: codel
tc qdisc add dev eth0 parent 1:2 handle 20: cake bandwidth $SPEED_DOWN \
	rtt $RTT ingress ethernet ether-vlan
# send packets marked as 10 to the pfifo for low latency
tc filter add dev eth0 parent 1:0 protocol ip prio 10 handle 10 fw flowid 1:1

# Upload is the data going out of eth1
# use prio classful queue and route everything by default to 1:1
tc qdisc add dev eth1 root handle 1: prio bands 2 priomap $PRIOMAP
tc qdisc add dev eth1 parent 1:1 handle 10: codel
tc qdisc add dev eth1 parent 1:2 handle 20: cake bandwidth $SPEED_UP \
	rtt $RTT egress ethernet ether-vlan
# send packets marked as 10 to the pfifo for low latency
tc filter add dev eth1 parent 1:0 protocol ip prio 10 handle 10 fw flowid 1:1

#
# Apply iptables rules for priority: first we identify high priority and
# best-effort services, then mark the rest as bulk.
#
iptables -t mangle -F POSTROUTING

# Low-latency high priority services & packets are marked as 10
if iptables -t mangle -N NO_SHAPE ; then
	iptables -t mangle -A NO_SHAPE -j MARK --set-mark 10
	iptables -t mangle -A NO_SHAPE -j ACCEPT # skip other rules
fi

# TCP control packets that do not carry data are maximum prio
iptables -t mangle -A POSTROUTING -p tcp \
	--tcp-flags URG,ACK,PSH,RST,SYN,FIN ACK -m length --length 40:64 \
	-j NO_SHAPE
# Local network transfers (and local multicast) must not be shaped
iptables -t mangle -A POSTROUTING -s 192.168.0.0/16 -d 192.168.0.0/16 \
	-j NO_SHAPE
iptables -t mangle -A POSTROUTING -s 192.168.0.0/16 -d 239.0.0.0/8 \
	-j NO_SHAPE
# DNS requests to/from this host maximim priority
iptables -t mangle -A POSTROUTING -m owner --uid-owner unbound -j NO_SHAPE
# SSH connections are also latency-sensitive
iptables -t mangle -A POSTROUTING -p tcp --dport 22 -j NO_SHAPE
iptables -t mangle -A POSTROUTING -p tcp --sport 22 -j NO_SHAPE
# Better not delay NTP
iptables -t mangle -A POSTROUTING -p udp --dport 123 -j NO_SHAPE
iptables -t mangle -A POSTROUTING -p udp --sport 123 -j NO_SHAPE

# Mark VOIP as EF
iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 8200,1853 \
	-j DSCP --set-dscp-class EF
iptables -t mangle -A POSTROUTING -p udp -m multiport --dports 8200,1853 \
	-j DSCP --set-dscp-class EF
iptables -t mangle -A POSTROUTING -p tcp -m multiport --sports 8200,1853 \
	-j DSCP --set-dscp-class EF
iptables -t mangle -A POSTROUTING -p udp -m multiport --sports 8200,1853 \
	-j DSCP --set-dscp-class EF

# Short HTTP(S) connections are best-effort. Accept them straight away
iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT
iptables -t mangle -A POSTROUTING -p tcp -m multiport --sports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT

# Leave alone all the packets that already have a DSCP class and do not fall in 
# the rules above. Actually DSCP is a subset/extension of TOS so just one of
# those rules will match.
iptables -t mangle -A POSTROUTING -m tos ! --tos 0 -j ACCEPT
iptables -t mangle -A POSTROUTING -m dscp ! --dscp 0 -j ACCEPT

# Everything else is bulk: mark everything as CS1 and let CAKE deal with it
iptables -t mangle -A POSTROUTING -m limit --limit 1/min -j LOG \
	--log-prefix "iptables-bulk: "
iptables -t mangle -A POSTROUTING -j DSCP --set-dscp-class CS1
