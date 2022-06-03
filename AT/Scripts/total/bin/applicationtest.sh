#!/bin/sh

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPLICATION_NAME=$2

DEPLOY_STATUS="N"
TRANSACTION="DEPLOY($1)"
SYNC_FRONTENDS="FALSE"
SYNC_WLSMACHINES="FALSE"
BACKUP_ENDPOINTS="FALSE"
TRIES=0
MAXTRIES=10
DEPLOYMENT_PID=$$

#Temporario inserido pelo Bruno
DATE=`date '+%H%M%S_%y%m%d'`

ARG_COUNT=0
FILE_COUNT=0
SUCCESS_COUNT=0
PROPERTYFILES_COUNT=0
APPLICATIONFILES_COUNT=0
HTMLCONTENT_COUNT=0
RESOURCEFILES_COUNT=0
FILELIST=$*

VERBOSE_ENABLED="N"
SIMULATE_ENABLED="N"

export WLS_BASE

#####################
# Usage information #
#####################
usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <APPLICATION_NAME> <FILE_1> ... <FILE_N> [OPTION]

  ENVIRONMENT        - The environment where the application exists: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME   - The name of the new application to deploy
  FILE 1 .. FILE N   - The list of files to deploy for the new application

 Options

  -verbose
  -simulate

EOF
}

##########################
# Perform initial checks #
##########################
start_arg_checks()
{
  # Check username
  if [ "${USER}" != "weblogic" ]; then
    failure "User must be weblogic"
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

  if [ -z ${APPLICATION_NAME} ]; then
    failure "You must provide your application name"
  fi

  if ! application_exists ${ENV} ${APPLICATION_NAME}
  then
    failure "Application ${APPLICATION_NAME} does not exist"
  fi

  check_application_deploy_date ${ENV} ${APPLICATION_NAME}
  info "$0 ${FILELIST}"

  APPLICATION_TARGETS=`list_all_application_targets ${ENV} ${APPLICATION_NAME}`
  VIRTUAL_HOST=`list_all_application_virtualhosts ${ENV} ${APPLICATION_NAME}`
  DOMAIN_NAME=`target_domain ${ENV} ${APPLICATION_TARGETS}`

  WLSERVERS=`list_all_cluster_servers ${ENV} ${DOMAIN_NAME} ${APPLICATION_TARGETS}`
  FRONTEND_LIST=`get_application_frontend_list ${ENV} ${APPLICATION_NAME}`
  STAGINGDIR="${STAGE_PATH}/tmp/${APPLICATION_NAME}"
  LOCKFILE="${STAGE_PATH}/tmp/appdeploy.${DOMAIN_NAME}.lck"

  DOMAIN_DETAILS=`get-env-info.pl ${ENV} ${DOMAIN_NAME}`
  DOMAIN_VERSION=`echo ${DOMAIN_DETAILS} | cut -d\: -f 3`
  ADMIN_HOST=`echo ${DOMAIN_DETAILS} | cut -d\: -f 5`
  ADMIN_PORT=`echo ${DOMAIN_DETAILS} | cut -d\: -f 6`
  ADMIN_USERNAME=`echo ${DOMAIN_DETAILS} | cut -d\: -f 7`
  ADMIN_PASSWORD=`echo ${DOMAIN_DETAILS} | cut -d\: -f 8`
  DOMAIN_PATH=`get_domain_path ${ENV} ${DOMAIN_NAME}`
}

##############################################
# Check for active deployments in the domain #
##############################################
check_active_deploys()
{
  if [ -f ${LOCKFILE} ]; then
    LCKFILE_PID=`cat ${LOCKFILE}`
    ACTIVE_PID=`ps --no-headers -p ${LCKFILE_PID} | wc -l`

    if [ ${ACTIVE_PID} -lt 1 ]; then
      info "No active processes with PID equal to ${LCKFILE_PID}"

      if [ -d ${STAGINGDIR} ]; then
        info "Removing lock file ${LOCKFILE} and staging dir ${STAGINGDIR}"
        rm -rf ${LOCKFILE} ${STAGINGDIR}
      else
        info "Removing lock file ${LOCKFILE}"
        rm -rf ${LOCKFILE}
      fi
    else
      failure "A deployment process is already running with PID ${LCKFILE_PID} on domain ${DOMAIN_NAME}"
    fi
  else
    if [ -d ${STAGINGDIR} ]; then
      info "Removing staging dir ${STAGINGDIR}"
      rm -rf ${STAGINGDIR}
    else
      info "No cleanups necessary"
      info "Using ${STAGINGDIR} as staging dir"
    fi
  fi

  echo ${DEPLOYMENT_PID} > ${LOCKFILE}
  mkdir -p ${STAGINGDIR}
  WLFILE=`get_weblogic_file ${ENV} ${DOMAIN_NAME} ${STAGINGDIR}`
}

