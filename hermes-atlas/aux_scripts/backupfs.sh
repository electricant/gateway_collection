#!/bin/bash
#
# Back up a single partition with fsarchiver, so the system can be quickly
# re-deployed to a new disk.
#
# The script stops with an error, which makes the systemd service fail, when:
#  - the backup drive is not mounted,
#  - the source filesystem has recorded errors since its last fsck,
#  - freeing space would leave fewer than KEEP_MIN archives,
#  - fsarchiver or the kernel report errors during the run.
#
set -euo pipefail

# Partition to back up
BACKUP_PART="/dev/mmcblk0p1"
# Backup target directory (no trailing slash); must be a mount point
BACKUP_DIR="/mnt/backup"
# Prefix of the archive files; the current date is appended
ARCHIVE_PREFIX="mmcblk0p1-"
# Old archives are deleted until this much space (MB) is free ...
MIN_FREE_MB=2048
# ... but the newest KEEP_MIN archives are never deleted
KEEP_MIN=3

fail() {
	echo "BACKUP FAILED: $*" >&2
	exit 1
}

space_avail() {
	df -Pm "$BACKUP_DIR" | tail -1 | awk '{print $4}'
}

# Write only to the backup drive, never to the root filesystem underneath it
mountpoint -q "$BACKUP_DIR" || fail "$BACKUP_DIR is not mounted"

# Do not archive a filesystem that has recorded errors since its last fsck
fs_errors=$(tune2fs -l "$BACKUP_PART" | \
	awk -F: '/^FS Error count/ {print $2+0}')
[ "${fs_errors:-0}" -eq 0 ] ||
	fail "$BACKUP_PART has recorded $fs_errors errors. Stopping."

# Delete the oldest archives until there is enough free space,
# but never the newest KEEP_MIN
echo "Free space in $BACKUP_DIR is $(space_avail) MB."
while [ "$(space_avail)" -lt "$MIN_FREE_MB" ]; do
	mapfile -t archives < <(find "$BACKUP_DIR" -maxdepth 1 -name "${ARCHIVE_PREFIX}*.fsa" | sort)
	[ "${#archives[@]}" -gt "$KEEP_MIN" ] ||
		fail "only $(space_avail) MB free and ${#archives[@]} archives left; not deleting more"
	echo "Deleting ${archives[0]} to free up space."
	rm -- "${archives[0]}"
	echo "Free space is now $(space_avail) MB."
done

archive="$BACKUP_DIR/${ARCHIVE_PREFIX}$(date +%Y%m%d).fsa"
start=$(date '+%Y-%m-%d %H:%M:%S')
log=$(mktemp)
trap 'rm -f "$log"' EXIT

echo "Backup running..."
fsarchiver savefs -A -j2 -Z6 "$archive" "$BACKUP_PART" \
	--exclude='/var/cache/pacman/pkg/*' \
	--exclude='/var/log/journal/*' 2>&1 | tee "$log"

# fsarchiver reports zero errors for files whose inodes the kernel refuses,
# so check its summary and the kernel log for the duration of the run
problems=$(
	grep -E 'files with errors:.*=[1-9]' "$log" || true
	journalctl -k -q --no-pager --since "$start" |
		grep -E 'EXT4-fs (error|warning)|I/O error|mmc[0-9]+: .*(error|stuck)' || true
)
if [ -n "$problems" ]; then
	mv -- "$archive" "$archive.suspect"
	fail "errors during the backup, archive renamed to $archive.suspect:
$problems"
fi

echo "Backup complete: $archive"

