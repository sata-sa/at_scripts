#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
DOMAIN=$2
TRANSACTION="DOMAIN_DEL(${DOMAIN})"
JOBID=${RANDOM}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <DOMAIN NAME>

  ENVIRONMENT  - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME  - The name of the domain to delete from the database

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
}

##################
# Check database #
##################
check_db()
{
  # Check if domain exists
  DBQUERY=`get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 1`

  if [ "${DBQUERY}" != "D" ]; then
    failure "DOMAIN ${DOMAIN} is not present in ${ENV} database"
  fi
}

#################
# Delete domain #
#################
delete_domain()
{
  info "Attempting to delete domain ${DOMAIN}"
  set-env-info.pl ${ENV} -d d,${DOMAIN}

  if [ $? -gt 0 ]; then
    failure "Unable to delete domain ${DOMAIN}"
  else
    info "Domain ${DOMAIN} removed from ${ENV} database"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
delete_domain

info "Operation complete"
exit 0
