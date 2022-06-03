#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
DOMAIN=$2
MACHINE=$3
CLUSTER=$6
TRANSACTION="MACHINE_ADD(${DOMAIN}:${MACHINE})"
JOBID=${RANDOM}
DISABLE_JAVA_NODEMGR="Y"

#########
# Paths #
#########
MACHINE_PYTHON_FILE=${HOME}/etc/py/machine_add.py
NODE_MGR_ENROLL=${HOME}/etc/py/nm_enroll.py
NODE_MGR_SSH=${HOME}/etc/py/nm_ssh.py
NODE_MGR_PLAIN=${HOME}/etc/py/nm_plain.py

#################################
# check for configuration files #
#################################
check_config_files()
{
  # Check Jython files
  if [ ! -e "${MACHINE_PYTHON_FILE}" ]; then
    failure "Jython file ${MACHINE_PYTHON_FILE} not found"
  fi

  if [ ! -e "${NODE_MGR_ENROLL}" ]; then
    failure "Jython file ${NODE_MGR_ENROLL} not found"
  fi

  if [ ! -e "${NODE_MGR_SSH}" ]; then
    failure "Jython file ${NODE_MGR_SSH} not found"
  fi

  if [ ! -e "${NODE_MGR_PLAIN}" ]; then
    failure "Jython file ${NODE_MGR_PLAIN} not found"
  fi
}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <DOMAIN NAME> <MACHINE NAME>

  ENVIRONMENT    - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME    - The domain name available
  MACHINE NAME   - The name of the machine to create in the domain

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

  if [ -z "${MACHINE}" ]; then
    failure "Machine must be defined"
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

#################################################
# Cross check database and weblogic information #
#################################################
check_db_weblogic()
{
  # Check if machine already exists
  DBQUERY=`get-env-info.pl ${ENV} ${MACHINE}`
  XMLQUERY=`get-wls-object-list.pl ${STAGE_PATH}/${DOMAIN}.${ENV}.xml machine | grep -w ${MACHINE}`

  if [ ! -z ${XMLQUERY} ]; then
    failure "Machine ${MACHINE} is already present in WebLogic domain ${DOMAIN}"
  else
    CREATE_WL_MACHINE="Y"
  fi

  if [ -z ${DBQUERY} ]; then
    CREATE_DB_MACHINE="Y"
  fi
}

