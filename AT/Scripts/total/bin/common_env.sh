#!/bin/bash
#set -x

#########
# Paths #
#########
DOMAIN_HOME="/weblogic"
WLS_BASE="${DOMAIN_HOME}"
STAGE_PATH="/opt/stage"
SSO_PATH_PRD="/opt/sso"
#SSO_PATH_QUA="${HOME}/etc/spnego"
SSO_PATH_QUA="/opt/sso"
#SSO_PATH_DEV="/opt/sso_dev"
SSO_PATH_DEV="/opt/sso"
SSO_PATH_SANDBOX="${HOME}/etc/spnego"
EXA_LOGS="/logs/weblogic"
NODE_MANAGER_PATH="/opt/nodemgr"
WEBLOGIC_DOMAIN_TEMPLATE="wls.jar"
#WEBLOGIC_DOMAIN_TEMPLATE="wls_webservice_jaxws.jar"
WLS_LIST=${HOME}/etc/domain_add/weblogic_versions.lst
JAVA_LIST=${HOME}/etc/domain_add/java_versions.lst
OPERATIONS_LOGFILE="${HOME}/var/log/operations.`hostname`.`date +%Y%m%d`.log"
CENTRALIZED_LOGFILE="${HOME}/var/log/operations.`hostname`.log"
WLST_LOGFILE="${HOME}/var/log/wlstoperations.`hostname`.`date +%Y%m%d`.log"
#TAXONOMY_SERVER="http://swnagcdev.ritta.local:7001/infoTaxonomia.asmx"
TAXONOMY_SERVER="http://swnagcdev.ritta.local:7001"

#################
# Script colors #
#################
WHITE="\E[0;37m\033[1m"
GREEN="\E[0;32m\033[1m"
BLUE="\E[0;34m\033[1m"
RED="\E[0;31m\033[1m"
YELLOW="\E[1;33m\033[1m"
BLINK="\E[5m"
RESET="\033[0m"

#########################
### Logging functions ###
#########################
log()
{
  if [ "XZ${SSH_CLIENT}" == "XZ" ]; then
    CALLER="Empty ssh client information"
  else
    CALLER=${SSH_CLIENT}
  fi

  if [ ! -z $SSH_TTY ]; then
    echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $*"
  fi

  echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $* [$0] [${CALLER}]" >> $OPERATIONS_LOGFILE
  echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $* [$0] [${CALLER}]" >> $CENTRALIZED_LOGFILE
}

wlstlog()
{
  if [ "XZ${SSH_CLIENT}" == "XZ" ]; then
    CALLER="Empty ssh client information"
  else
    CALLER=${SSH_CLIENT}
  fi

  echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $* [${CALLER}]" >> ${WLST_LOGFILE}
}

wlstinfo()
{
  wlstlog "[$*]"
}

info()
{
  log "[${GREEN}I${RESET}] [${GREEN}$*${RESET}]"
}

binfo()
{
  log "[${GREEN}${BLINK}I${RESET}] [${GREEN}${BLINK}$*${RESET}]"
}

inputuser()
{
  log "[${BLUE}R${RESET}] [${BLUE}$*${RESET}]"
}

warning()
{
  log "[${YELLOW}W${RESET}] [${YELLOW}$*${RESET}]"
}

bwarning()
{
  log "[${YELLOW}${BLINK}W${RESET}] [${YELLOW}${BLINK}$*${RESET}]"
}


failure()
{
  log "[${RED}F${RESET}] [${RED}$*${RESET}]"
  exit 1
}

error()
{
  log "[${RED}E${RESET}] [${RED}$*${RESET}]"
}

success()
{
  log \[S\] \[$*\]
  if [ ! -z $LOCKFILE ]; then
  if [ -f $LOCKFILE ]; then
    if rm $LOCKFILE
    then
      echo Removed lockfile $LOCKFILE
    else
      echo Failed to remove lockfile $LOCKFILE
    fi
  fi
  fi
}

############################################
### Domain related information functions ###
############################################
check_env()
{
  if [ -z "$1" ]; then
    failure Must specify environment \(PRD/QUA/DEV/SANDBOX\)
  else
    ENV=`echo $1 | tr [A-Z] [a-z]`

    if [ "${ENV}" != "prd" ]; then
      if [ "${ENV}" != "qua" ]; then
        if [ "${ENV}" != "dev" ]; then
          if [ "${ENV}" != "sandbox" ]; then
            failure Unrecognized environment ${ENV}
          fi
        fi
      fi
    fi
  fi
}

#######################################
### Check WebLogic version and home ###
#######################################
check_wl_version()
{
  check_env $1
  DOMAIN=$2

  # Get WebLogic version of domain from database
  WEBLOGIC_VERSION=`get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 3`

  # Check if WebLogic binaries are present
  if [ ! -z "${WEBLOGIC_VERSION}" ]; then
    WL_HOME=`cat ${WLS_LIST} | grep -w ${WEBLOGIC_VERSION} | cut -d\: -f 2`

    if [ ! -e "${WL_HOME}" ]; then
      failure "Weblogic ${WEBLOGIC_VERSION} not found on `hostname`"
    fi
  else
    failure "Domain ${DOMAIN} not found"
  fi
}

###################################
### Check Java version and home ###
###################################
check_java_version()
{
  check_env $1
  DOMAIN=$2

  # Get Java version of domain from database
  JAVA_VERSION=`get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 4`

  # Check if Java binaries are present
  if [ ! -z "${JAVA_VERSION}" ]; then
    JAVA_HOME=`cat ${JAVA_LIST} | grep -w "${JAVA_VERSION}" | cut -d\: -f 2`

    if [ ! -e "${JAVA_HOME}" ]; then
      failure "Java ${JAVA_VERSION} not found on `hostname`"
    fi
  else
    failure "Domain ${DOMAIN} not found"
  fi

  CLASSPATH="${WL_HOME}/server/lib/weblogic.jar"
  JVM_ARGS="-cp ${CLASSPATH}"
}

list_all_domains()
{
  check_env $1

  if [ -z $1 ]; then
    get-env-info.pl prd | cut -d\: -f 2 | sort
  else
    get-env-info.pl ${ENV} | cut -d\: -f 2 | sort
  fi
}

# List all servers from specified environment
list_all_servers()
{
  check_env $1
  DOMAIN=$2

  get-env-info.pl ${ENV} ${DOMAIN} -servers
}

