#
# Makefile to fetch config files from the selected host
HOST_SRC="root@192.168.8.4:"
#HOST_SRC="/media/pol/aac9f320-2825-4de6-bc58-25016b7799e3"

get-all:
	# Getting HTTP gui files...
	@scp -r $(HOST_SRC)/srv/http/192.168.8.4 http/
	@scp -r $(HOST_SRC)/srv/http/iot.pielluzza.ts http/

	# Getting various auxiliary scripts...
	@scp $(HOST_SRC)/home/alarm/traffic_shaping.sh  aux_scripts/
	@scp $(HOST_SRC)/home/alarm/blocklist-update.sh aux_scripts/

	# Getting service files...
	@scp $(HOST_SRC)/etc/systemd/system/traffic_shaping.service   services/
	@scp $(HOST_SRC)/etc/systemd/system/mosquitto.service.d/* \
		services/mosquitto.service.d
	@scp $(HOST_SRC)/etc/systemd/system/sensor_logger.service     services/
	
	# Getting dnsmasq config files
	@scp $(HOST_SRC)/etc/dnsmasq.conf config/dnsmasq/
	@scp $(HOST_SRC)/etc/ethers       config/dnsmasq/etc.ethers
	@scp $(HOST_SRC)/etc/hosts        config/dnsmasq/etc.hosts

	# Getting unbound config files
	@scp $(HOST_SRC)/etc/unbound/*.conf config/unbound/

	# Getting config files...
	@scp $(HOST_SRC)/etc/thttpd.conf              config/
	@scp $(HOST_SRC)/etc/systemd/network/*        config/systemd-networkd/
	@scp $(HOST_SRC)/etc/ssh/sshd_config          config/
	@scp $(HOST_SRC)/etc/iptables/iptables.rules  config/
	#@scp $(HOST_SRC)/etc/vnstat.conf              config/
	@scp $(HOST_SRC)/etc/ntp.conf                 config/
	@scp $(HOST_SRC)/etc/sysctl.d/*               config/sysctl/
	@scp $(HOST_SRC)/home/alarm/.bashrc           config/bashrc
	@scp $(HOST_SRC)/home/alarm/.vimrc            config/vimrc
	@scp $(HOST_SRC)/etc/mosquitto/mosquitto.conf config/

init:
	@mkdir -p http/192.168.8.4 http/iot.pielluzza.ts
	@mkdir aux_scripts
	@mkdir services
	@mkdir services/mosquitto.service.d
	@mkdir -p config/dnsmasq config/unbound config/systemd-networkd \
		config/sysctl

