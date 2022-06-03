#bash
#!/bin/sh
#set -x 
#@Luis Mangerico
# Function enviroment selection
COHERENCE_HOME=/opt/weblogic/12.2.1.0/coherence
JAVA_HOME=/opt/java/1.8.0_74
JAVAEXEC=$JAVA_HOME/bin/java
. ${HOME}/bin/common_env.sh
FILENAME="/home/weblogic/Coherence/hosts.lst"
APPFILE=`echo $3 | tr [A-Z] [a-z]`
FILEEXT=`echo $3 |awk -F "." '{print $NF}'`


#FILE=cat "/home/weblogic/Coherence/hosts.lst" |sort|uniq > $FILENAME

getenvir()
{
clear
echo "--------------------"
echo " COHERENCE INFRA    "
echo "--------------------"
echo " Environment PRD [1]"
echo "             QUA [2]"
echo "             DEV [3]"
read -p " #Answer: " ENVIRONMENT
echo "--------------------"
case $ENVIRONMENT in
1)
   ENVIRONMENT="prd"
menu;
;;
2)
   ENVIRONMENT="qua"
menu;
;;
3)
   ENVIRONMENT="dev"
menu;
;;
*)
   echo "One, Two or Three, just that..."
   #return 1
   getenvir;
esac
}
####################

menu()
{
clear
echo " ===================================="
echo " [1] Add Coherence Node"
echo " [2] Remove Coherence Node"
echo " [3] Deploy .JAR"
echo " [4] Check Coherence Status Nodes"
echo " [5] Start/Stop Coherence Nodes"
echo " [6] Add New Application to Coherence"
echo " ===================================="
echo " [0] Return to Main Menu"
echo " [9] Exit"

read -p " #Answer: " COH
case $COH in
1)
add_node;
;;
2)
delete_node;
;;
3)
deploy_jar;
;;
4)
check_status;
;;
5)
start_stop;
;;
6)
add_app;
;;
0)
getenvir;
;;
9)
return 1;
;;
*)
   echo "Choose a valid option"
   return 1
esac
}

deploy_jar()
{
ARGNUM=$#
APPFILE=`echo $3 | tr [A-Z] [a-z]`
LSFILE=`ls $2 2> /dev/null`
LSFILE1=`ls $APPFILE`

APPDIR=/home/weblogic/Coherence/hosts.lst
echo "Under construction"
ssh $MACHINE sed -ie "s/CLASSPATH:$/&$APPFILE/g" 

  info " Do you want to ADD/Substitute .jar: $APPFILE"
  warning "y/n"
  read ANSWER
  ANSWER=`echo $ANSWER | tr [A-Z] [a-z]`
     if [ $ANSWER == "n" ]; then
        failure  "Copy Canceled"
       # rm -rf $TMPDIR/
        exit 1
     elif [ $ANSWER == "y" ]; then
        info " Insert NodeName "
        read NODE
        #NODENAME=`grep -F $NODE $APPDIR | awk '{print $2}'`
	OSNAME=`less  $APPDIR  |grep -F $NODE | awk '{print $1}'`
	rsync -ralp -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" --progress  *.jar weblogic@$OSNAME:$NODE
	sed -ie "s/CLASSPATH:$/&$APPFILE/g"
           if [ $? -eq 0 ]; then
        #      rm -rf $TMPDIR/
              info ".JAR DEPLOYED: $HOST $DIRCOH"
           else
              failure "ERROR"
         #     rm -rf $TMPDIR/
           fi
     else
        warning  "NO SUTCH OPTION"
      #  rm -rf $TMPDIR/
        exit 1
        fi
}




check_status()
{
#machinename=$(cat /home/weblogic/Coherence/hosts.lst |awk '{print $1}')
#nodename=$(cat /home/weblogic/Coherence/hosts.lst |awk '{print $2}')
#ps aux --sort -rss |grep $nodename | awk '{print $4}'

#FILENAME="/home/weblogic/Coherence/hosts.lst"
while read LINE
do
#MACHINE=$(echo "$LINE" | awk '{print $1}'  ) 
MACHINE=$(echo "$LINE" | awk '{print $1}' ) 
NODE=$(echo "$LINE" | awk '{print $2}' )
# caso queira que seja contruido o ficheiro
#cat > /home/weblogic/Coherence/remote-box-commands.bash << EOF
#ps aux --sort -rss |grep -i Coherence  | awk '{print '$4'}'
#EOF

echo "----------MACHINE: $MACHINE  NODENAME:$NODE ------------------------"
echo "  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COM    "
memory=`cat /home/weblogic/Coherence/remote-box-commands.bash | ssh -T weblogic@$MACHINE`
echo " $memory"
echo "--------------------------------------------------------------------"
done < $FILENAME
sleep 3
menu;
}



