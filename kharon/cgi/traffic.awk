#!/usr/bin/awk -f
#
# Awk script that counts data usage and outputs it in MB, % and days remaining
# It parses the output of iptables looking for the chain data_total
#
BEGIN 	{ } # do nothing
/data_total/	{ sum += $2 } # number of bytes is on the second column
END 	{ mb = sum/(1024*1024)
	ratio = (mb / 4096)
	days = (1 - ratio) * 30
	printf "%.0fMB (%3.2f%s - %2.1f days remaining)\n", mb, ratio * 100, "%", days}
