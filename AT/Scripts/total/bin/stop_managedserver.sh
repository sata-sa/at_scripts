#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
SHUTDOWNMANAGEDSERVER_PYTHON_FILE="/home/weblogic/etc/py/start_managedserver.py"

ARGNUM=$#
ENVIRONMENT=`echo $1 | tr [A-Z] [a-z]`
MACHINE=($2)

#####################
# Usage information #
#####################
usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <APPLICATION_NAME>

  ENVIRONMENT        - The environment where the application exists: PRD/QUA/DEV/SANDBOX
  MACHINE NAME       - Which server you want to send to life???

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

if [ -z ${MACHINE} ]; then
   failure "You must provide managed server name"
fi

MANAGEDSERVER=`get-env-info.pl prd -members | grep $MACHINE | awk -F: '{print $1}'`

for DIESERVER in $MANAGEDSERVER; do
   DOMAIN=`get-env-info.pl $ENVIRONMENT -members | grep $DIESERVER | awk -F: '{print $2}'`
   WLHOST=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $5}'`
   echo $WLHOST
   WLPORT=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $6}'`
   echo $WLPORT
   WLPASS=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $8}'`
   echo $WLPASS
   "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${SHUTDOWNMANAGEDSERVER_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${DIESERVER}
done

#DOMAIN=`get-env-info.pl $ENVIRONMENT -members | grep $MACHINE | awk -F: '{print $2}'`
#echo $DOMAIN

## Function domain/app and target selection
#domtarg()
#{  
#for MANAGEDSERVER in "${MACHINE[@]}"; do
#   APNA=$APP
#   DOMAIN=(`get-env-info.pl $ENVIRONMENT -members | grep $MANAGEDSERVER | awk -F: '{print $2}' | uniq`)
#   echo "${DOMAIN[@]}"
#   WLHOST=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $5}'`
#   #echo $WLHOST
#   WLPORT=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $6}'`
#   #echo $WLPORT
#   if [[ $WLHOST != *ritta.local ]]; then
#      WLHOST=$WLHOST".ritta.local"
#   fi
#   WLPASS=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $8}'`
#   #echo $WLPASS
#
#   CONNTARGET=`list_all_application_targets $ENVIRONMENT $APP`
#   if [ -z $CONNTARGET ]; then
#      CONNTARGET=`get-env-info.pl $ENVIRONMENT -servers $APP`
#   fi
#   info "The "$CONNTARGET" will shutdown..."
#
#   if [ -z $DOMAIN ]; then
#      failure "Application does not exist!!!"
#   fi

#"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${SHUTDOWNCLUSTER_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${CONNTARGET}

#done
#}

#domtarg
