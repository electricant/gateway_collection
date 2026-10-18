#!/bin/bash
#
# Backup script that uses fsarchiver to backup a single partition.
# This script is used to quickly re-deploy a linux system to a new disk.
#
set -euo pipefail

# Partition to backup
BACKUP_PART="/dev/mmcblk0p1"
# Backup target directory (no trailing slash!)
BACKUP_DIR="/mnt/backup"
# Prefix for the backup archive file to which the current date will be appended
ARCHIVE_PREFIX="mmcblk0p1-"
# Target free space in $BACKUUP_DIR. Old backups will be deleted until there is
# this amount of free space in the directory
MIN_FREE_MB=2048

# Compute the available space in $BAKUP_DIR
function space_avail {
	df -Pm $BACKUP_DIR | tail -1 | awk '{print $4}'
}

echo "Free space in $BACKUP_DIR is $(space_avail) MB."

# Delete old bakups until there's enough free space
while [ $(space_avail) -lt $MIN_FREE_MB ]
do
	to_del=$(find "$BACKUP_DIR" -maxdepth 1 -name "$ARCHIVE_PREFIX*" \
		| sort | head -n1)

	echo "Deleting $to_del to free up space."
	rm $to_del
	echo "Free space is now $(space_avail) MB."
done

echo Backup running...
fsarchiver savefs -A -j2 -Z6 \
	"$BACKUP_DIR/$ARCHIVE_PREFIX$(date +"%Y%m%d").fsa" \
	$BACKUP_PART --exclude='/var/cache/pacman/pkg/*' --exclude='/var/log/journal/*'
echo Backup complete.

