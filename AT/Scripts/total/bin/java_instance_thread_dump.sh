#!/bin/bash

. $HOME/etc/operations/common_env.sh

usage() {
  echo "Usage: "`basename $0`" <Server instance> <Snapshot interval time in seconds> <Number of snapshots>"
}

DATE=`date +%d%m%Y%H%M%S`
SERVER=$1
SNAPSHOT_INTERVAL=$2
NUMBER_SNAPSHOTS=$3
TMPFILE=tdumpfilename.txt

if [ -z ${SERVER} ]; then
  echo "No server instance specified."
  usage
  exit 0
fi

if [ -z ${SNAPSHOT_INTERVAL} ]; then
  echo "No snapshot interval time specified."
  usage
  exit 0
fi

if [ -z ${NUMBER_SNAPSHOTS} ]; then
  echo "Number of snapshots not specified."
  usage
  exit 0
fi

PID=`ps -ef | grep "\-Dweblogic.Name=${SERVER} " | grep -v grep | awk '{print($2)}'`

if [ -z ${PID} ]; then
  echo "No instance ${SERVER} found."
  exit 1
fi

TDUMPOUT=${HOME}/threaddump.${SERVER}.${DATE}.out

if [ -e ${TDUMPOUT} ]; then
  rm -rf ${TDUMPOUT}
fi

for (( i=1 ; i <= ${NUMBER_SNAPSHOTS} ; i++ ))
do
  /opt/wls-10.3.3/jdk160_18/bin/jstack -l ${PID} >> ${TDUMPOUT}
  echo -n "${i} "
  sleep ${SNAPSHOT_INTERVAL}
done

echo
echo ${TDUMPOUT} > ${HOME}/${TMPFILE}

exit 0
