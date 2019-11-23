#
# Makefile to fetch files from kharon
HOST=root@192.168.13.2

get-all:
	# Getting HTTP gui files...
	@scp -r $(HOST):/srv/http/* http/

	# Getting various auxiliary scripits...
	@scp $(HOST):/home/alarm/traffic_shaping.sh aux_scripts/
	@scp $(HOST):/home/alarm/blocklist-update.sh aux_scripts/

	# Getting service files...
	@scp $(HOST):/usr/lib/systemd/system/traffic_shaping.service services/

	# Getting config files...
	@scp $(HOST):/etc/thttpd.conf config/
	@scp $(HOST):/etc/iptables/iptables.rules config/
	@scp $(HOST):/etc/vnstat.conf config/
	@scp $(HOST):/etc/dhcpd.conf config/
	@scp $(HOST):/boot/config.txt config/
	@scp $(HOST):/etc/unbound/unbound.conf config/
