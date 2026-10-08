USER=root
STAMP=$(date +%F_%H-%M)
mkdir -p backups

# Backup one database, including triggers, routines and events
mysqldump -u $USER -p --single-transaction --routines --triggers --events bank_db > backups/bank_db_$STAMP.sql

# Backup ALL databases
mysqldump -u $USER -p --single-transaction --all-databases > backups/all_databases_$STAMP.sql
