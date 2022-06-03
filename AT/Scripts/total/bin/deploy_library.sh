#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
CHKUSER=`echo $USER`
#set -x
#mangerico - update wiki
SSH_IP_ADDRESS=`echo $SSH_CONNECTION|awk '{printf($1)}'`
ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
LIBRARY_NAME=`echo $2 | tr [A-Z] [a-z]`
LIBRARY_ARTEFACT_RAW=$3
if [[ ! -z ${3} ]]; then
   LIBRARY_ARTEFACT=`basename $3`
   LIBRARY_ARTEFACT_NAMECHK=`basename $3 | sed 's/-.*//g' | tr [A-Z] [a-z]`
fi
#LIBRARY_ARTEFACT_NAMECHK=`basename $3 | sed 's/-.*//g' | tr [A-Z] [a-z]`
LIBRARY_NAME_CHK=[atauth:pfview]*[0-9].jar

#####################
#    Check Lock     # 
#####################
SCRIPTNAME=$(basename $0)
PIDFILE="/tmp/${SCRIPTNAME}"

exec 200>${PIDFILE}
flock -n 200 || failure "Deployment script already in use!!!"
PID=$$
echo ${PID} 1>&200

#####################
# Usage information #
#####################
usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <LIBRARY NAME> <FILE>

  ENVIRONMENT        - The environment where the application exists: PRD/QUA/DEV/SANDBOX
  LIBRARY NAME       - The name of the library to deploy
  FILE               - The list of files library to deploy into domains

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
  
  if [ ${ARGNUM} -gt 3 ]; then
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

  if [ -z ${LIBRARY_NAME} ]; then
    failure "You must provide your library name"
  elif [[ ${LIBRARY_NAME} != "atauth" && ${LIBRARY_NAME} != "pfview" ]]; then
    failure "Unrecognized library"
  fi
}

###################################
# Perform library filename checks #
###################################
library_filename_check()
{
   # Check filename nomenclature
   if [[ ${LIBRARY_ARTEFACT} != ${LIBRARY_NAME_CHK} ]];then
      failure "The file name does not respect the nomenclature"
   fi
}

library_match_arg_filename()
{
     # Check 
     if [[ ${LIBRARY_NAME} != ${LIBRARY_ARTEFACT_NAMECHK} ]]; then
          failure "The name of the library to make deployment does not match with the library indicated!!!"
     fi
}


#####################################################
# Create directory for the library and their copies #
#####################################################
create_library_directory_and_their_copy()
{
   # Create version directory
   case ${ENV} in 
   prd)
      info "Este deployment encontra-se definido para as Quartas-Feiras a partir das 2:00 AM em Producao"
      LIBRARY_VERSION=`echo ${LIBRARY_ARTEFACT} | sed 's/.jar//g'` 
      ssh weblogic@suldomaingold101-mgmt.ritta.local mkdir -p /opt/library/portalfin/versions/${LIBRARY_VERSION}
      ssh weblogic@suldomaingold101-mgmt.ritta.local ls /opt/library/portalfin/versions/${LIBRARY_VERSION}/${LIBRARY_ARTEFACT}
      if [ $? -eq 0 ]; then
         inputuser "Library already exist... /opt/library/portalfin/versions/${LIBRARY_VERSION}/${LIBRARY_ARTEFACT} -  Want to replace it? [Y/N]"
         replacelib()
         {
         read REPLACEIT
         REPLACEIT=`echo ${REPLACEIT} | tr [a-z] [A-Z]`
         case ${REPLACEIT} in
         Y)
            scp ${LIBRARY_ARTEFACT_RAW} weblogic@suldomaingold101-mgmt.ritta.local:/opt/library/portalfin/versions/${LIBRARY_VERSION}
            if [ $? -gt 0 ]; then
               failure "An error occurred in the copy of the library."
            fi
         ;;
         N)
            info "Library already exist...so did nothing."
            exit 0
         ;;
         *)
            error "Do not be stupid, Y or N, is simple... Try again..."
            return 1
         esac
         }
         replacelib
         while [ $? -gt 0 ]; do
            replacelib
         done
      else
         scp ${LIBRARY_ARTEFACT_RAW} weblogic@suldomaingold101-mgmt.ritta.local:/opt/library/portalfin/versions/${LIBRARY_VERSION}
         if [ $? -gt 0 ]; then
            failure "An error occurred in the copy of the library."
         fi
      fi
   ;;
   qua)
      LIBRARY_VERSION=`echo ${LIBRARY_ARTEFACT} | sed 's/.jar//g'` 
      ssh weblogic@sudomain301.ritta.local mkdir -p /opt/library/portalfin/versions/${LIBRARY_VERSION}
      ssh weblogic@sudomain301.ritta.local ls /opt/library/portalfin/versions/${LIBRARY_VERSION}/${LIBRARY_ARTEFACT}
      if [ $? -eq 0 ]; then
         inputuser "Library already exist... /opt/library/portalfin/versions/${LIBRARY_VERSION}/${LIBRARY_ARTEFACT} -  Want to replace it? [Y/N]"
         replacelib()
         {
         read REPLACEIT
         REPLACEIT=`echo ${REPLACEIT} | tr [a-z] [A-Z]`
         case ${REPLACEIT} in
         Y)
            scp ${LIBRARY_ARTEFACT_RAW} weblogic@sudomain301.ritta.local:/opt/library/portalfin/versions/${LIBRARY_VERSION}
            if [ $? -gt 0 ]; then
               failure "An error occurred in the copy of the library."
            fi
         ;;
         N)
            info "Library already exist...so did nothing."
            exit 0
         ;;
         *)
            error "Do not be stupid, Y or N, is simple... Try again..."
            return 1
         esac
         }
         replacelib
         while [ $? -gt 0 ]; do
            replacelib
         done
      else
         scp ${LIBRARY_ARTEFACT_RAW} weblogic@sudomain301.ritta.local:/opt/library/portalfin/versions/${LIBRARY_VERSION}
         if [ $? -gt 0 ]; then
            failure "An error occurred in the copy of the library."
         fi
      fi
   ;;
   *)
      echo "Unrecognized environment"
   ;;
   esac
}


