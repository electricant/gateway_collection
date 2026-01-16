#
# Makefile to fetch config files from the selected host
HOST_SRC=root@192.168.8.4

# SSH connection multiplexing options.
# This creates a master connection that all subsequent `scp` commands will
# reuse, so you only enter the password once.
SSH_OPTS=-o ControlMaster=auto \
	   -o ControlPath=/tmp/ssh-%r@%h:%p \
	   -o ControlPersist=10m

SCP=scp $(SSH_OPTS)
SSH=ssh $(SSH_OPTS)

get-all:
	# Establish master SSH connection
	@$(SSH) -fNT $(HOST_SRC) || true

	# Getting HTTP gui files...
	@$(SCP) -r $(HOST_SRC):/srv/http/192.168.8.4 http/
	@$(SCP) -r $(HOST_SRC):/srv/http/iot.pielluzza.ts http/

	# Getting various auxiliary scripts...
	@$(SCP) $(HOST_SRC):/home/alarm/traffic_shaping.sh  aux_scripts/
	@$(SCP) $(HOST_SRC):/home/alarm/blocklist-update.sh aux_scripts/

	# Getting service files...
	@$(SCP) $(HOST_SRC):/etc/systemd/system/traffic_shaping.service \
		services/
	@$(SCP) $(HOST_SRC):/etc/systemd/system/mosquitto.service.d/* \
		services/mosquitto.service.d
	@$(SCP) $(HOST_SRC):/etc/systemd/system/unbound.service.d/* \
		services/unbound.service.d
	@$(SCP) $(HOST_SRC):/etc/systemd/system/ntpd.service.d/* \
		services/ntpd.service.d
	@$(SCP) $(HOST_SRC):/etc/systemd/system/sensor_logger.service \
		services/
	
	# Getting dnsmasq config files
	@$(SCP) $(HOST_SRC):/etc/dnsmasq.conf config/dnsmasq/
	@$(SCP) $(HOST_SRC):/etc/ethers       config/dnsmasq/etc.ethers
	@$(SCP) $(HOST_SRC):/etc/hosts        config/dnsmasq/etc.hosts

	# Getting unbound config files
	@$(SCP) $(HOST_SRC):/etc/unbound/*.conf config/unbound/

	# Getting systemd-networkd config files
	@$(SCP) $(HOST_SRC):/etc/systemd/network/*        config/systemd-networkd/

	# Getting udev rules
	@$(SCP) $(HOST_SRC):/etc/udev/rules.d/*           config/udev-rules.d/

	# Getting config files...
	@$(SCP) $(HOST_SRC):/etc/lighttpd/lighttpd.conf   config/
	@$(SCP) $(HOST_SRC):/etc/ssh/sshd_config          config/
	@$(SCP) $(HOST_SRC):/etc/iptables/iptables.rules  config/
	#@$(SCP) $(HOST_SRC):/etc/vnstat.conf              config/
	@$(SCP) $(HOST_SRC):/etc/ntp.conf                 config/
	@$(SCP) $(HOST_SRC):/etc/sysctl.d/*               config/sysctl/
	@$(SCP) $(HOST_SRC):/home/alarm/.bashrc           config/bashrc
	@$(SCP) $(HOST_SRC):/home/alarm/.vimrc            config/vimrc
	@$(SCP) $(HOST_SRC):/etc/mosquitto/mosquitto.conf config/
	@$(SCP) $(HOST_SRC):/etc/systemd/swap.conf        config/

init:
	@mkdir -p http/192.168.8.4 http/iot.pielluzza.ts
	@mkdir -p aux_scripts
	@mkdir -p services/mosquitto.service.d
	@mkdir -p services/unbound.service.d
	@mkdir -p services/ntpd.service.d
	@mkdir -p config/dnsmasq config/unbound
	@mkdir -p config/systemd-networkd config/udev-rules.d
	@mkdir -p config/sysctl
