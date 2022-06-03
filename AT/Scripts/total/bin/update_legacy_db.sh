#!/bin/bash

OPERATION="UPDATE_LEGACY_DB"
JOBID=${RANDOM}
DATE=`date +%Y%m%d`
LOG="$HOME/var/log/cronjobs.${DATE}.log"
PATH=/home/weblogic/bin:$PATH
LANG=en_US.UTF-8
ENV=`echo $1 | tr [A-Z] [a-z]`

export PATH LANG

START_TIME=`date '+%Y/%m/%d %H:%M:%S'`
echo "[${START_TIME}] [${OPERATION} `echo ${ENV} | tr [a-z] [A-Z]`] [${JOBID}] [Started legacy database building process]" >> ${LOG}

build-legacy-db.pl ${ENV}

END_TIME=`date '+%Y/%m/%d %H:%M:%S'`
echo "[${END_TIME}] [${OPERATION} `echo ${ENV} | tr [a-z] [A-Z]`] [${JOBID}] [Legacy database building process complete]" >> ${LOG}
