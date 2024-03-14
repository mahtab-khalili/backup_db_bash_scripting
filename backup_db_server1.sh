#!/bin/bash

# This script creates a backup of a database and saves it to a file
# The backup is then uploaded to a remote server via SCP

# Set variables
DB_NAME="server1_db_name"
DB_USER="server1_db_user"
DB_PASS="server1_db_password"
BACKUP_DIR="/path"
BACKUP_FILE="$BACKUP_DIR/db-backup-$(date +%Y-%m-%d-%H-%M-%S).sql"
REMOTE_USER="server2_user_name"
REMOTE_HOST="0.0.0.0" #server2 ip address
REMOTE_SSH_PORT= 21 # enter your ssh port on server2
REMOTE_DIR="/home"
YESTERDAY_BACKUP=$(find "$BACKUP_DIR" -type f -name "db-backup-*.sql" -print -quit)



# Dump the database and compress it
docker exec container_db mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $BACKUP_FILE

# Upload the backup to the remote server
scp -P $REMOTE_SSH_PORT -i ~/.ssh/db-backup-key $BACKUP_FILE $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR

# Check if the scp transfer was successful
if [ $? -eq 0 ]; then
  echo "$(date +\%Y\%m\%d) - Transfer successful"

  # Import changes on Server2
  ssh -p 3031 $REMOTE_USER@$REMOTE_HOST "/home/import-backup-db.sh"

  # Check if the import on Server2 was successful
  if [ $? -eq 0 ]; then
    echo "$(date +\%Y\%m\%d) - Import on Server2 successful"

    # Update the timestamp of the last synchronization on Server1
    date +"%Y-%m-%d %H:%M:%S" > $LAST_SYNC_FILE
  else
    echo "$(date +\%Y\%m\%d) - Error during import on Server2"
  fi
else
  echo "$(date +\%Y\%m\%d) - Error during transfer to Server2"
fi

# Remove yesterday's backup
if [ -e "$YESTERDAY_BACKUP" ]; then
   rm "$YESTERDAY_BACKUP"
fi

# Remove backups older than 1 days
# find $BACKUP_DIR -type f -name "backup-*.sql" -mtime +1 -exec rm {} \;

# Update the timestamp of the last synchronization
date +"%Y-%m-%d %H:%M:%S" > /home/last_sync_timestamp.txt