delete_node()
{
        echo "------------------------------------"       
        echo "Remove/Backup Coherence Cache Server"       
        echo "------------------------------------"       
        read -p " Node Name: " nodename
	echo " Example: CoherenceCacheServer [1-10]"
        read -p " Machine Name: " MACHINE
        ssh weblogic@$MACHINE ls -la /weblogic/$nodename >/dev/null
        if [ $? -eq 0 ]; then
                echo "$nodename exists!"
	        # node=$(echo "$nodename" | awk '{print $2}')
	#echo 'for i in `ps -ef | grep '$nodename' | awk {print $2}`;do echo $i;done' > /home/weblogic/Coherence/testes.sh	


#martelada: VERIFICAR##	
FILEPIDS=/home/weblogic/Coherence/transfer.sh 
FILEBCK=/home/weblogic/Coherence/transfer.sh.bck
cp  $FILEPIDS  $FILEBCK
sed -i "s/coisa/$nodename/g" $FILEPIDS
		
		cat $FILEPIDS | ssh -T weblogic@$MACHINE
		mv $FILEBCK $FILEPIDS
		#ssh weblogic@$MACHINE  `for i in `ps -ef | grep $nodename | awk '{print  \$2}'`;do echo \$i;done`

	        ssh weblogic@$MACHINE mv /weblogic/$nodename /weblogic/$nodename"_offline"
		echo "$nodename is now in offline Mode in $MACHINE"
                exit 1
        else
        echo "$nodename not exists in the $machinename"
	fi
}


#     app=$(echo "$fqdn"  | awk -F"." '{print $1}')


start_stop()
{
        echo "------------------------------------"       
        echo "Start/Stop Coherence Cache Server"       
        echo "------------------------------------" 
	echo "Configured Nodes:"  
	cat /home/weblogic/Coherence/nodes.lst    
        read -p " Node Name: " nodename
        echo " Example: CoherenceCacheServer [1-10]"
        read -p " Machine Name: " MACHINE
        ssh weblogic@$MACHINE egrep -w "$nodename" /weblogic/ >/dev/null
        if [ $? -eq 0 ]; then
                echo "$nodename exists!"
		node='for i in `ps -ef | grep $nodename`'
                ssh weblogic@$MACHINE '$(echo "$node" | awk '{print $2}');do echo" node running in:" $i;done '
                exit 1
        else
        echo "$nodename not exists in the $machinename"
        fi
}





