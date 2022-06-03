#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
DOMAIN=$2
DOMAIN_PORT=$3
DOMAIN_PASSWORD=$4
MACHINE=$5
WEBLOGIC_VERSION=$6
JAVA_VERSION=$7
WLRUNNING="N"
TRANSACTION="DOMAIN_ADD(${DOMAIN})"
JOBID=${RANDOM}
USERNAME="CloudControlMonitor"
USER_PASSWORD="cloud20monitor13exa"
DATE_MOVE_SETDOMAIN=`date +%Y%m%d_%H%M%S`

#########
# Paths #
#########
DOMAIN_PYTHON_FILE=${HOME}/etc/py/domain_add_${ENV}.py
DOMAIN_WRITE_PYTHON_FILE=${HOME}/etc/py/domain_write_${ENV}.py
DOMAIN_WRITE_PYTHON_FILE_122C=${HOME}/etc/py/domain_write_${ENV}_122c.py
REORDER_PROVIDERS_PYTHON_FILE=${HOME}/etc/py/reorder_providers_template.py
EXALOGIC_PYTHON_FILE=${HOME}/etc/py/domain_exalogic_enhancements.py
USER_ADD_PYTHON_FILE=${HOME}/etc/py/user_add.py
DOMAIN_EXTENSION_PYTHON_FILE=${HOME}/etc/py/domain_extension.py
ADMIN_JAX_UNASSIGN_PYTHON_FILE=${HOME}/etc/py/unassign_adminserver_jax_extensions.py

############
# Defaults #
############
DEFAULT_KRB_MAIN_FILE="/opt/sso/krb5.conf"
DEFAULT_KRB_LOGIN_FILE="/opt/sso/krb5login.conf"

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <DOMAIN NAME> <ADMIN PORT> <ADMIN PASSWORD> <MACHINE NAME> [WEBLOGIC VERSION] [JAVA VERSION]

  ENVIRONMENT        - The environment where the new domain will be created. Available options are: PRD/QUA/DEV/SANDBOX
  DOMAIN NAME        - The name of the new domain. Will be installed under /weblogic
  ADMIN PORT         - Port where your administration server will be listening

                       Last used PRD admin port: `get-env-info.pl prd | cut -d\: -f 6 | sort -n | tail -1`
                       Last used QUA admin port: `get-env-info.pl qua | cut -d\: -f 6 | sort -n | tail -1`
                       Last used DEV admin port: `get-env-info.pl dev | cut -d\: -f 6 | sort -n | tail -1`

  ADMIN PASSWORD     - Password for user weblogic, to access the admiministration server
  MACHINE NAME       - Machine where the new AdminServer (domain) will be running
  WEBLOGIC VERSION   - Version of weblogic to use, for the new domain. Leave empty for default version

                       Available versions: ${DEFAULT_WEBLOGIC_VERSION} (Default)
                                           `echo -e "${WEBLOGIC_VERSION_LIST}" | sed ':a;N;$!ba;s/\n/, /g'`

  JAVA VERSION       - Version of Java to use, for the new domain. Leave empty for default version

                       Available versions: ${DEFAULT_JAVA_VERSION} (Default)
                                           `echo -e "${JAVA_VERSION_LIST}" | sed ':a;N;$!ba;s/\n/, /g'`

EOF
}

##############################################################################
#    Check Machines Availables - Change this to work with array in future    #
##############################################################################
check_machine_available()
{
   if [[ ${MACHINE} = "suldomaingold101" ]]; then
      failure "It's closed at the moment, come another time please. Glass is half full or half empty.... !!!!! ${MACHINE} !!!!!"
      #failute "This machine is not available for new Domains. ${MACHINE}"
   fi
 
}

###################################
# Build webLogic list of versions #
###################################
build_wls_versions_list()
{
  # Check script configuration files
  if [ -e "${WLS_LIST}" ]; then
    DEFAULT_WEBLOGIC_VERSION=`cat ${WLS_LIST} | grep -i default | cut -d\: -f 1`
    WEBLOGIC_VERSION_LIST=`cat ${WLS_LIST} | grep -vi default | cut -d\: -f 1`
  else
    failure "No Weblogic versions file list found"
  fi
}

