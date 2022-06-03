#!/bin/bash

. ${HOME}/bin/common_env.sh

ARGNUM=$#
ENV=`echo $1 | tr [A-Z] [a-z]`
OPERATION=$2
OPTION=$3
VALUE=$4
TRANSACTION="LOGS_MANAGEMENT(${ENV}:${OPERATION})"
JOBID=${RANDOM}

#####################
# Usage information #
#####################
usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <OPERATION> [OPTION (VALUE)]

  Operation

    -list        : Displays list of logs to be processed

    -process     : Start processing rules

    -list-rules  : Displays rules defined in the database

    -add-rule    : Add new rule to database
                   Format: domain/application name,relative path,depth,log pattern,retention period,action,bck machine,bck user,bck password,bck path

    -delete-rule : Delete rule from database

  Options

    -id          : Rule identifier
    -name        : Domain/Application name

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
    if [ "${ENV}" != "prd" -a "${ENV}" != "qua" -a "${ENV}" != "dev" ]; then
      failure "Unrecognized environment ${ENV}"
    fi
  fi

  if [ -z "${OPERATION}" ]; then
    failure "Operation must be specified"
  else
    if [ "${OPERATION}" != "-list" -a "${OPERATION}" != "-process" -a "${OPERATION}" != "-list-rules" -a "${OPERATION}" != "-add-rule" -a "${OPERATION}" != "-delete-rule" ]; then
      failure "Unrecognized operation ${OPERATION}"
    fi
  fi

  if [ "${OPTION}" == "-id" ]; then
    if [ -z "${VALUE}" ]; then
      failure "Value must be specified if option is used"
    fi
  fi
}

############################
# Start processing entries #
############################
start_processing()
{
  if [ ! -z ${OPTION} ]; then
    if [ "${OPTION}" == "-id" ]; then
      #Check if VALUE only contains valid characters
      if [ ! -z "${VALUE}" ] && [ -z "`echo \"${VALUE}\" | tr -d '[0-9-,]'`" ]; then
        #Check if valid characters are being used correctly
        if [ `echo ${#VALUE}` -gt 0 ] && [ -z "`echo \"${VALUE}\" | tr -d '[0-9]'`" ]; then
          LOG_ENTRY_DETAILS="`get-env-info.pl ${ENV} -logs-management | grep -w "LM:${VALUE}"`"

          if [ -z "${LOG_ENTRY_DETAILS}" ]; then
            failure "Rule id ${VALUE} not found in database"
          fi
        else
          RANGE_TEST="`echo ${VALUE} | tr -d [0-9] | sed 's/[-,]//'`"
          if [ -z "${RANGE_TEST}" ]; then
            RANGE_TEST="`echo ${VALUE} | sed 's/[-,]/ /'`"
            if [ ! -z "`echo \"${RANGE_TEST}\" | cut -d ' ' -f 1`" ]; then
              if [ ! -z "`echo \"${RANGE_TEST}\" | cut -d ' ' -f 2`" ]; then
                RANGE="`echo ${VALUE} | sed 's/-/../'`"
                for id in $(eval echo "{${RANGE}}")
                do
                  LOG_ENTRY_DETAILS="${LOG_ENTRY_DETAILS}\n`get-env-info.pl ${ENV} -logs-management | grep -w "LM:${id}"`"
                done
              else
                failure "Invalid id range"
              fi
            else
              failure "Invalid id range"
            fi
          else
            failure "Invalid id range"
          fi
        fi
      else
        failure "Invalid id range"
      fi
    elif [ "${OPTION}" == "-name" ]; then
      if [ ! -z "${VALUE}" ]; then
        RANGE="`echo ${VALUE} | sed 's/,/ /g'`"

        for name in ${RANGE}
        do
          LOG_ENTRY_DETAILS="${LOG_ENTRY_DETAILS}\n`get-env-info.pl ${ENV} -logs-management | grep -w "${name}"`"
        done
      fi
    fi
  else
    if [ "${OPERATION}" == "-list" -o "${OPERATION}" == "-process" ]; then
      LOG_ENTRY_DETAILS="`get-env-info.pl ${ENV} -logs-management`"
    fi
  fi

  if [ "${OPERATION}" == "-list" ]; then
    create_log_path_list
    list_logs
  elif [ "${OPERATION}" == "-process" ]; then
    create_log_path_list
    process_logs
  elif [ "${OPERATION}" == "-list-rules" ]; then
    list_rules
  elif [ "${OPERATION}" == "-add-rule" ]; then
    add-rule
  elif [ "${OPERATION}" == "-delete-rule" ]; then
    delete-rule
  fi
}

