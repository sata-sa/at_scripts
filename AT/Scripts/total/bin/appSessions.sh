#!/bin/bash
set -x

#. /opt/Oracle/wls-12.1.1.0/wlserver_12.1/server/bin/setWLSEnv.sh
. /opt/weblogic/10.3.0.0/wlserver_10.3/server/bin/setWLSEnv.sh
#. /opt/weblogic/10.3.3.0/wlserver_10.3/server/bin/setWLSEnv.sh

SERVERSTATUSCRIPT=${HOME}/etc/py/lixo1.py

java -version 
java weblogic.WLST $SERVERSTATUSCRIPT