#################################################################################################
# Sort the arguments, except the first, by extension, applications and static content for last! #
#################################################################################################
sort_args()
{
  for arg in ${FILELIST}; do
    ARG_COUNT=`expr ${ARG_COUNT} + 1`

    if [ ${ARG_COUNT} -lt 2 ]; then
      continue;
    fi

    if [ -f "${arg}" ]; then
      file=${arg}
      fileextension=`echo ${file} | awk -F . {'print $NF'}`
      filetype=`echo \`basename ${file}\` | awk -F. {'print $1'}`

      case ${filetype} in
        public_html*)
          TEMPLIST="${TEMPLIST} ${arg}"
          FILE_COUNT=`expr ${FILE_COUNT} + 1`
          continue;
          ;;
        install-*) # Old infrastructure static content files
          #STATIC_VERSION=`echo ${arg} | sed 's/.tar.gz//' | tr -d [A-Za-z-_]`
          STATIC_VERSION=`echo ${arg} | sed 's/.tar.gz//' | sed 's/.*_//g' | sed 's/.*-//g'`
          TEMPLIST="${TEMPLIST} ${arg}"
          FILE_COUNT=`expr ${FILE_COUNT} + 1`
          continue;
          ;;
        resources)
          TEMPLIST="${arg} ${TEMPLIST}"
          FILE_COUNT=`expr ${FILE_COUNT} + 1`
          continue;
          ;;
      esac

      case ${fileextension} in
        xml|dtd|txt|wsdl|xsd)
          TEMPLIST="${arg} ${TEMPLIST}"
          FILE_COUNT=`expr ${FILE_COUNT} + 1`
          continue;
          ;;
        properties)
          TEMPLIST="${arg} ${TEMPLIST}"
          FILE_COUNT=`expr ${FILE_COUNT} + 1`
          continue;
          ;;
        war|ear)
          TEMPLIST="${TEMPLIST} ${arg}"
          FILE_COUNT=`expr ${FILE_COUNT} + 1`
          continue;
          ;;
        jar|rar)
          TEMPLIST="${TEMPLIST} ${arg}"
          FILE_COUNT=`expr ${FILE_COUNT} + 1`
          continue;
          ;;
      esac
    else
      if [ ${arg} == "-verbose" ]; then
        VERBOSE_ENABLED="Y"
      elif [ "${arg}" == "-simulate" ]; then
        SIMULATE_ENABLED="Y"
      fi
    fi 
  done

  info "Identified ${FILE_COUNT} file(s) to process"
}

