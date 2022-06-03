#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh 

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
CREATEDATASOURCE_PYTHON_FILE="/home/weblogic/etc/py/create_pool.py"
PINGTOOL="/bin/ping"
NSLOOKUPTOOL="/usr/bin/nslookup"

# Default Variables
CACHESIZE=0
GRIDLINK='n'
DBPROTOCOL='TCP'
ONSSERVERS='NONE'

# Function enviroment selection
getenvir()
{
inputuser "Environment PRD [1]"
inputuser "            QUA [2]"
inputuser "            DEV [3]"
read ENVIRONMENT
case $ENVIRONMENT in
1)
   ENVIRONMENT="prd"
   SUBSYS="PDSN"
;;
2)
   ENVIRONMENT="qua"
   SUBSYS="QDSN"
;;
3)
   ENVIRONMENT="dev"
   SUBSYS="DDSN"
;;
*)
   error "One, Two or Three, just that..."
   return 1
esac
}

getenvir

while [ $? -gt 0 ]; do
   getenvir
done

# Function domain/app and target selection
domtarg()
{
inputuser "Application Name:"
read UDOMAIN
UDOMAIN=`echo $UDOMAIN | tr [:upper:] [:lower:]`
if [ -z $UDOMAIN ]; then
   failure "Domain does not exist!!!"
fi

APNA=$UDOMAIN
DOMAIN=`get-env-info.pl $ENVIRONMENT $UDOMAIN | awk -F: '{print $4}' | sed -e 's/[Cc]luster.*$//g'`
WLHOST=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $5}'`
WLPORT=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $6}'`
WLHOST=$WLHOST".ritta.local"
WLPASS=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $8}'`

CONNTARGET=`list_all_application_targets $ENVIRONMENT $UDOMAIN`
if [ -z $CONNTARGET ]; then
   CONNTARGET=`get-env-info.pl $ENVIRONMENT -servers $UDOMAIN`
fi 
info "Datasource will be associated with" $CONNTARGET

if [ -z $DOMAIN ]; then
   failure "Domain does not exist!!!"
fi
}

domtarg

# Issue just one machine show - Bruno 20160211 - Last Changed
#MACHINE=`list_all_servers_with_clusters_and_machines $ENVIRONMENT $DOMAIN | grep -m 1 $CONNTARGET | awk -F: '{print $4}'`
#
MACHINE=`list_all_servers_with_clusters_and_machines $ENVIRONMENT $DOMAIN | grep $CONNTARGET | awk -F: '{print $4}'`
echo $MACHINE

# Function DBTYPE selection
dbtype()
{
inputuser "Database Type: oracle   [1]"
inputuser "               db2      [2]"
inputuser "               oracleXA [3]"
inputuser "               db2XA    [4]"
read DBTYPE
case $DBTYPE in
1)
   DBORACLET="oracle.jdbc.OracleDriver"
   unset DBDB2T
;;
2)
   DBDB2T="com.ddtek.jdbc.shadow.ShadowDriver"
   unset DBORACLET
;;
3)
   DBORACLET="oracle.jdbc.xa.client.OracleXADataSource"
   unset DBDB2T
;;
4)
   DBDB2T="com.ddtek.jdbc.shadow.ShadowDriver"
   unset DBORACLET
;;
*)
   error "One, Two , Three and Four, please..."
   return 1
esac
}

dbtype
while [ $? -gt 0 ]; do
   dbtype
done

# Function DataSource Name
datasourcename()
{
inputuser "Connection Pool Name:"
read NAME
if [ -z $NAME ]; then
   error "It has not been defined NAME for the DataSource..."
   return 1
elif [[ $NAME == *[/\.\_\\\!\"\\#\$\%\&\/\(\)\=\?\_]* ]]; then
   #NAME=`echo $NAME | sed 's/^.*[\|!"#$%&/()=?_]//g'`
   NAME=`echo $NAME | tr -dc '[:alnum:]\n\r'`
   warning "It is not recommended to use special characters in the name of DataSourcerouce, changed to ${NAME}"
fi
}

datasourcename
while [ $? -gt 0 ]; do
   datasourcename
done

# Function DataSource JNDINAME
datasourcejndi()
{
inputuser "JNDI Name:"
read JNDI
if [ -z $JNDI ]; then
   error "It has not been defined JNDINAME for the DataSource..."
   return 1
fi
}

datasourcejndi
while [ $? -gt 0 ]; do
   datasourcejndi
done

# Function DBPORT Oracle selection
dbportoracle()
{
inputuser "DB Oracle Port: [Default 1521]"
inputuser "                        [1523]"
read DBPORT
case $DBPORT in
1521)
   DBPORT="1521"
;;
1523)
   DBPORT="1523"
;;
'')
   info "Using 1521 port"
   DBPORT="1521"
;;
*)
     info "Não é possível usar esse port."
     return 1
