#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
APPLICATION=$2
VIRTUALHOST=$3
FRONTEND=$4
#ENTERPRISE=$5
ENTERPRISE=`echo $5 | tr [A-Z] [a-z]`
#CHKATAUTH=$6
CHKATAUTH=`echo $6 | tr [a-z] [A-Z]`
#CHKPFVIEW=$7
CHKPFVIEW=`echo $7 | tr [a-z] [A-Z]`
AREA=`echo $8 | tr [a-z] [A-Z]`
TRANSACTION="APPLICATION_ADD(${APPLICATION})"
JOBID=${RANDOM}
VHOST_TEMPLATE="${HOME}/etc/application_add/VHOST.conf"
VHOST_QUA_DEV_TEMPLATE="${HOME}/etc/application_add/VHOST_QUA_DEV.conf"
ALIASES_TEMPLATE="${HOME}/etc/application_add/APPNAME.aliases.conf"
MOD_WL_TEMPLATE="${HOME}/etc/application_add/APPNAME.mod_weblogic.conf"

#########
# Paths #
#########
APP_ADD_PATH="${STAGE_PATH}/tmp/application_add/${APPLICATION}"

#####################
# Usage information #
#####################
usage()
{
  DEFAULT_PRD_FRONTENDS=`get_default_frontends PRD`
  DEFAULT_QUA_FRONTENDS=`get_default_frontends QUA`
  DEFAULT_DEV_FRONTENDS=`get_default_frontends DEV`
  DEFAULT_SANDBOX_FRONTENDS=`get_default_frontends SANDBOX`

cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME> <VIRTUALHOST> [FRONTEND LIST] [DEVELOPMENT TEAM] [ATAUTH] [PFVIEW] [AREA]

  ENVIRONMENT       - The environment where the domain exists. Available options are: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME  - The name of the new application
  VIRTUALHOST       - The virtual host name
  FRONTEND LIST     - The list of frontends that will serve this application.
                      The frontends must be separated by :

                      Default PRD frontends: ${DEFAULT_PRD_FRONTENDS}
                      Default QUA frontends: ${DEFAULT_QUA_FRONTENDS}
                      Default DEV frontends: ${DEFAULT_DEV_FRONTENDS}
                      Default SANDBOX frontends: ${DEFAULT_SANDBOX_FRONTENDS}

  DEVELOPMENT TEAM  - Specifies the name of the development company.
  ATAUTH            - [ENABLE] > If this application will use the ATAuth Library [DISABLE] if not.
  PFVIEW            - [ENABLE] > If this application will use the PFView Library [DISABLE] if not.
  AREA              - Specifies the name of AREA: [NAGC] [ASA] [AGI] [NGD] [NIP] [NIR] [NADW] [NSAI] [NIGC] [NPE] [NCC] [NICF] [PORTALFIN]
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

  if [ -z "${APPLICATION}" ]; then
    failure "Application name must be specified"
  fi

  if [ -z "${VIRTUALHOST}" ]; then
    failure "Virtual host name must be specified"
  fi

  if [ -z "${FRONTEND}" ]; then
    failure "Frontend must be specified"
    #USE_DEFAULT="Y"
  fi
  #@Mangerico
  if [ -z "${ENTERPRISE}" ]; then
    failure "Development company name must be specified"
  fi

  if [ -z "${AREA}" ]; then
    failure "AREA must be specified"
  else

    if [ "${AREA}" != "NAGC"  -a "${AREA}" != "ASA"  -a "${AREA}" != "AGI"   -a "${AREA}" != "NGD" -a  "${AREA}" != "NIP" -a "${AREA}" != "NIR" -a "${AREA}" != "NADW" -a "${AREA}" != "NSAI" -a "${AREA}" != "NIGC" -a "${AREA}" != "NPE" -a "${AREA}" != "NCC" -a "${AREA}" != "NICF" -a "${AREA}" != "PORTALFIN" ]; then
      failure "Unrecognized Area"
   fi
  fi

  if [ -z "${CHKATAUTH}" ]; then
    failure "You should specify whether the application uses the library ATAUTH: ENABLE/DISABLE"
    #USE_DEFAULT="Y"
  elif [[ ${CHKATAUTH} != "ENABLE" && ${CHKATAUTH} != "DISABLE" ]]; then
    failure "You should specify whether the application uses the library ATAUTH: ENABLE/DISABLE"
  fi

  if [ -z "${CHKPFVIEW}" ]; then
    failure "You should specify whether the application uses the library PFVIEW: ENABLE/DISABLE"
    #USE_DEFAULT="Y"
  elif [[ ${CHKPFVIEW} != "ENABLE" && ${CHKPFVIEW} != "DISABLE" ]]; then
    failure "You should specify whether the application uses the library PFVIEW: ENABLE/DISABLE"
  fi
}

