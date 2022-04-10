#!/bin/bash

echo "Content-type: text/plain"
echo ""

always_online=1 # Number of clients always online and present in the ARP table
tot_online=$(arp -a | grep ether.*eth0 | wc -l)

expr $tot_online - $always_online
