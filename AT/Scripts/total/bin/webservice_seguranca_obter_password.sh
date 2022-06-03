#!/bin/sh
#set -x
. $HOME/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPUSER=$2
TRANSACTION="WSGETPWD"

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <USER NAME>

  ENVIRONMENT       - Available options are: QUA/PRD
  USER NAME         - User for which the password is to be obtained

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
  if [ ${ARGNUM} -lt 2 ]; then
    usage
    exit 0
  fi

  if [ -z "${ENV}" ]; then
    failure "Environment must be specified"
  else
    if [ "${ENV}" = "prd" ]; then
      security_webservice_GetAccountPassword ${APPUSER}
    elif [ "${ENV}" = "qua" ]; then
      security_webservice_GetAccountPasswordqua ${APPUSER}
    else
     echo "WS_DSS_AREA_SEGURANCA_DISABLED_IN_THIS_ENVIRONMENT"
     exit 0
    fi
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
#security_webservice_GetAccountPassword ${APPUSER}