###############################
# Build Java list of versions #
###############################
build_java_versions_list()
{
  if [ -e "${JAVA_LIST}" ]; then
    DEFAULT_JAVA_VERSION=`cat ${JAVA_LIST} | grep -i default | cut -d\: -f 1`
    JAVA_VERSION_LIST=`cat ${JAVA_LIST} | grep -vi default | cut -d\: -f 1`
  else
    failure "No Java versions file list found"
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

  if [ -z "${DOMAIN_PORT}" ]; then
    failure "Domain port must be defined"
  elif [ ${DOMAIN_PORT} -gt "65535" ]; then
    failure "The port number is greater than 2^16-1"
  elif [ ${DOMAIN_PORT} -le 1024 ]; then
    failure "Recommended reading >> http://www.tcpipguide.com/free/t_TCPIPApplicationAssignmentsandServerPortNumberRang-2.htm"
  else
    CHECKNUMERICVAR='^[0-9]+$'
    #if [ ! -z "`echo ${DOMAIN_PORT} | tr -d [0-9]`" ]; then
    if ! [[ ${DOMAIN_PORT} =~ ${CHECKNUMERICVAR}  ]]; then
      failure "Domain port must be numeric"
    fi
  fi

  if [ -z "${DOMAIN_PASSWORD}" ]; then
    failure "Domain password must be defined"
  fi

  if [ -z "${MACHINE}" ]; then
    failure "Machine must be defined"
  fi

  # Check password length
  if [ `echo ${DOMAIN_PASSWORD} | tr -d '\n' | wc -m` -lt 8 ]; then
    failure "The password must be at least 8 alphanumeric characters with at least one number or special character"
  elif [ -z `echo ${DOMAIN_PASSWORD} | tr -d [a-z,A-Z]` ]; then
    failure "The password must be at least 8 alphanumeric characters with at least one number or special character"
  fi
}

##########################
# check for Jython files #
##########################
check_jython_files()
{
  # Check Jython files
  if [ ! -e "${DOMAIN_PYTHON_FILE}" ]; then
    failure "Jython file ${DOMAIN_PYTHON_FILE} not found"
  fi

  if [ "${ENV}" != "prd" ]; then
    if [ ! -e "${DOMAIN_WRITE_PYTHON_FILE}" ]; then
      failure "Jython file ${DOMAIN_WRITE_PYTHON_FILE} not found"
    fi
  fi

  if [ ! -e "${REORDER_PROVIDERS_PYTHON_FILE}" ]; then
    failure "jython file ${REORDER_PROVIDERS_PYTHON_FILE} not found"
  fi

  if [ ! -e "${EXALOGIC_PYTHON_FILE}" ]; then
    failure "jython file ${EXALOGIC_PYTHON_FILE} not found"
  fi

  if [ ! -e "${USER_ADD_PYTHON_FILE}" ]; then
    failure "jython file ${USER_ADD_PYTHON_FILE} not found"
  fi

  if [ ! -e "${DOMAIN_EXTENSION_PYTHON_FILE}" ]; then
    failure "jython file ${DOMAIN_EXTENSION_PYTHON_FILE} not found"
  fi

  if [ ! -e "${ADMIN_JAX_UNASSIGN_PYTHON_FILE}" ]; then
    failure "jython file ${ADMIN_JAX_UNASSIGN_PYTHON_FILE} not found"
  fi
}

