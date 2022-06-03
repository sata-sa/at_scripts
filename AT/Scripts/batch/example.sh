#!/bin/sh
#set -x

. /home/weblogic/bin/batch/batch-common-env.sh

ARGNUM=$#
TRANSACTION="TESTE $1"
AREA=$2
BATCH=$3
MACHINE=$4
NUCLEO=$5

BATCH_PATH="NULL"
BATCH_MACHINE="NULL"


###################
# Local Functions #
###################

usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME>

  ENVIRONMENT           - The environment where the application exists. Available options are: prd/qua/dev
  batatas e cenourinhas - sopa

EOF
}


#################
# Inital checks #
#################
start_arg_checks()
{
if [ "${USER}" != "weblogic" ]; then
  error "User must be weblogic."
fi

if [ ${ARGNUM} != 5 ]; then
  fail "Numero de argumentos errado!!!"
  usage
  exit 1
fi

}

########
# CODE #
########

start_arg_checks
check_env $1

check_area_t
check_batch_t
check_machine_t
check_nucleo_t


BATCH_PATH=`get_batch_path`
BATCH_MACHINE=`get_batch_machine`

echo "$BATCH_PATH by $0"
echo "$BATCH_MACHINE by $0"
