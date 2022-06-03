#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"

ARGNUM=$#

#####################
# Usage information #
#####################
usage()
{
cat << EOF 
USAGE: $0 <DBHOST> <SERVICE NAME> <USERNAME> <PASSWORD>

  DBHOST         - Hostname
  SERVICE NAME   - Service Name
  USERNAME       - DataBase username
  PASSWORD       - Password for username 

EOF
}

if [ ${ARGNUM} -ne 4 ]; then
   usage
   exit 0
fi

DBHOST=$1
DBSERVICENAME=$2
DBUSER=$3
DBPASS=$4


# Test connection to DataBase
info "Testing database connection..."
"$JAVA_HOME/bin/java" ${JVM_ARGS} utils.dbping ORACLE_THIN ${DBUSER} ${DBPASS} ${DBHOST}":1521/"${DBSERVICENAME}
if [ $? -gt 0 ]; then
   failure "Cannot test access to DataBase!!!"
fi