#####################################################
# Check which applications use the ATAuth or PFView #
#####################################################
deployment_process_atauth()
{
   #Check Targets with ATAuth ENABLE State

   ATAPPS=(`get-env-info.pl ${ENV} -atauth | grep ENABLE | awk -F: '{print $2}'`)
   info "To proceed with the deployment of the library ${LIBRARY_ARTEFACT} will stop the targets: ${ATAPPS[@]}"
   inputuser "You want proceed? [Y/N]"
   stoptarget()
   {
   read STOPIT
   STOPIT=`echo ${STOPIT} | tr [a-z] [A-Z]`
   case ${STOPIT} in
   Y)
      info "I will stop all clusters that have the flag to enable ${LIBRARY_NAME}"
	#mangerico
      TMPFILECLS="/tmp/tmpcluster.txt"
      # Run in 1º PFAPP
      PFAPP=`get-env-info.pl ${ENV} -cluster pfapp | awk -F: '{print $4}' | tr '\n' ' '`
      echo ${PFAPP} | tr '\n' ' ' >  ${TMPFILECLS}
      TST=`get-env-info.pl ${ENV} -atauth | grep ENABLE | grep -v $PFAPP | awk -F: '{print $2}' | paste -sd " " | tr '\n' ' '`
      echo ${TST} | tr '\n' ' ' >> ${TMPFILECLS}
      ATAUTHCHK=`cat ${TMPFILECLS}  | awk '{gsub(" ","\n");print}'`
      echo $ATAUTHCHK
      DOMAINS=(`echo "${ATAUTHCHK[@]}" | sed 's/Cluster[0-9]*//g' | tr ' ' '\n' | sort -u | tr '\n' ' '`)
      #DOMAINS=(`echo "${ATAUTHCHK[@]}" | sed 's/Cluster[0-9]*//g' | tr ' ' '\n' | tr '\n' ' '`)
      for i in ${DOMAINS[@]}; do
	 CLUSTERSTOP=`grep -o $i"Cluster"[0-9][0-9] ${TMPFILECLS} | paste -sd " "`
         CLUSTERDEPLOY=`grep -o $i"Cluster"[0-9][0-9] ${TMPFILECLS} | paste -sd ","`
         #echo ${CLUSTERSTOP}
         WLHOST=`get-env-info.pl $ENV $i | awk -F: '{print $5}'`
         WLPORT=`get-env-info.pl $ENV $i | awk -F: '{print $6}'`
         WLHOST=${WLHOST}".ritta.local"
         WLPASS=`get-env-info.pl $ENV $i | awk -F: '{print $8}'`
         # Stop Clusters
         "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/stop_cluster.py ${WLHOST} ${WLPORT} ${WLPASS} ${CLUSTERSTOP}
         # Undeploy/Deploy Library
         "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/undeploy_deploy_process.py ${WLHOST} ${WLPORT} ${WLPASS} ${LIBRARY_ARTEFACT_NAMECHK} ${LIBRARY_ARTEFACT_RAW} ${CLUSTERDEPLOY}
         # Start Clusters
         "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/start_cluster.py ${WLHOST} ${WLPORT} ${WLPASS} ${CLUSTERSTOP}
      done
   ;;
   N)
      info "Can not stop the targets just can not do deploy...I will not reverse the library copy..."
      exit 0
   ;;
   *)
      error "Do not be stupid, Y or N, is simple... Try again..."
      return 1
   esac
   }
   stoptarget
      while [ $? -gt 0 ]; do
         stoptarget
      done
}