#######################################################################
# Create list of machines and root path for the rules being processed #
#######################################################################
create_log_path_list()
{
  for entry in `echo -e "${LOG_ENTRY_DETAILS}"`
  do
    DOMAIN_APP_NAME="`echo "${entry}" | cut -d\: -f 3`"
    DOMAIN_APP_DETAILS="`get-env-info.pl ${ENV} ${DOMAIN_APP_NAME}`"
    ENTRY_TYPE="`echo ${DOMAIN_APP_DETAILS} | cut -d\: -f 1`"
    RULE_ID="`echo ${entry} | cut -d\: -f 2`"

    if [ "${ENTRY_TYPE}" == "D" ]; then
      HOST="`echo ${DOMAIN_APP_DETAILS} | cut -d\: -f 5`"
      ROOT_PATH="`echo ${DOMAIN_APP_DETAILS} | cut -d\: -f 9`"
      LOG_PATH_LIST="${RULE_ID}:${HOST}:${ROOT_PATH}\n${LOG_PATH_LIST}"
    elif [ "${ENTRY_TYPE}" == "A" ]; then
      APPLICATION_TARGETS="`list_all_application_targets ${ENV} ${DOMAIN_APP_NAME}`"
      DOMAIN_NAME="`target_domain ${ENV} ${APPLICATION_TARGETS}`"
      WLSERVERS="`list_all_cluster_servers ${ENV} ${DOMAIN_NAME} ${APPLICATION_TARGETS}`"
      ROOT_PATH="`get-env-info.pl ${ENV} ${DOMAIN_NAME} | cut -d\: -f 9`"

      for server in ${WLSERVERS}
      do
        MACHINE_NAME=`get_machine_name ${ENV} ${server}`
        LOG_PATH_LIST="${RULE_ID}:${MACHINE_NAME}:${ROOT_PATH}/servers/${server}\n${LOG_PATH_LIST}"
      done
    else
     failure "Application or domain not found"
    fi
  done

  #Reverse order
  LOG_PATH_LIST="`echo -e "${LOG_PATH_LIST}" | tac`"
}

#############
# List logs #
#############
list_logs()
{
  for entry in `echo -e "${LOG_PATH_LIST}"`
  do
    RULE_ID="`echo ${entry} | cut -d\: -f 1`"
    HOST="`echo ${entry} | cut -d\: -f 2`"
    ROOT_PATH="`echo ${entry} | cut -d\: -f 3`"
    DOMAIN_APP_NAME="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 3`"
    LOG_RELATIVE_PATH="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 4`"
    MAX_DEPTH="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 5`"
    LOG_PATTERN="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 6`"
    RETENTION="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 7`"
    LOG_PATH="${ROOT_PATH}/${LOG_RELATIVE_PATH}"
    OS_TYPE="`ssh ${USER}@${HOST} uname | tr [A-Z] [a-z]`"

    info "Rule id: ${RULE_ID} | Domain/Application name: ${DOMAIN_APP_NAME}"

    if [ "${OS_TYPE}" == "sunos" ]; then
      LOG_LIST=`ssh ${USER}@${HOST} find ${LOG_PATH} -type f -name \"${LOG_PATTERN}\" -mtime +${RETENTION}`
    elif [ "${OS_TYPE}" == "linux" ]; then
      LOG_LIST=`ssh ${USER}@${HOST} find ${LOG_PATH} -type f -name \"${LOG_PATTERN}\" -mtime +${RETENTION} -maxdepth ${MAX_DEPTH}`
    fi

    echo -e "${LOG_LIST}" | sort -n
  done
}

