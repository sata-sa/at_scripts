#!/bin/bash

#set -x


############################
# Script colors - complete #
############################
GREEN="\E[0;32m\033[1m"
BLUE="\E[0;34m\033[1m"
RED="\E[0;31m\033[1m"
YELLOW="\E[1;33m\033[1m"
RESET="\033[0m"


####################################
### Logging functions - complete ###
####################################
log()
{
  echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $*"
}

info()
{
  log "[${GREEN}I${RESET}] [${GREEN}$*${RESET}]"
}

inputuser()
{
  log "[${BLUE}R${RESET}] [${BLUE}$*${RESET}]"
}

warning()
{
  log "[${YELLOW}W${RESET}] [${YELLOW}$*${RESET}]"
}

fail()
{
  log "[${RED}E${RESET}] [${RED}$*${RESET}]"
}

error()
{
  log "[${RED}E${RESET}] [${RED}$*${RESET}]"
  exit 1
}

success()
{
  log "[${GREEN}S${RESET}] [${GREEN}$*${RESET}]"
}



########################
### Enviroment Check ###
########################
check_env()
{
  if [ -z "$1" ]; then
    error "Must specify environment (prd/qua/dev)"
  else
    ENV=`echo $1 | tr [A-Z] [a-z]`

    if [ "${ENV}" != "prd" ]; then
      if [ "${ENV}" != "qua" ]; then
        if [ "${ENV}" != "dev" ]; then
          error "Unrecognized environment ${ENV}"
        fi
      fi
    fi
  fi
}


check_area_t()
{
if [ -z ${AREA} ]; then
error "Area field empty"
else
  if [ -z "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -a | grep "${AREA}"`" ]; then
    error "Area doens't exist"
  else
    success "Area exists"
  fi
fi
}


check_area_f()
{
if [ -z ${AREA} ]; then
error "Area field empty"
else
  if [ -n "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -a | grep "${AREA}"`" ]; then
    error "Area exist"
  else
    success "Area doesn't exists"
  fi
fi
}


check_batch_t()
{
if [ -z ${BATCH} ]; then
error "Batch field empty"
else
  if [ -z "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -b | grep "${BATCH}"`" ]; then
    error "Batch doesn't exist"
  else
    success "Batch exists"
  fi
fi
}


check_batch_f()
{
if [ -z ${BATCH} ]; then
error "Batch field empty"
else
  if [ -n "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -b | grep "${BATCH}"`" ]; then
    error "Batch exists"
  else
    success "Batch doesn't exist"
  fi
fi
}


check_machine_t()
{
if [ -z ${MACHINE} ]; then
error "Machine empty"
else
  if [ -z "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -m | grep "${MACHINE}"`" ]; then
    error "Machine doens't exist"
  else
    success "Machine exists"
  fi
fi
}


check_machine_f()
{
if [ -z ${MACHINE} ]; then
error "Machine empty"
else
  if [ -n "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -m | grep "${MACHINE}"`" ]; then
    error "Machine exists"
  else
    success "Machine doesn't exist"
  fi
fi
}


check_nucleo_t()
{
if [ -z ${NUCLEO} ]; then
error "Nucleo field empty"
else
  if [ -z "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -n | grep "${NUCLEO}"`" ]; then
    error "Nucleo doens't exist"
  else
    success "Nucleo exists"
  fi
fi
}


check_nucleo_f()
{
if [ -z ${NUCLEO} ]; then
error "Nucleo field empty"
else
  if [ -n "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -n | grep "${NUCLEO}"`" ]; then
    error "Nucleo exists"
  else
    success "Nucleo doesn't exist"
  fi
fi
}


get_batch_path()
{
if [ -z ${BATCH} ]; then
error "Batch field empty"
else
  echo "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -i | grep "${BATCH}" | awk '{print $2}'`"
fi
}


get_batch_machine()
{
if [ -z ${BATCH} ]; then
error "Batch field empty"
else
  echo "`/home/weblogic/bin/batch/get-batch-info.pl ${ENV} -i | grep "${BATCH}" | awk '{print $3}'`"
fi
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


check_manifest()
{
  FILE=$1
  EXTRACT_DIR=$2

  MANIFEST_LOCATION=`unzip -l ${FILE} | grep -w "META-INF/MANIFEST.MF" | awk '{print($4)}' | awk '{if ($1 ~ /^META-INF/) print}'`

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


  if [ -z ${PWD} ]; then
    echo UNABLE_TO_GET_PWD_FROM_WS_DSS_AREA_SEGURANCA
    warning UNABLE TO OBTAIN PASSWORD FOR USER ${USER} 1>&2
  else
    echo ${PWD}
  fi

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

