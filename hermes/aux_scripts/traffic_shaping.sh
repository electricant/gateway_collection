#!/bin/bash
#
# Setup traffic shaping for this device.
# The classes are simple as I'm am intrested to keep interactivity high by
# limiting the maximum throughput

# exit when any command fails
set -e

# Speed and RTT definitions for CAKE (see man tc-cake for more information)
SPEED_DOWN="20Mbit"
SPEED_UP="16Mbit"
RTT="50ms"

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

###############################
# Iptables rules for priority #
###############################
iptables -t mangle -F POSTROUTING

# Low-latency high priority services & packets are marked as 10
if iptables -t mangle -N NO_SHAPE ; then
	iptables -t mangle -A NO_SHAPE -j MARK --set-mark 10
fi

# TCP control packets that do not carry data
iptables -t mangle -A POSTROUTING -p tcp \
	--tcp-flags URG,ACK,PSH,RST,SYN,FIN ACK -m length --length 40:64 \
	-j NO_SHAPE
# Local network transfers
iptables -t mangle -A POSTROUTING -s 192.168.0.0/16 -d 192.168.0.0/16 \
	-j NO_SHAPE
# DNS requests to/from this host
#iptables -t mangle -A POSTROUTING -p tcp -s 192.168.13.2 --dport 53 -j NO_SHAPE
#iptables -t mangle -A POSTROUTING -p tcp -d 192.168.13.2 --sport 53 -j NO_SHAPE
#iptables -t mangle -A POSTROUTING -p udp -s 192.168.13.2 --dport 53 -j NO_SHAPE
#iptables -t mangle -A POSTROUTING -p udp -d 192.168.13.2 --sport 53 -j NO_SHAPE
iptables -t mangle -A POSTROUTING -m owner --uid-owner unbound -j NO_SHAPE
# SSH connections
iptables -t mangle -A POSTROUTING -p tcp --dport 22 -j NO_SHAPE
iptables -t mangle -A POSTROUTING -p tcp --sport 22 -j NO_SHAPE
# UDP packets also do not like being dropped
#iptables -t mangle -A POSTROUTING -p udp -j NO_SHAPE

# Bulk transfers do not require low latency and slow everything down.
# Mark everything as CS1 and let CAKE deal with them
if iptables -t mangle -N BULK ; then
	iptables -t mangle -A BULK -j DSCP --set-dscp-class CS1
fi

# FTP(S)
iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 20,21,989,990 \
     	-j BULK
iptables -t mangle -A POSTROUTING -p tcp -m multiport --sports 20,21,989,990 \
     	-j BULK
# Long HTTP(S) connections
iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 80,443 \
	-m connbytes --connbytes $((3*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j BULK
iptables -t mangle -A POSTROUTING -p tcp -m multiport --sports 80,443 \
	-m connbytes --connbytes $((3*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j BULK
# Oddball HTTP ports are marked directly as bulk
iptables -t mangle -A POSTROUTING -p tcp -m multiport --dports 591,8000,8008,8080 \
     	-j BULK
iptables -t mangle -A POSTROUTING -p tcp -m multiport --sports 591,8000,8008,8080 \
     	-j BULK

