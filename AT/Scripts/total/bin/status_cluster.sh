#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
STATECLUSTER_PYTHON_FILE="/home/weblogic/etc/py/state_cluster.py"

ARGNUM=$#
ENVIRONMENT=`echo $1 | tr [A-Z] [a-z]`
UDOMAIN=($2)

#####################
# Usage information #
#####################
usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <APPLICATION_NAME>

  ENVIRONMENT        - The environment where the application exists: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME   - The name of application where the cluster/server is running, more than one application "app1 app2 ..."

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
   failure "You must provide your application name"
fi

# Function domain/app and target selection
domtarg()
{  
for APP in "${UDOMAIN[@]}"; do
   APNA=$APP
   DOMAIN=`get-env-info.pl $ENVIRONMENT $APP | awk -F: '{print $4}' | sed -e 's/[Cc]luster.*$//g'`
   WLHOST=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $5}'`
   WLPORT=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $6}'`
   if [[ $WLHOST != *ritta.local ]]; then
      DBHOST=$WLHOST".ritta.local"
   fi
   WLPASS=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $8}'`

   CONNTARGET=`list_all_application_targets $ENVIRONMENT $APP`
   if [ -z $CONNTARGET ]; then
      CONNTARGET=`get-env-info.pl $ENVIRONMENT -servers $APP`
   fi
   info "I will check the "$CONNTARGET" state"

   if [ -z $DOMAIN ]; then
      failure "Application does not exist!!!"
   fi

"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${STATECLUSTER_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${CONNTARGET}

done
}

domtarg