deployment_process_pfview()
{
   #Check Targets with ATAuth ENABLE State

   PFVIEWAPPS=(`get-env-info.pl ${ENV} -pfview | grep ENABLE | awk -F: '{print $2}'`)
   info "To proceed with the deployment of the library ${LIBRARY_ARTEFACT} will stop the targets: ${PFVIEWAPPS[@]}"

   inputuser "You want proceed? [Y/N]"
   stoptarget()
   {
   read STOPIT
   STOPIT=`echo ${STOPIT} | tr [a-z] [A-Z]`
   case ${STOPIT} in
   Y)
      #echo "Will stop"
      info "I will stop all clusters that have the flag to enable ${LIBRARY_NAME}"
      TMPFILECLS="/tmp/tmpcluster.txt"
      #mangerico
      # Run in 1º PFAPP
      PFAPP=`get-env-info.pl ${ENV} -cluster pfapp | awk -F: '{print $4}' | tr '\n' ' '`
      echo ${PFAPP} | tr '\n' ' ' >  ${TMPFILECLS}
      TST=`get-env-info.pl ${ENV} -pfview | grep ENABLE | grep -v $PFAPP | awk -F: '{print $2}' | paste -sd " " | tr '\n' ' '`
      echo ${TST} | tr '\n' ' ' >> ${TMPFILECLS}
      PFVIEWCHK=`cat ${TMPFILECLS}  | awk '{gsub(" ","\n");print}'`
      echo $PFVIEWCHK 
      #get-env-info.pl ${ENV} -pfview | grep ENABLE | awk -F: '{print $2}' | paste -sd " " > $TMPFILECLS
      DOMAINS=(`echo "${PFVIEWCHK[@]}" | sed 's/Cluster[0-9]*//g' | tr ' ' '\n' | sort -u | tr '\n' ' '`)
      #DOMAINS=(`echo "${PFVIEWCHK[@]}" | sed 's/Cluster[0-9]*//g' | tr ' ' '\n'  | tr '\n' ' '`)
      for i in ${DOMAINS[@]}; do
         CLUSTERSTOP=`grep -o $i"Cluster"[0-9][0-9] ${TMPFILECLS} | paste -sd " "`
         CLUSTERDEPLOY=`grep -o $i"Cluster"[0-9][0-9] ${TMPFILECLS} | paste -sd ","`
      #   echo ${CLUSTERSTOP}
         WLHOST=`get-env-info.pl $ENV $i | awk -F: '{print $5}'`
         WLPORT=`get-env-info.pl $ENV $i | awk -F: '{print $6}'`
         WLHOST=${WLHOST}".ritta.local"
         WLPASS=`get-env-info.pl $ENV $i | awk -F: '{print $8}'`
         # Stop Clusters
         "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/stop_cluster.py ${WLHOST} ${WLPORT} ${WLPASS} ${CLUSTERSTOP}
         # Undeploy/Deploy Library
         "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/undeploy_deploy_process.py ${WLHOST} ${WLPORT} ${WLPASS} ${LIBRARY_ARTEFACT_NAMECHK} ${LIBRARY_ARTEFACT_RAW} ${CLUSTERDEPLOY}
         # Start Clusters
         "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/start_cluster.py ${WLHOST} ${WLPORT} ${WLPASS} ${CLUSTERSTOP}
         #update_mediawiki
      done
   ;;
   N)
      info "Can not stop the targets just can not do deploy...I will not reverse the library copy..."
      exit 0
   ;;
   *)
      #error "Do not be stupid, Y or N, is simple... Try again..."
      error "-.. --- / -. --- - / -... . / ... - ..- .--. .. -.. --..-- / -.-- / --- .-. / -. --..-- / .. ... / ... .. -- .--. .-.. . .-.-.- .-.-.- .-.-.- / - .-. -.-- / .- --. .- .. -. .-.-.- .-.-.- .-.-.-"
      return 1
   esac
   }
   stoptarget
      while [ $? -gt 0 ]; do
         stoptarget
      done
}



#####################################################
# Check which applications use the ATAuth or PFView #
#####################################################
deploy_library()
{
    "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST /home/weblogic/etc/py/undeploy_deploy_process.py ${WLHOST} ${WLPORT} ${WLPASS} ${LIBRARY_ARTEFACT_NAMECHK} ${LIBRARY_ARTEFACT_RAW} ${CLUSTERSTOP}
}

########
# Main #
########
start_arg_checks
library_filename_check
library_match_arg_filename
create_library_directory_and_their_copy
if [[ ${LIBRARY_NAME} == atauth ]]; then
     deployment_process_atauth 
     #mangerico - Update wiki
     wlappdeploys_updatemediawiki.pl $LIBRARY_NAME $LIBRARY_ARTEFACT_RAW   ${SSH_IP_ADDRESS} Sim ${ENV}
else
     deployment_process_pfview
     wlappdeploys_updatemediawiki.pl $LIBRARY_NAME $LIBRARY_ARTEFACT_RAW   ${SSH_IP_ADDRESS} Sim ${ENV}
    
fi