####################################################################
# set up WL_HOME, the root directory of your WebLogic installation #
####################################################################
set_wls_version()
{
  if [ -z ${WEBLOGIC_VERSION} ]; then
    WL_HOME=`cat "${WLS_LIST}" | grep -i default | cut -d\: -f 2`

    # Check local and remote weblogic location
    if [ ! -e "${WL_HOME}" ]; then
      failure "Weblogic `dirname ${WL_HOME}` not found"
    else
      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -l ${WL_HOME}" &>/dev/null

      if [ $? -gt 0 ]; then
        failure "Weblogic `dirname ${WL_HOME}` not found at ${MACHINE}"
      fi
      WEBLOGIC_VERSION="${DEFAULT_WEBLOGIC_VERSION}"
    fi
  else
    WL_VERSIONS=`cat "${WLS_LIST}" | cut -d\: -f 1 | tr -d '.'`
    WL_VERSION=`echo ${WEBLOGIC_VERSION} | tr -d '.'`
    WL_HOME=`cat "${WLS_LIST}" | grep -w "${WEBLOGIC_VERSION}" | cut -d\: -f 2`

    if [ -z `echo -e "${WL_VERSIONS}" | grep -w "${WL_VERSION}"` ]; then
      failure "Weblogic ${WEBLOGIC_VERSION} not present in configuration file"
    else
      # Check local and remote weblogic location
      if [ ! -e "${WL_HOME}" ]; then
        failure "Weblogic `dirname ${WL_HOME}` not found"
      else
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -l ${WL_HOME}" &>/dev/null

        if [ $? -gt 0 ]; then
          failure "Weblogic `dirname ${WL_HOME}` not found at ${MACHINE}"
        fi
      fi
    fi
  fi
}

###############################
# Set Java HOME and CLASSPATH #
###############################
set_java_version()
{
  if [ -z ${JAVA_VERSION} ]; then
    JAVA_HOME=`cat "${JAVA_LIST}" | grep -i default | cut -d\: -f 2`

    # Check local and remote Java location
    if [ ! -e "${JAVA_HOME}" ]; then
      failure "Java ${JAVA_HOME} not found on `hostname`"
    else
      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -l ${JAVA_HOME}" &>/dev/null

      if [ $? -gt 0 ]; then
        failure "Java ${JAVA_HOME} not found at ${MACHINE}"
      fi
      JAVA_VERSION="${DEFAULT_JAVA_VERSION}"
    fi
  else
    JAVA_HOME=`cat "${JAVA_LIST}" | grep -w "${JAVA_VERSION}" | cut -d\: -f 2`

    if [ -z "${JAVA_HOME}" ]; then
      failure "Java ${JAVA_VERSION} not present in configuration file"
    else
      # Check local and remote Java location
      if [ ! -e "${JAVA_HOME}" ]; then
        failure "Java ${JAVA_HOME} not found"
      else
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -l ${JAVA_HOME}" &>/dev/null

        if [ $? -gt 0 ]; then
          failure "Java ${JAVA_HOME} not found at ${MACHINE}"
        fi
      fi
    fi
  fi

#Mangerico - 12.2.*
if [[ $WEBLOGIC_VERSION == 12.2.1.[2-9] ]]; then
 CLASSPATH="${WL_HOME}/modules/features/wlst.wls.classpath.jar"
 JVM_ARGS="-cp ${CLASSPATH}"
  else
 CLASSPATH="${WL_HOME}/server/lib/weblogic.jar"
 JVM_ARGS="-cp ${CLASSPATH}"
fi
  #versoes 12.1.*
 # CLASSPATH="${WL_HOME}/server/lib/weblogic.jar"
 # JVM_ARGS="-cp ${CLASSPATH}"
  # Ze Manel o que foi adicionado foi a linha em baixo.
  # CLASSPATH="${WL_HOME}/modules/features/wlst.wls.classpath.jar"
  #JVM_ARGS="-cp ${CLASSPATH}"
}

##################################
# Check if domain already exists #
##################################
check_domain_existance()
{
  # Check database
  DBQUERY=`get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 1`

  if [ "${DBQUERY}" == "D" ]; then
    failure "Domain ${DOMAIN} already exists in ${ENV} database"
  fi

  if [ -e "${DOMAIN_HOME}/${DOMAIN}" ]; then
    failure "Domain ${DOMAIN} already exists at location ${DOMAIN_HOME}/${DOMAIN}."
  else
    # Check remote domain existance
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -l ${DOMAIN_HOME}/${DOMAIN}" &>/dev/null

    if [ ! $? -gt 0 ]; then
      failure "Domain ${DOMAIN_HOME}/${DOMAIN} already exists at machine ${MACHINE}"
    fi
  fi
}

