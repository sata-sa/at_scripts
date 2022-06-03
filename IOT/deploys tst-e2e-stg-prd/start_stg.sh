#!/bin/bash

source /var/SP/nfs/common/deployments/DeploymentScripts/DeployComponents/variables_STG.sh

> $check_file
> $output_log
echo "0" > $check_file
echo " " > $output_log

start_app_1(){
out_info "START of APP1 server in APP domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$app_admin $app_username $app_pass $app1_target start >> $output_log          #Start APP01 Server
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START APP1 server in APP domain."
else
        out_info "APP1 server in APP domain started."
fi
}

start_app_2(){
out_info "START of APP2 server in APP domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$app_admin $app_username $app_pass $app2_target start >> $output_log         #Start APP02 Server
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START APP2 server in APP domain."
else
        out_info "APP2 server in APP domain started."
fi
}

start_aut_1(){
out_info "START of PORTLET1 server in AUT domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portlet1_target start >> $output_log             #Start Portlet AUTH01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTLET1 server in AUT domain."
        out_warning "Aborting START of PORTAL1 server in AUT domain."
        exit 1
else
        out_info "PORTLET1 server in AUT domain started."
fi

out_info "START of PORTAL1 server in AUT domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portal1_target start  >> $output_log             #Start Portal AUTH01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTAL1 server in AUT domain."
else
        out_info "PORTAL1 server in AUT domain started."
fi
}

start_aut_2(){
out_info "START of PORTLET2 server in AUT domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portlet2_target start >> $output_log         #Start Portlet AUTH02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTLET2 server in AUT domain."
        out_warning "Aborting START of PORTAL2 server in AUT domain."
        exit 1
else
        out_info "PORTLET2 server in AUT domain started."
fi

out_info "START of PORTAL2 server in AUT domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$aut_admin $aut_username $aut_pass $portal2_target start >> $output_log         #Start Portal AUTH02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTAL2 server in AUT domain."
else
        out_info "PORTAL2 server in AUT domain started."
fi
}

start_cus_1(){
out_info "START of PORTLET1 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portlet1_target start >> $output_log             #Start Portlet CUS01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTLET1 server in CUS domain."
        out_warning "Aborting START of PORTAL1 server in CUS domain."
        exit 1
else
        out_info "PORTLET1 server in CUS domain started."
fi

out_info "START of PORTAL1 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portal1_target start >> $output_log              #Start Portal CUS01
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTAL1 server in CUS domain."
else
        out_info "PORTAL1 server in CUS domain started."
fi
}

start_cus_2(){
out_info "START of PORTLET2 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portlet2_target start >> $output_log         #Start Portlet CUS02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTLET2 server in CUS domain."
        out_warning "Aborting START of PORTAL2 server in CUS domain."
        exit 1
else
        out_info "PORTLET2 server in CUS domain started."
fi

out_info "START of PORTAL2 server in CUS domain launched."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_restart t3://$cus_admin $cus_username $cus_pass $portal2_target start >> $output_log          #Start Portal CUS02
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to START PORTAL2 server in CUS domain."
else
        out_info "PORTAL2 server in CUS domain started."
fi
}


## MAIN BLOCK ##

start_app_1 &
start_app_2 &
wait

if [ $(cat $check_file) == 0 ]; then
        out_ok "All APP servers have been started."

        start_aut_1 &
        start_aut_2 &
        start_cus_1 &
        start_cus_2 &
        wait

        if [ $(cat $check_file) == 0 ]; then
                out_ok "All servers have been started."
        else
                out_warning "Unable to start all servers. Check log and console."
        fi
else
        out_failure "Unable to start all APP servers. Aborting script. Check log and console."
fi

echo ""
echo "For more info check $output_log"
echo ""