##################
# Create Machine #
##################
add_machine()
{
  # Try to contact the machine
  # Bruno 20150203
  EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "dmesg | grep -w Xen | wc -l" 2>/dev/null`
  #EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "/sbin/lspci | grep Xen" 2>/dev/null`

  if [ $? -gt 0 ]; then
    failure "Unable to contact machine ${MACHINE}"
  fi

  if [ "${CREATE_WL_MACHINE}" == "Y" ]; then

    info "Adding machine ${MACHINE} to domain ${DOMAIN}"
    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${MACHINE_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${MACHINE}

    if [ $? -gt 0 ]; then
      failure "Unable to create machine ${MACHINE}"
    else
      info "Machine ${MACHINE} created in WebLogic domain ${DOMAIN}"

      if [ "${CREATE_DB_MACHINE}" == "Y" ]; then
        info "`set-env-info.pl ${ENV} -i m,${MACHINE}`"
      else
        info "Machine ${MACHINE} already present in environment database"
      fi
    fi
  fi
}

#######################################
# Create domain strucuture on machine #
#######################################
pack_unpack_domain()
{
  ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls ${DOMAIN_HOME}/${DOMAIN}" &>/dev/null

  if [ $? -gt 0 ]; then
    WLSERVER_PATH=`grep -w "${WEBLOGIC_VERSION}" "${WLS_LIST}" | cut -d\: -f 2`
    PACK_PATH=`ssh -n -o StrictHostKeyChecking=no ${USER}@${ADMIN_HOST} "find ${WLSERVER_PATH} -name pack.sh"`

    if [ $? -gt 0 ]; then
      failure "Unable to locate command pack.sh on machine ${ADMIN_HOST}"
    fi

    info "Attempting to pack domain ${DOMAIN}"

    ssh -n -o StrictHostKeyChecking=no ${USER}@${ADMIN_HOST} "rm -f ${ADMIN_PATH}/${DOMAIN}_tmp.jar" &>/dev/null
    ssh -n -o StrictHostKeyChecking=no ${USER}@${ADMIN_HOST} "${PACK_PATH} -managed=true -domain=${ADMIN_PATH} -template=${ADMIN_PATH}/${DOMAIN}_tmp.jar -template_name=${DOMAIN}_template"

    if [ $? -gt 0 ]; then
      failure "Unable to pack domain ${DOMAIN}"
    fi

    info "Transfering domain template file from ${ADMIN_HOST} to ${MACHINE}"

    scp ${USER}@${ADMIN_HOST}:${ADMIN_PATH}/${DOMAIN}_tmp.jar ${STAGE_PATH}/${DOMAIN}_tmp.jar &>/dev/null

    if [ $? -gt 0 ]; then
      failure "Unable to transfer file ${DOMAIN}_tmp.jar from ${ADMIN_HOST} to local machine"
    fi

    scp ${STAGE_PATH}/${DOMAIN}_tmp.jar ${USER}@${MACHINE}:${DOMAIN_HOME} &>/dev/null

    if [ $? -gt 0 ]; then
      failure "Unable to transfer file ${DOMAIN}_tmp.jar from local machine to remote machine ${MACHINE}"
    fi
    
    #UNPACK ISSUE EXTRACT TEMP DIRECTORY - Bruno 20150921
    UNPACK_PATH=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "find ${WLSERVER_PATH} -name unpack.sh"`
    TMP_APP_PATH="/tmp/"${MACHINE}
    ##

    if [ $? -gt 0 ]; then
      failure "Unable to locate unpack.sh command on machine ${MACHINE}" 
    fi

    info "Attempting to unpack domain template on machine ${MACHINE}"
 
    #UNPACK ISSUE EXTRACT TEMP DIRECTORY - Bruno 20150921
    #ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "${UNPACK_PATH} -domain=${ADMIN_PATH} -template=${DOMAIN_HOME}/${DOMAIN}_tmp.jar"
    ##Mangerico 20150925
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm -rf /tmp/${MACHINE}"
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "${UNPACK_PATH} -log_priority=debug -log=/home/weblogic/unpacklog.txt  -app_dir=${TMP_APP_PATH} -domain=${ADMIN_PATH} -template=${DOMAIN_HOME}/${DOMAIN}_tmp.jar"
    #ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "${UNPACK_PATH} -app_dir=${TMP_APP_PATH} -domain=${ADMIN_PATH} -template=${DOMAIN_HOME}/${DOMAIN}_tmp.jar"
    ##

    if [ $? -gt 0 ]; then
      failure "Unable to unpack domain template file ${DOMAIN_HOME}/${DOMAIN}_tmp.jar"
    fi

    #Cleanup
    #rm -rf ${STAGE_PATH}/${DOMAIN}_tmp.jar
    #UNPACK ISSUE EXTRACT TEMP DIRECTORY - Bruno 20150921
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm -rf ${DOMAIN_HOME}/${DOMAIN}_tmp.jar"
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm -rf ${TMP_APP_PATH}"
    ##Mangerico 20150925
    #ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm -rf /tmp/${MACHINE}"

    ssh -n -o StrictHostKeyChecking=no ${USER}@${ADMIN_HOST} "rm -rf ${ADMIN_PATH}/${DOMAIN}_tmp.jar"
  else
    info "Domain ${DOMAIN} already present on machine ${MACHINE}. Skipping domain unpack"
  fi
}

##################################
# Update NodeManager information #
##################################
update_node_manager()
{
  # Check if machine is in Exalogic Realm
  # Bruno 20150304
  EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "/sbin/lspci | grep Xen" 2>/dev/null`
  #if [ "${EXAID}" == "0" ]; then
  if [ -z "${EXAID}" ]; then
    info "Machine ${MACHINE} does not belong to Exalogic Realm. Configuring NodeManager to use SSH"
    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${NODE_MGR_SSH} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${MACHINE} ${MACHINE}

    if [ $? -gt 0 ]; then
      failure "Unable to update NodeManager information for machine ${MACHINE}"
    fi
  else
    if [ "${DISABLE_JAVA_NODEMGR}" == "Y" ]; then
      info "Java based NodeManager disabled. Using SSH to start managed servers"
      LISTEN_ADDRESS="`echo ${MACHINE} | cut -d\. -f 1`-clu.ritta.local"
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${NODE_MGR_SSH} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${MACHINE} ${LISTEN_ADDRESS}

      if [ $? -gt 0 ]; then
        failure "Unable to update NodeManager information for machine ${MACHINE}"
      fi
    else
      info "Machine ${MACHINE} belongs to Exalogic Realm"

      FILE_LIST=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -1 ${NODE_MANAGER_PATH}/${MACHINE}"`

      if [ $? -gt 0 ]; then
        failure "Directory ${NODE_MANAGER_PATH}/${MACHINE} not found"
      fi

      # Confgure domain
      info "Configuring NodeManager in domain ${DOMAIN}"
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${NODE_MGR_PLAIN} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${MACHINE}

      if [ $? -gt 0 ]; then
        failure "Unable to configure NodeManager in domain ${DOMAIN}"
      fi

      # Enroll machine with domain
      info "Enrolling machine ${MACHINE} with domain ${DOMAIN}"
      scp ${NODE_MGR_ENROLL} ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN} &>/dev/null

      if [ $? -gt 0 ]; then
        failure "Unable to scp file ${NODE_MGR_ENROLL} to machine ${MACHINE}"
      else
        REMOTE_NODE_MGR_ENROLL=${DOMAIN_HOME}/${DOMAIN}/`basename ${NODE_MGR_ENROLL}`
      fi

      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${REMOTE_NODE_MGR_ENROLL} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${MACHINE} ${NODE_MANAGER_PATH}"

      if [ $? -gt 0 ]; then
        failure "Unable to enroll machine ${MACHINE} in domain ${DOMAIN}"
      else
        info "Machine ${MACHINE} enrolled with domain ${DOMAIN}"
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm -f ${REMOTE_NODE_MGR_ENROLL}"
      fi
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
check_wl_version ${ENV} ${DOMAIN}
check_java_version ${ENV} ${DOMAIN}
get_domain_details
check_db_weblogic
add_machine
pack_unpack_domain
update_node_manager

info "Operation complete"
binfo "RESTART ADMINSERVER TO APPLY CHANGES"
exit 0
