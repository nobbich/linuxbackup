#!/bin/bash
# create in /usr/local/bin/incr_backup_to_smb.sh
set -e

BACKUP_DIR="/mnt/rsyncXyz"
CONF_FILE="/etc/backup_paths.conf"
LOG_FILE="/var/log/backup_to_smb.log"
TODAY=$(date +%Y-%m-%d)
TARGET_DIR="$BACKUP_DIR/$TODAY"
MAX_BACKUPS=5

echo "==== Backup started at $(date) ====" >> "$LOG_FILE"

# Check mount
if ! mountpoint -q "$BACKUP_DIR"; then
    echo "$(date) - Mounting SMB share..." >> "$LOG_FILE"
    mount "$BACKUP_DIR"
fi

# Check if target dir exists
mkdir -p "$TARGET_DIR"

# Execute backup
while read -r path; do
    if [[ -d "$path" ]]; then
        echo "$(date) - Backing up $path" >> "$LOG_FILE"
        rsync -a "$path" "$TARGET_DIR/"
    else
        echo "$(date) - ERROR: Path $path not found!" >> "$LOG_FILE"
    fi
done < "$CONF_FILE"

# Cleanup old backups: keep last 5
echo "$(date) - Check for old backups..." >> "$LOG_FILE"
cd "$BACKUP_DIR"
ls -1d 20*/ | sort | head -n -"$MAX_BACKUPS" | while read oldbackup; do
    echo "$(date) - Remove old backup folder $oldbackup" >> "$LOG_FILE"
    chmod -R u+w "$oldbackup"  # remove write protection before delete
    rm -rf "$oldbackup"
done

# Add write protection for old backups (the actual one stays writeable)
echo "$(date) - set write protection to..." >> "$LOG_FILE"
ls -1d 20*/ | grep -v "$TODAY" | while read oldbackup; do
    chmod -R a-w "$oldbackup"
done

echo "==== Backup done on $(date) ====" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
