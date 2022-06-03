#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
GETSTUCKTHREADSPYTHONFILE="/home/weblogic/etc/py/get_number_stuck_threads.py"


CURRENTDATE=`date +%Y-%m-%d_%HH%MM%SS`
STUCKTHREADPATHDATE=`date +%Y%m%d`
HISTORYSTUCKTHREADFILE=STUCKTHREADS_HISTORY_THIS_DAY.txt

ssh weblogic@suapp301.ritta.local ls /archive_sonas/dsl_logs/thread_dumps/portalfin/${STUCKTHREADPATHDATE}

if [ $? -eq 2 ]; then
   ssh weblogic@suapp301.ritta.local mkdir -p /archive_sonas/dsl_logs/thread_dumps/portalfin/${STUCKTHREADPATHDATE}
fi

"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${GETSTUCKTHREADSPYTHONFILE} | sed -e "1,8 d" > /tmp/tmp_GI10_STUCKTHREADS.txt

/bin/cat /tmp/tmp_GI10_STUCKTHREADS.txt | ssh weblogic@suapp301.ritta.local "cat >> /archive_sonas/dsl_logs/thread_dumps/portalfin/${STUCKTHREADPATHDATE}/${HISTORYSTUCKTHREADFILE}"

#CURRENTDATE=`date +%Y-%m-%d_%HH%MM%SS`
#STUCKTHREADPATHDATE=`date +%Y%m%d`
#HISTORYSTUCKTHREADFILE=STUCKTHREADS_HISTORY_THIS_DAY.txt
#
#ssh weblogic@suapp301.ritta.local ls /archive_sonas/dsl_logs/thread_dumps/sef/${STUCKTHREADPATHDATE}
#
#if [ $? -eq 2 ]; then
#   ssh weblogic@suapp301.ritta.local mkdir -p /archive_sonas/dsl_logs/thread_dumps/sef/${STUCKTHREADPATHDATE}
#fi

#"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${GETSTUCKTHREADSPYTHONFILE} | sed -e "1,8 d" > /tmp/tmp_SEF_STUCKTHREADS.txt

#/bin/cat /tmp/tmp_SEF_STUCKTHREADS.txt | ssh weblogic@suapp301.ritta.local "cat >> /archive_sonas/dsl_logs/thread_dumps/sef/${STUCKTHREADPATHDATE}/${HISTORYSTUCKTHREADFILE}"
