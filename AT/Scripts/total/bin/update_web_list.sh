#!/bin/bash

OPERATION="UPDATE_WEB_LIST"
JOBID=${RANDOM}
DATE=`date +%Y%m%d`
LOG="$HOME/var/log/cronjobs.${DATE}.log"
PATH=/home/weblogic/bin:$PATH
LANG=en_US.UTF-8
ENV=`echo $1 | tr [A-Z] [a-z]`
PUBHTML="/opt/scripts/public_html"

export PATH LANG

START_TIME=`date '+%Y/%m/%d %H:%M:%S'`
echo "[${START_TIME}] [${OPERATION} `echo ${ENV} | tr [a-z] [A-Z]`] [${JOBID}] [Started application web list building process]" >> ${LOG}

describe.sh ${ENV} > ${PUBHTML}/${ENV}.html.tmp
mv -f ${PUBHTML}/${ENV}.html.tmp ${PUBHTML}/${ENV}.html

END_TIME=`date '+%Y/%m/%d %H:%M:%S'`
echo "[${END_TIME}] [${OPERATION} `echo ${ENV} | tr [a-z] [A-Z]`] [${JOBID}] [Application web list building process complete]" >> ${LOG}
