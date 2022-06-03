#!/bin/bash
set -x

source /opt/SP/oracle/home/scripts_TST3/variables_TST3.sh

> $deploy_log
> $WLST_log
> $check_file
echo "0" > $check_file

stop_app () {
out_info "STOP of APP launched."

#$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$app_admin $username $app_pass $app_target stop >> $WLST_log

if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of APP failed, check log."
else
        out_info "STOP of APP done."
fi
}

stop_portlet () {
out_info "STOP of PORTLET lauched."

#$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $username $cus_pass $portlet_target stop >> $WLST_log

if [ $? != 0  ]; then
        echo "1" > /tmp/output_var
        out_failure "STOP of PORTLET failed, check log."
else
        out_info "STOP of PORTLET done."
fi
}

stop_portal () {
out_info "STOP of PORTAL lauched"

#$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $username $cus_pass $portal_target stop >> $WLST_log

if [ $? != 0  ]; then
        echo "1" > /tmp/output_var
        out_failure "STOP of PORTAL failed, check log."
else
        out_info "STOP of PORTAL done."
fi
}


## MAIN BLOCK ##

stop_app &
stop_portlet &
stop_portal &

wait

if [ $(cat $check_file) == 0 ]; then
        out_ok "ALL SERVERS STOPPED"
else
        out_failure "Unable to stop all servers!!"
fi

echo ""
echo "For more info check "$WLST_log
echo ""