esac
}

# Function DBPORT DB2 selection
dbportdb2()
{
echo "DB2 Port: [1200, 1202, 1201, 1203, 1204] "
read DBPORT
case $DBPORT in
1200)
   DBPORT="1200"
;;
1201)
   DBPORT="1201"
;;
1203)
   DBPORT="1203"
;;
1204)
   DBPORT="1204"
;;
1202)
   DBPORT="1202"
;;
*)
   error "Não é possível usar esse port."
   return 1
esac
}

if [ -z $DBORACLET ]; then
   dbportdb2
   while [ $? -gt 0 ]; do
      dbportdb2
   done
else
   dbportoracle
   while [ $? -gt 0 ]; do
      dbportoracle
   done
fi

# Check DB Host
inputuser "DB Host:"
read DBHOST
if [[ $DBHOST == *.*.*.* ]]; then
   DBHOST=`$NSLOOKUPTOOL $DBHOST | grep ritta.local | awk '{print $4}' | sed 's/.$//g'`
   if [[ -z $DBHOST ]]; then
      failure "Unrecognized host!!!"
   fi
fi
DBHOST=`echo $DBHOST | tr [:upper:] [:lower:]`
if [[ $DBHOST != *ritta.local ]]; then
   DBHOST=$DBHOST".ritta.local"
fi

# Get SID or Service NAME
if [ -z $DBORACLET ]; then
   DBSID="NONAME"
else
   inputuser "Service Name:"
   read DBSID
   DBSID=`echo $DBSID | tr [:lower:] [:upper:]`
fi

# Set JDBCURL to NULL Value
JDBCURL='NONE'


# Check if is a gridlink datasource
if [ ${DBHOST} == "sudm1-scan.ritta.local" ]; then
   if [[ ${MACHINE} == sul* ]]; then
      GRIDLINK='y'
      if [ ${ENVIRONMENT} == "prd" ]; then
         info "Create a GridLink datasource with SDP Protocol..."
         DBPROTOCOL='SDP'
         JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=SDP)(HOST=sudm1db01-ibvip.ritta.local)(PORT=1522))(ADDRESS=(PROTOCOL=SDP)(HOST=sudm1db02-ibvip.ritta.local)(PORT=1522))(ADDRESS=(PROTOCOL=SDP)(HOST=sudm1db03-ibvip.ritta.local)(PORT=1522))(ADDRESS=(PROTOCOL=SDP)(HOST=sudm1db04-ibvip.ritta.local)(PORT=1522)))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         #JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL='${DBPROTOCOL}')(HOST='${DBHOST}')(PORT=1522)))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         ONSSERVERS='sudm1db01-ibvip.ritta.local:6200,sudm1db02-ibvip.ritta.local:6200,sudm1db03-ibvip.ritta.local:6200,sudm1db04-ibvip.ritta.local:6200'
      else
         failure "Exadata is only used in a production environment..."
      fi 
   elif [[ ${MACHINE} == suv* ]]; then
      GRIDLINK='y'
      if [ ${ENVIRONMENT} == "prd" ]; then
         info "Create a GridLink datasource with TCP Protocol directly to SCAN..."
         DBPROTOCOL='TCP'
         JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST='${DBHOST}')))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         ONSSERVERS='sudm1db01.ritta.local:6200,sudm1db02.ritta.local:6200,sudm1db03.ritta.local:6200,sudm1db04.ritta.local:6200'
      else
         failure "Exadata is only used in a production environment..."
      fi
   elif [[ ${MACHINE} != su[v-l]* ]]; then
      GRIDLINK='y'
      if [ ${ENVIRONMENT} == "prd" ]; then
         info "Create a GridLink datasource with TCP Protocol directly to SCAN..."
         DBPROTOCOL='TCP'
         JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST='${DBHOST}')))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         ONSSERVERS='sudm1db01.ritta.local:6200,sudm1db02.ritta.local:6200,sudm1db03.ritta.local:6200,sudm1db04.ritta.local:6200'
      elif [ ${ENVIRONMENT} == "qua" ]; then
         info "Create a GridLink datasource with TCP Protocol directly to SCAN..."
         DBPROTOCOL='TCP'
         JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST='${DBHOST}')))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         ONSSERVERS='sudm1db01.ritta.local:6200,sudm1db02.ritta.local:6200,sudm1db03.ritta.local:6200,sudm1db04.ritta.local:6200'
      else
         failure "Exadata is only used in a production or stating environment..."
      fi
   fi