# List all clusters from specified environment
list_all_clusters()
{
  check_env $1
  DOMAIN=$2

  get-env-info.pl ${ENV} ${DOMAIN} -clusters
}

# List all servers belonging to a cluster
list_all_cluster_servers()
{
  check_env $1
  DOMAIN=$2
  CLUSTER=$3

  # Check if cluster is in fact a server
  if server_exists ${ENV} ${CLUSTER}
  then
    echo ${CLUSTER}
  else
    get-env-info.pl ${ENV} -members ${DOMAIN} | grep -w ${CLUSTER} | cut -d\: -f 1
  fi
}

# Lists all servers with respective clusters and machines
list_all_servers_with_clusters_and_machines()
{
  check_env $1
  DOMAIN=$2

  get-env-info.pl ${ENV} ${DOMAIN} -members
}

# List all virtualhosts
list_all_virtualhosts()
{
  check_env $1

  get-env-info.pl ${ENV} -virtualhosts
}

# List all applications
list_all_applications()
{
  check_env $1
  VIRTUAL_HOST=$2

  get-env-info.pl ${ENV} ${VIRTUAL_HOST} | cut -d\: -f 3
}

# List all targets associated with an application
list_all_application_targets()
{
  check_env $1
  APPLICATION=$2

  if [ -z ${APPLICATION} ]; then
    return 1
  else
    get-env-info.pl ${ENV} -apptargets | grep "^${APPLICATION}:" | cut -d\: -f 2
    return 3
  fi
}

# Lists all the applications associated with a target
list_all_target_applications()
{
  check_env $1
  TARGET=$2

  if [ -z $TARGET ]; then
    return 1
  fi

  get-env-info.pl ${ENV} -apptargets | grep ":${TARGET}" | cut -d\: -f 1

  return 0
}

list_all_application_virtualhosts()
{
  check_env $1
  APPLICATION=$2

  if [ -z ${APPLICATION} ]; then
    return 2
  fi

  get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION}:" | cut -d\: -f 2

  return 0
}

# Check if virtual host exists
virtualhost_exists()
{
  check_env $1
  VHOST=$2

  if [ -z $2 ]; then
    return 1
  else
    if [ "X`get-env-info.pl ${ENV} ${VHOST} | cut -d\: -f 1`" == "XV" ]; then
      return 0
    fi
  fi

  return 1
}

# Check if domain exists
domain_exists()
{
  check_env $1
  DOMAIN=$2

  if [ -z "${DOMAIN}" ]; then
    return 1
  else
    if [ "X`get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 1`" == "XD" ]; then
      return 0
    fi
  fi

  return 1
}

# Check if server exists
server_exists()
{
  check_env $1
  SERVER=$2

  if [ -z ${SERVER} ]; then
    return 1
  else
    if [ "X`get-env-info.pl ${ENV} ${SERVER} | cut -d\: -f 1`" == "XS" ]; then
      return 0
    fi
  fi

  return 1
}

# Check if machine exists
machine_exists()
{
  check_env $1
  MACHINE=$2

  if [ -z ${MACHINE} ]; then
    return 1
  else
    if [ "X`get-env-info.pl ${ENV} ${MACHINE} | cut -d\: -f 1`" == "XM" ]; then
      return 0
    fi
  fi

  return 1
}

# Check if cluster exists
cluster_exists()
{
  check_env $1
  CLUSTER=$2

  if [ -z ${CLUSTER} ]; then
    return 1
  else
    if [ "X`get-env-info.pl ${ENV} ${CLUSTER} | cut -d\: -f 1 | uniq`" == "XC" ]; then
      return 0
    fi
  fi

  return 1
}

application_exists()
{
  check_env $1
  APPLICATION=$2

  if [ -z ${APPLICATION} ]; then
    return 1
  else
    if [ ! -z "`get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION}:"`" ]; then
      return 0
    fi
  fi

  return 1
}

frontend_exists()
{
  check_env $1
  FRONTEND=$2

  if [ -z ${FRONTEND} ]; then
    return 1
  else
    if [ "X`get-env-info.pl ${ENV} ${FRONTEND} | cut -d\: -f 1`" == "XF" ]; then
      return 0
    fi
  fi

  return 1
}

# Get the domain location in the filesystem
get_domain_path()
{
  check_env $1
  DOMAIN=$2

  if [ -z ${DOMAIN} ]; then
    failure "Must input domain name"
  else
    get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 9
  fi
}

# Get the domain administration console URL
get_domain_url()
{
  check_env $1
  DOMAIN=$2

  if [ -z ${DOMAIN} ]; then
    failure "Must input domain name"
  else
    echo "http://`get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 5-6`/console"
  fi
}

get_domain_config_file_path()
{
  check_env $1
  DOMAIN=$2

  if [ -z ${DOMAIN} ]; then
    failure "Must input domain name"
  else
    DOMAIN_INFO=`get-env-info.pl ${ENV} ${DOMAIN}`

    if [ `echo ${DOMAIN_INFO} | cut -d\: -f 4 | cut -d\. -f 1` -lt 9 ];then
      echo `echo ${DOMAIN_INFO} | cut -d\: -f 10`
    else
      echo `echo ${DOMAIN_INFO} | cut -d\: -f 10`"/config"
    fi
  fi
}

get_domain_version()
{
  check_env $1
  DOMAIN=$2

  if [ -z ${DOMAIN} ]; then
    failure "Must input domain name"
  else
    get-env-info.pl ${ENV} ${DOMAIN} | cut -d\: -f 3
  fi
}

# Gets a target machine address based on it's name
get_machine_name()
{
  check_env $1
  SERVER=$2

  if [ -z ${SERVER} ]; then
    failure "Must input server name"
  else
    get-env-info.pl ${ENV} ${SERVER} | cut -d\: -f 5
  fi
}

# Get application frontend list
get_application_frontend_list()
{
  check_env $1
  APPLICATION=$2

  if [ -z ${APPLICATION} ]; then
    failure "Must input application name"
  else
    FLIST=`get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION}:" | cut -d\: -f 4 | tr [,] [\ ]`

    if [ "${FLIST}" == "DEFAULT" ]; then
      get-env-info.pl ${ENV} -frontends Details | grep -w "Y" | cut -d\: -f 1
    else
      echo "${FLIST}"
    fi
  fi
}

