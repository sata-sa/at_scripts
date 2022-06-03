#set -x

. ${HOME}/bin/common_env.sh 

JAVA_HOME="/opt/java/1.7.0_51"
JVM_ARGS=" -cp /opt/weblogic/12.1.3.0/wlserver/server/lib/weblogic.jar"
GETALLURLDATASOURCE_PYTHON_FILE="/home/weblogic/etc/py/get_url_all_datasources.py"


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
;;
2)
   ENVIRONMENT="qua"
;;
3)
   ENVIRONMENT="dev"
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
read DOMAIN
if [ -z $DOMAIN ]; then
   failure "Domain does not exist!!!"
fi

#APNA=$UDOMAIN
#DOMAIN=`get-env-info.pl $ENVIRONMENT $UDOMAIN | awk -F: '{print $4}' | sed -e 's/[Cc]luster.*$//g'`
WLHOST=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $5}'`
WLPORT=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $6}'`
WLHOST=$WLHOST".ritta.local"
WLPASS=`get-env-info.pl $ENVIRONMENT $DOMAIN | awk -F: '{print $8}'`

if [ -z $DOMAIN ]; then
   failure "Domain does not exist!!!"
fi
}

domtarg


"$JAVA_HOME/bin/java" ${JVM_ARGS} weblogic.WLST ${GETALLURLDATASOURCE_PYTHON_FILE} ${WLHOST} ${WLPORT} ${WLPASS}
