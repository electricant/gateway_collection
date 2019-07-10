#!/bin/sh
#

# Directory holding temporary files
TEMP_DIR="/tmp"
# Location of tpl2dnsmasq
TPL2DNSMASQ="/root/tpl/tpl2dnsmasq"

curl https://easylist-msie.adblockplus.org/easyprivacy.tpl >$TEMP_DIR/list.tpl

# clean the list from known and/or wrong domains
sed -i '/opera.com/d' $TEMP_DIR/list.tpl

# save and restart dnsmasq
$TPL2DNSMASQ $TEMP_DIR/list.tpl >/etc/dnsmasq.d/blocklist.conf
systemctl restart dnsmasq

