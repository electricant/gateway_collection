#!/usr/bin/env bash
#
# Simple script to update the DNS blocklist for unbound
#

set -e # Exit when any command fails

# Lists to pull the hosts from
#
# See also:
#	https://firebog.net/
#	https://www.github.developerdan.com/hosts/
SOURCES=("http://www.malwaredomainlist.com/hostslist/hosts.txt"
         "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts"
	   "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
	   "https://someonewhocares.org/hosts/hosts"
	   "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
	   "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
	   "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
	   "https://raw.githubusercontent.com/llacb47/mischosts/master/social/tiktok-block"
	   "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
#	   "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
	   "https://raw.githubusercontent.com/llacb47/mischosts/master/microsoft-telemetry"
	  )

# Temporary file where the hosts are stored
TEMPFILE=/tmp/rawlist.tmp

# File where the cleaned list will be installed
TARGET=/etc/unbound/blocked-domains.conf

# Clean temporary download file
echo "" > $TEMPFILE

# Download sources and append them to the temp file
for src in ${SOURCES[@]}
do
	partialTmp=$(mktemp).block
	
	echo Downloading: $src
	# remove unneeded whitespace and make all ips 0.0.0.0
	curl -s $src | sed 's/\r//;s/127.0.0.1/0.0.0.0/' >$partialTmp
	echo Hosts: $(wc -l $partialTmp)
	cat $partialTmp >>$TEMPFILE
done

echo Lines before cleanup: $(wc -l $TEMPFILE)

# Cleanup ip addresses (ignoring comments) & remove localhost stuff
cat $TEMPFILE | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ { print $1,$2 }' \
     | grep -vE 'local$|localhost.*$|broadcasthost$|ip6-.*$' > $TEMPFILE.dedup
# Cleanup 2nd pass: remove duplicates
sort -u $TEMPFILE.dedup > $TEMPFILE

echo Lines after cleanup: $(wc -l $TEMPFILE)

# Now convert the list entries into a format that unbound can handle:
# We want to retrieve the domain part only and tell unbound to always return
# NXDOMAIN for such a request. This is faster and requires less memory.
cat $TEMPFILE \
	| awk '{print "local-zone: \""$2"\" always_nxdomain"}' > $TEMPFILE.unbound

# Install
cp $TEMPFILE.unbound $TARGET
systemctl reload unbound
