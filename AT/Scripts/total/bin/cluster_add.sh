#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
DOMAIN=$2
CLUSTER=$3
TRANSACTION="CLUSTER_ADD(${DOMAIN}:${CLUSTER})"
JOBID=${RANDOM}

#########
# Paths #
#########
CLUSTER_PYTHON_FILE=${HOME}/etc/py/cluster_add.py

#################################
# check for configuration files #
#################################
check_config_files()
{
  # Check Jython scrits
  if [ ! -e "${CLUSTER_PYTHON_FILE}" ]; then
    failure "Jython file ${CLUSTER_PYTHON_FILE} not found"
  fi
}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <DOMAIN NAME> <CLUSTER NAME>

  ENVIRONMENT    - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME    - The domain name available
  CLUSTER NAME   - Name of your new cluster

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

  if [ -z "${CLUSTER}" ]; then
    failure "Cluster must be defined"
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
  # Check if cluster already exists
  if [ ! -z ${CLUSTER} ]; then
    DBQUERY=`get-env-info.pl ${ENV} ${CLUSTER}`
    XMLQUERY=`get-wls-object-list.pl ${STAGE_PATH}/${DOMAIN}.${ENV}.xml cluster | grep -w ${CLUSTER}`

    if [ ! -z ${DBQUERY} ] && [ ! -z ${XMLQUERY} ]; then
      failure "Cluster ${CLUSTER} already present in ${ENV} database and WebLogic domain ${DOMAIN}"
    elif [ ! -z ${DBQUERY} ]; then
      failure "Cluster ${CLUSTER} already present in ${ENV} database"
    elif [ ! -z ${XMLQUERY} ]; then
      failure "Cluster ${CLUSTER} already present in WebLogic domain ${DOMAIN}"
    fi

    CREATE_CLUSTER="Y"
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
      # Create the cluster first
      info "Cluster ${CLUSTER} created in WebLogic domain ${DOMAIN}"
      info "`set-env-info.pl ${ENV} -i c,${CLUSTER},${DOMAIN}`"
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
add_cluster

info "Operation complete"
exit 0
