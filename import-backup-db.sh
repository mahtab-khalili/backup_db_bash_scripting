#!/bin/bash

# // ******************************** SET VARIABLES ********************************* //

# Database details for Server2
DB_HOST="localhost"
DB_USER="root"
DB_PASSWORD="123456"
DB_NAME="database"

# Backup directory on Server2
BACKUP_DIR="/home/backup-db"

# Find the latest backup file with the format "db-backup-*.sql"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/db-backup-*.sql | head -n 1)

# Log directory
LOG_DIR="/home/backup-db/logs"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

# Monthly log file
MONTHLY_LOG_FILE="$LOG_DIR/restore_log_$(date +\%Y\%m).txt"

# Backup file for yesterday
YESTERDAY_BACKUP=$(find "$BACKUP_DIR" -type f -name "db-backup-*.sql" -print -quit)

# // ******************************** IMPORT DATABASE  ********************************* //

# Check if a backup file is found for today
if [ -n "$LATEST_BACKUP" ]; then

    # Import the changes
    docker exec -i container-db-bkup mysql -u $DB_USER -p$DB_PASSWORD --init-command="SET foreign_key_checks=0;"  $DB_NAME < $LATEST_BACKUP

   # Check if the import was successful
    if [ $? -eq 0 ]; then
        echo "$(date +\%Y\%m\%d) - Database restored from: $LATEST_BACKUP" >> "$MONTHLY_LOG_FILE"

	# Remove yesterday's backup

	if [ -e "$YESTERDAY_BACKUP" ]; then
           rm "$YESTERDAY_BACKUP"
           echo "$(date +\%Y\%m\%d) - Yesterday's backup removed: $YESTERDAY_BACKUP" >> "$MONTHLY_LOG_FILE"
        else
           echo "$(date +\%Y\%m\%d) - Yesterday's backup not found: $YESTERDAY_BACKUP" >> "$MONTHLY_LOG_FILE"
       fi

    else
        echo "$(date +\%Y\%m\%d) - Error during database import. Backup file not removed." >> "$MONTHLY_LOG_FILE"
    fi
else
  echo "$(date +\%Y\%m\%d) - No backup files found in $BACKUP_DIR" >> "$MONTHLY_LOG_FILE"
fi

