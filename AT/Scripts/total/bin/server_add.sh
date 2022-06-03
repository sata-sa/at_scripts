#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
DOMAIN=$2
MACHINE=$3
SERVER=$4
SERVER_LISTEN_PORT=$5
#CLUSTER=$6
APPLICATION_NAME=$6
CLUSTER=$7
TRANSACTION="SERVER_ADD(${DOMAIN}:${SERVER})"
JOBID=${RANDOM}

#########
# Paths #
#########
SERVER_PYTHON_FILE=${HOME}/etc/py/server_add_${ENV}.py
SERVER_START_PYTHON_FILE=${HOME}/etc/py/server_start.py
CLUSTER_PYTHON_FILE=${HOME}/etc/py/cluster_add.py
SERVER_CLUSTER_ASSIGN_PYTHON_FILE=${HOME}/etc/py/server_cluster_assign.py
EXALOGIC_SERVER_PYTHON_FILE=${HOME}/etc/py/server_exalogic_enhancements.py
EXALOGIC_CLUSTER_PYTHON_FILE=${HOME}/etc/py/cluster_exalogic_enhancements.py
SERVER_ADD_JAX_EXTENSIONS_PYTHON_FILE=${HOME}/etc/py/assign_server_jax_extensions.py


############
# Defaults #
############
DEFAULT_KRB_MAIN_FILE="/opt/sso/krb5.conf"
DEFAULT_KRB_LOGIN_FILE="/opt/sso/krb5login.conf"

#################################
# check for configuration files #
#################################
check_config_files()
{
  # Check Jython scrits
  if [ ! -e "${SERVER_PYTHON_FILE}" ]; then
    failure "Jython file ${SERVER_PYTHON_FILE} not found"
  fi

  if [ ! -e "${SERVER_START_PYTHON_FILE}" ]; then
    failure "Jython file ${SERVER_PYTHON_FILE} not found"
  fi

  if [ ! -e "${CLUSTER_PYTHON_FILE}" ]; then
    failure "Jython file ${CLUSTER_PYTHON_FILE} not found"
  fi

  if [ ! -e "${SERVER_CLUSTER_ASSIGN_PYTHON_FILE}" ]; then
    failure "Jython file ${SERVER_CLUSTER_ASSIGN_PYTHON_FILE} not found"
  fi

  if [ ! -e "${EXALOGIC_SERVER_PYTHON_FILE}" ]; then
    failure "Jython file ${EXALOGIC_SERVER_PYTHON_FILE} not found"
  fi

  if [ ! -e "${EXALOGIC_CLUSTER_PYTHON_FILE}" ]; then
    failure "Jython file ${EXALOGIC_CLUSTER_PYTHON_FILE} not found"
  fi

  if [ ! -e "${SERVER_ADD_JAX_EXTENSIONS_PYTHON_FILE}" ]; then
    failure "Jython file ${SERVER_ADD_JAX_EXTENSIONS_PYTHON_FILE} not found"
  fi
}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <DOMAIN NAME> <MACHINE NAME> <SERVER NAME> <SERVER LISTEN PORT> <APPLICATION NAME> [CLUSTER_NAME]

  ENVIRONMENT         - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME         - The domain name available
  MACHINE NAME        - Machine where the JVM will be running
  SERVER NAME         - Name of your new server
  SERVER LISTEN PORT  - Listen port for your server - NOTICE: it'll also use the next two contiguous ports
  APPLICATION NAME    - The name of the new application
  CLUSTER NAME        - Name of the cluster where the server is assigned to. Leave empty for standalone server

EOF
}

