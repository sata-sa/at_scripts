#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
POOL_OPERATION="`echo $1 | tr [a-z] [A-Z]`"
POOLS_FILE=$2
TRANSACTION="POOL_OPERATION(${POOL_OPERATION}:${POOLS_FILE})"
JOBID=${RANDOM}

#########
# Paths #
#########
POOL_OPERATION_PYTHON_FILE=${HOME}/etc/py/pool_operation.py

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <POOL OPERATION> <POOLS FILE>

  POOL OPERATION  - The Operation to perform on the pools. Valid options are SUSPEND/RESUME/SHUTDOWN/START
  POOLS FILE      - The name of the file with the list of pools to affect

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

  if [ -z "${POOL_OPERATION}" ]; then
    failure "Pool operation must be specified"
  else
    if [ "${POOL_OPERATION}" != "SHUTDOWN" -a "${POOL_OPERATION}" != "START" -a "${POOL_OPERATION}" != "RESUME" -a "${POOL_OPERATION}" != "SUSPEND" ]; then
      failure "Unrecognized pool operation ${POOL_OPERATION}"
    fi
  fi

  if [ -z "${POOLS_FILE}" ]; then
    failure "Pools file name must be specified"
  else
    if [ -f "${POOLS_FILE}" ]; then
      POOLS_LIST=`cat "${POOLS_FILE}" | grep -v "^#"`
    else
      failure "File ${POOLS_FILE} not found"
    fi
  fi
}

############################
# Start operating on pools #
############################
pools_operate()
{
  for pool in ${POOLS_LIST}
  do
    ENV=`echo ${pool} | cut -d\: -f 1 | tr [A-Z] [a-z]`

    if [ "${ENV}" != "prd" -a "${ENV}" != "qua" -a "${ENV}" != "dev" -a "${ENV}" != "sandbox" ]; then
      warning "Unrecognized environment ${ENV} on entry ${pool}"
      continue
    fi

    DOMAIN_NAME=`echo ${pool} | cut -d\: -f 2`
    DOMAIN_CHECK=`get-env-info.pl ${ENV} ${DOMAIN_NAME}`

    if [ "`echo ${DOMAIN_CHECK} | cut -d\: -f 1`" != "D" ]; then
      warning "Unrecognized domain ${DOMAIN_NAME} on entry ${pool}"
      continue
    else
      check_wl_version ${ENV} ${DOMAIN_NAME}
      check_java_version ${ENV} ${DOMAIN_NAME}
      POOL_NAME=`echo ${pool} | cut -d\: -f 3`
    fi

    DOMAIN_VERSION="`echo ${DOMAIN_CHECK} | cut -d\: -f 3`"
    DOMAIN_SERVER="`echo ${DOMAIN_CHECK} | cut -d\: -f 5`"
    DOMAIN_PORT="`echo ${DOMAIN_CHECK} | cut -d\: -f 6`"
    DOMAIN_USER="`echo ${DOMAIN_CHECK} | cut -d\: -f 7`"
    DOMAIN_PASSWD="`echo ${DOMAIN_CHECK} | cut -d\: -f 8`"

    info "${POOL_NAME}: Trying to `echo ${POOL_OPERATION} | tr [A-Z] [a-z]` pool located on domain ${DOMAIN_NAME}"
    wlstinfo "${POOL_NAME}: Trying to `echo ${POOL_OPERATION} | tr [A-Z] [a-z]` pool located on domain ${DOMAIN_NAME}"

    # Check WebLogic major version
    DOMAIN_MAJOR_VERSION="`echo ${DOMAIN_VERSION} | cut -d\. -f 1`"

    if [ ${DOMAIN_MAJOR_VERSION} -gt 8 ]; then
      wlstinfo "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${POOL_OPERATION_PYTHON_FILE} ${DOMAIN_SERVER} ${DOMAIN_PORT} ##### ${POOL_NAME} ${POOL_OPERATION}"

      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${POOL_OPERATION_PYTHON_FILE} ${DOMAIN_SERVER} ${DOMAIN_PORT} ${DOMAIN_PASSWD} ${POOL_NAME} ${POOL_OPERATION} >> ${WLST_LOGFILE}
    else
      DOMAIN_MINOR_VERSION="`echo ${DOMAIN_VERSION} | cut -d\. -f 3`"

      if [ "${POOL_OPERATION}" == "SUSPEND" ]; then
        wlstinfo "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.Admin -url t3://${DOMAIN_SERVER}:${DOMAIN_PORT} -username ${DOMAIN_USER} -password ##### SUSPEND_POOL -poolName ${POOL_NAME}"

        $JAVA_HOME/bin/java ${JVM_ARGS} weblogic.Admin -url t3://${DOMAIN_SERVER}:${DOMAIN_PORT} -username ${DOMAIN_USER} -password ${DOMAIN_PASSWD} SUSPEND_POOL -poolName "${POOL_NAME}" >> ${WLST_LOGFILE}
      elif [ "${POOL_OPERATION}" == "RESUME" ]; then
        if [ "${DOMAIN_MINOR_VERSION}" -gt 3 ]; then
          wlstinfo "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.Admin -url t3://${DOMAIN_SERVER}:${DOMAIN_PORT} -username ${DOMAIN_USER} -password ##### RESET_POOL -poolName ${POOL_NAME}"

          $JAVA_HOME/bin/java ${JVM_ARGS} weblogic.Admin -url t3://${DOMAIN_SERVER}:${DOMAIN_PORT} -username ${DOMAIN_USER} -password ${DOMAIN_PASSWD} RESET_POOL -poolName "${POOL_NAME}" >> ${WLST_LOGFILE}
        else
          wlstinfo "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.Admin -url t3://${DOMAIN_SERVER}:${DOMAIN_PORT} -username ${DOMAIN_USER} -password ##### RESET_POOL ${POOL_NAME}"

          $JAVA_HOME/bin/java ${JVM_ARGS} weblogic.Admin -url t3://${DOMAIN_SERVER}:${DOMAIN_PORT} -username ${DOMAIN_USER} -password ${DOMAIN_PASSWD} RESET_POOL ${POOL_NAME} >> ${WLST_LOGFILE}
        fi
      else
        warning "Operation `echo ${POOL_OPERATION} | tr [A-Z] [a-z]` not supported on WebLogic version 8.1"
        continue
      fi
    fi

    if [ $? -gt 0 ]; then
      warning "${POOL_NAME}: Unable to `echo ${POOL_OPERATION} | tr [A-Z] [a-z]` pool located on domain ${DOMAIN_NAME}"
    else
      info "${POOL_NAME}: Operation `echo ${POOL_OPERATION} | tr [A-Z] [a-z]` completed on pool located on domain ${DOMAIN_NAME}"
    fi

  done
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
pools_operate

info "Operation complete"
exit 0
