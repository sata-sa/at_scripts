#!/bin/bash - 

# Just fill out the DB_USER and DB_PASSWORD vars and if it's a remote host
# the DB_HOST aswell, it will backup all databases, one at a time

####################
# Script Variables #
####################

# database access
DB_USER="root"
DB_PASSWORD="aplpass"
DB_HOST="sucacti101"

# mysql tools
MYSQL="/usr/bin/mysql"
MYSQLDUMP="/usr/bin/mysqldump"

# gzip location
GZIP="/bin/gzip"

# location where the dumps will be stored
DUMP_DIR="/backup/${DB_HOST}/mysql"

# log files
LOG="/var/log/backups/${DB_HOST}_mysql.log"
ERROR_LOG="/var/log/backups/${DB_HOST}_mysql_error.log"

# rotation value
ROTATION=$(date +'%Y%m%d')

# get date
date=$(date +'%Y-%m-%d %H:%M:%S')

##################
# Script Actions #
##################
# check if dump directory exist and create if not
if [ ! -d ${DUMP_DIR} ]; then
	  mkdir -p ${DUMP_DIR}
	    chmod 500 ${DUMP_DIR}
fi

# travel through all the databases
for db in $(${MYSQL} -u ${DB_USER} -p${DB_PASSWORD} -Ns -e 'show databases'); do

      	# prepare dump directory
	if [ ! -d ${DUMP_DIR}/${db} ]; then
	    mkdir ${DUMP_DIR}/${db}
	    chmod 500 ${DUMP_DIR}/${db}
	fi

	# dump database
	echo -n "[${date}] ${db}... " 2>&1 | tee -a ${LOG}

	if [ ${db} = mysql -o ${db} = information_schema -o ${db} = performance_schema ]; then
		${MYSQLDUMP} --skip-lock-tables -u ${DB_USER} -p${DB_PASSWORD} ${db} 2>> ${ERROR_LOG} > ${DUMP_DIR}/${db}/${db}-${ROTATION}.sql;
	else
		${MYSQLDUMP} -u ${DB_USER} -p${DB_PASSWORD} -FER ${db} 2>> ${ERROR_LOG} > ${DUMP_DIR}/${db}/${db}-${ROTATION}.sql;
	fi

	if [ $? = 0 ]; then
		chmod 400 ${DUMP_DIR}/${db}/${db}-${ROTATION}.sql;
		${GZIP} -q -f ${DUMP_DIR}/${db}/${db}-${ROTATION}.sql;
		echo -e "OK\n" 2>&1 | tee -a ${LOG}
	else
	        echo -e "FAILED\n" 2>&1 | tee -a ${LOG}
	fi
done