add_node()
{
	echo "--------------------------"	
	echo "Add Coherence Cache Server"	
	echo "--------------------------"	
	echo " Example: CoherenceCacheServer [1-10]"
	read -p " Node Name: " nodename
    	read -p " Machine Name: " MACHINE
	echo "$MACHINE   $nodename" >> $FILENAME
	read -p " Coherence Memory: " machinemem
        echo " Example: CoherenceCacheServer [1-10]"
        ssh weblogic@$MACHINE ls -la /weblogic/$nodename >/dev/null
        if [ $? -eq 0 ]; then
                echo "Coherence exists!"
               exit 1
        else
	ssh weblogic@$MACHINE ls -la  $JAVA_HOME >/dev/null
 	 if [ $? -eq 0 ]; then
                echo "Java Exists!"
                #exi t 1
#	else 
 	ssh weblogic@$MACHINE ls -la  $COHERENCE_HOME >/dev/null
 	 if [ $? -eq 0 ]; then
              echo "Coherence_Home Exists!"
        echo "Creating Coherence Entry in $MACHINE"
	ssh weblogic@$MACHINE mkdir -p /weblogic/$nodename/
    #    scp /home/weblogic/Coherence/*.xml  weblogic@$MACHINE:/weblogic/$nodename/ 
     #   app=$(echo "$fqdn"  | awk -F"." '{print $1}')
     #	set-env-info.pl $ENVIRONMENT -u a,$app,DISABLE,ENABLE

	
cat > /home/weblogic/Coherence/NodeTransfer/$nodename.sh  << EOF  

######################## Coherence: $machinename ############################################
# This will start a cache server
# specify the Coherence installation directory
MEMORY=$machinemem
CONFIG_HOME=/weblogic/$nodename
COHERENCE_HOME=$COHERENCE_HOME
JAVA_HOME=$JAVA_HOME
JAVAEXEC=$JAVAEXEC
JMXPROPERTIES="-Dcom.sun.management.jmxremote -Dtangosol.coherence.management=all -Dtangosol.coherence.management.remote=true"
JAVA_OPTS="-Xms$MEMORY -Xmx$MEMORY -Dtangosol.coherence.distributed.localstorage=true -Dtangosol.coherence.cacheconfig=$CONFIG_HOME/tangosol-cache-config-distributed.xml -Dtangosol.coherence.ttl=1 -Dtangosol.coherence.clusteraddress=224.5.5.5 -Dtangosol.coherence.clusterport=7574 -Dtangosol.coherence.cluster=CoherenceProxyCluster $JMXPROPERTIES -Dtangosol.coherence.extend.enabled=false -Dtangosol.coherence.member=CacheServer1Manage -Dtangosol.coherence.machine=$MACHINE"

#CLASSPATH="$COHERENCE_HOME/lib/coherence.jar:/weblogic/cohDEV/CoherenceScripts/app/coherencesimplewebapp.war"

CLASSPATH=$COHERENCE_HOME/lib/coherence.jar
## em caso de nova app adicionar o .jar com as classes á minha ClassPAth


#$JAVAEXEC -server -showversion $JAVA_OPTS -cp $CLASSPATH com.tangosol.net.DefaultCacheServer $1
$JAVAEXEC -server -showversion -Xms$machinemem -Xmx$machinemem -Dtangosol.coherence.distributed.localstorage=true -Dtangosol.coherence.cacheconfig=/weblogic/$nodename/tangosol-cache-config-distributed.xml -Dtangosol.coherence.ttl=1 -Dtangosol.coherence.clusteraddress=224.5.5.5 -Dtangosol.coherence.clusterport=7574 -Dtangosol.coherence.cluster=CoherenceProxyCluster $JMXPROPERTIES -Dtangosol.coherence.extend.enabled=false -Dtangosol.coherence.member=$nodename -Dtangosol.coherence.machine=$MACHINE -cp $COHERENCE_HOME/lib/coherence.jar  com.tangosol.net.DefaultCacheServer $1



EOF
chmod +x /home/weblogic/Coherence/NodeTransfer/*

scp /home/weblogic/Coherence/NodeTransfer/*.xml  /home/weblogic/Coherence/NodeTransfer/$nodename.sh  weblogic@$MACHINE:/weblogic/$nodename/

ssh $MACHINE "nohup /weblogic/$nodename/$nodename.sh > /dev/null 2>&1 &"


	echo "Created Coherence Entry  in $MACHINE"
        fi
fi
fi

sleep 3;
menu;
}
###############################
set_java_version()
{

    # Check local and remote Java location
    if [ ! -e "${JAVA_HOME}" ]; then
      failure "Java ${JAVA_HOME} not found on `machinename`"
    else
      ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -l ${JAVA_HOME}" &>/dev/null

      if [ $? -gt 0 ]; then
        failure "Java ${JAVA_HOME} not found at ${MACHINE}"
      fi
      JAVA_VERSION="${DEFAULT_JAVA_VERSION}"
    fi
    JAVA_HOME=`cat "${JAVA_LIST}" | grep -w "${JAVA_VERSION}" | cut -d\: -f 2`

    if [ -z "${JAVA_HOME}" ]; then
      failure "Java ${JAVA_VERSION} not present in configuration file"
    else
      # Check local and remote Java location
      if [ ! -e "${JAVA_HOME}" ]; then
        failure "Java ${JAVA_HOME} not found"
      else
        ssh -n -o StrictHostKeyChecking=no ${USER}@${MACHINE} "ls -l ${JAVA_HOME}" &>/dev/null

        if [ $? -gt 0 ]; then
          failure "Java ${JAVA_HOME} not found at ${MACHINE}"
        fi
      fi
    fi

  CLASSPATH="${WL_HOME}/server/lib/weblogic.jar"
  JVM_ARGS="-cp ${CLASSPATH}"
}

##################################
getenvir;
