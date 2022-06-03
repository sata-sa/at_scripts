#!/bin/bash

source /opt/SP/oracle/home/scripts_TST3/variables_TST3.sh

> $deploy_log
> $WLST_log
> $check_file
echo "0" > $check_file

##FUNCTIONS ##
deploy_app_domain(){
out_info "Starting deploy of $validateapp in app domain"
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $username -p $app_pass -a $app_admin -n $app_name -v $validateapp -f $loc_appear -t $app_target >> $WLST_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $validateapp in app domain."
else
        out_info "Finished deploy of $validateapp in app domain."
fi
}

deploy_cus_domain(){
out_info "Starting deploy of $validateprl in cus domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $username -p $cus_pass -a $cus_admin -n $prl_name -v $validateprl -f $loc_prlear -t $portlet_target >> $WLST_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $validateprl in cus domain."
        exit 1
else
        out_info "Finished deploy of $validateprl in cus domain."
fi

out_info "Starting deploy of $validateres in cus domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $username -p $cus_pass -a $cus_admin -n $res_name -v $validateres -f $loc_reswar -t $portal_target >> $WLST_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $validateres in cus domain."
        exit 1
else
        out_info "Finished deploy of $validateres in cus domain."
fi

out_info "Starting deploy of $validatescp in cus domain."
$loc_java -cp .:$CLASSPATH:$loc_weblogic weblogic.WLST $loc_deployer -u $username -p $cus_pass -a $cus_admin -n $fo_name -v $validatescp -f $loc_scpear -t $portal_target >> $WLST_log
if [ $? != 0  ]; then
        echo "1" > $check_file
        out_failure "Unable to deploy $validatescp in cus domain."
else
        out_info "Finished deploy of $validatescp in cus domain."
fi
}

## MAIN BLOCK ##
deploy_app_domain &
deploy_cus_domain &
wait

if [ $(cat $check_file) == 0 ]; then
        out_ok "ALL artefacts have been deployed"
else
        out_failure "Unable to deploy all artefacts!!"
fi

echo ""
echo "For more info check "$WLST_log
echo ""
