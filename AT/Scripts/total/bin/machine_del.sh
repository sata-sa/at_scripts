#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
DOMAIN=$2
MACHINE=$3
TRANSACTION="MACHINE_DEL(${DOMAIN}:${MACHINE})"
JOBID=${RANDOM}

#########
# Paths #
#########
MACHINE_DEL_PYTHON_FILE=${HOME}/etc/py/machine_del.py

#################################
# check for configuration files #
#################################
check_config_files()
{
  # Check Jython scrits
  if [ ! -e "${MACHINE_DEL_PYTHON_FILE}" ]; then
    failure "Jython file ${MACHINE_DEL_PYTHON_FILE} not found"
  fi
}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <DOMAIN NAME> <MACHINE NAME>

  ENVIRONMENT         - The environment where the machine exists. Available options are: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME         - The domain where the machine exists
  CLUSTER NAME        - The name of the machine to delete

EOF
}

##########################
# Perform initial checks #
##########################
start_arg_checks()
{
  if [ -z "${SSH_TTY}" ]; then
    SSH_TTY="NA"
  fi

  if [ -z "${SSH_CLIENT}" ]; then
    SSH_CLIENT="NA"
  fi

  # Check username
  if [ "${USER}" != "weblogic" ]; then
    failure "User must be weblogic"
  else
    cd ${HOME}
  fi

  # Check user parameters
  if [ ${ARGNUM} -lt 1 ]; then
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

  if [ -z "${DOMAIN}" ]; then
    failure "Domain name must be specified"
  fi

  if [ -z "${MACHINE}" ]; then
    failure "Machine must be defined"
  fi
}

#################################
# Get access details for domain #
#################################
get_domain_details()
{
  DOMAIN_DETAILS=`get-env-info.pl ${ENV} ${DOMAIN}`
  ADMIN_HOST=`echo ${DOMAIN_DETAILS} | cut -d\: -f 5`
  ADMIN_PORT=`echo ${DOMAIN_DETAILS} | cut -d\: -f 6`
  ADMIN_PASSWORD=`echo ${DOMAIN_DETAILS} | cut -d\: -f 8`
  ADMIN_PATH=`echo ${DOMAIN_DETAILS} | cut -d\: -f 9`

  if [ "`echo ${WEBLOGIC_VERSION} | cut -d\. -f 1`" != "8" ]; then
    scp ${USER}@${ADMIN_HOST}:${ADMIN_PATH}/config/config.xml ${STAGE_PATH}/${DOMAIN}.${ENV}.xml &> /dev/null
  else
    scp ${USER}@${ADMIN_HOST}:${ADMIN_PATH}/config.xml ${STAGE_PATH}/${DOMAIN}.${ENV}.xml &> /dev/null
  fi

  if [ $? -gt 0 ]; then
    failure "Unable to scp file ${ADMIN_PATH}/config.xml to `hostname`"
  fi
}

#################################################
# Cross check database and weblogic information #
#################################################
check_db_weblogic()
{
  # Check if machine exists
  DBQUERY=`get-env-info.pl ${ENV} ${MACHINE}`
  XMLQUERY=`get-wls-object-list.pl ${STAGE_PATH}/${DOMAIN}.${ENV}.xml machine | grep -w ${MACHINE}`

  if [ -z ${DBQUERY} ] && [ -z ${XMLQUERY} ]; then
    failure "Machine ${MACHINE} is not present in database and WebLogic"
  elif [ -z ${DBQUERY} ]; then
    failure "Machine ${MACHINE} is not present in database"
  elif [ -z ${XMLQUERY} ]; then
    failure "Machine ${MACHINE} is not present in WebLogic domain ${DOMAIN}"
  fi
}

##################
# Delete machine #
##################
delete_machine()
{
  info "Attempting to delete machine ${MACHINE}"
  "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${MACHINE_DEL_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${MACHINE}

  if [ $? -gt 0 ]; then
    failure "Unable to delete machine ${MACHINE}"
  else
    info "Machine ${MACHINE} deleted from WebLogic domain ${DOMAIN}"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_config_files
check_wl_version ${ENV} ${DOMAIN}
check_java_version ${ENV} ${DOMAIN}
get_domain_details
check_db_weblogic
delete_machine

info "Operation complete"
exit 0
