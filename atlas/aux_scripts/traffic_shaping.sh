#!/bin/bash
#
# Script to setup traffic shaping for this device.

# Exit when any command fails
set -e

# Interfaces definition
IF_DL="eth0"
IF_UL="lte0"

# Speed and RTT definitions for CAKE (see man tc-cake for more information)
SPEED_DOWN="36Mbit"
SPEED_UP="16Mbit"
RTT="80ms"

# Function to cleanup and remove traffic shaping
cleanup () {
	# Reset interfaces (ignoring errors if there's no root qdisc)
	tc qdisc del dev $IF_DL root || true
	tc qdisc del dev $IF_UL root || true
	
	# Flush mangle table rules
	# TODO: use a separate table for shaping? To avoid flushing the whole
	#       postrouting chain
	iptables -t mangle -F POSTROUTING
	
	# TSHAPE chain may not exist so ignore errors
	iptables -t mangle -F TSHAPE || true
	# NO_SHAPE chain may not exist so ignore errors
	iptables -t mangle -F NO_SHAPE || true
	# SET_EF chain may not exist so ignore errors
	iptables -t mangle -F SET_EF || true
}

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
	# Root qdisc just to separate packets into shaped ones (that go to cake)
	# and those that bypass shaping completely (that go to codel)
	tc qdisc add dev $1 root handle 1: prio bands 2 \
	       	priomap 1 1 1 1 1 1 1 1 1 1 1 1 1 1 # everything goes to cake
	
	tc qdisc add dev $1 parent 1:1 handle 10: codel ecn
	tc qdisc add dev $1 parent 1:2 handle 20: cake bandwidth $2 rtt $RTT \
		ethernet $3
	
	# send packets marked as 10 (local network packets and those that are
	# very sensitive to latency) to the maximum reliability queue
	tc filter add dev $1 parent 1: protocol ip prio 1 handle 10 fw flowid 1:1
}

# First some cleanup
cleanup

# If this script has been invoked with 'stop' as parameter just do the cleanup
if [ "$1" == "stop" ]; then
	exit 0
fi

# Setup queuing disciplines
tc_setup $IF_DL $SPEED_DOWN "ingress dual-dsthost"
tc_setup $IF_UL $SPEED_UP dual-srchost

# Setup iptables rules for traffic shaping

# Create tshape chain if it does not exist already and send to it only packets
# that exit from $IF_UL and $IF_DL without DSCP markings.
# Packets for which the TOS/DSCP field is already set are dealt with by cake
iptables -t mangle -N TSHAPE || true
iptables -t mangle -A POSTROUTING -o $IF_UL -m dscp --dscp 0 -j TSHAPE
iptables -t mangle -A POSTROUTING -o $IF_DL -m dscp --dscp 0 -j TSHAPE

# Chain for low-latency high priority services. Those are marked as 10.
# Those packets bypass the shaping rules completely. Use this sparingly.
iptables -t mangle -N NO_SHAPE || true
iptables -t mangle -A NO_SHAPE -j MARK --set-mark 10
iptables -t mangle -A NO_SHAPE -j ACCEPT # skip other rules

# VOIP traffic that is not already marked falls into this chain
iptables -t mangle -N SET_EF || true
iptables -t mangle -A SET_EF -j DSCP --set-dscp-class EF
iptables -t mangle -A SET_EF -j ACCEPT # skip other rules

# Local network transfers (and local multicast) must not be shaped
iptables -t mangle -A TSHAPE -s 192.168.0.0/16 -d 192.168.0.0/16 -j NO_SHAPE
iptables -t mangle -A TSHAPE -s 192.168.0.0/16 -d 239.0.0.0/8 -j NO_SHAPE

# Do not shape icmp
iptables -t mangle -A TSHAPE -p icmp -j NO_SHAPE

# DNS requests to/from this host are maximum priority
iptables -t mangle -A TSHAPE -m owner --uid-owner unbound -j NO_SHAPE

# Better not delay NTP
iptables -t mangle -A TSHAPE -p udp --dport 123 -j NO_SHAPE
iptables -t mangle -A TSHAPE -p udp --sport 123 -j NO_SHAPE

# TCP control packets that do not carry data contribute to cake rate but are maximum prio
iptables -t mangle -A TSHAPE -p tcp \
	--tcp-flags URG,ACK,PSH,RST,SYN,FIN ACK -m length --length 40:64 \
	-j SET_EF

# Mark VOIP as EF
iptables -t mangle -A TSHAPE -p udp -m multiport \
	--dports 5060:5090,8000:8200 -j SET_EF -m comment --comment "VOIP"
iptables -t mangle -A TSHAPE -p udp -m multiport \
       	--sports 5060:5090,8000:8200 -j SET_EF -m comment --comment "VOIP"
iptables -t mangle -A TSHAPE -p udp -m multiport --sports 3478:3481 \
	-j SET_EF -m comment --comment "Skype, Microsoft Teams"
iptables -t mangle -A TSHAPE -p udp -m multiport --dports 3478:3481 \
	-j SET_EF -m comment --comment "Skype, Microsoft Teams"
iptables -t mangle -A TSHAPE -p udp -m multiport --sports 8800:8810 \
	-j SET_EF -m comment --comment "Zoom P2P video"
iptables -t mangle -A TSHAPE -p udp -m multiport --dports 8800:8810 \
	-j SET_EF -m comment --comment "Zoom P2P video"

# Short HTTP(S) connections are best-effort. Accept them straight away
iptables -t mangle -A TSHAPE -p tcp -m multiport --dports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT
iptables -t mangle -A TSHAPE -p tcp -m multiport --sports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT

# The same for QUIC traffic used for browsing the web
iptables -t mangle -A TSHAPE -p udp -m multiport --dports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT
iptables -t mangle -A TSHAPE -p udp -m multiport --sports 80,443 \
	-m connbytes --connbytes 0:$((2*1024*1024)) --connbytes-mode bytes \
	--connbytes-dir both -j ACCEPT

# SSH connections should be marked as best effort (if not already marked)
iptables -t mangle -A TSHAPE -p tcp --dport 22 -j ACCEPT
iptables -t mangle -A TSHAPE -p tcp --sport 22 -j ACCEPT

# VPN packets are also best effort
iptables -t mangle -A TSHAPE -p udp --dport 1194 -j ACCEPT
iptables -t mangle -A TSHAPE -p udp --sport 1194 -j ACCEPT
iptables -t mangle -A TSHAPE -m owner --uid-owner openvpn -j ACCEPT

# Everything not matched by the rules above is sent to bulk. Log the packets
# just to make sure we are not delaying traffic that should not belong here.
# Use connmark to match already logged connections.
iptables -t mangle -A TSHAPE -m connmark ! --mark 9999 \
	-j LOG --log-prefix "iptables-bulk: "
iptables -t mangle -A TSHAPE -j CONNMARK --set-mark 9999
iptables -t mangle -A TSHAPE -j DSCP --set-dscp-class CS1