###########################################
# Process public_html and resources files #
###########################################
process_static()
{
  TEMPLIST="$1 ${TEMPLIST}"
  FILELIST=${TEMPLIST}
  SUCCESS_STATE="N"

  for arg in ${FILELIST}; do
    if [ -f ${arg} ]; then
      file=${arg}
      fileextension=`echo ${file} | awk -F . {'print $NF'}`
      filetype=`echo \`basename ${file}\` | awk -F. {'print $1'}`

      case ${filetype} in
        public_html*|install-*)
          info "Processing argument \"${arg}\" - Phase 1"

          #Basedir cleanup and update
          STATIC_CONTENT_BASE_DESTINATION=${STAGINGDIR}/public_html

          if [ ${VERBOSE_ENABLED} == "Y" ]; then
            rm -rf ${STATIC_CONTENT_BASE_DESTINATION}
            mkdir -p ${STATIC_CONTENT_BASE_DESTINATION}
            decompress_file ${file} ${STATIC_CONTENT_BASE_DESTINATION}
          else
            rm -rf ${STATIC_CONTENT_BASE_DESTINATION} &>/dev/null
            mkdir -p ${STATIC_CONTENT_BASE_DESTINATION} &>/dev/null
            decompress_file ${file} ${STATIC_CONTENT_BASE_DESTINATION} &>/dev/null
          fi

          if [ $? -gt 0 ]; then
            warning "Unable to decompress static content"
          else
            #Correct permissions before proceeding, to avoid future scp errors
            find "${STATIC_CONTENT_BASE_DESTINATION}" -type d -exec chmod 755 {} \;
            find "${STATIC_CONTENT_BASE_DESTINATION}" -type f -exec chmod 644 {} \;
            SYNC_FRONTENDS="TRUE"
            SUCCESS_COUNT=`expr ${SUCCESS_COUNT} + 1`
            continue;
          fi
          ;;
        resources)
          info "Processing argument \"${arg}\" - Phase 1"

          for target in ${WLSERVERS}; do
            RESOURCES_DESTINATION=${STAGINGDIR}/${target}/var

            if [ ${VERBOSE_ENABLED} == "Y" ]; then
              mkdir -p ${RESOURCES_DESTINATION}
              decompress_file ${file} ${RESOURCES_DESTINATION}
            else
              mkdir -p ${RESOURCES_DESTINATION} &>/dev/null
              decompress_file ${file} ${RESOURCES_DESTINATION} &>/dev/null
            fi
          
            if [ $? -gt 0 ]; then
              warning "Unable to decompress resources"
            else
              #Correct permissions before proceeding, to avoid future scp errors
              find "${RESOURCES_DESTINATION}" -type d -exec chmod 755 {} \;
              find "${RESOURCES_DESTINATION}" -type f -exec chmod 644 {} \;
              SYNC_WLSMACHINES="TRUE"
              SUCCESS_STATE="Y"
            fi
          done

          if [ "${SUCCESS_STATE}" == "Y" ]; then
            SUCCESS_COUNT=`expr ${SUCCESS_COUNT} + 1`
          fi
          continue;
          ;;
      esac
    fi
  done
}

