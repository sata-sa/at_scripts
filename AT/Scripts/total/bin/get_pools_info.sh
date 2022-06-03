#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT>

  ENVIRONMENT        - The environment where the new domain will be created. Available options are: PRD/QUA/DEV/SANDBOX

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

#########################
# List pool information #
#########################
get_pool_info()
{
  DOMAINS_LIST=`get-env-info.pl ${ENV}`
  EXCLUDED_DOMAINS="`cat ${HOME}/etc/get_pools_info/excluded_domains.conf | grep -v \"^#\"`"

  #Remove excluded domains
  for xdomain in ${EXCLUDED_DOMAINS}
  do
    DOMAINS_LIST=`echo -e "${DOMAINS_LIST}" | grep -wv ${xdomain}`
  done

  for entry in `echo -e "${DOMAINS_LIST}"`
  do
    DOMAIN=`echo ${entry} | cut -d\: -f 2`
    WLSVERSION=`echo ${entry} | cut -d\: -f 3`
    SERVER=`echo ${entry} | cut -d\: -f 5`
    PORT=`echo ${entry} | cut -d\: -f 6`
    USERNAME=`echo ${entry} | cut -d\: -f 7`
    PASSWORD=`echo ${entry} | cut -d\: -f 8`

    info "${DOMAIN}"

    check_wl_version ${ENV} ${DOMAIN}
    check_java_version ${ENV} ${DOMAIN}
 
    CMDOUT=`"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.Admin -url ${SERVER}:${PORT} -username ${USERNAME} -password ${PASSWORD} GET -pretty -type JDBCConnectionPool`

    if [ $? -gt 0 ]; then
      warning "Unable to get connection pool information for domain ${DOMAIN}"
    else
      for entry in `echo -e "${CMDOUT}" | tr -d '\t '`
      do
        if [ "${entry:0:9}" == "MBeanName" ]; then
          POOL_NAME=`echo ${entry} | cut -d\= -f 2 | cut -d\, -f 1`
        fi

        if [ "${entry:0:7}" == "Targets" ]; then
          TARGET=`echo ${entry} | cut -d\: -f 2`
        fi

        if [ "${entry:0:3}" == "URL" ]; then
          URL=`echo ${entry} | cut -d\: -f 2-`

          if [ "${URL:0:17}" == "jdbc:oracle:thin:" ]; then
            URL="`echo ${URL} | cut -d\@ -f 2`"
          fi
        fi

        if [ "${entry:0:10}" == "Properties" ]; then
          PROPERTIES=`echo ${entry} | cut -d\: -f 2-`

          if [ "`echo ${PROPERTIES} | cut -d\= -f 1 | tr [A-Z] [a-z]`" == "user" ]; then
            PROPERTIES=`echo ${PROPERTIES} | cut -d\= -f 2`
          fi
        fi

        if [ "${entry:0:2}" == "--" ]; then
          echo "${DOMAIN}|${WLSVERSION}|${POOL_NAME}|${TARGET}|${URL}|${PROPERTIES}"
        fi
      done
    fi
  done
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
get_pool_info

info "Operation complete"
exit 0