elif [ ${DBHOST} == "sdm1-scan.ritta.local" ]; then
      if [[ ${MACHINE} == suv* ]]; then
      GRIDLINK='y'
      if [ ${ENVIRONMENT} == "prd" ]; then
         info "Create a GridLink datasource with SDP Protocol..."
         DBPROTOCOL='SDP'
         JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=SDP)(HOST=sdm1db01-ibvip.ritta.local)(PORT=1522))(ADDRESS=(PROTOCOL=SDP)(HOST=sdm1db02-ibvip.ritta.local)(PORT=1522))(ADDRESS=(PROTOCOL=SDP)(HOST=sdm1db03-ibvip.ritta.local)(PORT=1522))(ADDRESS=(PROTOCOL=SDP)(HOST=sdm1db04-ibvip.ritta.local)(PORT=1522)))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         ONSSERVERS='sdm1db01-ibvip.ritta.local:6200,sdm1db02-ibvip.ritta.local:6200,sdm1db03-ibvip.ritta.local:6200,sdm1db04-ibvip.ritta.local:6200'
      else
         failure "Exadata is only used in a production or stating environment..."
      fi
   elif [[ ${MACHINE} == sul* ]]; then
      GRIDLINK='y'
      if [ ${ENVIRONMENT} == "prd" ]; then
         info "Create a GridLink datasource with TCP Protocol directly to SCAN..."
         DBPROTOCOL='TCP'
         JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST='${DBHOST}')))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         ONSSERVERS='sdm1db01.ritta.local:6200,sdm1db02.ritta.local:6200,sdm1db03.ritta.local:6200,sdm1db04.ritta.local:6200'
      else
         failure "Exadata is only used in a production environment..."
      fi
   elif [[ ${MACHINE} != su[v-l]* ]]; then
      GRIDLINK='y'
      if [ ${ENVIRONMENT} == "prd" ]; then
         info "Create a GridLink datasource with TCP Protocol directly to SCAN..."
         DBPROTOCOL='TCP'
         JDBCURL='jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST='${DBHOST}')))(CONNECT_DATA=(SERVICE_NAME='${DBSID}')))'
         ONSSERVERS='sdm1db01.ritta.local:6200,sdm1db02.ritta.local:6200,sdm1db03.ritta.local:6200,sdm1db04.ritta.local:6200'
      else
         failure "Exadata is only used in a production environment..."
      fi
   fi
fi

$PINGTOOL -c 1 -W 5 $DBHOST > /dev/null 2>&1
if [[ $? != 0 ]]; then
   failure "Unknown Host or Destination Unreachable!!!!"
fi

# Read for input username for database
inputuser "DBUSER:"
read DBUSER
DBUSER=`echo $DBUSER | tr [:lower:] [:upper:]`
inputuser "DBPASS:"
read DBPASS

# Function to define GlobalTransactions
glotransaction()
{
inputuser "Support global transactions: (y/n)"
read GLOBALTRANS
case $GLOBALTRANS in
y)
   inputuser "OnePhaseCommit: [1] DEFAULT"
   inputuser "TwoPhaseCommit: [2]"
   read GLOBALTRANS
   case $GLOBALTRANS in
   1)
      GLOBALTRANS='OnePhaseCommit'
   ;;
   2)
      GLOBALTRANS='TwoPhaseCommit'
   ;;
   '')
      GLOBALTRANS='OnePhaseCommit'
   ;;
   *)
      error "Do not be stupid, or is it 1 or 2, is simple... Try again..."
      return 1
   esac
