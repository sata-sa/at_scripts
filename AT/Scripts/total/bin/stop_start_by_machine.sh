#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"


ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
EXPECMACHINE=`echo $2 | tr [A-Z] [a-z]`
GRPEXPECMACHINE=`echo ${EXPECMACHINE} | tr [A-Z] [a-z] | sed 's/jvm*.*/domain/g;s/apps*.*/domain/g'`
JOBTODO=(`echo $3 | tr [A-Z] [a-z]`)
EXPECDOMAIN=(`echo $4 | tr [A-Z] [a-z]`)
if [ -z ${EXPECDOMAIN} ];then
   EXPECDOMAIN=NULL
fi

#####################
# Usage information #
#####################
usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <MACHINE NAME> <DOMAIN>

  ENVIRONMENT        - The environment where the application exists: PRD/QUA/DEV/SANDBOX
  MACHINE NAME       - The name of the machine to which you want to stop the Managedservers
  JOB TO DO          - What you want stop/start??
  DOMAIN             - Specify a domain if you just want to stop this domain "domain1 domain2 ..."

EOF
}

##########################
# Perform initial checks #
##########################
start_arg_checks()
{
  # Check username
  if [ "${USER}" != "weblogic" ]; then
    failure "User must be weblogic"
  fi

  # Check user parameters
  if [ ${ARGNUM} -lt 1 ]; then
    usage
    exit 0
  fi

  if [ ${ARGNUM} -gt 4 ]; then
    usage
    exit 0
  fi

  if [ -z "${ENV}" ]; then
    failure "Environment must be specified"
  else
    if [ "${ENV}" != "prd" -a "${ENV}" != "qua" -a "${ENV}" != "dev" -a "${ENV}" != "sandbox" ]; then
      failure "Unrecognized environment"
    fi
  fi

  if [ -z ${EXPECMACHINE} ]; then
    failure "You must provide machine name"
  fi

  if [ -z ${JOBTODO} ]; then
    failure "I am stupid, you have to explain everything: start or stop..."
  fi
}

##########################
#     Start Machines     #
##########################
start_managedservers()
{
if [ ${EXPECDOMAIN} == "NULL" ]; then
   DOMAINS=(`get-env-info.pl ${ENV} | grep ${GRPEXPECMACHINE} | awk -F: '{print $2}'`)
   for i in ${DOMAINS[@]}; do
      ADMIN=`get-env-info.pl ${ENV} $i | awk -F: '{print $5}'`
      PORT=`get-env-info.pl ${ENV} $i | awk -F: '{print $6}'`
      PASSWORD=`get-env-info.pl ${ENV} $i | awk -F: '{print $8}'`
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/stop_start_by_machine.py ${ADMIN} ${PORT} ${PASSWORD} ${EXPECMACHINE} start
   done
else
   for i in ${EXPECDOMAIN[@]}; do
      ADMIN=`get-env-info.pl ${ENV} $i | awk -F: '{print $5}'`
      PORT=`get-env-info.pl ${ENV} $i | awk -F: '{print $6}'`
      PASSWORD=`get-env-info.pl ${ENV} $i | awk -F: '{print $8}'`
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/stop_start_by_machine.py ${ADMIN} ${PORT} ${PASSWORD} ${EXPECMACHINE} start
   done
fi
}

##########################
#     Stop Machines      #
##########################
stop_managedservers()
{
if [ ${EXPECDOMAIN} == "NULL" ]; then
   DOMAINS=(`get-env-info.pl ${ENV} | grep ${GRPEXPECMACHINE} | awk -F: '{print $2}'`)
   for i in ${DOMAINS[@]}; do
      ADMIN=`get-env-info.pl ${ENV} $i | awk -F: '{print $5}'`
      PORT=`get-env-info.pl ${ENV} $i | awk -F: '{print $6}'`
      PASSWORD=`get-env-info.pl ${ENV} $i | awk -F: '{print $8}'`
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/stop_start_by_machine.py ${ADMIN} ${PORT} ${PASSWORD} ${EXPECMACHINE} stop
   done
else
   for i in ${EXPECDOMAIN[@]}; do
      ADMIN=`get-env-info.pl ${ENV} $i | awk -F: '{print $5}'`
      PORT=`get-env-info.pl ${ENV} $i | awk -F: '{print $6}'`
      PASSWORD=`get-env-info.pl ${ENV} $i | awk -F: '{print $8}'`
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/stop_start_by_machine.py ${ADMIN} ${PORT} ${PASSWORD} ${EXPECMACHINE} stop
   done
fi
}

# Main
start_arg_checks
if [ ${JOBTODO} == "start" ]; then
   start_managedservers
else
   stop_managedservers
fi
