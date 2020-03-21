#!/bin/bash
#
# Setup traffic shaping for this device.
# The classes are simple as I'm am intrested to keep interactivity high by
# limiting the maximum throughput

# exit when any command fails
set -e

# Speed and latency definitions
SPEED_DOWN="28Mbit"
BURST_DOWN="256kbit" # 32k byte
LATENCY_DOWN="100ms"
SPEED_UP="15Mbit"
BURST_UP="128kbit" # 16k Byte
LATENCY_UP="70ms"

# see https://linux.die.net/man/8/tc-prio
PRIOMAP="1 1 1 1 1 1 0 0 1 1 1 1 1 1 1 1"

# Reset interfaces just to be safe (ignoring errors)
tc qdisc del dev eth0 root || true
tc qdisc del dev eth1 root || true

# Download is the data going out from eth0
# Use prio classful queue with two bands
# (one for low latency and one for target throughput)
tc qdisc add dev eth0 root handle 1: prio bands 2 priomap $PRIOMAP
tc qdisc add dev eth0 parent 1:1 handle 10: pfifo_fast
tc qdisc add dev eth0 parent 1:2 handle 20: tbf rate $SPEED_DOWN \
	latency $LATENCY_DOWN burst $BURST_DOWN
# send packets marked as 10 to the pfifo for low latency
tc filter add dev eth0 parent 1:0 protocol ip prio 10 handle 10 fw flowid 1:1

# Upload is the data going out of eth1
# use prio classful queue and route everything by default to 1:1
tc qdisc add dev eth1 root handle 1: prio bands 2 priomap $PRIOMAP
tc qdisc add dev eth1 parent 1:1 handle 10: pfifo_fast
tc qdisc add dev eth1 parent 1:2 handle 20: tbf rate $SPEED_UP \
	latency $LATENCY_UP burst $BURST_UP
# send packets marked as 10 to the pfifo for low latency
tc filter add dev eth1 parent 1:0 protocol ip prio 10 handle 10 fw flowid 1:1

# mark high priority packets as 10 (works on both interfaces)
iptables -t mangle -A POSTROUTING -p tcp \
	--tcp-flags URG,ACK,PSH,RST,SYN,FIN ACK -m length --length 40:64 \
	-j MARK --set-mark 10
iptables -t mangle -A POSTROUTING -p udp -j MARK --set-mark 10
# SSH is also high priority
iptables -t mangle -A POSTROUTING -p tcp --dport 22 -j MARK --set-mark 10
