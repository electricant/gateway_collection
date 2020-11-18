#
# Makefile to fetch files from kharon
HOST=root@192.168.8.4

get-all:
	# Getting HTTP gui files...
	@scp -r $(HOST):/srv/http/192.168.8.4 http/
	@scp -r $(HOST):/srv/http/iot.pielluzza.ts http/

	# Getting various auxiliary scripits...
	@scp $(HOST):/home/alarm/traffic_shaping.sh aux_scripts/
	@scp $(HOST):/home/alarm/var_log_overlay.sh aux_scripts/
	@scp $(HOST):/home/alarm/blocklist-update.sh aux_scripts/

	# Getting service files...
	@scp $(HOST):/usr/lib/systemd/system/traffic_shaping.service services/
	@scp $(HOST):/etc/systemd/system/var_log_overlay.service services/

	# Getting config files...
	@scp $(HOST):/etc/thttpd.conf config/
	@scp $(HOST):/etc/iptables/iptables.rules config/
	@scp $(HOST):/etc/vnstat.conf config/
	@scp $(HOST):/boot/config.txt config/
	@scp $(HOST):/boot/cmdline.txt config/
	@scp $(HOST):/etc/unbound/unbound.conf config/
	@scp $(HOST):/etc/ntp.conf config/
	@scp $(HOST):/etc/sysctl.d/* config/sysctl/
	@scp $(HOST):/etc/systemd/network/* config/systemd-networkd/