# Get application static content location
get_static_path()
{
  check_env $1
  APPLICATION=$2

  if [ -z ${APPLICATION} ]; then
    failure "Must input application name"
  else
    # Change because ATAuth and PFView usage - Bruno 2016Jun16
    #STATIC_PATH=`get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION}:" | cut -d\: -f 8`
    STATIC_PATH=`get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION}:" | cut -d\: -f 11`

    if [ ! -z ${STATIC_PATH} ]; then
      echo ${STATIC_PATH} | tr -d [\\n]
    else
      return 1
    fi
  fi
}

get_target_address()
{
  WLFILE=$1
  SERVER=$2

  if [ -z ${WLFILE} ]; then
    failure "Must input weblogic.xml file location"
  else
    if [ -z ${SERVER} ]; then
      failure "Must input server name"
    else
      get-wls-object-list.pl ${WLFILE} -listenport server | grep -w ${SERVER} | cut -d\: -f 2
    fi
  fi
}

# Download weblogic.xml config file to specified destination
get_weblogic_file()
{
  check_env $1
  DOMAIN=$2
  DESTINATION=$3
  DOMAIN_INFO="`get-env-info.pl ${ENV} ${DOMAIN}`"

  if [ -z ${DOMAIN} ]; then
    failure "Must input domain name"
  fi

  if [ -z ${DESTINATION} ]; then
    failure "Must input destination file name"
  fi

  if [ "`echo ${DOMAIN_INFO} | cut -d\: -f 1`" == "D" ]; then
    ADMIN_MACHINE="`echo ${DOMAIN_INFO} | cut -d\: -f 5`"
    DOMAIN_PATH="`echo ${DOMAIN_INFO} | cut -d\: -f 9`"
  else
    return 1
  fi

  scp ${USER}@${ADMIN_MACHINE}:${DOMAIN_PATH}/config/config.xml ${DESTINATION}/${DOMAIN}.${ENV}.xml &>/dev/null

  if [ $? -eq 0 ]; then
    echo "${DESTINATION}/${DOMAIN}.${ENV}.xml"
  else
    return 1
  fi
}

# Get the machine where the application managed server is running
get_application_machine_name()
{
  check_env $1
  APPLICATION=$2
  APPTARGET=`get-env-info.pl ${ENV} ${APPLICATION} | cut -d\: -f 4`
  TARGET_DOMAIN=`target_domain ${ENV} ${APPTARGET}`

  for WLSERVER in `list_all_cluster_servers ${ENV} ${TARGET_DOMAIN} ${APPTARGET}`
  do
    MACHINE_LIST="`get_machine_name ${ENV} ${WLSERVER}` ${MACHINE_LIST}"
  done

  echo -e "${MACHINE_LIST}" | sed 's/.$//' | sed 's/ /\n/g' | sort | uniq
}

# Get the domain name where the application is deployed
get_application_domain_name()
{
  check_env $1
  APPLICATION=$2

  if [ -z ${APPLICATION} ]; then
    failure "Must specify application name"
  fi

  APPTARGET=`get-env-info.pl ${ENV} ${APPLICATION} | cut -d\: -f 4`

  target_domain ${ENV} ${APPTARGET}
}

# Returns the list of default frontends for the specified environment
get_default_frontends()
{
  check_env $1

  get-env-info.pl ${ENV} -frontends Details | grep -w "Y" | cut -d\: -f 1 | tr '\n' ',' | sed 's/,$//g' | sed 's/,/, /g'
}

# Returns the domain where the target belongs
target_domain()
{
  check_env $1
  TARGET=$2

  if [ -z "${TARGET}" ]; then
    failure "Must input target name"
  fi

  DOMAIN=`get-env-info.pl ${ENV} ${TARGET} | cut -d\: -f 3`

  if [ `echo "${DOMAIN}" | wc -l` -lt 1  ]; then
    return 1
  else
    echo "${DOMAIN}" | cut -d\: -f 1
    return 0
  fi
}

# Uncompress files
decompress_file()
{
  file=$1
  dest=$2

  if [ ! -f ${file} ]; then
    return 1
  fi

  if [ ! -d ${dest} ]; then
    return 2
  fi

  fileextension=`echo ${file} | awk -F . {'print $NF'}`

  info "Decompressing ${file} to ${dest}"

  case ${fileextension} in
    zip)
      unzip -t $file
      if [ $? -ne 0 ]; then
         failure "Some kind of problem in the $file"
      fi
      unzip -u $file -d $dest
      ;;
    tgz)
      cd $dest && tar xzf $file
      ;;
    gz)
      tar zxvf $file -C $dest
      ;;
    bz2)
      cd $dest && tar xjf $file
      ;;
  esac

  return $?
}

element_exists()
{
  ELEMENT=$1

  if [ -z ${ELEMENT} ]; then
    return 1
  fi

  COUNT=0

  for elem in $*; do
    if [ $COUNT -gt 0 ]; then
      if [ ${elem} == ${ELEMENT} ]; then
        return 0
      fi
    fi
    COUNT=`expr ${COUNT} + 1`
  done

  return 1
}

# Parse properties files
process_properties()
{
  FILE=$1
  DEST=$2

  if [ -f ${FILE} ]; then
    if [ -f ${LOCKFILE} ]; then
      if [ "${VERBOSE_ENABLED}" == "Y" ]; then
        echo "create_properties_endpoints.pl ${FILE} ${DEST}"
      fi

      OUTPUT=`create_properties_endpoints.pl ${FILE} ${DEST}`

      if [ $? -gt 0 ]; then
        error "Unable to process properties file `basename ${FILE}` (variable loading failed in $0 ?)"
      else
        if [ ! -z "`echo ${OUTPUT} | grep \"Password obtained\"`" ]; then
          warning "${OUTPUT}"
        fi

        info "Wrote affected properties file `basename ${FILE}` to ${DEST}/`basename ${FILE}`"
        return 0
      fi
    fi
  fi

  return 1
}

process_xml_properties()
{
  FILE=$1
  DEST=$2

  if [ -f ${FILE} ]; then
    if [ -f ${LOCKFILE} ]; then
      if [ "${VERBOSE_ENABLED}" == "Y" ]; then
        echo "create_properties_endpoints.pl ${FILE} ${DEST}"
      fi

      OUTPUT=`create_properties_endpoints.pl ${FILE} ${DEST}`

      if [ $? -gt 0 ]; then
        error "Unable to process properties file `basename ${FILE}` (variable loading failed in $0 ?)"
      else
        info "Wrote affected properties file `basename ${FILE}` to ${DEST}/`basename ${FILE}`"
        return 0
      fi
    fi
  fi

  return 1
}

