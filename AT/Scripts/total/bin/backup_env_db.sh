#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
TRANSACTION="BACKUP_ENV_DB(${ENV})"
BACKUP_PATH="/opt/scripts/bck"
FILENAME_PREFIX="db-backup-"
JOBID=${RANDOM}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT>

  ENVIRONMENT    - The environment database. Available options are: PRD/QUA/DEV/SANDBOX

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
}

################################
# Get the database credentials #
################################
get_db_credentials()
{
  echo -n "Enter root DB password: "
  stty -echo                   
  read PASSWD                  
  stty echo                    
}

###################
# Database backup #
###################
backup_database()
{
  FILE_PATH="${BACKUP_PATH}/${FILENAME_PREFIX}${ENV}.sql.gz"

  info "Trying to backup WebLogic environment database"
  info "mysqldump -u root -p [Weblogic_`echo ${ENV} | tr [a-z] [A-Z]`] > ${FILE_PATH}"

  mysqldump -u root -p Weblogic_`echo ${ENV} | tr [a-z] [A-Z]` | gzip > ${FILE_PATH}

  if [ $? -gt 0 ]; then
    failure "Unable to backup ${ENV} database"
  else
    info "Database backup file created"
    chown ${USER}:${USER} "${FILE_PATH}"
    chmod 600 "${FILE_PATH}"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
#get_db_credentials
backup_database

info "Operation complete"
exit 0