##############################################################################
#    Check Machines Availables - Change this to work with array in future    #
##############################################################################
check_machine_available()
{
   if [[ ${MACHINE} == "suljvmgold10"[1-9] || ${MACHINE} == "suljvmgold110" && ${ENV} == "prd" ]]; then
      failure "It's closed at the moment, come another time please. Glass is half full or half empty.... !!!!! ${MACHINE} !!!!!"
      #failute "This machine is not available for new Domains. ${MACHINE}"
   fi

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
  if [ ${ARGNUM} -lt 7 ]; then
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

  if [ -z "${SERVER}" ]; then
    failure "Server must be defined"
  fi

  if [ -z "${SERVER_LISTEN_PORT}" ]; then
    failure "Server port must be defined"
  else
    ##Bruno 20151030 - Issue numeric value port
    CHECKPORTNUMERIC='^[0-9]+$'
    #if [ ! -z "`echo ${SERVER_LISTEN_PORT} | tr -d [0-9]`" ]; then
    if ! [[ ${SERVER_LISTEN_PORT} =~ ${CHECKPORTNUMERIC} ]]; then
    ##
      failure "Server port must be numeric"
    fi
  fi

  if [ -z "${APPLICATION_NAME}" ]; then
     failure "The application name must be specified"
  fi
}

#################################
# Get access details for domain #
#################################
get_domain_details()
{
  DOMAIN_DETAILS=`get-env-info.pl ${ENV} ${DOMAIN}`
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
  # Check if machine exists
  DBQUERY=`get-env-info.pl ${ENV} ${MACHINE}`
  XMLQUERY=`get-wls-object-list.pl ${STAGE_PATH}/${DOMAIN}.${ENV}.xml machine | grep -w ${MACHINE}`

  if [ -z ${DBQUERY} ] && [ -z ${XMLQUERY} ]; then
    failure "Machine ${MACHINE} is not present in database and WebLogic. Add with machine_add.sh"
  elif [ -z ${DBQUERY} ]; then
    failure "Machine ${MACHINE} is not present in database"
  elif [ -z ${XMLQUERY} ]; then
    failure "Machine ${MACHINE} is not present in WebLogic domain ${DOMAIN}"
  fi

  # Check if cluster already exists
  if [ ! -z ${CLUSTER} ]; then
    DBQUERY=`get-env-info.pl ${ENV} ${CLUSTER}`
    XMLQUERY=`get-wls-object-list.pl ${STAGE_PATH}/${DOMAIN}.${ENV}.xml cluster | grep -w ${CLUSTER}`

    if [ ! -z ${DBQUERY} ] && [ ! -z ${XMLQUERY} ]; then
      info "Cluster ${CLUSTER} already present in ${ENV} database and WebLogic domain ${DOMAIN}"
      CREATE_CLUSTER="N"
    elif [ ! -z ${DBQUERY} ]; then
      failure "Cluster ${CLUSTER} is only present in ${ENV} database"
    elif [ ! -z ${XMLQUERY} ]; then
      failure "Cluster ${CLUSTER} is only present in WebLogic domain ${DOMAIN}"
    else
      CREATE_CLUSTER="Y"
    fi
  fi

  # Check if server already exists
  DBQUERY=`get-env-info.pl ${ENV} ${SERVER}`
  XMLQUERY=`get-wls-object-list.pl ${STAGE_PATH}/${DOMAIN}.${ENV}.xml -members all | grep -w ${SERVER}`

  if [ ! -z ${DBQUERY} ] && [ ! -z ${XMLQUERY} ]; then
    failure "Server ${SERVER} already present in ${ENV} database and WebLogic domain ${DOMAIN}"
  elif [ ! -z ${DBQUERY} ]; then
    failure "Server ${SERVER} already present in ${ENV} database"
  elif [ ! -z ${XMLQUERY} ]; then
    failure "Server ${SERVER} already present in WebLogic domain ${DOMAIN}"
  fi

  CREATE_SERVER="Y"

  # Set Kerberos files locations
  if [ "${ENV}" == "prd" ]; then
    KRB_MAIN_FILE="${SSO_PATH_PRD}/krb5.conf"
    KRB_LOGIN_FILE="${SSO_PATH_PRD}/krb5login_`echo ${ADMIN_HOST} | cut -d\. -f 1`.conf"
  elif [ "${ENV}" == "qua" ]; then
    #KRB_MAIN_FILE="${SSO_PATH_QUA}/krb5.conf"
    #KRB_LOGIN_FILE="${SSO_PATH_QUA}/krb5login_`echo ${ADMIN_HOST} | cut -d\. -f 1`.conf"
    KRB_MAIN_FILE="${SSO_PATH_DEV}/krb5.${APPLICATION_NAME}.conf"
    KRB_LOGIN_FILE="${SSO_PATH_DEV}/krb5login.${APPLICATION_NAME}.conf"
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_MAIN_FILE} ${KRB_MAIN_FILE}; chmod 440 ${KRB_MAIN_FILE}"
    if [ $? -gt 0 ]; then
       failure "Problems creating the file ${KRB_MAIN_FILE}"
    fi
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_LOGIN_FILE} ${KRB_LOGIN_FILE}; chmod 440 ${KRB_LOGIN_FILE}"
    if [ $? -gt 0 ]; then
       failure "Problems creating the file ${KRB_LOGIN_FILE}"
    fi
  elif [ "${ENV}" == "dev" ]; then
    KRB_MAIN_FILE="${SSO_PATH_DEV}/krb5.${APPLICATION_NAME}.conf"
    KRB_LOGIN_FILE="${SSO_PATH_DEV}/krb5login.${APPLICATION_NAME}.conf"
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_MAIN_FILE} ${KRB_MAIN_FILE}; chmod 440 ${KRB_MAIN_FILE}"
    if [ $? -gt 0 ]; then
       failure "Problems creating the file ${KRB_MAIN_FILE}"
    fi
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_LOGIN_FILE} ${KRB_LOGIN_FILE}; chmod 440 ${KRB_LOGIN_FILE}"
    if [ $? -gt 0 ]; then
       failure "Problems creating the file ${KRB_LOGIN_FILE}"
    fi
  elif [ "${ENV}" == "sandbox" ]; then
    KRB_MAIN_FILE="${SSO_PATH_SANDBOX}/krb5.conf"
    KRB_LOGIN_FILE="${SSO_PATH_SANDBOX}/krb5login_`echo ${ADMIN_HOST} | cut -d\. -f 1`.conf"
  fi
}

