#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
FRONTEND=$2
ISDEFAULT=`echo $3 | tr [a-z] [A-Z]`
TRANSACTION="FRONTEND_ADD(${FRONTEND})"
JOBID=${RANDOM}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <FRONTEND NAME> [IS DEAFULT]

  ENVIRONMENT    - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  FRONTEND NAME  - The name of the new frontend
  IS DEFAULT     - Is the frontend a default one (Y/N)

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

  if [ ! -z "${ISDEFAULT}" ]; then
    if [ "${ISDEFAULT}" != "Y" -a "${ISDEFAULT}" != "N" ]; then
      failure "Specify Y or N, for default value"
    fi
  else
    ISDEFAULT="N"
  fi
}

##################
# Check database #
##################
check_db()
{
  # Check if frontend already exists in database
  DBQUERY=`get-env-info.pl ${ENV} -frontends | grep ${FRONTEND}`

  if [ -z ${DBQUERY} ]; then
    CREATE_FRONTEND="Y"
  else
    failure "Frontend ${FRONTEND} already exists in ${ENV} database"
  fi
}

###################
# Create Frontend #
###################
add_frontend()
{
  if [ "${CREATE_FRONTEND}" == "Y" ]; then

    info "Adding frontend ${FRONTEND} to ${ENV} database"
    info "`set-env-info.pl ${ENV} -i f,${FRONTEND},${ISDEFAULT}`"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
add_frontend

info "Operation complete"
exit 0
