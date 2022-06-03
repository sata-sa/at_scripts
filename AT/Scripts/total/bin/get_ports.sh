#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
GETPORTS_PYTHON_FILE="/home/weblogic/etc/py/get_ports.py"

ARGNUM=$#
ENVIRONMENT=`echo $1 | tr [A-Z] [a-z]`
UDOMAIN=($2)

usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <APPLICATION_NAME>

  ENVIRONMENT        - The environment where the application exists: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME        - The domain name from which you want to know the servers and their ports, more than one domain "domain1 domain2 ..."

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
   failure "You must provide your domain name"
fi

# Function domain selection
domsel()
{  
for APP in "${UDOMAIN[@]}"; do
   #APNA=$APP
   DOMAIN=`get-env-info.pl $ENVIRONMENT $APP | awk -F: '{print $2}'`
   WLHOST=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $5}'`
   WLPORT=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $6}'`
   if [[ $WLHOST != *ritta.local ]]; then
      DBHOST=$WLHOST".ritta.local"
   fi
   WLPASS=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $8}'`

   if [ -z $DOMAIN ]; then
      failure "Domain ${DOMAIN} does not exist!!!"
   fi

#echo "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${GETPORTS_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS}
"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${GETPORTS_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS}

done
}

domsel
