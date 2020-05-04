#!/usr/bin/env sh
#
# Mount /var/log as overlayfs with tmpfs overlay.
# To save changes permanently just unomunt /var/log and copy data from
# /var/log.overlay/upper

# Create tmpfs for overlay stuff
mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=16m,mode=0775 tmpfs /var/log.overlay

# Create required directories
mkdir /var/log.overlay/upper
mkdir /var/log.overlay/work

# Mount overlay
mount -t overlay -o rw,lowerdir=/var/log,upperdir=/var/log.overlay/upper,workdir=/var/log.overlay/work overlay /var/log
