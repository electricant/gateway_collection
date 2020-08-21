#!/usr/bin/env bash
#
# Simple script to update the DNS blocklist for unbound
#

set -e # Exit when any command fails

# Lists to pull the hosts from
SOURCES=("http://www.malwaredomainlist.com/hostslist/hosts.txt"
         "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Dead/hosts"
	   "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
	   "https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts"
	   "https://raw.githubusercontent.com/azet12/KADhosts/master/KADhosts.txt"
	   "https://someonewhocares.org/hosts/hosts"
	   "https://raw.githubusercontent.com/llacb47/mischosts/master/social/tiktok-block"
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
	echo Downloading $src
	# remove unneeded whitespace and make all ips 0.0.0.0
	curl -s $src | sed 's/\r//;s/127.0.0.1/0.0.0.0/' >>$TEMPFILE
done

echo Lines before cleanup:
wc -l $TEMPFILE

# Cleanup ip addresses (ignoring comments) & remove localhost stuff
cat $TEMPFILE | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ { print $1,$2 }' \
     | grep -vE 'local$|localhost.*$|broadcasthost$|ip6-.*$' > $TEMPFILE.dedup
# Cleanup 2nd pass: remove duplicates
sort -u $TEMPFILE.dedup > $TEMPFILE

echo Lines after cleanup:
wc -l $TEMPFILE

# Now convert it into a format that unbound can handle
# see: https://deadc0de.re/articles/unbound-blocking-ads.html
cat $TEMPFILE \
	| awk '{print "local-zone: \""$2"\" redirect"
	        print "local-data: \""$2" A 0.0.0.0\""}' > $TEMPFILE.unbound

# Install
cp $TEMPFILE.unbound $TARGET
systemctl reload unbound
