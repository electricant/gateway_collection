#
# Makefile to fetch files from kharon

get-all:
	#
	# HTTP gui
	#
	@scp -r root@lilith:/srv/http/* http/
	#
	# fortia login daemon
	#
	@scp -r root@lilith:/root/ONAOSI/* fortia/perl/
	@scp root@lilith:/usr/local/bin/connect.sh aux_scripts/
	@scp root@lilith:/etc/systemd/system/wifi_connect.service services/
	#
	# various auxiliary scripits
	#
	@scp root@lilith:/root/tpl/blocklist-update.sh aux_scripts/
	@scp root@lilith:/root/redirect/redirect.pl aux_scripts/
	#
	# services
	#
	@scp root@lilith:/etc/systemd/system/blocklist-update.service services/
	@scp root@lilith:/etc/systemd/system/blocklist-update.timer services/
	@scp root@lilith:/etc/systemd/system/http_proxy.service services/
	@scp root@lilith:/etc/systemd/system/repos-update.service services/
	@scp root@lilith:/etc/systemd/system/repos-update.timer services/
	@scp root@lilith:/etc/systemd/system/socks_proxy.service services/
	@scp root@lilith:/etc/systemd/system/remote_help.service services/
	#
	# config files
	#
	@scp root@lilith:/etc/dnsmasq.conf config/
	@scp root@lilith:/etc/hostapd/hostapd.conf config/
	@scp root@lilith:/etc/lighttpd/lighttpd.conf config/
	@scp root@lilith:/etc/minidlna.conf config/
	@scp root@lilith:/etc/samba/smb.conf config/
	@scp root@lilith:/etc/squid/squid.conf config/
	@scp root@lilith:/etc/ssmtp/ssmtp.conf config/
