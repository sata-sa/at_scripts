#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPLICATION=$2
TARGET=$3
TRANSACTION="TARGET_ADD(${APPLICATION})"
JOBID=${RANDOM}

#########
# Paths #
#########
TARGET_ADD_PATH="${STAGE_PATH}/tmp/target_add/${APPLICATION}"
MOD_WL_TEMPLATE="${HOME}/etc/application_add/APPNAME.mod_weblogic.conf"
WLS_PARSER="get-wls-object-list.pl"

#####################
# Usage information #
#####################
#usage()
#{
#cat << EOF
#USAGE: $0 <ENVIRONMENT> <APPLICATION NAME> <FQDN> <TARGET NAME>
#
#  ENVIRONMENT       - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
#  APPLICATION NAME  - The name of the new application
#  FQDN              - FQDN Application (ex resef.ffcompensarestit.ritta.local)
#  TARGET NAME       - The name of an existing target, either a server or cluster in any domain
#
#EOF
#}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME> <TARGET NAME>

  ENVIRONMENT       - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME  - The name of the new application
  TARGET NAME       - The name of an existing target, either a server or cluster in any domain

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

  if [ -z "${TARGET}" ]; then
    failure "Target name must be specified"
  fi
}

##################
# Check database #
##################
check_db()
{
  # Check if application exists in database
  APPENTRY="`get-env-info.pl ${ENV} -applications Details | grep -w ^${APPLICATION}`"

  if [ "X${APPENTRY}" != "X" ]; then
    CURR_TARGET="`echo ${APPENTRY} | cut -d\: -f 3`"

    if [ "X${CURR_TARGET}" != "X" ]; then
      if [ "${TARGET}" == "${CURR_TARGET}" ]; then
        info "Target ${TARGET} is already defined for application ${APPLICATION}"
        exit 0
      else
        failure "Remove target ${CURR_TARGET} with target_del.sh, before setting new target"
      fi
    fi
  else
    failure "Application ${APPLICATION} does not exist"
  fi
}

######################
# Create Application #
######################
update_target()
{
  info "Setting new target for for application ${APPLICATION}"
#mangerico
#set-env-info.pl ${ENV} -u a,${APPLICATION},,NULL,,
#set-env-info.pl ${ENV} -u a,${APPLICATION},,NULL,NULL,
set-env-info.pl ${ENV} -u a,${APPLICATION},,${TARGET}



}

##########################################
# Copy configuration files for frontends #
##########################################
copy_frontend_files()
{
  mkdir -p "${TARGET_ADD_PATH}"

  FRONTENDS=`get_application_frontend_list ${ENV} ${APPLICATION}`
  APPLICATION_TARGETS=`list_all_application_targets ${ENV} ${APPLICATION}`
  DOMAIN=`target_domain ${ENV} ${APPLICATION_TARGETS}`
  WLFILE=`get_weblogic_file ${ENV} ${DOMAIN} ${TARGET_ADD_PATH}`
  WLSERVERS=`list_all_cluster_servers ${ENV} ${DOMAIN} ${APPLICATION_TARGETS}`
  VIRTUALHOST=`list_all_application_virtualhosts ${ENV} ${APPLICATION}`

  for wlserver in ${WLSERVERS}
  do
    # Check if server exists in WebLogic configuration file
    if [ "X`${WLS_PARSER} ${WLFILE} server | grep -w ${wlserver}`" == "X" ]; then
      failure "Server ${wlserver} not present in WebLogic confguration file"
    fi

    TARGET_MACHINE=`get_machine_name ${ENV} ${wlserver}`
    TARGET_ADDRESS=`get_target_address ${WLFILE} ${wlserver}`

    # Bruno 20150305
    #EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${TARGET_MACHINE} "dmesg | grep -w Xen | wc -l" 2>/dev/null`
    EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${TARGET_MACHINE} "/sbin/lspci | grep Xen" 2>/dev/null`

    if [ -n "${EXAID}" ]; then
      WLS="${TARGET_MACHINE}-app:${TARGET_ADDRESS},${WLS}"
    else
      WLS="${TARGET_MACHINE}:${TARGET_ADDRESS},${WLS}"
    fi
  done

  WLS=`echo -e "${WLS}" | sed "s/,$//g"`

  sed -e "s/APPNAME/${APPLICATION}/g" -e "s/\<WLS\>/${WLS}/g" ${MOD_WL_TEMPLATE} > "${TARGET_ADD_PATH}/${APPLICATION}.mod_weblogic.conf"

  for frontend in ${FRONTENDS}
  do
    info "scp ${TARGET_ADD_PATH}/${APPLICATION}.mod_weblogic.conf ${USER}@${frontend}:/httpd/conf/${frontend}/${VIRTUALHOST}/"
    scp "${TARGET_ADD_PATH}/${APPLICATION}.mod_weblogic.conf" ${USER}@${frontend}:/httpd/conf/${frontend}/${VIRTUALHOST}/

    # Create Apache logs directory
    if [ "${ENV}" != "prd" ]; then
      info "Creating directory /httpd/data/${frontend}/${VIRTUALHOST}/logs on machine ${frontend}"
      ssh -n -o StrictHostKeyChecking=no ${USER}@${frontend} "mkdir -p /httpd/data/${frontend}/${VIRTUALHOST}/logs"

      if [ $? -gt 0 ]; then
        warning "Unable to create directory /httpd/data/${frontend}/${VIRTUALHOST}/logs on machine ${frontend}"
      fi
    else
      info "Creating directory /logs/httpd/${frontend}/${VIRTUALHOST} on machine ${frontend}"
      ssh -n -o StrictHostKeyChecking=no ${USER}@${frontend} "mkdir -p /logs/httpd/${frontend}/${VIRTUALHOST}"

      if [ $? -gt 0 ]; then
        warning "Unable to create directory /logs/httpd/${frontend}/${VIRTUALHOST} on machine ${frontend}"
      fi
    fi

    # Create static content directory (public_html)
    info "Creating directory /httpd/data/${frontend}/${VIRTUALHOST}/public_html on machine ${frontend}"
    ssh -n -o StrictHostKeyChecking=no ${USER}@${frontend} "mkdir -p /httpd/data/${frontend}/${VIRTUALHOST}/public_html"

    if [ $? -gt 0 ]; then
      warning "Unable to create directory /httpd/data/${frontend}/${VIRTUALHOST}/public_html on machine ${frontend}"
    fi
  done

  rm -rf "${TARGET_ADD_PATH}"
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
update_target
copy_frontend_files

info "Operation complete"
exit 0