# Update the versions list
update_retiree_list()
{
  check_env $1
  APPLICATION=$2

  if [ -z ${APPLICATION} ]; then
    failure "Must specify application name"
  fi

  # JAVA_HOME is defined with "check_java_version" and WL_HOME is defined with "check_wl_version"
  if [ `echo ${DOMAIN_VERSION} | cut -d\. -f 1` -gt 8 ]; then
    VERSION_LIST="`${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -listapps | grep -w ${APPLICATION}`"
    ACTIVE_VERSION=`echo -e "${VERSION_LIST}" | grep -i active | awk -F = '{print(\$2)}' | awk -F ] '{print(\$1)}'`
    RETIRE_VERSION=`echo -e "${VERSION_LIST}" | grep -vi active | awk -F = '{print(\$2)}' | awk -F ] '{print(\$1)}' | tail -1`

    if [ -z "${ACTIVE_VERSION}" ]; then
      if [ -z "${RETIRE_VERSION}" ]; then
        info "No versions found of application ${APPLICATION}"
      else
        info "Found inactive version ${RETIRE_VERSION} of application ${APPLICATION}"
      fi
    else
      info "Found active version ${ACTIVE_VERSION} of application ${APPLICATION}"

      if [ -z "${RETIRE_VERSION}" ]; then
        info "No inactive version found of application ${APPLICATION}"
      else
        info "Found inactive version ${RETIRE_VERSION} of application ${APPLICATION}"
      fi
    fi
  else
    info "Versioning not supported on WebLogic 8 deployments"
    VERSION_LIST="`${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -listapps | grep -w ${APPLICATION}`"
  fi
}

application_count_retirees()
{
  if [ -z "${VERSION_LIST}" ]; then
    echo 0
  else
    echo -e "${VERSION_LIST}" | wc -l
  fi 
}

# Stop running edit sessions
unlock_edit_session()
{
  check_env $1
  APPLICATION=$2
  PYTHON_UNLOCK_FILE="${HOME}/etc/py/unlock_domain.py"

  if [ -z ${APPLICATION} ]; then
    failure "Must specify application name"
  fi

  if [ ! -f ${PYTHON_UNLOCK_FILE} ]; then
    failure "Jython file ${PYTHON_UNLOCK_FILE} not found"
  fi

  # JAVA_HOME is defined with "check_java_version" and WL_HOME is defined with "check_wl_version"
  "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${PYTHON_UNLOCK_FILE} ${ADMIN_HOST} ${ADMIN_PORT} ${ADMIN_PASSWORD} &>/dev/null

  return 0
}

# Check MANIFEST.MF
check_manifest()
{
  FILE=$1
  EXTRACT_DIR=$2

  # Bruno - 20151019 - MANIFEST.MF Issue with SCRFA (Two MANIFEST.MF Files in same war file)
  #MANIFEST_LOCATION=`unzip -l ${FILE} | grep -w MANIFEST.MF | awk '{print($4)}'`
  #unzip -l ${FILE} | grep -w "META-INF/MANIFEST.MF" | awk '{print($4)}' | awk '{if ($1 ~ /^META-INF/) print}'
  MANIFEST_LOCATION=`unzip -l ${FILE} | grep -w "META-INF/MANIFEST.MF" | awk '{print($4)}' | awk '{if ($1 ~ /^META-INF/) print}'`
  ##

  if [ ! -z "${MANIFEST_LOCATION}" ]; then
    unzip ${FILE} ${MANIFEST_LOCATION} -d ${EXTRACT_DIR} &> /dev/null
  else
    warning "No MANIFEST.MF file found in archive ${FILE}"
  fi

  WEBLOGIC_APP_VERSION=`grep -wi weblogic-application-version ${EXTRACT_DIR}/${MANIFEST_LOCATION}`
  WEBLOGIC_APP_VERSION=`echo ${WEBLOGIC_APP_VERSION} | awk -F: '{print $2}'`
  WEBLOGIC_APP_VERSION=`echo ${WEBLOGIC_APP_VERSION} | sed 's/\r//'`

  if [ -z "${WEBLOGIC_APP_VERSION}" ]; then
    info "Using timestamp as version identifier"
    NEW_APP_VERSION="`date +%Y%m%d%H%M%S`.0"
  else
    info "Using version identifier specified in MANIFEST.MF"
    echo ${WEBLOGIC_APP_VERSION} | cut -d\: -f 2 | tr -d [\ ] > "${EXTRACT_DIR}/MANIFEST_VERSION"
    dos2unix "${EXTRACT_DIR}/MANIFEST_VERSION" &> /dev/null
    NEW_APP_VERSION="`cat \"${EXTRACT_DIR}/MANIFEST_VERSION\"`"
  fi
}

# Check WLCookieName
check_wlcookiename()
{
  FILE=$1
  EXTRACT_DIR=$2

  # Check if FILE is a war or a ear
  FILEEXTENSION=`echo ${FILE} | awk -F . {'print $NF'}`

  case ${FILEEXTENSION} in
    ear)
      XML_LOCATION=`unzip -l ${FILE} | grep -w weblogic-application.xml | awk '{print($4)}'`
      ;;
    war)
      XML_LOCATION=`unzip -l ${FILE} | grep -w weblogic.xml | awk '{print($4)}'`
      ;;
  esac

  if [ ! -z "${XML_LOCATION}" ]; then
    unzip ${FILE} ${XML_LOCATION} -d ${EXTRACT_DIR} &> /dev/null
  else
    case ${FILEEXTENSION} in
      ear)
        warning "No weblogic-application.xml file found in archive ${FILE}"
        ;;
      war)
        warning "No weblogic.xml file found in archive ${FILE}"
        ;;
    esac
  fi

  COOKIE_NAME=`grep ${APPLICATION_NAME}_JSessionID ${EXTRACT_DIR}/${XML_LOCATION}`
  COOKIE_ENTRY=`grep cookie-name ${EXTRACT_DIR}/${XML_LOCATION} | dos2unix | sed 's/<cookie-name>//g' | sed 's/<\/cookie-name>//g' | tr -d '\t \n'`

  if [ ! -z "${COOKIE_NAME}" ];  then
    info "Found cookie name ${APPLICATION_NAME}_JSessionID"
  else
    warning "Cookie name ${APPLICATION_NAME}_JSessionID not defined (${COOKIE_ENTRY})"
  fi
}

