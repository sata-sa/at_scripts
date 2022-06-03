#!/bin/bash
set -x

#. ${HOME}/bin/common_env.sh
. /home/weblogic/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
SHUTDOWNADMINSERVER_PYTHON_FILE="/home/weblogic/etc/py/stop_admin_server.py"

ARGNUM=$#
ENVIRONMENT=`echo $1 | tr [A-Z] [a-z]`
UDOMAIN=($2)

#####################
# Usage information #
#####################
usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <DOMAIN_NAME>

  ENVIRONMENT        - The environment where the application exists: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME        - The domain name to stop, more than one domain "domain1 domain2 ..."

EOF
}

if [ ${ARGNUM} -ne 2 ]; then
   usage
   exit 0
fi

if [ -z "${ENVIRONMENT}" ]; then
   failure "Environment must be specified"
else
   if [ "${ENVIRONMENT}" != "prd" -a "${ENVIRONMENT}" != "qua" -a "${ENVIRONMENT}" != "dev" -a "${ENVIRONMENT}" != "sandbox" ]; then
      failure "Unrecognized environment"
   fi
fi

if [ -z ${UDOMAIN} ]; then
   failure "You must provide domain name"
fi

# Function domain/app and target selection
domtarg()
{  
for APP in "${UDOMAIN[@]}"; do
   APNA=$APP
   DOMAIN=`get-env-info.pl $ENVIRONMENT $APP | awk -F: '{print $2}'`
   ADMINSERVER=${DOMAIN}"AdminServer"
   WLSVERSION=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $3}'`
   if [[ $WLSVERSION == 10* ]]; then
      ADMINSERVER="AdminServer"
   fi
   WLHOST=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $5}'`
   WLPORT=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $6}'`
   if [[ $WLHOST != *ritta.local ]]; then
      DBHOST=$WLHOST".ritta.local"
   fi
   WLPASS=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $8}'`

   info "The $ADMINSERVER will shutdown..."

   if [ -z $DOMAIN ]; then
      failure "Application does not exist!!!"
   fi

#echo "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${SHUTDOWNADMINSERVER_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${ADMINSERVER}
"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${SHUTDOWNADMINSERVER_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${ADMINSERVER}

done
}

domtarg
