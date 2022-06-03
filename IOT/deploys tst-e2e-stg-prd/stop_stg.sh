#!/bin/bash

source /var/SP/nfs/common/deployments/DeploymentScripts/DeployComponents/variables_STG.sh

> $check_file
> $output_log
echo "0" > $check_file
echo " " > $output_log


stop_app_1(){
out_info "STOP of APP01 server in APP domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$app_admin $app_username $app_pass $app1_target stop >> $output_log #Stop APP01 Server
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of APP01 server in APP domain failed, check log."
else
        out_info "STOP of APP01 server in APP domain done."
fi
}

stop_app_2(){
out_info "STOP of APP02 server in APP domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$app_admin $app_username $app_pass $app2_target stop >> $output_log #Stop APP02 Server
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of APP02 server in APP domain failed, check log."
else
        out_info "STOP of APP02 server in APP domain done."
fi
}

stop_auth_portlet_1(){
out_info "STOP of PORTLET01 server in AUTH domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portlet1_target stop >> $output_log #Stop Portlet AUTH01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTLET01 server in AUTH domain failed, check log."
else
        out_info "STOP of PORTLET01 server in AUTH domain done."
fi
}

stop_auth_portlet_2(){
out_info "STOP of PORTLET02 server in AUTH domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portlet2_target stop >> $output_log #Stop Portlet AUTH02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTLET02 server in AUTH domain failed, check log."
else
        out_info "STOP of PORTLET02 server in AUTH domain done."
fi
}

stop_auth_portal_1(){
out_info "STOP of PORTAL01 server in AUTH domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portal1_target stop >> $output_log #Stop Portal AUTH01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTAL01 server in AUTH domain failed, check log."
else
        out_info "STOP of PORTAL01 server in AUTH domain done."
fi
}


stop_auth_portal_2(){
out_info "STOP of PORTAL01 server in AUTH domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portal2_target stop >> $output_log #Stop Portal AUTH02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTAL02 server in AUTH domain failed, check log."
else
        out_info "STOP of PORTAL02 server in AUTH domain done."
fi
}

stop_cus_portlet_1(){
out_info "STOP of PORTLET01 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portlet1_target stop >> $output_log #Stop Portlet CUS01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTLET01 server in CUS domain failed, check log."
else
        out_info "STOP of PORTLET01 server in CUS domain done."
fi
}

stop_cus_portlet_2(){
out_info "STOP of PORTLET02 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portlet2_target stop >> $output_log #Stop Portlet CUS02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTLET02 server in CUS domain failed, check log."
else
        out_info "STOP of PORTLET02 server in CUS domain done."
fi
}

stop_cus_portal_1(){
out_info "STOP of PORTAL01 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portal1_target stop >> $output_log #Stop Portal CUS01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTAL01 server in CUS domain failed, check log."
else
        out_info "STOP of PORTAL01 server in CUS domain done."
fi
}

stop_cus_portal_2(){
out_info "STOP of PORTAL02 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portal2_target stop >> $output_log #Stop Portal CUS02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "STOP of PORTAL02 server in CUS domain failed, check log."
else
        out_info "STOP of PORTAL02 server in CUS domain done."
fi
}


## MAIN BLOCK ##

stop_app_1 &
stop_app_2 &
stop_auth_portlet_1 &
stop_auth_portlet_2 &
stop_auth_portal_1 &
stop_auth_portal_2 &
stop_cus_portlet_1 &
stop_cus_portlet_2 &
stop_cus_portal_1 &
stop_cus_portal_2 &

wait

if [ $(cat $check_file) == 0 ]; then
        out_ok "ALL SERVERS STOPPED"
else
        out_failure "Unable to stop all servers!!"
fi

echo ""
echo "For more info check " $output_log
echo ""