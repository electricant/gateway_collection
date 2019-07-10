#!/bin/bash
#

# Connect to WiFi network
ip link set wlp2s4 down
rfkill unblock all
ip link set wlp2s4 up
iwconfig wlp2s4 essid ONAOSI
dhclient -q wlp2s4
# uncomment the following line if resolv.conf is writable
#echo nameserver 127.0.0.1 >/etc/resolv.conf

# setup iptables
iptables -t nat -C POSTROUTING -o wlp2s4 -j MASQUERADE
retval=$?
if [[ $retval == 1 ]]; then
	iptables -t nat -A POSTROUTING -o wlp2s4 -j MASQUERADE
	iptables -t nat -A PREROUTING -d 192.168.6.1 -j ACCEPT
	iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to 192.168.6.1:53
	iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 192.168.6.1:53
	iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3128
	iptables -t nat -A PREROUTING -p tcp -d 192.168.65.254 --dport 1000 -j REDIRECT --to-port 3128
fi

# Add traffic shaping
tc qdisc del dev wlp0s29f7u2 root
tc qdisc add dev wlp0s29f7u2 root tbf rate 4Mbit latency 50ms burst 32k

# authenticate using fortia (see sources)
/root/ONAOSI/fortia.pl