# Check Qua Version
check_qua_version()
{
  LIST_APP_QUA_VERSION_PYTHON_FILE="${HOME}/etc/py/list_qua_app_version.py"

  ADMIN_HOST_QUA=$1
  ADMIN_PORT_QUA=$2
  ADMIN_PASSWORD_QUA=$3
  APP_NAME_QUA=$4 
  APP_VERSION_TO_DEPLOY_QUA=$5

  "${JAVA_HOME}/bin/java" ${JVM_ARGS} weblogic.WLST ${LIST_APP_QUA_VERSION_PYTHON_FILE} ${ADMIN_HOST_QUA} ${ADMIN_PORT_QUA} ${ADMIN_PASSWORD_QUA} ${APP_NAME_QUA} ${APP_VERSION_TO_DEPLOY_QUA}
  if [[ $? -eq 1 ]]; then
     warning "Production is bigger than Quality Enviromment... You want to continue[Y/N]"

     user_response()
     {
        read RESPONSE_USER
        RESPONSE_USER=`echo ${RESPONSE_USER} | tr [:lower:] [:upper:]`

        case $RESPONSE_USER in
        Y)
           continue
        ;;
        N)
           failure "Operation aborted by user."
        ;;
        *)
           error "[Y/N]"
           return 1
        esac
     }
     
     user_response
     while [ $? -gt 0 ]; do
        user_response
     done

  fi
}

