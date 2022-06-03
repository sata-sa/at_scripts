#!/bin/bash
#@Luis_Mangerico
#List Ports DEV 

. /home/weblogic/bin/common_env.sh

#set -x

user="weblogic";
#hosts=$(cat Hosts_list)

get_date=$(date +"_%d-%m-%y")
password1=$(echo 'NWFyZGE1Cg==' | base64 -d -i)

TestPing () {
warning "Insert Environment (PRD/QUA/DEV)"
read env;
env1=`echo $env | tr [A-Z] [a-z]`
  if [ "${env1}" != "prd" -a "${env1}" != "qua" -a "${env1}" != "dev" -a "${env1}" ]; then
      failure "Unrecognized environment"
  fi
warning "Insert HostName:"
read hosts;
lista=`get-env-info.pl $env | grep $hosts | awk -F: '{print $2}'|wc -l`
#echo $lista
for i in $hosts;
do
if [ "$(ping -q -c1 "$i")" ];
then echo "Host '$i' Reachable"; 
sshpass -p $password1 scp /home/weblogic/Host_scripts/ListarPortos/DEV/listarDEV.sh weblogic@$hosts:/tmp 
###################
echo "";
inputuser "___________Begin_'$i'___________";
#sleep 1;
#warning "Insert Root Password for Machine $i :"
#read password2;
#unset password;
#while IFS= read -r -s -n1 pass; do
#  if [[ -z $pass ]]; then
#    echo
#     break
#  else
#     echo -n '*'
#    password+=$pass
#  fi
#done



ScriptCfg;
inputuser "------------>>> $hosts Weblogic Admin USED PORTS <<<------------"
cenas= sshpass -p $password1 ssh $hosts cat /tmp/ports.lst | grep  -i admin  | awk -F"," '{print  $2}' | sort -n| uniq 
sshpass -p $password1 ssh $hosts "rm -f  /tmp/listarDEV.sh  /tmp/ports.lst"
warning "Memory Info"
sshpass -p $password1 ssh $hosts free -m
warning "Disk Info"
echo "                      Size Used Avail Use% Mounted on"
sshpass -p $password1 ssh $hosts df -h |grep -w "/weblogic"
warning "         ----->>> Dont use 0-2000 Port Range (Reserved For System) <<<<-------              "
warning "         ---->>> DEV - Choose a free Port and sum + 100 For AdminServers <<-----            "
warning "         ---->>> QUA - Choose a free Port and sum + 200 For AdminServers <<-----            "
warning "         ---->>> PRD - Choose a free Port and sum + 400 For AdminServers <<-----            "
warning "                                                                                            "
error   "       ---->>> In the Machine: $hosts Exists $lista ->> Consider MAXIMUM VALUE IS 15  <<----"


else echo "Host '$i' Unreachable";fi
done;
}


ScriptCfg(){
inputuser "....Collecting Ports....Please Wait";

sshpass -p $password1 ssh $hosts chmod +x "/tmp/listarDEV.sh"
sshpass -p $password1 ssh $hosts ". /tmp/listarDEV.sh > /tmp/ports.lst"

#spawn ssh -tq $user@$i su - root
#expect -c "
#set timeout 300
#spawn ssh -tq  $user@$i su - root
# expect  "ssword:" { send \"$password\r\"}
# expect  "#" { send \"chmod +x /tmp/listarDEV.sh\r\"}
# expect  "#" { send \". /tmp/listarDEV.sh > /tmp/ports.lst\r\"}
# expect  "#" { send \"chown weblogic: /tmp/ports.lst\r\"}
# expect  "#" { send \"exit\r\"}
#expect eof
#"
}

sleep 1;

Install () {
clear;
inputuser "--->> Collect Weblogic Admin Used Ports in Host ?? <<----";
echo "____________________________________________________________"
echo $hosts 
echo
echo "Confirm script? [y/n]";
read opcao;

case $opcao in

        y) TestPing;;

        n) exit 0;;

        *) echo "Unknown Option."; sleep 1; Install;;

esac

}
Install;