#########################################################
# Process properties, xml, dtd, wsdl, xsd and txt files #
#########################################################
process_resources()
{
  export APPLICATION_NAME
  export DOMAIN_HOME
  SUCCESS_STATE="N"

  for arg in ${FILELIST}; do
    if [ -f ${arg} ]; then
      file=${arg}
      fileextension=`echo ${file} | awk -F . {'print $NF'}`
      filetype=`echo \`basename ${file}\` | awk -F. {'print $1'}`

      case ${fileextension} in
        xml|dtd|wsdl|xsd)
          info "Processing argument \"${arg}\" - Phase 2"

          for target in ${WLSERVERS}; do
            #Construct node config directory structure in staging dir
            RESOURCES_DESTINATION="${STAGINGDIR}/${target}/config"

            export ENV
            export DOMAIN_NAME
            export MACHINE_NAME=`get_machine_name ${ENV} ${target}`
            export SERVER_LISTEN_ADDRESS=`get_machine_name ${ENV} ${target}`
            export TARGET_ADDRESS=`get_target_address ${WLFILE} ${target}`
            export SERVER_LISTEN_PORT=${TARGET_ADDRESS}
            export VIRTUALHOST_NAME=${VIRTUAL_HOST}
            export SERVER_NAME=${target}

            if [ ${VERBOSE_ENABLED} == "Y" ]; then
              mkdir -p ${RESOURCES_DESTINATION}
            else
              mkdir -p ${RESOURCES_DESTINATION} &>/dev/null
            fi

            if ! process_xml_properties ${file} ${RESOURCES_DESTINATION}
            then
              failure "Unable to make properties file"
            else
              SYNC_WLSMACHINES="TRUE"
              SUCCESS_STATE="Y"
            fi
          done

          if [ "${SUCCESS_STATE}" == "Y" ]; then
            SUCCESS_COUNT=`expr ${SUCCESS_COUNT} + 1`
          fi
          continue;
        ;;
        jar)
          info "Processing argument \"${arg}\" - Phase 2"

          for target in ${WLSERVERS}; do
            #Construct node lib directory structure in staging dir
            RESOURCES_DESTINATION=${STAGINGDIR}/${target}/lib

            if [ ${VERBOSE_ENABLED} == "Y" ]; then
              mkdir -p ${RESOURCES_DESTINATION}
              cp -p $file ${RESOURCES_DESTINATION}
            else
              mkdir -p ${RESOURCES_DESTINATION} &>/dev/null
              cp -p $file ${RESOURCES_DESTINATION} &>/dev/null
            fi

            if [ -f "${RESOURCES_DESTINATION}/`basename ${file}`" ]; then
              SYNC_WLSMACHINES="TRUE"
              SUCCESS_STATE="Y"
            else
              failure "Unable to copy ${file} to ${RESOURCES_DESTINATION}"
            fi
          done

          if [ "${SUCCESS_STATE}" == "Y" ]; then
            SUCCESS_COUNT=`expr ${SUCCESS_COUNT} + 1`
          fi
          continue;
        ;;
        txt)
          info "Processing argument \"${arg}\" - Phase 2"

          for target in ${WLSERVERS}; do
            #Construct node config directory structure in staging dir
            RESOURCES_DESTINATION="${STAGINGDIR}/${target}/config/"

            if [ ${VERBOSE_ENABLED} == "Y" ]; then
              mkdir -p ${RESOURCES_DESTINATION}
              cp -p $file ${RESOURCES_DESTINATION}
            else
              mkdir -p ${RESOURCES_DESTINATION} &>/dev/null
              cp -p $file ${RESOURCES_DESTINATION} &>/dev/null
            fi

            if [ -f "${RESOURCES_DESTINATION}/`basename ${file}`" ]; then
              SYNC_WLSMACHINES="TRUE"
              SUCCESS_STATE="Y"
            else
              failure "Unable to copy ${file} to ${RESOURCES_DESTINATION}"
            fi
          done

          if [ "${SUCCESS_STATE}" == "Y" ]; then
            SUCCESS_COUNT=`expr ${SUCCESS_COUNT} + 1`
          fi
          continue;
        ;;
        properties)
          info "Processing argument \"${arg}\" - Phase 2"

          for target in ${WLSERVERS}; do
            #Construct node config directory structure in staging dir
            RESOURCES_DESTINATION="${STAGINGDIR}/${target}/config"

            export ENV
            export DOMAIN_NAME
            export MACHINE_NAME=`get_machine_name ${ENV} ${target}`
            export SERVER_LISTEN_ADDRESS=`get_machine_name ${ENV} ${target}`
            export TARGET_ADDRESS=`get_target_address ${WLFILE} ${target}`
            export SERVER_LISTEN_PORT=${TARGET_ADDRESS}
            export VIRTUALHOST_NAME=${VIRTUAL_HOST}
            export SERVER_NAME=${target}

            if [ ${VERBOSE_ENABLED} == "Y" ]; then
              mkdir -p ${RESOURCES_DESTINATION}
            else
              mkdir -p ${RESOURCES_DESTINATION} &>/dev/null
            fi

            process_properties ${file} ${RESOURCES_DESTINATION}

            if [ $? -gt 0 ]; then
              failure "Unable to make properties file"
            else
              SYNC_WLSMACHINES="TRUE"
              BACKUP_ENDPOINTS="TRUE"
              SUCCESS_STATE="Y"
            fi
          done

          if [ "${SUCCESS_STATE}" == "Y" ]; then
            SUCCESS_COUNT=`expr ${SUCCESS_COUNT} + 1`
          fi
          continue;
        ;;
      esac
    fi
  done
}