# Deploy war/ear files
deploy_file()
{
  APP_NAME=$1
  TARGET=$2
  FILE=$3
  DEPLOYMENTPLANFILE=$4

  if [ -z ${APP_NAME} ]; then
    return 1
  fi

  if [ -z ${TARGET} ]; then
    return 2
  fi

  if [ ! -f ${FILE} ]; then
    return 3
  fi

  # Update application version list
  update_retiree_list ${ENV} ${APP_NAME}

  # With pipefail enabled, the pipeline's return status is the value of the last (rightmost) command to exit with a non-zero status.
  # If all commands exit successfully, the exit status is zero.
  set -o pipefail

  # Process WebLogic 8 versions
  if [ `echo ${DOMAIN_VERSION} | cut -d\. -f 1` -eq 8 ]; then
    if [ `application_count_retirees` -eq 1 ]; then
      info "Trying to retire application ${APP_NAME}"
      info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -undeploy -name ${APP_NAME}"

      if [ "${SIMULATE_ENABLED}" == "N" ]; then
        wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -undeploy -name ${APP_NAME}"

        ${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -undeploy -name ${APP_NAME} | tee -a ${WLST_LOGFILE}
      fi

      if [ $? -gt 0 ]; then
        failure "Unable to undeploy application ${APP_NAME}"
      else
        info "Attempting to deploy ${FILE} to ${TARGET} in ${DOMAIN}"
        info "${JAVA_HOME}/bin/java -Xmx1024m -Xms1024m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -name ${APP_NAME} -targets ${TARGET} -remote -upload -deploy ${FILE}"

        if [ "${SIMULATE_ENABLED}" == "N" ]; then
          wlstinfo "${JAVA_HOME}/bin/java -Xmx1024m -Xms1024m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -name ${APP_NAME} -targets ${TARGET} -remote -upload -deploy ${FILE}"

          ${JAVA_HOME}/bin/java -Xmx1024m -Xms1024m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -name ${APP_NAME} -targets ${TARGET} -remote -upload -deploy ${FILE} | tee -a ${WLST_LOGFILE}
        fi

        if [ $? -gt 0 ]; then
          failure "Unable to deploy new version of application ${APP_NAME}"
        else
          info "Deploy of application ${APP_NAME} completed"
        fi
      fi
    else
      info "Attempting to deploy ${FILE} to ${TARGET} in ${DOMAIN}"
      info "${JAVA_HOME}/bin/java -Xmx1024m -Xms1024m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -name ${APP_NAME} -targets ${TARGET} -remote -upload -deploy ${FILE}"

      if [ "${SIMULATE_ENABLED}" == "N" ]; then
        wlstinfo "${JAVA_HOME}/bin/java -Xmx1024m -Xms1024m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -name ${APP_NAME} -targets ${TARGET} -remote -upload -deploy ${FILE}"

        ${JAVA_HOME}/bin/java -Xmx1024m -Xms1024m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl t3://${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -name ${APP_NAME} -targets ${TARGET} -remote -upload -deploy ${FILE} | tee -a ${WLST_LOGFILE}
      fi

      if [ $? -gt 0 ]; then
        failure "Unable to deploy new version of application ${APP_NAME}"
      else
        info "Deploy of application ${APP_NAME} completed"
      fi
    fi
    set +o pipefail
  else
    #
    # Process WebLogic versions greater than 8
    #
    # Check if the application is configured for more than one version on WebLogic
    NUMBER_OF_VERSIONS=`get-env-info.pl ${ENV} -applications Details | grep "^${APP_NAME}:" | cut -d\: -f 6`

    # Release WebLogic configuration change session
    unlock_edit_session ${ENV} ${DOMAIN_NAME}

    # Check Hotdeploy option
    HOTDEPLOY=`get-env-info.pl ${ENV} -applications Details | grep "^${APP_NAME}:" | cut -d\: -f 5`

    if [ "${HOTDEPLOY}" == "ENABLE" ]; then
      info "Hotdeploy is enabled for application ${APP_NAME}"
    else
      info "Hotdeploy is disabled for application ${APP_NAME}"
    fi

    if [ `application_count_retirees` -gt 1 ]; then
      info "Trying to retire the old version ${RETIRE_VERSION} of ${APP_NAME}"
      info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -undeploy -name ${APP_NAME} -appversion ${RETIRE_VERSION}"

      if [ "${SIMULATE_ENABLED}" == "N" ]; then
        wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -undeploy -name ${APP_NAME} -appversion ${RETIRE_VERSION}"

        ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -undeploy -name ${APP_NAME} -appversion ${RETIRE_VERSION} | tee -a ${WLST_LOGFILE}

        if [ $? -gt 0 ]; then
          failure "Unable to undeploy version ${RETIRE_VERSION} of application ${APP_NAME}"
        fi
      fi

      if [ ! -z "${ACTIVE_VERSION}" ]; then
        if [ "${HOTDEPLOY}" == "DISABLE" ]; then
          info "Stopping currently active version ${ACTIVE_VERSION} of application ${APP_NAME}"
          info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -name ${APP_NAME} -stop"

          if [ "${SIMULATE_ENABLED}" == "N" ]; then
            wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -name ${APP_NAME} -stop"

            ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -name ${APP_NAME} -stop | tee -a ${WLST_LOGFILE}

            if [ $? -gt 0 ]; then
              failure "Unable to stop currently running application ${APP_NAME}"
            fi
          fi

          if [ ${NUMBER_OF_VERSIONS} -eq 1 ]; then
            info "Application ${APP_NAME} configured for only one version"
            info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -undeploy -name ${APP_NAME} -appversion ${ACTIVE_VERSION}"

            if [ "${SIMULATE_ENABLED}" == "N" ]; then
              wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -undeploy -name ${APP_NAME} -appversion ${ACTIVE_VERSION}"

              ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -undeploy -name ${APP_NAME} -appversion ${ACTIVE_VERSION} | tee -a ${WLST_LOGFILE}

              if [ $? -gt 0 ]; then
                failure "Unable to undeploy version ${ACTIVE_VERSION} of application ${APP_NAME}"
              fi
            fi
          fi
        fi
      fi
    elif [ `application_count_retirees` -eq 1 ]; then
      if [ ! -z "${ACTIVE_VERSION}" ]; then
        if [ "${HOTDEPLOY}" == "DISABLE" ]; then
          info "Stopping currently active version ${ACTIVE_VERSION} of ${APP_NAME}"
          info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -name ${APP_NAME} -stop -appversion ${ACTIVE_VERSION}"

          if [ "${SIMULATE_ENABLED}" == "N" ]; then
            wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -name ${APP_NAME} -stop -appversion ${ACTIVE_VERSION}"

            ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -name ${APP_NAME} -stop -appversion ${ACTIVE_VERSION} | tee -a ${WLST_LOGFILE}

            if [ $? -gt 0 ]; then
              failure "Unable to stop currently running application ${APP_NAME}"
            fi
          fi

          if [ ${NUMBER_OF_VERSIONS} -eq 1 ]; then
            info "Application ${APP_NAME} configured for only one version"
            info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -undeploy -name ${APP_NAME} -appversion ${ACTIVE_VERSION}"

            if [ "${SIMULATE_ENABLED}" == "N" ]; then
              wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -undeploy -name ${APP_NAME} -appversion ${ACTIVE_VERSION}"

              ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -undeploy -name ${APP_NAME} -appversion ${ACTIVE_VERSION} | tee -a ${WLST_LOGFILE}

              if [ $? -gt 0 ]; then
                failure "Unable to undeploy version ${ACTIVE_VERSION} of application ${APP_NAME}"
              fi
            fi
          fi
        fi
      fi
    fi

    # Initiating deploy of new version of application
    info "Deploying ${FILE} to ${TARGET} in ${DOMAIN}"
    check_manifest ${FILE} ${STAGINGDIR}
    info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -deploy -name ${APP_NAME} -remote -upload ${FILE} -targets ${TARGET} -appversion ${NEW_APP_VERSION}"

    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -deploy -name ${APP_NAME} -remote -upload ${FILE} -targets ${TARGET} -appversion ${NEW_APP_VERSION}"

      if [ ${APP_NAME} == "samluumds" -o ${APP_NAME} == "msnode" ]; then
         info "You are deploying samluumds or msnode application so let's use the deployment plan file."
         ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -plan ${DEPLOYMENTPLANFILE} -deploy -name ${APP_NAME} -remote -upload ${FILE} -targets ${TARGET} -appversion ${NEW_APP_VERSION} | tee -a ${WLST_LOGFILE}
      else
         ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -deploy -name ${APP_NAME} -remote -upload ${FILE} -targets ${TARGET} -appversion ${NEW_APP_VERSION} | tee -a ${WLST_LOGFILE}
      fi

      if [ $? -gt 0 ]; then
        failure "Unable to deploy new version ${NEW_APP_VERSION} of application ${APP_NAME}"
      else
        info "Attempting to start new version ${NEW_APP_VERSION} of application ${APP_NAME}"

        if [ "${SIMULATE_ENABLED}" == "N" ]; then
          wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -start -name ${APP_NAME} -appversion ${NEW_APP_VERSION}"

          ${JAVA_HOME}/bin/java -Xmx2048m -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -start -name ${APP_NAME} -appversion ${NEW_APP_VERSION} | tee -a ${WLST_LOGFILE}

          if [ $? -gt 0 ]; then
            failure "Unable to start new version of application ${APP_NAME}"
          else
            info "Application ${APP_NAME} started successfully"
          fi
        fi
      fi
    fi

    # Check if application has Hotdeploy enabled and is configured for one version only
    if [ "${HOTDEPLOY}" == "ENABLE" ] && [ ${NUMBER_OF_VERSIONS} -eq 1 ]; then
      info "Application ${APP_NAME} configured for only one version"

      # Update application version list again to remove inactive version, if present
      update_retiree_list ${ENV} ${APP_NAME}

      if [ ! -z "${RETIRE_VERSION}" ]; then
        info "Trying to retire the old version ${RETIRE_VERSION} of ${APP_NAME}"
        info "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ###### -undeploy -name ${APP_NAME} -appversion ${RETIRE_VERSION}"

        if [ "${SIMULATE_ENABLED}" == "N" ]; then
          wlstinfo "${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ##### -undeploy -name ${APP_NAME} -appversion ${RETIRE_VERSION}"

          ${JAVA_HOME}/bin/java -cp ${WL_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl ${ADMIN_HOST}:${ADMIN_PORT} -username ${ADMIN_USERNAME} -password ${ADMIN_PASSWORD} -undeploy -name ${APP_NAME} -appversion ${RETIRE_VERSION} | tee -a ${WLST_LOGFILE}

          if [ $? -gt 0 ]; then
            failure "Unable to undeploy version ${RETIRE_VERSION} of application ${APP_NAME}"
          fi
        fi
      fi
    fi
    set +o pipefail
    return 0
  fi
}

security_webservice_GetAccountPassword()
{
  USER=$1

  if [ -z "${USER}" ]; then
    echo NO_USER_DEFINED
    return 1
  fi

  TMPFILE=${STAGE_PATH}/tmp/wscall.${RANDOM}

cat > ${TMPFILE} << EOF
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dgit="http://www.dgita.min-financas.pt/">
   <soap:Header/>
   <soap:Body>
      <dgit:GetAccountPassword>
         <!--Optional:-->
         <dgit:strUserAccount>${USER}</dgit:strUserAccount>
      </dgit:GetAccountPassword>
   </soap:Body>
</soap:Envelope>
EOF

  if [[ ${USER} == "sefUser" || ${APP_NAME} == "sef" ]]; then
     #warning This user has the problem of security webservice having a password that is not correct, so it will be changed to the correct password. ${USER} 1>&2
     warning Two aces of spades in the deck... Bad Bad Bad... ${USER} is cheating 1>&2
     PWD="fsZDI1yCUv1oOO0uuBArJMZnp3RCDElN"
  else
     PWD=`curl -m 30 -k -H 'Content-type: text/xml;charset=UTF-8;action="http://www.dgita.min-financas.pt/GetAccountPassword"' -d@${TMPFILE} https://wsusersservice.ritta.local:667/SecurityWebServices.asmx 2>/dev/null | awk -F\< {'print $5'} | awk -F\> {'print $2'}`
  fi

  #PWD=`curl -m 30 -k -H 'Content-type: text/xml;charset=UTF-8;action="http://www.dgita.min-financas.pt/GetAccountPassword"' -d@${TMPFILE} https://wsusersservice.ritta.local:667/SecurityWebServices.asmx 2>/dev/null | awk -F\< {'print $5'} | awk -F\> {'print $2'}`

  if [ -z ${PWD} ]; then
    echo UNABLE_TO_GET_PWD_FROM_WS_DSS_AREA_SEGURANCA
    warning UNABLE TO OBTAIN PASSWORD FOR USER ${USER} 1>&2
  else
    echo ${PWD}
  fi

  #if [[ ${USER} == "sefUser" || ${APP_NAME} == "sef" ]]; then
  #   warning You not have two aces of space in a deck, so I\'ll remove one of them...  ${USER} 1>&2
  #   PWD=fsZDI1yCUv1oOO0uuBArJMZnp3RCDElN
  #fi

  rm -rf ${TMPFILE}
}

security_webservice_GetAccountPasswordqua()
{
  USER=$1

  if [ -z "${USER}" ]; then
    echo NO_USER_DEFINED
    return 1
  fi

  TMPFILE=${STAGE_PATH}/tmp/wscall.${RANDOM}

cat > ${TMPFILE} << EOF
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dgit="http://www.dgita.min-financas.pt/">
   <soap:Header/>
   <soap:Body>
      <dgit:GetAccountPassword>
         <!--Optional:-->
         <dgit:strUserAccount>${USER}</dgit:strUserAccount>
      </dgit:GetAccountPassword>
   </soap:Body>
</soap:Envelope>
EOF

  PWD=`curl -m 30 -k -H 'Content-type: text/xml;charset=UTF-8;action="http://www.dgita.min-financas.pt/GetAccountPassword"' -d@${TMPFILE} https://wsusersservicequa.ritta.local:667/SecurityWebServices.asmx 2>/dev/null | awk -F\< {'print $5'} | awk -F\> {'print $2'}`

  if [ -z ${PWD} ]; then
    echo UNABLE_TO_GET_PWD_FROM_WS_DSS_AREA_SEGURANCA
    warning UNABLE TO OBTAIN PASSWORD FOR USER ${USER} 1>&2
  else
    echo ${PWD}
  fi

  rm -rf ${TMPFILE}
}

check_application_deploy_date()
{
  ENV=$1
  APPLICATION_NAME=$2
  START_DEPLOYMENT="NO"
  # Aqui:
  DB_DATE_ENTRY="`get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION_NAME}:" | cut -d\: -f 7`"
  DB_HOUR_ENTRY0="`get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION_NAME}:" | cut -d\: -f 7| awk -F ";" '{print $2}' | awk -F "|" '{print $1}'`"
  DB_HOUR_ENTRY1="`get-env-info.pl ${ENV} -applications Details | grep "^${APPLICATION_NAME}:" | cut -d\: -f 7 | awk -F ";" '{print $3}'`"
  
   if [ "${DB_DATE_ENTRY}" != "NOTSET" ]; then
    CURRENT_WEEK_DAY="`date +%A | tr [A-Z] [a-z]`"
    #DB_WEEK_DAYS="`echo ${DB_DATE_ENTRY} | tr [\|] [\\\n] | cut -d\; -f 1 | tr [A-Z] [a-z] | sort | uniq`"
    # mangerico
    DB_WEEK_DAYS="`echo ${DB_DATE_ENTRY} | tr [\|] [\\\n] | cut -d\; -f 1 | tr [A-Z] [a-z]  | uniq`"
    # Check for valid weekdays in database
    for weekday in `echo ${DB_WEEK_DAYS}`
    do
      if [ ${weekday} != "monday" -a ${weekday} != "tuesday" -a ${weekday} != "wednesday" -a ${weekday} != "thursday" -a ${weekday} != "friday" ]; then
        failure "Invalid weekday in database: $weekday"
      fi
    done

    if [ -z "`echo -e \"${DB_WEEK_DAYS}\" | grep ${CURRENT_WEEK_DAY}`" ]; then
      warning "Dia de Passagem a PRD: `echo -e \"${DB_WEEK_DAYS}\" | sed 's/monday/segunda-feira/g' | sed 's/tuesday/terca-feira/g' | sed 's/wednesday/quarta-feira/g' | sed 's/thursday/quinta-feira/g' | sed 's/friday/sexta-feira/g' | sed ':a;N;$!ba;s/\n/, /g' | sed 's/\(.*\),/\1 e/'` "
      warning "                  Horas: $DB_HOUR_ENTRY0    $DB_HOUR_ENTRY1"  
    get_user_input
    else
      # Check deploy time period
      CURRENT_ENTRY="`echo ${DB_DATE_ENTRY} | tr [\|] [\\\n] | tr [A-Z] [a-z] | grep ${CURRENT_WEEK_DAY}`"
      CURRENT_HOUR="`date +%H`"
      CURRENT_MINUTES="`date +%M`"
      CURRENT_TIME_INT="${CURRENT_HOUR}${CURRENT_MINUTES}"

      for entry in `echo ${CURRENT_ENTRY}`
      do
        DB_TIME_PERIOD=`echo ${entry} | cut -d\; -f 2`

        # Check if it's a time interval
        if [ "`echo ${DB_TIME_PERIOD} | tr -d [0-9.]`" != "-" ]; then
          failure "You must specify a valid time period [Database entry: `echo ${DB_TIME_PERIOD}`]. Example: 12.30-13.45"
        fi

        # DEPLOY START TIME
        DB_START_HOUR="`echo ${DB_TIME_PERIOD} | cut -d\- -f 1 | awk -F\. '{print($1)}'`"
        DB_START_MINUTES="`echo ${DB_TIME_PERIOD} | cut -d\- -f 1 | awk -F\. '{print($2)}'`"

        # Check if hour is a valid entry
        if [[ ${DB_START_HOUR} -ge 0 && ${DB_START_HOUR} -le 23 ]]; then
          if [ -z "${DB_START_MINUTES}" ]; then
            DB_START_TIME_INT="${DB_START_HOUR}00"
          else
            # Check if minutes are a valid entry
            if [[ ${DB_START_MINUTES} -ge 0 && ${DB_START_MINUTES} -le 59 ]]; then
              DB_START_TIME_INT="${DB_START_HOUR}${DB_START_MINUTES}"
            else
              failure "You must specify a valid minutes entry [Database entry: `echo ${DB_TIME_PERIOD}`]"
            fi
          fi
        else
          failure "You must specify a valid hours entry [Database entry: `echo ${DB_TIME_PERIOD}`]"
        fi

        # DEPLOY END TIME
        DB_END_HOUR="`echo ${DB_TIME_PERIOD} | cut -d\- -f 2 | awk -F\. '{print($1)}'`"
        DB_END_MINUTES="`echo ${DB_TIME_PERIOD} | cut -d\- -f 2 | awk -F\. '{print($2)}'`"

        # Check if hour is a valid entry
        if [[ ${DB_END_HOUR} -ge 0 && ${DB_END_HOUR} -le 23 ]]; then
          if [ -z "${DB_END_MINUTES}" ]; then
            DB_END_TIME_INT="${DB_END_HOUR}00"
          else
            # Check if minutes are a valid entry
            if [[ ${DB_END_MINUTES} -ge 0 && ${DB_END_MINUTES} -le 59 ]]; then
              DB_END_TIME_INT="${DB_END_HOUR}${DB_END_MINUTES}"
            else
              failure "You must specify a valid minutes entry [Database entry: `echo ${DB_TIME_PERIOD}`]"
            fi
          fi
        else
          failure "You must specify a valid hours entry [Database entry: `echo ${DB_TIME_PERIOD}`]"
        fi

        # Convert to integer
        DB_START_TIME_INT=`expr ${DB_START_TIME_INT} + 0`
        DB_END_TIME_INT=`expr ${DB_END_TIME_INT} + 0`
        CURRENT_TIME_INT=`expr ${CURRENT_TIME_INT} + 0`

        if [[ ${DB_START_TIME_INT} -le ${CURRENT_TIME_INT} && ${DB_END_TIME_INT} -ge ${CURRENT_TIME_INT} ]]; then
          START_DEPLOYMENT="YES"
          start_deploy_message
          break
        fi
      done

      if [ ${START_DEPLOYMENT} == "NO" ]; then
        warning "Esta aplicacao esta configurada para ser instalada hoje, `echo -e \"${CURRENT_ENTRY}\" | cut -d\; -f 2 | tr [.] [:] | sed 's/^/das /g' | sed 's/-/ as /g' | sed ':a;N;$!ba;s/\n/, /g' | sed 's/\(.*\),/\1 e/'`"
        get_user_input
      fi
    fi
  fi
}

get_user_input()
{
  info "Do you which to proceed? (y/n)"
  read USER_INPUT
  USER_INPUT="`echo ${USER_INPUT} | tr [A-Z] [a-z]`"

  if [ "${USER_INPUT}" != "y" -a "${USER_INPUT}" != "n" ]; then
    failure "Must input y or n"
  elif [ "${USER_INPUT}" == "n" ]; then
    info "Deployment cancelled"
    exit 0
  else
    start_deploy_message
  fi
}

start_deploy_message()
{
  info "Starting deployment for application ${APPLICATION_NAME}"
}

taxonomy_webservice_GetApplicationsList()
{
  TMPFILE=${STAGE_PATH}/tmp/wstaxonomycall.${RANDOM}

cat > ${TMPFILE} << EOF
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:getTodasAplicacoes/>
   </soapenv:Body>
</soapenv:Envelope>
EOF

  HEADER="Content-Type: text/xml;charset=UTF-8;SOAPAction: \"http://tempuri.org/getTodasAplicacoes\""

  CMD=`curl -m 30 -k -H "${HEADER}" -d@${TMPFILE} ${TAXONOMY_SERVER}/infoTaxonomia.asmx 2>/dev/null`

  echo -e "${CMD}"
}

taxonomy_webservice_GetApplicationFQDN()
{
  APPLICATION=$1

  if [ -z "${APPLICATION}" ]; then
    failure "No application sepcified"
  fi

  TMPFILE=${STAGE_PATH}/tmp/wstaxonomycall.${RANDOM}

cat > ${TMPFILE} << EOF
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">
   <soap:Header/>
   <soap:Body>
      <tem:getDadosAplicacaoBySigla>
         <!--Optional:-->
         <tem:sigla>${APPLICATION}</tem:sigla>
      </tem:getDadosAplicacaoBySigla>
   </soap:Body>
</soap:Envelope>
EOF

  HEADER="Content-Type: text/xml;charset=UTF-8;SOAPAction: \"http://tempuri.org/getDadosAplicacaoBySigla\""
  CMD=`curl -m 30 -k -H "${HEADER}" -d@${TMPFILE} ${TAXONOMY_SERVER}/infoTaxonomia.asmx 2>/dev/null | awk -F\< {'print $18'} | cut -d\> -f 2`

  if [ -z "${CMD}" ]; then
    info "Application ${APPLICATION} not found in taxonomy database"
  else
    echo -e "${CMD}"
  fi
}

