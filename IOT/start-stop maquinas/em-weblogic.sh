#!/bin/bash
# chkconfig: 2345 91 11
# description: WLS e NM START/STOP

##Source function library.
. /etc/init.d/functions

#set -x

# ENVIRONMENT VARIABLES
RUN_AS_USER=m2miitcdev01admin
DOMAIN_NAME=M2MIITCDEV
ADMIN_SERVER="10.254.3.80"
ADMIN_PORT="7001"
ADMIN_USERNAME=weblogic
ADMIN_PASS=welcome1
DOMAIN_LOC=/app/vodafone/dat/dmn/M2MIITCDEV/
NM_LOC=/app/vodafone/env/fmw/wlserver_10.3/server/bin/
JAVA_LOC=/app/vodafone/env/jdk1.7.0_79/bin/java
JAR_LOC=/app/vodafone/env/fmw/wlserver_10.3/server/lib/weblogic.jar
###########################################################################
# WLS VARIABLES
T3="t3://$ADMIN_SERVER:$ADMIN_PORT"
RESTART_LOC=$DOMAIN_LOC/bin/restart.py
START_ADMIN=$DOMAIN_LOC/bin/startWebLogic.sh
STOP_ADMIN=$DOMAIN_LOC/bin/stopWebLogic.sh
LOG_ADMIN=$DOMAIN_LOC/nohup.out
# NM VARIABLES
NM_START=$NM_LOC/startNodeManager.sh
NM_LOG=$NM_LOC/nohup.out

USER=`whoami`


start() {
        ################################## NODEMANAGER ##################################
        PID_NM=`ps -ef | grep "weblogic.NodeManager" | grep -v grep | awk '{print $2}'`
        if [[ -n "$PID_NM" ]]
        then
                echo "WLS Node Manager is running with PID:" $PID_NM
        else
                echo "Starting WLS Node Manager..."
                if [ "$USER" != "$RUN_AS_USER" ];
                then
                        su - $RUN_AS_USER -c "$NM_START >> $NM_LOG 2>&1 &"
                        sleep 5
                        echo "WLS Node Manager Started."
                else
                        . $NM_START >> $NM_LOG 2>&1 &
                        sleep 5
                        echo "WLS Node Manager Started."
                fi
        fi
        ################################## ADMIN SERVER ##################################
        PID_WLS=`ps -ef | grep $DOMAIN_NAME | grep -v grep | awk '{print $2}'`
        if [[ -n "$PID_WLS" ]]
        then
                echo "WLS is running with PID:" $PID_WLS
        else
                echo "Waiting to Start WLS."
                echo "" > $LOG_ADMIN
                if [ "$USER" != "$RUN_AS_USER" ];
                then
                        su - $RUN_AS_USER -c "$START_ADMIN >> $LOG_ADMIN 2>&1 &"
                        sleep 10
                        while [ `less $LOG_ADMIN |grep "Server started in RUNNING mode." |wc -l` -ne 1 ]
                        do
                                echo -ne "."
                                sleep 10
                        done
                        echo ""
                        echo "WLS is Running."
                else
                        . $START_ADMIN >> $LOG_ADMIN 2>&1 &
                        sleep 10
                        while [ `less $LOG_ADMIN |grep "Server started in RUNNING mode." |wc -l` -ne 1 ]
                        do
                                echo -ne "."
                                sleep 10
                        done
                        echo ""
                        echo "WLS is Running."
                fi
        fi
        ################################## WEBLOGIC SERVERS ##################################
        if [ "$USER" != "$RUN_AS_USER" ];
        then
                su - $RUN_AS_USER -c "$JAVA_LOC -cp .:$CLASSPATH:$JAR_LOC weblogic.WLST $RESTART_LOC $T3 $ADMIN_USERNAME $ADMIN_PASS APP_Server start"
                su - $RUN_AS_USER -c "$JAVA_LOC -cp .:$CLASSPATH:$JAR_LOC weblogic.WLST $RESTART_LOC $T3 $ADMIN_USERNAME $ADMIN_PASS PRL_Server start"
                su - $RUN_AS_USER -c "$JAVA_LOC -cp .:$CLASSPATH:$JAR_LOC weblogic.WLST $RESTART_LOC $T3 $ADMIN_USERNAME $ADMIN_PASS PRT_Server start"
        else
                $JAVA_LOC -cp .:$CLASSPATH:$JAR_LOC weblogic.WLST $RESTART_LOC $T3 $ADMIN_USERNAME $ADMIN_PASS APP_Server start
                $JAVA_LOC -cp .:$CLASSPATH:$JAR_LOC weblogic.WLST $RESTART_LOC $T3 $ADMIN_USERNAME $ADMIN_PASS PRL_Server start
                $JAVA_LOC -cp .:$CLASSPATH:$JAR_LOC weblogic.WLST $RESTART_LOC $T3 $ADMIN_USERNAME $ADMIN_PASS PRT_Server start
        fi
}
stop() {
        ################################## WLS STOP ##################################
        PID_WLS=`ps -ef | grep $DOMAIN_NAME | grep -v grep | awk '{print $2}'`
        if [[ -n "$PID_WLS" ]]
        then
                echo "Stopping WLS with PID:" $PID_WLS
                kill -9 $PID_WLS
                echo "WLS Stopped."
        else
                echo "WLS is not running."
        fi
        ################################## NODEMANAGER ##################################
        PID_NM=`ps -ef | grep "weblogic.NodeManager" | grep -v grep | awk '{print $2}'`
        if [[ -n "$PID_NM" ]]
        then
                echo "Stopping WLS NodeManager currently running with PID:" $PID_NM
                kill -9 $PID_NM
                echo "WLS NodeManager Stopped."
        else
                echo "WLS NodeManager is NOT running."
        fi
}

status(){
       PID_NM=`ps -ef | grep "weblogic.NodeManager" | grep -v grep | awk '{print $2}'`
       if [ -n "$PID_NM" ]; then
          echo "WLS NodeManager is running with pid:" $PID_NM
       else
          echo "WLS NodeManager is NOT running."
       fi

       PID_WLS=`ps -ef | grep $DOMAIN_NAME | grep -v grep | awk '{print $2}'`
       if [ -n "$PID_WLS" ]; then
          echo "WLS is running with pid:" $PID_WLS
       else
          echo "WLS is NOT running."
       fi
}

case "$1" in
        start)
                start &
        ;;
        stop)
                stop &
        ;;
        status)
                status
        ;;
        *)
                echo "Usage: $0 {start|stop|status}"
esac

exit 0

