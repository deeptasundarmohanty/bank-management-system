#!/bin/bash
# Backup and restore for MySQL (Lab Exp 4 backup, Unit 5 recovery)
# Usage: bash 07_backup.sh
USER=root
STAMP=$(date +%F_%H-%M)
mkdir -p backups

# Backup one database, including triggers, routines and events
mysqldump -u $USER -p 
mysqldump -u $USER -p 
