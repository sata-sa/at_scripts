#!/bin/bash

. ${HOME}/bin/common_env.sh

APPLICATION=$1

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <APPLICATION NAME>

  APPLICATION NAME - The name of the application to get FQDN

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

  # Check application
  if [ -z ${APPLICATION} ]; then
    usage
    exit 0
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
taxonomy_webservice_GetApplicationFQDN ${APPLICATION}

exit 0
