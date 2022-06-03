#!/bin/bash
# chkconfig: 2345 90 10
# description: APACHE HTTPD Service START/STOP

##Source function library.
. /etc/init.d/functions

#set -x

##
RUN_AS_USER=m2miitcdev01admin
APACHE_LOC=/app/vodafone/env/apache/bin/

## User to run the commands
APACHE_BIN=$APACHE_LOC/apachectl
APACHE_LOG=$APACHE_LOC/output.log
USER=`whoami`


start(){
        APACHE_PID=`pgrep "httpd" | head -1`
        if [[ -n "$APACHE_PID" ]]; then
                echo "HTTPD is already running... PID:" $APACHE_PID
        else
                echo "Starting HTTP. Please standby."
                if [ "$USER" != "$RUN_AS_USER" ]; then
                        su - $RUN_AS_USER -c "$APACHE_BIN start >> $APACHE_LOG 2>&1"
                        APACHE_PID=`ps -fe | grep "httpd" | head -1 | awk '{print $2}'`
                        echo "HTTPD RUNNING. PID:" $APACHE_PID
                else
                        $APACHE_BIN start >> $APACHE_LOG 2>&1
                        APACHE_PID=`ps -fe | grep "httpd" | head -1 | awk '{print $2}'`
                        echo "HTTPD RUNNING. PID:" $APACHE_PID
                fi
        fi
}

stop(){
        APACHE_PID=`pgrep "httpd" | head -1`
        if [[ -n "$APACHE_PID" ]]; then
                echo "Stopping HTTP. Please standby. PID:" $APACHE_PID
                if [ "$USER" != "$RUN_AS_USER" ]; then
                        su - $RUN_AS_USER -c "$APACHE_BIN stop >> $APACHE_LOG 2>&1"
                        echo "HTTPD Stopped."
                else
                        $APACHE_BIN stop >> $APACHE_LOG 2>&1
                        echo "HTTPD Stopped"
                fi
        else
                echo "HTTPD is not running."
        fi
}

status(){
        APACHE_PID=`pgrep "httpd" | head -1`
        if [ -n "$APACHE_PID" ]; then
                echo "HTTPD is running. PID:" $APACHE_PID
        else
                echo "HTTPD is not running."
                exit 1
        fi
}

case "$1" in
        start)
                start
        ;;
        stop)
                stop
        ;;
        status)
                status
        ;;
        *)
                echo "Usage: $0 {start|stop|status}"
esac

exit 0

