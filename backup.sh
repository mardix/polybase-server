# --------------------------------------------------------------------------
# Polybase-Server backup.sh
#
# curl https://raw.githubusercontent.com/mardix/lunabase-server/master/backup.sh > lunbase-server-backup.sh
# chmod 755 lunabase-server-backup.sh
# ./lunabase-server-backup.sh
#--------------------------------------------------------------------------
# *** Example with incremental backup
# > ./lunabase-server-backup.sh
# *** To archive a backup, add -a. It will place the backup inside of /archive
# > ./lunabase-server-backup.sh --archive
################################################################
################################################################
# CONFIGURATION
# AWS
CONF_AWS_BUCKET_NAME="BUCKET"

# 
# DATA_LIST 
# List of data dir to backup to S3
# format: $NAME:$DATA_DIR
# one data dir per line
#
DATA_LIST="
redis:/var/lib/redis
arango:/var/lib/arangodb3
typesense:/var/lib/typesense
influxdb:/var/lib/influxdb/data
"

# --------------------------------------------------------------
################################################################
# STOP!!!
# DO NOT MODIFY BELOW, UNLESS YOU KNOW WHAT YOU ARE DOING :) 
################################################################
APP_NAME="Polybase-Server"
# Backup time
DT_NOW=`date +%H00`
# Datetime for archive backup
DT_ARCHIVE=`date +%Y%m%d%H00`
# Daily name, from 0=sunday, 6=saturday -> daily.0
DT_DAILY=$(date +"%H00")



echo 
echo "$APP_NAME backup..."
echo 

for fname in $DATA_LIST
do
  IFS=":" read -a data <<< "$fname"
  NAME=${data[0]}
  DATA_DIR=${data[1]}
  BACKUP_NAME=$NAME
  BACKUP_FILENAME=$BACKUP_NAME.tar.gz
  BACKUP_FILE=/tmp/backup_$BACKUP_FILENAME
  BACKUP_OBJECT=daily/$DT_DAILY/$BACKUP_FILENAME
  
  # archive
  if [ "$1" ]; then
      BACKUP_OBJECT=archive/$DT_ARCHIVE/$BACKUP_FILENAME
  fi
  
  echo "> $BACKUP_NAME"
  echo "   - starting: $(date +"%Y-%m-%d %H:%M:%S") ..."
  echo "   - object name: $BACKUP_OBJECT"
  echo "   - archiving $DATA_DIR -> $BACKUP_FILE ..."
  #tar -zcf $BACKUP_FILE $DATA_DIR
  echo "   - uploading to AWS S3 $CONF_AWS_BUCKET_NAME/$BACKUP_OBJECT ..."
  #aws put --no-vhost $CONF_AWS_BUCKET_NAME/$BACKUP_OBJECT $BACKUP_FILE
  echo "   - removing temp file $BACKUP_FILE ..."  
  #rm -rf $BACKUP_FILE
  echo "   - completed: $(date +"%Y-%m-%d %H:%M:%S") ..."
  echo 
done
echo "$APP_NAME backup completed!"
echo 