##################
# Check database #
##################
check_db()
{
  # Check if application already exists
  #Bruno#
  #if [ "X`get-env-info.pl ${ENV} -applications Details | grep -w ${APPLICATION}`" != "X" ]; then
  #Bruno#
  ### jserras 2014-12-04 assertion was failing because it matched to much ###
  #if [ "X`get-env-info.pl ${ENV} -applications Details | grep ${APPLICATION}:`" != "X" ]; then
  if [ "X`get-env-info.pl ${ENV} -applications Details | grep ^${APPLICATION}:`" != "X" ]; then
  ### jserras ###
    failure "Application ${APPLICATION} already exists"
  fi

  # Check if frontend exists in database
  if [ ! -z "${FRONTEND}" ]; then
    for frontend in `echo "${FRONTEND}" | tr [:] [\ ]`
    do
      DBQUERY=`get-env-info.pl ${ENV} ${frontend}`

      if [ -z "${DBQUERY}" ]; then
        failure "Frontend ${frontend} does not exist in ${ENV} database"
      fi
    done
  else
    # Check if there are any default frontends since no frontends were specified
    for frontend in `get-env-info.pl ${ENV} -frontends`
    do
      if [ "`get-env-info.pl ${ENV} ${frontend} | cut -d\: -f 3`" == "Y" ]; then
        DEFAULT_EXISTS="Y"
        break
      fi
    done

    if [ "${DEFAULT_EXISTS}" != "Y" ]; then
      failure "No virtual hosts defined as default"
    fi
  fi
}

######################
# Create Application #
######################
add_application()
{
  info "Adding application ${APPLICATION} to ${ENV} database"
  if [ ! -z "${FRONTEND}" ]; then
    info "`set-env-info.pl ${ENV} -i a,${APPLICATION},${VIRTUALHOST},,${FRONTEND},DISABLE,2,NOTSET,${ENTERPRISE},${CHKATAUTH},${CHKPFVIEW}`"
  elif [ "${DEFAULT_EXISTS}" == "Y" ]; then
    info "`set-env-info.pl ${ENV} -i a,${APPLICATION},${VIRTUALHOST},,DEFAULT,DISABLE,2,NOTSET,${ENTERPRISE},${CHKATAUTH},${CHKPFVIEW}`"
  fi
}

