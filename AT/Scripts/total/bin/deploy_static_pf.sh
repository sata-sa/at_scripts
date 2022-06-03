#!/bin/bash
# Script para copiar estático para a suhttp301
##set -x
# Bruno Correia 2011/10/21
#Luis Mangerico
#set -x

#. ${HOME}/bin/common_env.sh
. /home/weblogic/bin/common_env.sh

#"${y,,}"


RED='\e[1;31m'
GREEN='\e[0;32m'
NC='\e[0m'
ENV=`echo $1 | tr [A-Z] [a-z]`
ARGNUM=$#
APPLICATION_NAME=`echo $2 | tr [A-Z] [a-z]`
APPFILE=`echo $3 | tr [A-Z] [a-z]`
#APP_BD= `'/home/weblogic/bin/get-env-info.pl' $ENV -applications ${|grep}  $APPLICATION_NAME`
#@Luis Mangerico
#APPSCONTENTFILEQUA="/httpd/data/suhttp301/pfstatic.stinternetqua.ritta.local/public_html"
DIRSTATICPRD1="/httpd/data/sulhttpstatic101/pfstatic.stinternet.ritta.local/public_html"
DIRSTATICPRD2="/httpd/data/sulhttpstatic102/pfstatic.stinternet.ritta.local/public_html"
DIRSTATICQUA="/httpd/data/suhttp301/pfstatic.stinternetqua.ritta.local/public_html"
HOSTPRD1="sulhttpstatic101.ritta.local"
HOSTPRD2="sulhttpstatic102.ritta.local"
HOSTQUA="suhttp301.ritta.local"
TMPDIR="/tmp/$APPLICATION_NAME"
FILEEXT=`echo $3 |awk -F "." '{print $NF}'`
#FILEEXT=`echo $3 |awk -F "." '{print $2}'`

usage()
{
cat << EOF 
USAGE: $0 <ENVIRONMENT> <APPLICATION_NAME> <FILE_*.zip> 

  ENVIRONMENT        - The environment where the application exists: PRD/QUA
  APPLICATION NAME   - The name of the new application to deploy
  pfstatic-*.zip     - The list of files to deploy for the new application
EOF
}



start_arg_checks()
{
LSFILE1=`ls $APPFILE` 

  # Check username
  if [ "${USER}" != "weblogic" ]; then
    echo "User must be weblogic"
  fi

  # Check user parameters
  if [ ${ARGNUM} -lt 3 ]; then
    usage
    exit 0
  fi

  if [ -z "${ENV}" ]; then
    warning "Environment must be specified"
  else
    if [ "${ENV}" != "prd" -a "${ENV}" != "qua" ]; then
     warning "Unrecognized environment"
    fi
  fi

  if [ -z ${APPLICATION_NAME} ]; then
    warning "You must provide your application name"
  fi

  if [ "${APPLICATION_NAME}" != "pfstatic" ]; then
    warning " Unrecognized application; Provide Application Name: pfstatic"
    exit 0
    fi

  if [ "$FILEEXT" != "zip" ]; then
#  if [ "$FILEEXT" != pfstatic*[0-9].zip ]; then
      warning "Unrecognized file, please choose: pfstatic*.zip"
      exit 0
    fi

  if [ -z "$LSFILE1" ]; then
      warning "Unrecognized file"
      exit 0
    fi


  if [ "${ENV}" = "qua" ]; then
      deploy_qua;
    fi
  if [ "${ENV}" = "prd" ]; then
      deploy_prd;
   fi
}



deploy_qua()
{
  LSFILE=`ls $2 2> /dev/null`
  unzip $APPFILE -d $TMPDIR
  cd $TMPDIR
  info "Tem a certeza de que quer substituir o conteudo estático da aplicação $APPLICATION_NAME existente na máquina suhttp301?"
  warning "s/n"
  read ANSWER
  ANSWER=`echo $ANSWER | tr [A-Z] [a-z]`
     if [ $ANSWER == "n" ]; then
        failure  "Cópia cancelada"
        rm -rf $TMPDIR/
        exit 1
     elif [ $ANSWER == "s" ]; then
rsync -ralp -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress  $TMPDIR/* weblogic@$HOSTQUA:$DIRSTATICQUA
           if [ $? -eq 0 ]; then
              rm -rf $TMPDIR/
              info "Conteudo estático copiado com sucesso para: $HOSTQUA $DIRSTATICQUA"
           else
              failure "Não foi possivel copiar o conteudo estático"
              rm -rf $TMPDIR/
           fi
     else
        warning  "Opção inválida"
        rm -rf $TMPDIR/
        exit 1
	fi
}


deploy_prd()
{
  LSFILE=`ls $2 2> /dev/null`
  unzip $APPFILE -d $TMPDIR
  cd $TMPDIR
  info "Tem a certeza de que quer substituir o conteudo estático da aplicação $APPLICATION_NAME existente nas maquinas $HOSTPRD1 e $HOSTPRD2?"
  warning "s/n"
  read ANSWER 
  ANSWER=`echo $ANSWER | tr [A-Z] [a-z]`
     if [ ${ANSWER} == "n" ]; then
        failure "Cópia cancelada"
        rm -rf $TMPDIR/
        exit 1
     elif [ ${ANSWER} == "s" ]; then
rsync -ralp -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress  $TMPDIR/* weblogic@$HOSTPRD1:$DIRSTATICPRD1
rsync -ralp -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress  $TMPDIR/* weblogic@$HOSTPRD2:$DIRSTATICPRD2

           if [ $? -eq 0 ]; then
              rm -rf $TMPDIR/
              info "Conteudo estático copiado com sucesso para $HOSTPRD1 -->  $DIRSTATICPRD1"
              info "Conteudo estático copiado com sucesso para $HOSTPRD2 -->  $DIRSTATICPRD2"
           else
              failure "Não foi possivel copiar o conteudo estático."
              rm -rf $TMPDIR/
           fi
     else
        failure "Opção inválida."
        rm -rf $TMPDIR/
        exit 1
     fi
}
start_arg_checks