###################################
# Check if port is already in use #
###################################
check_port_usage()
{
  PORT_LIST=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} \"\"netstat -l\"\"`

  if [ `echo -e "${PORT_LIST}" | grep -w LISTEN | grep -w ${DOMAIN_PORT} | wc -l` -gt 0 ]; then
    failure "Port ${DOMAIN_PORT} is already in use at machine ${MACHINE}"
  fi
}

##############################
# Call WLST to create domain #
##############################
create_domain()
{
  info "Creating domain ${DOMAIN} template, using WebLogic version ${WEBLOGIC_VERSION} and Java version ${JAVA_VERSION}"
  DOMAIN_HOME_TMP=${STAGE_PATH}

  # Get domain template location
  DOMAIN_TEMPLATE=`find ${WL_HOME} -name ${WEBLOGIC_DOMAIN_TEMPLATE}`

  # Start WLST
  #echo "JAVA VERSION IS :"
  #java -version
  #echo "ENVIROMENT: "
  #env
  #java -cp /opt/weblogic/12.2.1.3/wlserver/modules/features/wlst.wls.classpath.jar weblogic.WLST /home/weblogic/bin/readdomain.py
  #"$JAVA_HOME/bin/java" ${JVM_ARGS} -Dpython.verbose=debug -Dwlst.debug.init=TRUE -Dwlst.offline.log.priority=debug -Dwlst.offline.log=/home/weblogic/debug_domain_add.log -Dpython.cachedir=/home/weblogic/tempWLST weblogic.WLST ${DOMAIN_PYTHON_FILE} ${DOMAIN_TEMPLATE} ${DOMAIN} ${DOMAIN_PORT} ${DOMAIN_PASSWORD} ${MACHINE} ${DOMAIN_HOME_TMP} ${JAVA_HOME} ${WL_HOME}
  "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${DOMAIN_PYTHON_FILE} ${DOMAIN_TEMPLATE} ${DOMAIN} ${DOMAIN_PORT} ${DOMAIN_PASSWORD} ${MACHINE} ${DOMAIN_HOME_TMP} ${JAVA_HOME} ${WL_HOME}

  if [ $? -gt 0 ]; then
    rm -rf ${DOMAIN_HOME}/${DOMAIN}.jar
    failure "Domain template creation failed, exiting..."
  fi

  if [[ ${ENV} = "prd" || ${ENV} = "qua" || ${ENV} = "sandbox" ]]; then
    create_boot_properties
    if [[ ${WEBLOGIC_VERSION} == 12.2.1.[0-9] ]]; then
       cp ${DOMAIN_WRITE_PYTHON_FILE_122C} ${STAGE_PATH}/${DOMAIN}.py
    else
       cp ${DOMAIN_WRITE_PYTHON_FILE} ${STAGE_PATH}/${DOMAIN}.py
    fi
    LOCAL_FILE_LIST="${STAGE_PATH}/${DOMAIN}.py ${STAGE_PATH}/${DOMAIN}.jar ${STAGE_PATH}/bootp_${DOMAIN}.sh"
    REMOTE_FILE_LIST="${DOMAIN_HOME}/${DOMAIN}.py ${DOMAIN_HOME}/${DOMAIN}.jar ${DOMAIN_HOME}/bootp_${DOMAIN}.sh"
  else
    if [[ ${WEBLOGIC_VERSION} == 12.2.1.[0-9] ]]; then
       KRB_MAIN_FILE="${SSO_PATH_DEV}/krb5.${DOMAIN}.conf"
       KRB_LOGIN_FILE="${SSO_PATH_DEV}/krb5login.${DOMAIN}.conf"
       ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_MAIN_FILE} ${KRB_MAIN_FILE}; chmod 440 ${KRB_MAIN_FILE}"
       if [ $? -gt 0 ]; then
          failure "Problems creating the file ${KRB_MAIN_FILE}"
       fi
       ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_LOGIN_FILE} ${KRB_LOGIN_FILE}; chmod 440 ${KRB_LOGIN_FILE}"
       if [ $? -gt 0 ]; then
          failure "Problems creating the file ${KRB_LOGIN_FILE}"
       fi
       cp ${DOMAIN_WRITE_PYTHON_FILE_122C} ${STAGE_PATH}/${DOMAIN}.py
    else
       KRB_MAIN_FILE="${SSO_PATH_DEV}/krb5.${DOMAIN}.conf"
       KRB_LOGIN_FILE="${SSO_PATH_DEV}/krb5login.${DOMAIN}.conf"
       ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_MAIN_FILE} ${KRB_MAIN_FILE}; chmod 440 ${KRB_MAIN_FILE}"
       if [ $? -gt 0 ]; then
          failure "Problems creating the file ${KRB_MAIN_FILE}"
       fi
       ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cp ${DEFAULT_KRB_LOGIN_FILE} ${KRB_LOGIN_FILE}; chmod 440 ${KRB_LOGIN_FILE}"
       if [ $? -gt 0 ]; then
          failure "Problems creating the file ${KRB_LOGIN_FILE}"
       fi
       cp ${DOMAIN_WRITE_PYTHON_FILE} ${STAGE_PATH}/${DOMAIN}.py
    fi
    LOCAL_FILE_LIST="${STAGE_PATH}/${DOMAIN}.py ${STAGE_PATH}/${DOMAIN}.jar"
    REMOTE_FILE_LIST="${DOMAIN_HOME}/${DOMAIN}.py ${DOMAIN_HOME}/${DOMAIN}.jar"
  fi

  info "Copying files to machine ${MACHINE}"
  scp -rp ${LOCAL_FILE_LIST} ${USER}@${MACHINE}:${DOMAIN_HOME}

  if [ $? -gt 0 ]; then
    rm -rf ${LOCAL_FILE_LIST}
    failure "Unable to transfer files to machine ${MACHINE}"
  else
    rm -rf ${LOCAL_FILE_LIST}
  fi

  info "Writing domain ${DOMAIN}, using WebLogic version ${WEBLOGIC_VERSION}, on machine ${MACHINE}"
  # BRUNO AGORA
  #if [[ ${WEBLOGIC_VERSION} ==  12.2.1.[1-9] ]]; then
  if [[ ${WEBLOGIC_VERSION} ==  12.2.1.[0-9] ]]; then
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${DOMAIN_HOME}/${DOMAIN}.py ${DOMAIN} ${DOMAIN_HOME} ${JAVA_HOME} ${DOMAIN_PASSWORD}"
  else
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${DOMAIN_HOME}/${DOMAIN}.py ${DOMAIN} ${DOMAIN_HOME} ${JAVA_HOME}"
  fi


  if [ $? -gt 0 ]; then
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm -rf ${REMOTE_FILE_LIST}"
    failure "Unable to create domain ${DOMAIN} on machine ${MACHINE}"
  else
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "sh ${DOMAIN_HOME}/bootp_${DOMAIN}.sh"
    info "Deleting ${REMOTE_FILE_LIST}"
    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm -rf ${REMOTE_FILE_LIST}"
  fi

  if [ ${ENV} == "prd" ]; then
    # Check if machine belongs to Exalogic realm
    EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "dmesg | grep -w Xen | wc -l" 2>/dev/null`

    if [ "${EXAID}" != "0" ]; then
      info "Machine appears to belong to Exalogic Realm."
      info "Creating logs directory ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer for AdminServer"
      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"

      if [ $? -gt 0 ]; then
        warning "Unable to create directory ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"
      else
        info "Creating symbolic link to ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ln -s ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer ${DOMAIN_HOME}/${DOMAIN}/servers/${DOMAIN}AdminServer/logs"

        if [ $? -gt 0 ]; then
          warning "Unable to create symbolic link to ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"
        fi
      fi

      ENABLE_EXALOGIC_OPTIMIZATIONS="Y"
    fi
  fi

  if [ ${ENV} == "qua" ]; then
      info "Creating logs directory ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer for AdminServer"
      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "mkdir -p ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"

      if [ $? -gt 0 ]; then
        warning "Unable to create directory ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"
      else
        info "Creating symbolic link to ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ln -s ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer ${DOMAIN_HOME}/${DOMAIN}/servers/${DOMAIN}AdminServer/logs"

        if [ $? -gt 0 ]; then
          warning "Unable to create symbolic link to ${EXA_LOGS}/${DOMAIN}/${DOMAIN}AdminServer"
        fi
      fi
    fi
}

################
# Start domain #
################
start_weblogic()
{
  info "Attempting to start domain ${DOMAIN} at ${MACHINE}"
  ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "cd ${DOMAIN_HOME}/${DOMAIN};((nohup ./startWebLogic.sh &>nohup.out) &)" &>/dev/null

  if [ $? -gt 0 ]; then
    failure "Unable to start domain ${DOMAIN}"
  fi

  while [ ${WLRUNNING} == "N" ]
  do
    WLSTATUS=`ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "tail -30 ${DOMAIN_HOME}/${DOMAIN}/nohup.out"`

    if [ `echo -e "${WLSTATUS}" | grep "started in RUNNING mode" | wc -l` -gt 0 ]; then
      WLRUNNING="S"
      info "Domain ${DOMAIN} appears to be running."
    else
      info "Sleeping for 10 seconds"
      sleep 10
    fi
  done
}

####################################
# Reorder authentication providers #
####################################
reorder_providers()
{
  info "Reordering authentication providers"
  "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${REORDER_PROVIDERS_PYTHON_FILE} ${DOMAIN} ${DOMAIN_PORT} ${DOMAIN_PASSWORD} ${MACHINE}

  if [ $? -gt 0 ]; then
    warning "Unable to reorder authentication providers"
  fi
}

################################################################
# Create the boot.properties file for PRD and QUA environments #
################################################################
create_boot_properties()
{
  info "Creating boot.properties file for ${ENV} environment"

  echo "mkdir -p ${DOMAIN_HOME}/${DOMAIN}/servers/${DOMAIN}AdminServer/security" > ${STAGE_PATH}/bootp_${DOMAIN}.sh
  echo "chmod -R 740 ${DOMAIN_HOME}/${DOMAIN}/servers/" >> ${STAGE_PATH}/bootp_${DOMAIN}.sh
  echo "echo -e \"username=${USER}\npassword=${DOMAIN_PASSWORD}\" > ${DOMAIN_HOME}/${DOMAIN}/servers/${DOMAIN}AdminServer/security/boot.properties" >> ${STAGE_PATH}/bootp_${DOMAIN}.sh
  echo "chmod 600 ${DOMAIN_HOME}/${DOMAIN}/servers/${DOMAIN}AdminServer/security/boot.properties" >> ${STAGE_PATH}/bootp_${DOMAIN}.sh
}

################################
# Enable Exalogic enhancements #
################################
exalogic_enhancements()
{
  if [ "${ENABLE_EXALOGIC_OPTIMIZATIONS}" == "Y" ]; then
    info "Enabling Exalogic-specific enhancements"
    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${EXALOGIC_PYTHON_FILE} ${MACHINE} ${DOMAIN_PORT} ${DOMAIN_PASSWORD}

    if [ $? -gt 0 ]; then
      warning "Unable to activate Exalogic-specific enhancements"
    fi
  fi
}

######################################################
# Extend domain with Web Services Extension Template #
######################################################
add_webservices_extension()
{
  info "Attempting to add JAX-WS extensions to domain ${DOMAIN}"
  #mangerico 20170329
  # Find template location
  JAX_TEMPLATE_FILE=`find ${WL_HOME} -name wls_webservice_jaxws.jar`
  if [ $WEBLOGIC_VERSION == "12.1.3.0" ]; then
     JAX_TEMPLATE_FILE=`find "/opt/weblogic/12.1.3.0/" -name oracle.wls-webservice-jaxws-template_12.1.3.jar`
     if [ $? -gt 0 ]; then
        warning "Unable to locate template oracle.wls-webservice-jaxws-template_12.1.3.jar"
     fi
  elif [[ $WEBLOGIC_VERSION == 12.2.1.[0-9] ]]; then
     JAX_TEMPLATE_FILE=`find "/opt/weblogic/$WEBLOGIC_VERSION/" -name oracle.wls-webservice-jaxws-template.jar`
     if [ $? -gt 0 ]; then
        warning "Unable to locate template oracle.wls-webservice-template.jar"
     fi
  fi

  if [ $? -gt 0 ]; then
    warning "Unable to locate template wls_webservice_jaxws.jar"
  else
    scp ${DOMAIN_EXTENSION_PYTHON_FILE} ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}

    if [ $? -gt 0 ]; then
      warning "Unable to copy domain extension script to ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}"
    else
      DOMAIN_EXTENSION_SCRIPT_NAME=`basename ${DOMAIN_EXTENSION_PYTHON_FILE}`

      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${DOMAIN_HOME}/${DOMAIN}/${DOMAIN_EXTENSION_SCRIPT_NAME} ${DOMAIN_HOME}/${DOMAIN} ${JAX_TEMPLATE_FILE}"

      if [ $? -gt 0 ]; then
        warning "Unable to add JAX-WS Extensions to domain ${DOMAIN}"
      else
        info "JAX-WS Extensions added to domain ${DOMAIN}"
      fi
    fi

    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm ${DOMAIN_HOME}/${DOMAIN}/${DOMAIN_EXTENSION_SCRIPT_NAME}"
  fi

  info "Attempting to add JAX-RPC extensions to domain ${DOMAIN}"

  # Find template location
  JAX_TEMPLATE_FILE=`find ${WL_HOME} -name wls_webservice.jar`
  if [ $WEBLOGIC_VERSION == "12.1.3.0" ]; then
     JAX_TEMPLATE_FILE=`find "/opt/weblogic/12.1.3.0/" -name oracle.wls-webservice-template_12.1.3.jar`
     if [ $? -gt 0 ]; then
        warning "Unable to locate template oracle.wls-webservice-template_12.1.3.jar"
     fi
  #mangerico - alterado para todas as versoes 12.2.1*
  elif [[ $WEBLOGIC_VERSION == 12.2.1.[0-9] ]]; then
     JAX_TEMPLATE_FILE=`find "/opt/weblogic/$WEBLOGIC_VERSION/" -name oracle.wls-webservice-template.jar`
     if [ $? -gt 0 ]; then
        warning "Unable to locate template oracle.wls-webservice-template.jar"
     fi
  fi

  if [ $? -gt 0 ]; then
    warning "Unable to locate template wls_webservice.jar"
  else
    scp ${DOMAIN_EXTENSION_PYTHON_FILE} ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}

    if [ $? -gt 0 ]; then
      warning "Unable to copy domain extension script to ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}"
    else
      DOMAIN_EXTENSION_SCRIPT_NAME=`basename ${DOMAIN_EXTENSION_PYTHON_FILE}`

      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${DOMAIN_HOME}/${DOMAIN}/${DOMAIN_EXTENSION_SCRIPT_NAME} ${DOMAIN_HOME}/${DOMAIN} ${JAX_TEMPLATE_FILE}"

      if [ $? -gt 0 ]; then
        warning "Unable to add JAX-RPC Extensions to domain ${DOMAIN}"
      else
        info "JAX-RPC Extensions added to domain ${DOMAIN}"
      fi
    fi

    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm ${DOMAIN_HOME}/${DOMAIN}/${DOMAIN_EXTENSION_SCRIPT_NAME}"
  fi

  info "Unassigning JAX resources from the Administration Server"
  scp ${ADMIN_JAX_UNASSIGN_PYTHON_FILE} ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}

  if [ $? -gt 0 ]; then
    warning "Unable to copy JAX AdminServer unassign script to ${USER}@${MACHINE}:${DOMAIN_HOME}/${DOMAIN}"
  else
    JAX_UNASSIGN_SCRIPT_NAME=`basename ${ADMIN_JAX_UNASSIGN_PYTHON_FILE}`

    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "$JAVA_HOME/bin/java ${JVM_ARGS} weblogic.WLST ${DOMAIN_HOME}/${DOMAIN}/${JAX_UNASSIGN_SCRIPT_NAME} ${DOMAIN_HOME}/${DOMAIN}"

    if [ $? -gt 0 ]; then
      warning "Unable to unassign JAX resources from the Administration Server"
    else
      info "JAX resources successfully unassigned from Administration Server"
    fi

    ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "rm ${DOMAIN_HOME}/${DOMAIN}/${JAX_UNASSIGN_SCRIPT_NAME}"
  fi
}

################################
# Add user CloudControlMonitor #
################################
user_add()
{
  DESC="CloudControl"

  OUT=`"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${USER_ADD_PYTHON_FILE} ${MACHINE} ${DOMAIN_PORT} ${DOMAIN_PASSWORD} ${DESC} ${USERNAME} ${USER_PASSWORD}`

  if [ "`echo -e "${OUT}" | grep "User already exists." | wc -l`" -gt 0 ]; then
    info "User already exists in domain ${DOMAIN}"
  else
    if [ "`echo -e "${OUT}" | grep "User ${USERNAME} created successfully." | wc -l`" -gt 0 ]; then
      info "User ${USERNAME} created successfully"
    else
      warning "Unable to create user ${USERNAME}"
    fi
  fi
}

