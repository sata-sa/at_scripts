#!/bin/bash

source /opt/SP/oracle/home/scripts_TST3/variables_TST3.sh

> $deploy_log
> $WLST_log
> $check_file
echo "0" > $check_file

##FUNCTIONS
start_all(){
out_info "START of APP launched."
#$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$app_admin $username $app_pass $app_target start >> $WLST_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to start the APP Server."
        return 1
else
        out_info "APP Server started."
fi


out_info "START of PORTLET launched."
#$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $username $cus_pass $portlet_target start >> $WLST_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to start the PORTLET Server."
        return 1
else
        out_info "PORTLET Server started."
fi



out_info "START of PORTAL launched."
#$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $username $cus_pass $portal_target start >> $WLST_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to start the PORTAL Server."
        return 1
else
        out_info "PORTAL Server started."
fi
}

## MAIN BLOCK ##
start_all

if [ $(cat $check_file) == 0 ]; then
        out_ok "ALL servers have started"
else
        out_failure "Unable to start all servers!!"
fi

echo ""
echo "For more info check "$WLST_log
echo ""