##################
# Create cluster #
##################
add_cluster()
{
  if [ "${CREATE_CLUSTER}" == "Y" ]; then
    info "Attempting to create cluster ${CLUSTER}"
    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${CLUSTER_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${CLUSTER}

    if [ $? -gt 0 ]; then
      failure "Unable to create cluster ${CLUSTER}"
    else
      info "Cluster ${CLUSTER} created in WebLogic domain ${DOMAIN}"
      info "`set-env-info.pl ${ENV} -i c,${CLUSTER},${DOMAIN}`"
    fi
  fi
}

#################
# Create server #
#################
add_server()
{
  if [ "${CREATE_SERVER}" == "Y" ]; then
    MACHINE_MEM=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cat /proc/meminfo | grep MemFree | cut -d\: -f2 | tr -d [:alpha:] | tr -d [:blank:]" 2>/dev/null`

    if [ ${MACHINE_MEM} -lt 1048576 ]
    then
      warning "Available memory on machine ${MACHINE} is below 1.0 GB: ${MACHINE_MEM} kB"
    else
      info "Available memory on machine ${MACHINE}: ${MACHINE_MEM} kB"
    fi

    info "Attempting to create server ${SERVER}"

    "${JAVA_HOME}/bin/java" ${JVM_ARGS} weblogic.WLST ${SERVER_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${SERVER} ${MACHINE} ${SERVER_LISTEN_PORT} ${KRB_LOGIN_FILE} ${KRB_MAIN_FILE} ${JAVA_HOME}

    if [ $? -gt 0 ]; then
      failure "Unable to create server ${SERVER}"
    else
      info "Server ${SERVER} created in WebLogic domain ${DOMAIN}"
      server_exalogic_enhancements

      if [ -z "${CLUSTER}" ]; then
        info "`set-env-info.pl ${ENV} -i s,${SERVER},${DOMAIN},,${MACHINE}`"
      else
        info "`set-env-info.pl ${ENV} -i s,${SERVER},${DOMAIN},${CLUSTER},${MACHINE}`"
        server_cluster_assign
      fi
    fi
  fi
}

####################################################
# Assign newly created server to specified cluster #
####################################################
server_cluster_assign()
{
  if [ ! -z "${CLUSTER}" ]; then
    info "Attempting to assign server ${SERVER} to cluster ${CLUSTER}"

    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${SERVER_CLUSTER_ASSIGN_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${SERVER} ${CLUSTER}

    if [ $? -gt 0 ]; then
      failure "Unable to assign server ${SERVER} to cluster ${CLUSTER}"
    else
       if [ "${ENV}" == "prd" ]; then
          cluster_exalogic_enhancements
       elif [ "${ENV}" == "qua" ]; then
          server_normal_enhancements
       fi

      info "Server ${SERVER} assigned to cluster ${CLUSTER}"
#      `set-env-info.pl ${ENV} -u s,${SERVER},,${CLUSTER}`

#alterado aqui:: Mangerico
#coloca o porto
      `set-env-info.pl ${ENV} -u s,${SERVER},,${SERVER_LISTEN_PORT}`


    fi
  fi
}

#######################################
# Enable server Exalogic enhancements #
#######################################
server_exalogic_enhancements()
{
  if [ ! -z "${CLUSTER}" ]; then
    # Check if machine where server is going to run, belongs to Exalogic realm
    # Bruno 20150304
    #EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "dmesg | grep -w Xen | wc -l" 2>/dev/null`
    EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "/sbin/lspci | grep Xen" 2>/dev/null`

    #if [ "${EXAID}" != "0" ]; then
    if [ -n "${EXAID}" ]; then
      info "Enabling server Exalogic-specific enhancements"
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${EXALOGIC_SERVER_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${SERVER} ${MACHINE} ${CLUSTER}

      # Check logs directory existance
      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls ${EXA_LOGS}/${DOMAIN}/${SERVER}" &>/dev/null

      if [ $? -gt 0 ]; then
        info "Creating logs directory for server ${SERVER}"
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${EXA_LOGS}/${DOMAIN}/${SERVER}"

        if [ $? -gt 0 ]; then
          warning "Unable to create logs directory ${EXA_LOGS}/${DOMAIN}/${SERVER}"
        else
          info "Creating server directory ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"
          ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"

          if [ $? -gt 0 ]; then
            warning "Unable to create server directory ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"
          else
            info "Creating symbolic link to ${EXA_LOGS}/${DOMAIN}/${SERVER}"
            ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ln -s ${EXA_LOGS}/${DOMAIN}/${SERVER} ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}/logs"

            if [ $? -gt 0 ]; then
              warning "Unable to create symbolic link to ${EXA_LOGS}/${DOMAIN}/${SERVER}"
            fi
          fi
        fi
      else
        info "Logs directory ${EXA_LOGS}/${DOMAIN}/${SERVER} already exists"
      fi
    fi
  fi
} 

##############################
# Enable server enhancements #
##############################
server_normal_enhancements()
{
    # Check logs directory existance
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls ${EXA_LOGS}/${DOMAIN}/${SERVER}" &>/dev/null

    if [ $? -gt 0 ]; then
       info "Creating logs directory for server ${SERVER}"
       ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${EXA_LOGS}/${DOMAIN}/${SERVER}"

       if [ $? -gt 0 ]; then
          warning "Unable to create logs directory ${EXA_LOGS}/${DOMAIN}/${SERVER}"
       else
          info "Creating server directory ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"
          ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"

          if [ $? -gt 0 ]; then
            warning "Unable to create server directory ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"
          else
            info "Creating symbolic link to ${EXA_LOGS}/${DOMAIN}/${SERVER}"
            ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ln -s ${EXA_LOGS}/${DOMAIN}/${SERVER} ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}/logs"

            if [ $? -gt 0 ]; then
               warning "Unable to create symbolic link to ${EXA_LOGS}/${DOMAIN}/${SERVER}"
            fi
          fi
       fi
    else
       info "Logs directory ${EXA_LOGS}/${DOMAIN}/${SERVER} already exists"
    fi
}

#######################################
# Enable server Exalogic enhancements #
#######################################
server_exalogic_enhancements()
{
  if [ ! -z "${CLUSTER}" ]; then
    # Check if machine where server is going to run, belongs to Exalogic realm
    # Bruno 20150304
    #EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "dmesg | grep -w Xen | wc -l" 2>/dev/null`
    EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "/sbin/lspci | grep Xen" 2>/dev/null`

    #if [ "${EXAID}" != "0" ]; then
    if [ -n "${EXAID}" ]; then
      info "Enabling server Exalogic-specific enhancements"
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${EXALOGIC_SERVER_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${SERVER} ${MACHINE} ${CLUSTER}

      # Check logs directory existance
      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls ${EXA_LOGS}/${DOMAIN}/${SERVER}" &>/dev/null

      if [ $? -gt 0 ]; then
        info "Creating logs directory for server ${SERVER}"
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${EXA_LOGS}/${DOMAIN}/${SERVER}"

        if [ $? -gt 0 ]; then
          warning "Unable to create logs directory ${EXA_LOGS}/${DOMAIN}/${SERVER}"
        else
          info "Creating server directory ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"
          ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"

          if [ $? -gt 0 ]; then
            warning "Unable to create server directory ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}"
          else
            info "Creating symbolic link to ${EXA_LOGS}/${DOMAIN}/${SERVER}"
            ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ln -s ${EXA_LOGS}/${DOMAIN}/${SERVER} ${DOMAIN_HOME}/${DOMAIN}/servers/${SERVER}/logs"

            if [ $? -gt 0 ]; then
              warning "Unable to create symbolic link to ${EXA_LOGS}/${DOMAIN}/${SERVER}"
            fi
          fi
        fi
      else
        info "Logs directory ${EXA_LOGS}/${DOMAIN}/${SERVER} already exists"
      fi
    fi
  fi
}

#######################################
# Enable cluster Exalogic enhancements #
#######################################
cluster_exalogic_enhancements()
{
  # Check if machine where server is going to run, belongs to Exalogic realm
  # Bruno 20150304
  #EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "dmesg | grep -w Xen | wc -l" 2>/dev/null`
  EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "/sbin/lspci | grep Xen" 2>/dev/null`

  #if [ "${EXAID}" != "0" ]; then
  if [ -n "${EXAID}" ]; then
    info "Enabling cluster Exalogic-specific enhancements"
    # Bruno
    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${EXALOGIC_CLUSTER_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${CLUSTER} ${MACHINE} ${SERVER_LISTEN_PORT}
    ###
  fi
}

add_webservices_extension()
{
  # Check if domain supports JAX extensions
  ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls ${DOMAIN_HOME}/${DOMAIN}/wls_webservice_complete_update_utils.py" &>/dev/null

  if [ $? -gt 0 ]; then
    info "No JAX extensions on domain ${DOMAIN}"
  else
    info "Attempting to add JAX extensions to server ${SERVER}"

    scp ${SERVER_ADD_JAX_EXTENSIONS_PYTHON_FILE} ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}

    if [ $? -gt 0 ]; then
      warning "Unable to copy jax extension script to ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}"
    else
      SERVER_EXTENSION_SCRIPT_NAME=`basename ${SERVER_ADD_JAX_EXTENSIONS_PYTHON_FILE}`

      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${DOMAIN_HOME}/${DOMAIN}/${SERVER_EXTENSION_SCRIPT_NAME} ${DOMAIN_HOME}/${DOMAIN} ${SERVER}"

      if [ $? -gt 0 ]; then
        warning "Unable to add JAX extensions to server ${SERVER}"
      else
        info "JAX extensions added to server ${SERVER}"
      fi
    fi
  fi
}

########################
# start managed server #
########################
start_server()
{
  info "Attempting to start managed server ${SERVER}"
  "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${SERVER_START_PYTHON_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} ${SERVER}

  if [ $? -gt 0 ]; then
    warning "Unable to start ${SERVER}"
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
check_machine_available
start_arg_checks
check_config_files
check_wl_version ${ENV} ${DOMAIN}
check_java_version ${ENV} ${DOMAIN}
get_domain_details
check_db_weblogic
add_cluster
add_server
add_webservices_extension
#start_server

info "Operation complete"
exit 0
