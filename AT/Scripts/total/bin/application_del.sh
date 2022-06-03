#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPLICATION=$2
TRANSACTION="APPLICATION_DEL(${DOMAIN}:${APPLICATION})"
JOBID=${RANDOM}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME>

  ENVIRONMENT         - The environment where the application exists. Available options are: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME    - The name of the application to delete from the database

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
}

##################
# Check database #
##################
check_db()
{
  # Check if application exists
  DBQUERY=`get-env-info.pl ${ENV} -applications Details | grep -w ${APPLICATION} | cut -d\: -f 1`

  if [ "${DBQUERY}" != "${APPLICATION}" ]; then
    failure "Application ${APPLICATION} is not present in ${ENV} database"
  fi
}

######################
# Delete application #
######################
delete_application()
{
  info "Attempting to delete application ${APPLICATION}"
  set-env-info.pl ${ENV} -d a,${APPLICATION}

  if [ $? -gt 0 ]; then
    failure "Unable to delete application${APPLICATION}"
  else
    info "Application ${APPLICATION} removed from ${ENV} database"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
delete_application

info "Operation complete"
exit 0
