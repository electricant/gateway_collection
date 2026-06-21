#
# Makefile to fetch config files from the selected host
# Note: rsync must be installed on both the local and remote machines.
HOST_SRC="root@192.168.8.4:"
#HOST_SRC="/media/pol/aac9f320-2825-4de6-bc58-25016b7799e3"
RSYNC_CMD=rsync -avz

get-all:
	# Getting HTTP gui files...
	@$(RSYNC_CMD) $(HOST_SRC)/srv/http/ http/

	# Getting various auxiliary scripts...
	@$(RSYNC_CMD) \
		$(HOST_SRC)/home/alarm/traffic_shaping.sh \
		$(HOST_SRC)/home/alarm/blocklist-update.sh \
		aux_scripts/

	# Getting service files...
	@$(RSYNC_CMD) \
		$(HOST_SRC)/etc/systemd/system/traffic_shaping.service \
		$(HOST_SRC)/etc/systemd/system/sensor_logger.service \
		services/
	@$(RSYNC_CMD) $(HOST_SRC)/etc/systemd/system/mosquitto.service.d/ services/mosquitto.service.d/
	
	# Getting dnsmasq config files...
	@$(RSYNC_CMD) \
		$(HOST_SRC)/etc/dnsmasq.conf \
		$(HOST_SRC)/etc/ethers \
		$(HOST_SRC)/etc/hosts \
		config/dnsmasq/

	# Getting config files...
	@$(RSYNC_CMD) \
		$(HOST_SRC)/etc/lighttpd/lighttpd.conf \
		$(HOST_SRC)/etc/ssh/sshd_config \
		$(HOST_SRC)/etc/iptables/iptables.rules \
		$(HOST_SRC)/etc/ntp.conf \
		$(HOST_SRC)/etc/mosquitto/mosquitto.conf \
		config/
	@$(RSYNC_CMD) $(HOST_SRC)/etc/systemd/network/ config/systemd-networkd/
	@$(RSYNC_CMD) $(HOST_SRC)/etc/sysctl.d/ config/sysctl/
	@$(RSYNC_CMD) $(HOST_SRC)/home/alarm/.bashrc config/bashrc
	@$(RSYNC_CMD) $(HOST_SRC)/home/alarm/.vimrc config/vimrc
