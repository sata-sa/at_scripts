#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
DOMAIN=$2
TRANSACTION="CONFIG_TO_HTML(${DOMAIN})"
JOBID=${RANDOM}

#########
# Paths #
#########
STATIC_LOCATION="/opt/scripts/public_html/config"

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <DOMAIN NAME>

  ENVIRONMENT   - The environment where the application exists. Available options are: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME   - The name of the domain with the config.xml to convert

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
    failure "Domain ${DOMAIN} is not present in ${ENV} database"
  fi
}

#################################
# Get access details for domain #
#################################
get_domain_details()
{
  DOMAIN_DETAILS=`get-env-info.pl ${ENV} ${DOMAIN}`
  WEBLOGIC_VERSION=`echo ${DOMAIN_DETAILS} | cut -d\: -f 3`
  ADMIN_HOST=`echo ${DOMAIN_DETAILS} | cut -d\: -f 5`
  ADMIN_PORT=`echo ${DOMAIN_DETAILS} | cut -d\: -f 6`
  ADMIN_PASSWORD=`echo ${DOMAIN_DETAILS} | cut -d\: -f 8`
  ADMIN_PATH=`echo ${DOMAIN_DETAILS} | cut -d\: -f 9`

  if [ "`echo ${WEBLOGIC_VERSION} | cut -d\. -f 1`" != "8" ]; then
    scp ${USER}@${ADMIN_HOST}:${ADMIN_PATH}/config/config.xml ${STAGE_PATH}/${DOMAIN}.${ENV}.xml &> /dev/null
  else
    scp ${USER}@${ADMIN_HOST}:${ADMIN_PATH}/config.xml ${STAGE_PATH}/${DOMAIN}.${ENV}.xml &> /dev/null
  fi

  if [ $? -gt 0 ]; then
    failure "Unable to scp file ${ADMIN_PATH}/config.xml to `hostname`"
  fi
}

parse_xml()
{
  get-wls-object-list.pl ${STAGE_PATH}/${DOMAIN}.${ENV}.xml -xml2html > ${STATIC_LOCATION}/${DOMAIN}.${ENV}.html

  if [ $? -gt 0 ]; then
    failure "Unable to create HTML file ${DOMAIN}.${ENV}.html in ${STATIC_LOCATION}"
  else
    info "HTML file ${DOMAIN}.${ENV}.html created in ${STATIC_LOCATION}"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
get_domain_details
parse_xml

info "Operation complete"
exit 0