#####################################
# Backup endpoints.properties files #
#####################################
backup_endpoint()
{
  if [ ${BACKUP_ENDPOINTS} == "TRUE" ]; then
    info "Backing up endpoints.properties files - Phase 3"

    for target in ${WLSERVERS}; do
      MACHINE_NAME=`get_machine_name ${ENV} ${target}`
      REMOTECMD="ssh -n ${USER}@${MACHINE_NAME} 'bash --login -c \"cp -f ${DOMAIN_PATH}/servers/${target}/config/endpoints.properties ${DOMAIN_PATH}/servers/${target}/config/endpoints.properties.bck.${DATE} \"'"
      info "${MACHINE_NAME}: cp -f ${DOMAIN_PATH}/servers/${target}/config/endpoints.properties ${DOMAIN_PATH}/servers/${target}/config/endpoints.properties.bck.${DATE}"

      if [ "${SIMULATE_ENABLED}" == "N" ]; then
        eval ${REMOTECMD}
      fi

      if [ $? == "0" ]; then
        info "Successfully backed up endpoints.properties file for server ${target}"
      else
        warning "Unable to backup endpoints.properties file for server ${target}"
      fi
    done
  else
    info "No backup required for endpoints.properties files - Phase 3"
  fi
}

##########################################################
# Update static content files for the new infrastructure #
##########################################################
update_new_static_files()
{
  STATIC_PATH=`get_static_path ${ENV} ${APPLICATION_NAME}`

  if [ -z "${STATIC_PATH}" ]; then
    STATIC_PATH="/httpd/data/${host}/${VIRTUAL_HOST}/public_html"
  fi

  # Check static path existance
  EXAID=`ssh -n -o StrictHostKeyChecking=no ${USER}@${host} "ls ${STATIC_PATH}" &>/dev/null`

  if [ $? -gt 0 ]; then
    failure "Is static path ${STATIC_PATH} present on machine ${host}??"
  fi

  info "scp -r ${STATIC_CONTENT_BASE_DESTINATION}/* ${host}:${STATIC_PATH}/"

  if [ ${VERBOSE_ENABLED} == "Y" ]; then
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      scp -r ${STATIC_CONTENT_BASE_DESTINATION}/* ${host}:${STATIC_PATH}/
    fi
  else
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      scp -r ${STATIC_CONTENT_BASE_DESTINATION}/* ${host}:${STATIC_PATH}/ &>/dev/null
    fi
  fi

  if [ $? -gt 0 ]; then
    warning "Unable to copy static content to ${host}:${STATIC_PATH}"
    SUCCESS_STATE="N"
  else
    info "Frontend ${host} sucessfully synchronized"
    DEPLOY_STATUS="Y"
  fi
}

##########################################################
# Update static content files for the old infrastructure #
##########################################################
update_old_static_files()
{
  STATIC_PATH=`get_static_path ${ENV} ${APPLICATION_NAME}`
  OLD_STATIC_PATH="${STATIC_PATH}/public_html/${STATIC_VERSION}"

  info "Attempting to create static path ${OLD_STATIC_PATH} on host ${host}"

  if [ ${VERBOSE_ENABLED} == "Y" ]; then
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      ssh -n -o StrictHostKeyChecking=no ${USER}@${host} mkdir "${OLD_STATIC_PATH}"
    fi
  else
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      ssh -n -o StrictHostKeyChecking=no ${USER}@${host} mkdir "${OLD_STATIC_PATH}" &>/dev/null
    fi
  fi

  if [ $? -gt 0 ]; then
    failure "Unable to create static path ${OLD_STATIC_PATH}"
  fi

  # Attempt to copy static content files to host
  info "scp -r ${STATIC_CONTENT_BASE_DESTINATION}/* to ${host}:${OLD_STATIC_PATH}"

  if [ ${VERBOSE_ENABLED} == "Y" ]; then
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      scp -r ${STATIC_CONTENT_BASE_DESTINATION}/* to ${host}:${OLD_STATIC_PATH}
    fi
  else
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      scp -r ${STATIC_CONTENT_BASE_DESTINATION}/* to ${host}:${OLD_STATIC_PATH} &>/dev/null
    fi
  fi

  # Remove old sym link from the host
  info "Attempting to remove old sym link ${STATIC_PATH}/public_html/current"

  if [ ${VERBOSE_ENABLED} == "Y" ]; then
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      ssh -n -o StrictHostKeyChecking=no ${USER}@${host} "rm -f ${STATIC_PATH}/public_html/current"
    fi
  else
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      ssh -n -o StrictHostKeyChecking=no ${USER}@${host} "rm -f ${STATIC_PATH}/public_html/current" &>/dev/null
    fi
  fi

  if [ $? -gt 0 ]; then
    failure "Unable to remove old sym link ${STATIC_PATH}/public_html/current"
  fi

  # Create new sym link on host
  info "Attempting to create new sym link ${STATIC_PATH}/public_html/current on host ${host}"

  if [ ${VERBOSE_ENABLED} == "Y" ]; then
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      ssh -n -o StrictHostKeyChecking=no ${USER}@${host} "ln -s ${OLD_STATIC_PATH} ${STATIC_PATH}/public_html/current"
    fi
  else
    if [ "${SIMULATE_ENABLED}" == "N" ]; then
      ssh -n -o StrictHostKeyChecking=no ${USER}@${host} "ln -s ${OLD_STATIC_PATH} ${STATIC_PATH}/public_html/current" &>/dev/null
    fi
  fi

  if [ $? -gt 0 ]; then
    failure "Unable to create new sym link ${STATIC_PATH}/public_html/current on host ${host}"
  fi

  info "Frontend ${host} sucessfully synchronized"
  DEPLOY_STATUS="Y"
}

###############
# SCP files #
###############
scp_files()
{
  SUCCESS_STATE="Y"

  if [ ${SYNC_FRONTENDS} == "FALSE" -a ${SYNC_WLSMACHINES} == "FALSE" ]; then
    info "Nothing to synchronize - Phase 4"
  else
  {
    info "Synchronizing - Phase 4"

    # Update static content
    if [ ${SYNC_FRONTENDS} == "TRUE" ]; then
      for host in `get_application_frontend_list ${ENV} ${APPLICATION_NAME}`; do
        if [ -z "${STATIC_VERSION}" ]; then
          update_new_static_files
        else
          update_old_static_files
        fi
      done

      if [ "${SUCCESS_STATE}" == "N" ]; then
        SUCCESS_COUNT=`expr ${SUCCESS_COUNT} - 1`
        SUCCESS_STATE="Y"
      fi
    fi

    # Update managed servers config files
    if [ ${SYNC_WLSMACHINES} == "TRUE" ]; then
      for host in `get_application_machine_name ${ENV} ${APPLICATION_NAME}`; do
        for wlserver in ${WLSERVERS}; do
          if [ `get_machine_name ${ENV} ${wlserver}` == "${host}" ]; then
            info "scp -r ${STAGINGDIR}/${wlserver} to ${host}:${DOMAIN_PATH}/servers/${wlserver}"

            if [ ${VERBOSE_ENABLED} == "Y" ]; then
              if [ "${SIMULATE_ENABLED}" == "N" ]; then
                scp -r ${STAGINGDIR}/${wlserver} ${host}:${DOMAIN_PATH}/servers/
              fi
            else
              if [ "${SIMULATE_ENABLED}" == "N" ]; then
                scp -r ${STAGINGDIR}/${wlserver} ${host}:${DOMAIN_PATH}/servers/ &>/dev/null
              fi
            fi

            if [ $? -gt 0 ]; then
              warning "Unable to copy ${wlserver} files to managed server ${host}"
              SUCCESS_STATE="N"
            else
              info "Application server ${host} sucessfully synchronized"
              DEPLOY_STATUS="Y"
            fi
          fi
        done
      done
      if [ "${SUCCESS_STATE}" == "N" ]; then
        SUCCESS_COUNT=`expr ${SUCCESS_COUNT} - 1`
        SUCCESS_STATE="Y"
      fi
    fi
  }
  fi
}

#######################
# Deploy war/ear file #
#######################
app_deploy()
{
  SUCCESS_STATE="Y"
  export APPLICATION_NAME

  #Get the files
  for arg in ${FILELIST}; do
    if [ -f ${arg} ]; then
      file=${arg}
      fileextension=`echo ${file} | awk -F . {'print $NF'}`
      filetype=`echo \`basename ${file}\` | awk -F. {'print $1'}`

      case ${fileextension} in
        war|ear)
          #Check for correct WLCookieName definition
          check_wlcookiename ${file} ${STAGINGDIR}

          info "Attempting deployment - Phase 5"

          if [ -z ${APPLICATION_NAME} ]; then
            failure "Unable to find the application name hence, ${arg} file could not be deployed \(no targets\)."
          fi

          if [ -z ${APPLICATION_TARGETS} ]; then
            failure "No targets for ${APPLICATION_NAME}. Use target_add.sh."
          fi

          deploy_file ${APPLICATION_NAME} ${APPLICATION_TARGETS} ${file}

          if [ $? -gt 0 ]; then
            failure "Unable to deploy file \(check locks, applications, etc...\)"
          else
            info "Successfully deployed ${file} on ${APPLICATION_TARGETS} for ${APPLICATION_NAME}"
            DEPLOY_STATUS="Y"
            SUCCESS_COUNT=`expr ${SUCCESS_COUNT} + 1`
          fi
          continue;
        ;;
      esac
    fi
  done

  if [ ${FILE_COUNT} -lt 1 ]; then
    failure "No files found to deploy. Please specify your files as arguments for the application ${APPLICATION_NAME}"
  fi

  if [ ${SUCCESS_COUNT} -eq 0 ]; then
    warning "No files were deployed for application ${APPLICATION_NAME}"
  else
    info "${SUCCESS_COUNT} files of ${FILE_COUNT}, where deployed for application ${APPLICATION_NAME}"
  fi

  if [ ${VERBOSE_ENABLED} == "Y" ]; then
    if [ "${SIMULATE_ENABLED}" != "Y" ]; then
      info "Removing staging dir ${STAGINGDIR} and lockfile ${LOCKFILE}"
      rm -rf "${STAGINGDIR}"
      rm -rf "${LOCKFILE}"
    fi
  else
    if [ "${SIMULATE_ENABLED}" != "Y" ]; then
      rm -rf "${STAGINGDIR}" &>/dev/null
      rm -rf "${LOCKFILE}" &>/dev/null
    fi
  fi

  # Update mediawiki deployments page
  if [ "${SIMULATE_ENABLED}" != "Y" ]; then 
    update_mediawiki
  fi

  success "Operation complete"
}

#####################################
# Update mediawiki deployments page #
#####################################
update_mediawiki()
{
  SSH_IP_ADDRESS=`echo $SSH_CONNECTION|awk '{printf($1)}'`
  FLIST=`echo ${FILELIST}|sed 's/ /,/g'`

  if [ "${DEPLOY_STATUS}" == "Y" ]; then
    wlappdeploys_updatemediawiki.pl ${APPLICATION_NAME} ${FLIST} ${SSH_IP_ADDRESS} Sim ${ENV}
  else
    wlappdeploys_updatemediawiki.pl ${APPLICATION_NAME} ${FLIST} ${SSH_IP_ADDRESS} Não ${ENV}
  fi
}

print_variables()
{
  if [ ${VERBOSE_ENABLED} == "Y" ]; then
    info "== VERBOSE MODE ENABLED =="
    info "APPLICATION_NAME = ${APPLICATION_NAME}"
    info "APPLICATION_TARGETS = ${APPLICATION_TARGETS}"
    info "VIRTUAL_HOST = ${VIRTUAL_HOST}"
    info "DOMAIN = ${DOMAIN_NAME}"
    info "WLSERVERS = `echo ${WLSERVERS}`"
    info "FRONTEND_LIST = ${FRONTEND_LIST}"
    info "STAGINGDIR = ${STAGINGDIR}"
    #info "ENDPOINT_FILENAME = ${ENDPOINT_FILENAME}"
    info "LOCKFILE = ${LOCKFILE}"
    info "WLFILE = ${WLFILE}"
  fi

  if [ "${SIMULATE_ENABLED}" == "Y" ]; then
    warning "== SIMULATION MODE ENABLED =="
  fi
}

########################
# MAIN EXECUTION BLOCK #
########################
start_arg_checks
check_wl_version ${ENV} ${DOMAIN_NAME}
check_java_version ${ENV} ${DOMAIN_NAME}
check_active_deploys
sort_args
print_variables
process_static
process_resources
backup_endpoint
scp_files
app_deploy