###################################
# Update the environment database #
###################################
update_environment()
{
  info "Updating environment database"
  info "`set-env-info.pl ${ENV} -i d,${DOMAIN},${WEBLOGIC_VERSION},${JAVA_VERSION},${MACHINE},${DOMAIN_PORT},${USER},${DOMAIN_PASSWORD},${DOMAIN_HOME}/${DOMAIN}`"

  if [ -z "`get-env-info.pl ${ENV} ${MACHINE}`" ]; then
    info "`set-env-info.pl ${ENV} -i m,${MACHINE}`"
  fi

  if [ "${ENV}" == "dev" ]; then
    info "`set-env-info.pl ${ENV} -i c,${DOMAIN}Cluster01,${DOMAIN}`"
    info "`set-env-info.pl ${ENV} -i s,${DOMAIN}Server01,${DOMAIN},${DOMAIN}Cluster01,${MACHINE}`"
    info "`set-env-info.pl ${ENV} -i s,${DOMAIN}Server02,${DOMAIN},${DOMAIN}Cluster01,${MACHINE}`"
   
   #mangerico
   info "`set-env-info.pl ${ENV} -u s,${DOMAIN}Server01,,$(($DOMAIN_PORT + 3))`" 
   info "`set-env-info.pl ${ENV} -u s,${DOMAIN}Server02,,$(($DOMAIN_PORT + 6))`"

  fi

  info "Domain configuration complete. Running on http://${MACHINE}:${DOMAIN_PORT}/console and located at ${DOMAIN_HOME}/${DOMAIN} on machine ${MACHINE}"
  info "Domain must be restarted to assume some configuration changes"
}

##############################################
# Use JDBC 12.1.0.2 in WLS 12.1.1 and 12.1.2 #
##############################################
#update_jdbc12c()
#{
#   info "Updating setDomainEnv.sh for domain ${DOMAIN}"
#   info "Make backup setDomainEnv.sh file from ${DOMAIN}"
#   echo "ssh weblogic@${MACHINE} /bin/cp ${DOMAIN_HOME}/bin/setDomainEnv.sh ${DOMAIN_HOME}/bin/setDomainEnv.sh.${DATE_MOVE_SETDOMAIN}"
#}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
check_machine_available
build_wls_versions_list
build_java_versions_list
start_arg_checks
check_jython_files
set_wls_version
set_java_version
check_domain_existance
check_port_usage
create_domain
start_weblogic
#mangerico
reorder_providers
exalogic_enhancements
add_webservices_extension
#user_add
update_environment
#update_jdbc12c

info "Operation complete"
exit 0
