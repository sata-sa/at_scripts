#!/bin/bash

. $HOME/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPNAME=$2
USERNAME=$3
PASSWORD=$4
GROUPNAME=$5
WLSMACHINE=`hostname`".ritta.local"
TRANSACTION="USER_ADD(${APPNAME}:${USERNAME})"

#########
# Paths #
#########
USER_ADD_PYTHON_FILE=${HOME}/etc/py/user_add.py
GROUP_ADD_PYTHON_FILE=${HOME}/etc/py/group_add.py

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME> <USER NAME> <USER PASSWORD> [GROUP NAME]

  ENVIRONMENT         - The environment where the application exists. Available options are: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME    - The name of the application for the user
  USER NAME           - The name of the user to be created
  USER PASSWORD       - The password of the user to be created
  GROUP NAME          - The name of the group the user belongs to (Optional)

EOF
}

#########################
# Check user parameters #
#########################
start_arg_checks()
{
  if [ -z "${SSH_TTY}" ]; then
    SSH_TTY="NA"
  fi

  if [ -z "${SSH_CLIENT}" ]; then
    SSH_CLIENT="NA"
  fi

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

  if [ -z "${USERNAME}" ]; then
    failure "User name must be provided."
  fi

  if [ -z "${PASSWORD}" ]; then
    failure "User password must be provided."
  fi
}

#################################
# check for configuration files #
#################################
check_config_files()
{
  # Check Jython scrits
  if [ ! -e "${USER_ADD_PYTHON_FILE}" ]; then
    failure "Jython file ${USER_ADD_PYTHON_FILE} not found"
  fi

  if [ ! -e "${GROUP_ADD_PYTHON_FILE}" ]; then
    failure "Jython file ${GROUP_ADD_PYTHON_FILE} not found"
  fi
}

##########################
# Check application name #
##########################
check_application_name()
{
  if ! application_exists ${ENV} ${APPNAME}
  then
    failure "Application ${APPNAME} does not exist"
  fi
}

#################################
# Get access details for domain #
#################################
get_domain_details()
{
  DOMAIN=`get_application_domain_name ${ENV} ${APPNAME}`
  DOMAIN_DETAILS=`get-env-info.pl ${ENV} ${DOMAIN}`
  ADMIN_HOST=`echo ${DOMAIN_DETAILS} | cut -d\: -f 5`
  ADMIN_PORT=`echo ${DOMAIN_DETAILS} | cut -d\: -f 6`
  ADMIN_PASSWORD=`echo ${DOMAIN_DETAILS} | cut -d\: -f 8`
  ADMIN_PATH=`echo ${DOMAIN_DETAILS} | cut -d\: -f 9`
}

#########################
# Create user in domain #
#########################
user_add()
{
  # Check if user already exists
  OUT=`"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${USER_ADD_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${APPNAME} ${USERNAME} ${PASSWORD}`

  if [ "`echo -e "${OUT}" | grep "User already exists." | wc -l`" -gt 0 ]; then
    info "User already exists in domain ${DOMAIN}"
  else
    if [ "`echo -e "${OUT}" | grep "User ${USERNAME} created successfully." | wc -l`" -gt 0 ]; then
      info "User ${USERNAME} created successfully"
    else
      failure "Unable to create user ${USERNAME}"
    fi
  fi

  if [ ! -z ${GROUPNAME} ]; then
    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${GROUP_ADD_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${APPNAME} ${USERNAME} ${GROUPNAME}

    if [ $? -gt 0 ]; then
      warning "Unable to create group ${GROUPNAME}"
    fi
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_config_files
check_application_name
get_domain_details
check_wl_version ${ENV} ${DOMAIN}
check_java_version ${ENV} ${DOMAIN}
user_add

info "Operation complete"
exit 0
