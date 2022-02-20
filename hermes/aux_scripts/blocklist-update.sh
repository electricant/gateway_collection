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
SOURCES=("https://someonewhocares.org/hosts/hosts"
	"https://pgl.yoyo.org/as/serverlist.php?hostformat=hosts;showintro=0"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
	"https://raw.githubusercontent.com/FadeMind/hosts.extras/master/CoinBlockerList/hosts"
	"https://raw.githubusercontent.com/llacb47/mischosts/master/social/tiktok-block"
	"https://raw.githubusercontent.com/llacb47/mischosts/master/microsoft-telemetry"
	"https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
	"https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
# Too many hostnames!
	"https://phishing.army/download/phishing_army_blocklist.txt"
#	"https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
#	"https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
#	"https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
	)

# Temporary file where the hosts are stored
TEMPFILE=/tmp/rawlist.tmp

# File where the cleaned list will be installed
TARGET=/etc/unbound/blocked-domains.conf

# Clean temporary download file
echo "" > $TEMPFILE

# Add custom hosts
# https://superuser.com/questions/363120/block-access-to-windows-update
echo "windowsupdate.microsoft.com" >> $TEMPFILE
echo "update.microsoft.com" >> $TEMPFILE
echo "windowsupdate.com" >> $TEMPFILE
echo "download.windowsupdate.com" >> $TEMPFILE
echo "download.microsoft.com" >> $TEMPFILE
echo "wustat.windows.com" >> $TEMPFILE
echo "ntservicepack.microsoft.com" >> $TEMPFILE
echo "stats.microsoft.com" >> $TEMPFILE
# Also block bitdefender
echo "bitdefender.com" >> $TEMPFILE
echo "bitdefender.net" >> $TEMPFILE

# Download sources and append them to the temp file
for src in ${SOURCES[@]}
do
	partialTmp=$(mktemp -t XXXXXX.block.part)
	
	echo Downloading: $src
	# Remove ips & whitespaces since we don't need them
	curl -s $src \
		| sed -r 's/(\b[0-9]{1,3}\.){3}[0-9]{1,3}\b\s//;s/\s+//' >$partialTmp
	wc -l $partialTmp
	# Also remove comments & DOS CR from lines
	cat $partialTmp | sed 's/#.*$//g;s/\r$//g' >>$TEMPFILE
done

echo Lines before cleanup: $(wc -l $TEMPFILE)

# Cleanup: remove localhost stuff, invalid and duplicate domains
cat $TEMPFILE \
	| grep -vE 'local$|localhost.*$|broadcasthost$|ip6-.*$' \
	| grep -E '^(([[:alnum:]_-]([[:alnum:]_-])*)\.)+[a-zA-Z]{2,}$' \
	>$TEMPFILE.dedup
sort -u $TEMPFILE.dedup > $TEMPFILE

echo Lines after cleanup: $(wc -l $TEMPFILE)

# Now convert the list entries into a format that unbound can handle, ignoring
# empty lines. We want to tell unbound to always return NXDOMAIN for such 
# domain requests and for all subdomains. This is faster and requires less
# memory.
cat $TEMPFILE \
	| awk 'NF {print "local-zone: \""$1".\" always_nxdomain"}' > $TEMPFILE.unbound

# Install, making sure the new list works bofore reloading
mv $TEMPFILE.unbound $TARGET
unbound-checkconf
systemctl reload unbound