;;
n)
   GLOBALTRANS='None'
;;
*)
   error "y/n"
   return 1
esac
}

glotransaction
while [ $? -gt 0 ]; do
   glotransaction
done

# Function to define INIT SQL
initsqlpara()
{
inputuser "INIT SQL: (y/n)"
read INITSQL
case $INITSQL in
y)
   inputuser "Insert INIT SQL:"
   read INITSQL
;;
n)
   info "Default INIT SQL!!!"
   INITSQL="NONE"
;;
*)
   error "Yes[y] or No[n]"
   return 1
esac
}

initsqlpara
while [ $? -gt 0 ]; do
   initsqlpara
done

#echo $INITSQL

# Function confirm target connection pool deploy
conndomtar()
{
inputuser "You want to add a datasource to the target $CONNTARGET : [y/n]"
read TARGETCONCLUSTER
case $TARGETCONCLUSTER in
y)
   TARGETCONCLUSTER="$CONNTARGET"
;;
n)
   TARGETCONCLUSTER="NONE"
;;
*)
   error "Stop being stupid!!!"
   return 1
esac
}

conndomtar
while [ $? -gt 0 ]; do
   conndomtar
done

# Test connection to DataBase
info "Testing database connection..."
if [[ -z $DBDB2T ]]; then
   "$JAVA_HOME/bin/java" ${JVM_ARGS} utils.dbping ORACLE_THIN ${DBUSER} ${DBPASS} ${DBHOST}":"${DBPORT}"/"${DBSID}
   if [ $? -gt 0 ]; then
      failure "Datasource creation aborted!!!"
   fi
else
   info "Due to technical problems it is not possible to test datasource for DB2!!!"
fi

# Function create datasource
create_datasource()
{
   info "Attempting to create datasource ${NAME}"
   if [ -z $DBORACLET ]; then
      #echo "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${CREATEDATASOURCE_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${NAME} ${JNDI} ${DBHOST} ${DBPORT} ${DBSID} ${DBUSER} ${DBPASS} ${DBDB2T} ${CACHESIZE} ${GLOBALTRANS} "${INITSQL}" ${TARGETCONCLUSTER}
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${CREATEDATASOURCE_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${NAME} ${JNDI} ${DBHOST} ${DBPORT} ${DBSID} ${DBUSER} ${DBPASS} ${DBDB2T} ${CACHESIZE} ${GLOBALTRANS} "${INITSQL}" ${TARGETCONCLUSTER} ${SUBSYS} ${APNA}
   else
      #echo "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${CREATEDATASOURCE_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${NAME} ${JNDI} ${DBHOST} ${DBPORT} ${DBSID} ${DBUSER} ${DBPASS} ${DBORACLET} 10 ${GLOBALTRANS} "${INITSQL}" ${TARGETCONCLUSTER} "NONE" "NONE" ${GRIDLINK} ${DBPROTOCOL} ${ONSSERVERS} ${JDBCURL} ${ENVIRONMENT}
      "$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${CREATEDATASOURCE_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS} ${NAME} ${JNDI} ${DBHOST} ${DBPORT} ${DBSID} ${DBUSER} ${DBPASS} ${DBORACLET} 10 ${GLOBALTRANS} "${INITSQL}" ${TARGETCONCLUSTER} "NONE" "NONE" ${GRIDLINK} ${DBPROTOCOL} ${ONSSERVERS} ${JDBCURL} ${ENVIRONMENT}
   fi
}

create_datasource
if [[ $? == 0 ]]; then
   info "Create another datasource? [y/n]"
   read cont
   case $cont in
   y)
      info "Again..."
      /home/weblogic/bin/create_pool.sh
   ;;
   n)
      info "Done!!!"
      exit 0
   ;;
   *)
      info "Not yet know where the [y] and [n] keys???? DONE"
      exit 0
   esac
fi
