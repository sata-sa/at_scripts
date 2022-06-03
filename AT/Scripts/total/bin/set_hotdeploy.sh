#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPLICATION=$2
HOTDEPLOY=`echo $3 | tr [A-Z] [a-z]`
TRANSACTION="ENABLE_HOTDEPLOY(${APPLICATION})"
JOBID=${RANDOM}

#################################
# check for configuration files #
#################################
check_config_files()
{
  if [ -z "${SSH_TTY}" ]; then
    SSH_TTY="NA"
  fi

  if [ -z "${SSH_CLIENT}" ]; then
    SSH_CLIENT="NA"
  fi
}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME> <ENABLE/DISABLE>

  ENVIRONMENT       - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME  - The name of the new application
  ENABLE/DISABLE    - Enable/Disable Hotdeploy

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

  if [ -z "${APPLICATION}" ]; then
    failure "Application name must be specified"
  fi

  if [ -z "${HOTDEPLOY}" ]; then
    failure "Hotdeploy option must be specified"
  else
    if [ "${HOTDEPLOY}" != "enable" -a "${HOTDEPLOY}" != "disable" ]; then
      failure "Hotdeploy option must be ENABLE or DISABLE"
    fi
  fi
}

##################
# Check database #
##################
check_db()
{
  # Check if application exists
  APPDETAIL=`get-env-info.pl ${ENV} ${APPLICATION}`

  if [ -z "${APPDETAIL}" ]; then
    failure "Application ${APPLICATION} does not exist"
  else
    if [ "${HOTDEPLOY}" == "`echo ${APPDETAIL} | cut -d\: -f 6 | tr [A-Z] [a-z]`" ]; then
      info "Hotdeploy is already in `echo ${HOTDEPLOY} | tr [A-Z] [a-z]` state"
      exit 0
    fi
  fi
}

######################
# Create Application #
######################
update_hotdeploy()
{
  if [ "${HOTDEPLOY}" == "enable" ]; then
    info "Enabling Hotdeploy for application ${APPLICATION}"
    set-env-info.pl ${ENV} -u a,${APPLICATION},DISABLE,ENABLE
  else
    info "Disabling Hotdeploy for application ${APPLICATION}"
    set-env-info.pl ${ENV} -u a,${APPLICATION},ENABLE,DISABLE
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_config_files
check_db
update_hotdeploy

info "Operation complete"
exit 0
