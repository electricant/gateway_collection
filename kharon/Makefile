#
# Makefile to fetch files from kharon

get-all:
	# HTML gui
	@scp -r root@kharon:/usr/share/mini-httpd/cgi/* cgi/
	@scp root@kharon:/usr/share/mini-httpd/index.html .
	@scp root@kharon:/usr/share/mini-httpd/favicon.png .
	# scripts
	@scp root@kharon:/usr/local/bin/connect.sh .
	@scp root@kharon:/usr/local/bin/iptables.sh .
	# services
	@scp root@kharon:/etc/systemd/system/iptables.service services/
	# iptables configuration
	@scp root@kharon:/etc/iptables.rules .