##########################################
# Copy configuration files for frontends #
##########################################
copy_frontend_files()
{
  if [ ! -z "${FRONTEND}" ]; then
    FRONTEND=`echo ${FRONTEND} | tr [\:] [\ ]`
  else
    for frontend in `get-env-info.pl ${ENV} -frontends`
    do
      if [ "`get-env-info.pl ${ENV} ${frontend} | cut -d\: -f 3`" == "Y" ]; then
        FRONTEND="${FRONTEND} ${frontend}"
      fi
    done
  fi

  info "Using the following frontends: ${FRONTEND}"
  mkdir -p "${APP_ADD_PATH}"

  for frontend in ${FRONTEND}
  do
    # Create global configuration file for application
    if [ "${ENV}" != "prd" ]; then
      sed -e "s/\<VHOST\>/${VIRTUALHOST}/g" -e "s/\<FRONTEND\>/${frontend}/g" ${VHOST_QUA_DEV_TEMPLATE} > "${APP_ADD_PATH}/${VIRTUALHOST}.conf"
    else
      sed -e "s/\<VHOST\>/${VIRTUALHOST}/g" -e "s/\<FRONTEND\>/${frontend}/g" ${VHOST_TEMPLATE} > "${APP_ADD_PATH}/${VIRTUALHOST}.conf"
    fi

    # Create aliases file for application
    sed -e "s/\<VHOST\>/${VIRTUALHOST}/g" -e "s/\<FRONTEND\>/${frontend}/g" -e "s/APPNAME/${APPLICATION}/g" ${ALIASES_TEMPLATE} > "${APP_ADD_PATH}/${APPLICATION}.aliases.conf"

    # scp files to frontend
    info "ssh -n -o StrictHostKeyChecking=no ${USER}@${frontend} \"mkdir -p /httpd/conf/${frontend}/${VIRTUALHOST}\""
    ssh -n -o StrictHostKeyChecking=no ${USER}@${frontend} "mkdir -p /httpd/conf/${frontend}/${VIRTUALHOST}"

    info "scp ${APP_ADD_PATH}/${VIRTUALHOST}.conf ${USER}@${frontend}:/httpd/conf/${frontend}"
    scp "${APP_ADD_PATH}/${VIRTUALHOST}.conf" ${USER}@${frontend}:/httpd/conf/${frontend}/

    info "${APP_ADD_PATH}/${APPLICATION}.aliases.conf ${USER}@${frontend}:/httpd/conf/${frontend}/${VIRTUALHOST}/"
    scp "${APP_ADD_PATH}/${APPLICATION}.aliases.conf" ${USER}@${frontend}:/httpd/conf/${frontend}/${VIRTUALHOST}/
  done

  rm -rf "${APP_ADD_PATH}"
}

check_deployDate()
#@Mangerico
{
NAGC_DATE="Monday;22.00-5.00"
ASA_DATE="Tuesday;05.00-8.00|Wednesday;22.00-5.00"
AGI_DATE="Tuesday;12.30-14.00"
NGD_DATE="Tuesday;22.00-5.00|Thursday;5.00-8.00"
NIP_DATE="Monday;5.00-8.00|Wednesday;12.30-14.00"
NIR_DATE="Wednesday;5.00-8.00"
NADW_DATE="Thursday;12.30-14.00"
NSAI_DATE="Thursday;12.30-14.00"
NIGC_DATE="Monday;22.00-5.00|Thursday;5.00-8.00"
NPE_DATE="Tuesday;22.00-5.00|Friday;5.00-8.00"
NCC_DATE="Monday;5.00-8.00|Thursday;22.00-5.00"
NICF_DATE="Wednesday;5.00-8.00|Friday;5.00-8.00"
PORTAL_DATE="Wednesday;2.00-3.00"

if [ "${ENV}" = "prd" ]; then

##read ENVIRONMENT
case $AREA in
NAGC)
  echo "AREA: NAGC"
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NAGC
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NAGC_DATE
;;
ASA)
  echo "AREA: ASA "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,ASA
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$ASA_DATE
;;
AGI)
  echo "AREA: AGI "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,AGI
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$AGI_DATE
;;
NGD)
  echo "AREA: NGD "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NGD
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NGD_DATE
;;
NIP)
  echo "AREA: NIP "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NIP
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NIP_DATE
;;
NIR)
  echo "AREA: NIR "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NIR
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NIR_DATE
;;
NADW)
  echo "AREA: NADW "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NADW
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NADW_DATE
;;
NSAI)
  echo "AREA: NSAI "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NSAI
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NSAI_DATE
;;
NIGC)
  echo "AREA: NIGC "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NIGC
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NIGC_DATE
;;
NPE)
  echo "AREA: NPE "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NPE
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NPE_DATE
;;
NCC)
  echo "AREA: NCC "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NCC
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NCC_DATE
;;
NICF)
  echo "AREA: NICF "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NICF
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$NICF_DATE
;;
PORTALFIN)
  echo "AREA: NAGC "
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,AREA51,NAGC
/opt/scripts/bin/set-env-info.pl $ENV -u a,$APPLICATION,NOTSET,$PORTAL_DATE
;;
*)
   return 1
esac
else 
echo "Database updated in $ENV"
fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
check_db
add_application
copy_frontend_files
#Mangerico
check_deployDate
info "Operation complete"
exit 0
