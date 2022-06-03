#!/bin/bash

source /var/SP/nfs/common/deployments/DeploymentScripts/DeployComponents/variables_STG.sh

> $check_file
> $output_log
echo "0" > $check_file
echo " " > $output_log


deploy_app(){
out_info "Starting deploy of $app_name in APP domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $app_username -p $app_pass -a $app_admin -n $app_name -f $loc_appear -t $app_target_cluster >> $output_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $app_name in APP domain."
else
        out_info "Finished deploy of $app_name in APP domain."
fi
}

deploy_aut(){
out_info "Starting deploy of $fo_name in AUT domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $aut_username -p $aut_pass -a $aut_admin -n $fo_name -f $loc_aut_scpear -t $portal_target_cluster >> $output_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $fo_name in AUT domain."
else
        out_info "Finished deploy of $fo_name in AUT domain."
fi

out_info "Starting deploy of $prl_name in AUT domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $aut_username -p $aut_pass -a $aut_admin -n $prl_name -f $loc_aut_prlear -t $portlet_target_cluster >> $output_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $prl_name in AUT domain."
else
        out_info "Finished deploy of $prl_name in AUT domain."
fi

out_info "Starting deploy of $res_name in AUT domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $aut_username -p $aut_pass -a $aut_admin -n $res_name -f $loc_aut_reswar -t $portal_target_cluster >> $output_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $res_name in AUT domain."
else
        out_info "Finished deploy of $res_name in AUT domain."
fi
}
deploy_cus(){
out_info "Starting deploy of $fo_name in CUS domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $cus_username -p $cus_pass -a $cus_admin -n $fo_name -f $loc_scpear -t $portal_target_cluster >> $output_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $fo_name in CUS domain."
else
        out_info "Finished deploy of $fo_name in CUS domain."
fi

out_info "Starting deploy of $prl_name in CUS domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $cus_username -p $cus_pass -a $cus_admin -n $prl_name -f $loc_prlear -t $portlet_target_cluster >> $output_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $prl_name in CUS domain."
else
        out_info "Finished deploy of $prl_name in CUS domain."
fi

out_info "Starting deploy of $res_name in CUS domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $cus_username -p $cus_pass -a $cus_admin -n $res_name -f $loc_reswar -t $portal_target_cluster >> $output_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $res_name in CUS domain."
else
        out_info "Finished deploy of $res_name in CUS domain."
fi
}

## MAIN BLOCK ##
deploy_app &
deploy_aut &
deploy_cus &

wait

if [ $(cat $check_file) == 0 ]; then
        out_ok "ALL artefacts have been deployed"
else
        out_failure "Unable to deploy all artefacts!!"
fi

echo ""
echo "For more info check "$output_log
echo ""


