#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPLICATION=$2
TARGET=$3
TRANSACTION="TARGET_DEL(${APPLICATION})"
JOBID=${RANDOM}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME> <TARGET NAME>

  ENVIRONMENT       - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME  - The name of the new application
  TARGET NAME       - The name of an existing target, either a server or cluster in any domain

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

  if [ -z "${APPLICATION}" ]; then
    failure "Application name must be specified"
  fi

  if [ -z "${TARGET}" ]; then
    failure "Target name must be specified"
  fi
}

##################
# Check database #
##################
check_db()
{
  # Check if application exists
  APPDETAIL="`get-env-info.pl ${ENV} -applications Details | grep -w ${APPLICATION}`"
  CURR_TARGET=`echo ${APPDETAIL} | cut -d\: -f 3`

  if [ -z "${APPDETAIL}" ]; then
    failure "Application ${APPLICATION} does not exist"
  else
    if [ "${TARGET}" != "${CURR_TARGET}" ]; then
      failure "Target ${TARGET} is not set for application ${APPLICATION}"
    fi
  fi
}

######################
# Create Application #
######################
update_target()
{
  info "Removing target association for application ${APPLICATION}"
  set-env-info.pl ${ENV} -u a,${APPLICATION},${CURR_TARGET},
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
update_target

info "Operation complete"
exit 0
