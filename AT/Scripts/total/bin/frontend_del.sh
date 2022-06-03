#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
FRONTEND=$2
TRANSACTION="FRONTEND_DEL(${DOMAIN}:${FRONTEND})"
JOBID=${RANDOM}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <FRONTEND NAME>

  ENVIRONMENT         - The environment where the frontend exists. Available options are: PRD/QUA/DEV/SANDBOX
  FRONTEND NAME       - The name of the frontend to delete from the database

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

  if [ -z "${FRONTEND}" ]; then
    failure "Frontend name must be specified"
  fi
}

##################
# Check database #
##################
check_db()
{
  # Check if application exists
  DBQUERY=`get-env-info.pl ${ENV} -frontends | grep ${FRONTEND}`

  if [ -z "${DBQUERY}" ]; then
    failure "Frontend ${FRONTEND} is not present in ${ENV} database"
  fi
}

###################
# Delete frontend #
###################
delete_frontend()
{
  info "Attempting to delete frontend ${FRONTEND}"
  set-env-info.pl ${ENV} -d f,${FRONTEND}

  if [ $? -gt 0 ]; then
    failure "Unable to delete frontend ${FRONTEND}"
  else
    info "Frontend ${FRONTEND} removed from ${ENV} database"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
delete_frontend

info "Operation complete"
exit 0