################
# Process logs #
################
process_logs()
{
  for entry in `echo -e "${LOG_PATH_LIST}"`
  do
    RULE_ID="`echo ${entry} | cut -d\: -f 1`"
    HOST="`echo ${entry} | cut -d\: -f 2`"
    ROOT_PATH="`echo ${entry} | cut -d\: -f 3`"
    DOMAIN_APP_NAME="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 3`"
    LOG_RELATIVE_PATH="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 4`"
    MAX_DEPTH="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 5`"
    LOG_PATTERN="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 6`"
    RETENTION="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 7`"
    ACTION="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 8`"
    BCK_HOST="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 9`"
    BCK_USER="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 10`"
    BCK_PATH="`echo -e \"${LOG_ENTRY_DETAILS}\" | grep -w "LM:${RULE_ID}" | cut -d\: -f 12`"
    LOG_PATH="${ROOT_PATH}/${LOG_RELATIVE_PATH}"
    OS_TYPE="`ssh ${USER}@${HOST} uname | tr [A-Z] [a-z]`"

    info "Rule id: ${RULE_ID} | Domain/Application name: ${DOMAIN_APP_NAME}"

    if [ "${OS_TYPE}" == "sunos" ]; then
      LOG_LIST=`ssh ${USER}@${HOST} find ${LOG_PATH} -type f -name \"${LOG_PATTERN}\" -mtime +${RETENTION}`
    elif [ "${OS_TYPE}" == "linux" ]; then
      LOG_LIST=`ssh ${USER}@${HOST} find ${LOG_PATH} -type f -name \"${LOG_PATTERN}\" -mtime +${RETENTION} -maxdepth ${MAX_DEPTH}`
    fi

    for log in ${LOG_LIST}
    do
      case "${ACTION}" in
        "Compress")
          echo compress
          ;;
        "Compress_Move")
          echo "compress and Move"
          ;;
        "Compress_Copy")
          echo "compress and Copy"
          ;;
        "Move")
          echo "Move"
          ;;
        "Copy")
          scp ${USER}@${HOST}:${log} ${BCK_USER}@${BCK_HOST}:${BCK_PATH}
      esac
    done
  done
}

#########################################
# List all rules present inthe database #
#########################################
list_rules()
{
  echo "Rule id | Domain/Application name | Relative path | Log depth | Log pattern | Retention period | Action | Bck machine | Bck user | Bck pass | Bck path"
  get-env-info.pl ${ENV} -logs-management | cut -d \: -f 2- | sed 's/:/ | /g'
}

################################
# Add new rule to the database #
################################
add-rule()
{
  DOMAIN_APP_NAME="`echo ${OPTION} | cut -d\, -f 1`"
  RELATIVE_PATH="`echo ${OPTION} | cut -d\, -f 2`"
  DEPTH="`echo ${OPTION} | cut -d\, -f 3`"
  PATTERN="`echo ${OPTION} | cut -d\, -f 4`"
  RETENTION="`echo ${OPTION} | cut -d\, -f 5`"
  ACTION="`echo ${OPTION} | cut -d\, -f 6`"
  BCK_MACHINE="`echo ${OPTION} | cut -d\, -f 7`"
  BCK_USER="`echo ${OPTION} | cut -d\, -f 8`"
  BCK_PASSWORD="`echo ${OPTION} | cut -d\, -f 9`"
  BCK_PATH="`echo ${OPTION} | cut -d\, -f 10`"

  LOG_RULE="`set-env-info.pl ${ENV} -i l,${DOMAIN_APP_NAME},${RELATIVE_PATH},${DEPTH},${PATTERN},${RETENTION},${ACTION},${BCK_MACHINE},${BCK_USER},${BCK_PASSWORD},${BCK_PATH}`"

  if [ "`echo ${LOG_RULE} | cut -d\: -f 1`" == "Log rule id" ]; then
    info "Added new rule to database with id `echo ${LOG_RULE} | cut -d\: -f 2 | tr -d ' '`"
    info "Domain / Application name : ${DOMAIN_APP_NAME}"
    info "Relative path : ${RELATIVE_PATH}"
    info "Log depth : ${DEPTH}"
    info "Log pattern : ${PATTERN}"
    info "Retention period : ${RETENTION}"
    info "Action : ${ACTION}"
    info "Backup machine : ${BCK_MACHINE}"
    info "Backup user : ${BCK_USER}"
    info "Backup password : ${BCK_PASSWORD}"
    info "Backup path : ${BCK_PATH}"
  else
    failure "Unable to add new rule to database"
  fi
}

##################################
# Remove rules from the database #
##################################
delete-rule()
{
  if [ "${OPTION}" != "-id" ]; then
    failure "-id must be specified when deleting rules"
  else
    for entry in `echo -e "${LOG_ENTRY_DETAILS}"`
    do
      RULEID="`echo ${entry} | cut -d\: -f 2`"

      if [ ! -z "${RULEID}" ]; then
        set-env-info.pl ${ENV} -d l,${RULEID}
      fi
    done
  fi
}

########################
#                      #
# MAIN EXECUTION BLOCK #
#                      #
########################
start_arg_checks
start_processing
