#!/bin/bash
#set -x

. ${HOME}/bin/common_env.sh

ENV=`echo $1 | tr '[:upper:]' '[:lower:]'`
APP=`echo $2 | tr '[:upper:]' '[:lower:]'`
SLEEP=$3
COUNT=$4
WANTTAKEHEAPDUMP=`echo $5 | tr '[:upper:]' '[:lower:]'`
DIRTIME=`date +%Y%m%d`
THREADDUMPTIME=`date +%HH-%MM-%SS-%N`

usage()
{
cat << EOF
USAGE: $0 <ENVIRONMENT> <APPLICATION NAME> <SNAPSHOT INTERVAL> <NUMBER OF SNAPSHOTS>

  ENVIRONMENT           - The environment where the application exists. Available options are: PRD/QUA/DEV/SANDBOX
  APPLICATION NAME      - The name of the application
  SNAPSHOT INTERVAL     - The interval time in seconds between snapshots <Default 5>
  NUMBER OF SNAPSHOTS   - The number of snapshots to take <Default 3>  
  TAKE A HEAPDUMP??     - Y/N

EOF
}

if [ $# -gt "5" ]; then
   usage
   exit 1
elif [ $# -lt "5" ]; then
   usage
   exit 1
fi

if [ -z $SLEEP ]; then
   SLEEP=5
fi

if [ -z $COUNT ]; then
   COUNT=3
fi

if [[ $APP == *server* ]]; then
   SERVER=`list_all_servers $ENV | grep -i $APP`
   DOMAIN=`echo $APP | sed 's/ser*.*$//'`
   MACHINE=`list_all_servers_with_clusters_and_machines $ENV $DOMAIN | grep $SERVER | awk -F: '{print $1 ":" $4}'`
   CLUSTER=`list_all_servers_with_clusters_and_machines $ENV $DOMAIN | grep -i $SERVER | awk -F: '{print $3}'`
   APPLICATION=`list_all_target_applications $ENV $CLUSTER`

# Function to define take a HeapDump
   heapdump()
   {
      #inputuser "Take a HeapDump: $SERVER? (y/n)"
      #read USERRESPONSE
      #case $USERRESPONSE in
      case $WANTTAKEHEAPDUMP in
         y)
            TAKEHEAPDUMP=1
      ;;
         n)
            TAKEHEAPDUMP=0
      ;;
         *)
            error "y/n"
            return 1
      esac
    }

   heapdump
   while [ $? -gt 0 ]; do
      heapdump
   done

# ThreadDump Cycle
   for vmmachine in ${MACHINE[@]}; do
      COUNTER=0
      SSHMACHINE=`echo $vmmachine | awk -F: '{print $2}'`
      SERVERNAME=`echo $vmmachine | awk -F: '{print $1}'`

      TIME=`date +%Y%m%d_%H%M%S`

# Check if managedserver is running
      JVMPID=`ssh weblogic@$SSHMACHINE".ritta.local" /usr/sbin/lsof /weblogic/$DOMAIN"/servers/"$SERVERNAME/logs/$SERVERNAME.out | grep -m1 java | awk '{print $2}'`
      JDKVERSION=`ssh weblogic@$SSHMACHINE".ritta.local" /usr/sbin/lsof -p $JVMPID | grep /bin/java | awk '{print $9}'`
      JDKVERSION=`dirname $JDKVERSION`
   
      if [ -z $JVMPID ]; then
         warning $SERVERNAME" is not running"
         continue 
      fi
      TAIL_FILE="/weblogic/"$DOMAIN"/servers/"$SERVERNAME"/logs/"$SERVERNAME".out"
      THREADDUMPFILE="/tmp/"$SERVERNAME"_"$TIME".txt"
      TOPFILE="/tmp/"$SERVERNAME"_"$TIME"_top.txt"
      JMAPHEAPFILE="/tmp/"$SERVERNAME"_"$TIME"_jmapheap.txt"

      ssh weblogic@$SSHMACHINE".ritta.local" /usr/bin/tail -f $TAIL_FILE > $THREADDUMPFILE &
      REMOTETAIL_PID=`ssh weblogic@$SSHMACHINE".ritta.local" /bin/ps -ef | /bin/grep "tail" | /bin/grep -m1 $TAIL_FILE | awk '{print $2}'`

# Taking JMAP HEAP

      ssh weblogic@$SSHMACHINE".ritta.local" $JDKVERSION/jmap -heap $JVMPID > $JMAPHEAPFILE
      if [[ TAKEHEAPDUMP -eq "1" ]]; then
         TMPDIRHEAPDUMPFILE=/uploadsonas/tmp_heapdumps_jfr_dontremove/$SERVERNAME-$TIME.bin
         ssh weblogic@$SSHMACHINE".ritta.local" $JDKVERSION/jmap -dump:live,file=$TMPDIRHEAPDUMPFILE $JVMPID
         ssh weblogic@suldeploy101.ritta.local mkdir -p /archive_sonas/dsl_logs/thread_dumps/$APPLICATION/$DIRTIME/$THREADDUMPTIME
         scp weblogic@$SSHMACHINE".ritta.local:"$TMPDIRHEAPDUMPFILE /archive_sonas/dsl_logs/thread_dumps/$APPLICATION/$DIRTIME/$THREADDUMPTIME
         ssh weblogic@$SSHMACHINE".ritta.local" rm $TMPDIRHEAPDUMPFILE
      fi

# Taking threaddumps
      info "A efetuar "$COUNT" dumps com um intervalo de "$SLEEP" segundos ao "$SERVERNAME" da aplicacao "$APP"."
      while [ $COUNTER -le $COUNT ]; do
         ssh weblogic@$SSHMACHINE".ritta.local" /usr/bin/top -b -n 1 -H -p $JVMPID >> $TOPFILE
         ssh weblogic@$SSHMACHINE".ritta.local" /usr/bin/kill -3 $JVMPID
         sleep $SLEEP
         COUNTER=$[$COUNTER+1]
      done

# Kill Remote TAIL PID
      ssh weblogic@$SSHMACHINE".ritta.local" /bin/kill $REMOTETAIL_PID

# Parsing threaddump file

      ssh weblogic@suldeploy101.ritta.local mkdir -p /archive_sonas/dsl_logs/thread_dumps/$APPLICATION/$DIRTIME/$THREADDUMPTIME
      scp $THREADDUMPFILE weblogic@suldeploy101.ritta.local:/archive_sonas/dsl_logs/thread_dumps/$APPLICATION/$DIRTIME/$THREADDUMPTIME
      scp $TOPFILE weblogic@suldeploy101.ritta.local:/archive_sonas/dsl_logs/thread_dumps/$APPLICATION/$DIRTIME/$THREADDUMPTIME
      scp $JMAPHEAPFILE weblogic@suldeploy101.ritta.local:/archive_sonas/dsl_logs/thread_dumps/$APPLICATION/$DIRTIME/$THREADDUMPTIME
# Remove Temporary Files
      rm $THREADDUMPFILE
      rm $TOPFILE

   done
else
# Function to define take a HeapDump
   heapdump()
   {
      #inputuser "Take a HeapDump: $SERVER? (y/n)"
      #read USERRESPONSE
      #case $USERRESPONSE in
      case $WANTTAKEHEAPDUMP in
         y)
            TAKEHEAPDUMP=1
      ;;
         n)
            TAKEHEAPDUMP=0
      ;;
         *)
            error "y/n"
            return 1
      esac
    }

   heapdump
   while [ $? -gt 0 ]; do
      heapdump
   done

# Check Enviroment
   case $ENV in
   dev)
      failure "Debug aplicacional do ambiente de desenvolvimento nao e efetuado pela NSD"
      exit 1
   ;;
   qua)
      ENVVERSION=`get-env-info.pl $ENV $APP | awk -F: '{print $1}'`

      if [ $ENVVERSION == "A" ]; then

# Get cluster
         CLUSTER=`get-env-info.pl $ENV $APP | awk -F: '{print $4}'`
         echo "Cluster > "$CLUSTER

# Get Domain
         DOMAIN=`get-env-info.pl $ENV $APP | awk -F: '{print $4}' | sed 's/[cC]luster[0-9]*//g'`
         echo "Domain > "$DOMAIN

# Get ClusterServers
         CLUSTERSERVERS=`list_all_cluster_servers $ENV $DOMAIN $CLUSTER`
         echo "Cluster_Members > "$CLUSTERSERVERS
      elif [ $ENVVERSION == "D" ]; then
# Get ServerRun
         SERVER=
         echo $ENVVERSION"is a domain"
         exit 1
      fi
   ;;
   prd)
# Get cluster
      CLUSTER=`get-env-info.pl $ENV $APP | awk -F: '{print $4}'`
      echo "Cluster > "$CLUSTER

# Get Domain
      DOMAIN=`get-env-info.pl $ENV $APP | awk -F: '{print $4}' | sed 's/[cC]luster[0-9]*//g'`
      echo "Domain > "$DOMAIN

# Get ClusterServers
      CLUSTERSERVERS=`list_all_cluster_servers $ENV $DOMAIN $CLUSTER`
      echo "Cluster_Members > "$CLUSTERSERVERS
   ;;
   *)
      failure "Unrecognized environment!"
      exit 1
   ;;
   esac
# Get Machine 
   MACHINE_SERVERNAME=(`list_all_servers_with_clusters_and_machines $ENV $DOMAIN | grep $CLUSTER | awk -F: '{print $1 ":" $4}'`)

# ThreadDump Cycle
   for vmmachine in ${MACHINE_SERVERNAME[@]}; do
      COUNTER=0
      SSHMACHINE=`echo $vmmachine | awk -F: '{print $2}'`
      SERVERNAME=`echo $vmmachine | awk -F: '{print $1}'`

      TIME=`date +%Y%m%d_%H%M%S`

# Check if managedserver is running
      JVMPID=`ssh weblogic@$SSHMACHINE".ritta.local" /usr/sbin/lsof /weblogic/$DOMAIN"/servers/"$SERVERNAME/logs/$SERVERNAME.out | grep -m1 java | awk '{print $2}'`
      JDKVERSION=`ssh weblogic@$SSHMACHINE".ritta.local" /usr/sbin/lsof -p $JVMPID | grep /bin/java | awk '{print $9}'`
      JDKVERSION=`dirname $JDKVERSION`

      if [ -z $JVMPID ]; then
         warning $SERVERNAME" is not running"
         continue 
      fi
      TAIL_FILE="/weblogic/"$DOMAIN"/servers/"$SERVERNAME"/logs/"$SERVERNAME".out"
      THREADDUMPFILE="/tmp/"$SERVERNAME"_"$TIME".txt"
      TOPFILE="/tmp/"$SERVERNAME"_"$TIME"_top.txt"
      JMAPHEAPFILE="/tmp/"$SERVERNAME"_"$TIME"_jmapheap.txt"

      ssh weblogic@$SSHMACHINE".ritta.local" /usr/bin/tail -f $TAIL_FILE > $THREADDUMPFILE &
      REMOTETAIL_PID=`ssh weblogic@$SSHMACHINE".ritta.local" /bin/ps -ef | /bin/grep "tail" | /bin/grep -m1 $TAIL_FILE | awk '{print $2}'`

# Taking JMAP and HEAPDUMP

      #ssh weblogic@$SSHMACHINE".ritta.local" /opt/java/1.7.0_45/bin/jmap -heap $JVMPID > $JMAPHEAPFILE
      ssh weblogic@$SSHMACHINE".ritta.local" $JDKVERSION/jmap -heap $JVMPID > $JMAPHEAPFILE
      if [[ TAKEHEAPDUMP -eq "1" ]]; then
         TMPDIRHEAPDUMPFILE=/uploadsonas/tmp_heapdumps_jfr_dontremove/$SERVERNAME-$TIME.bin
         ssh weblogic@$SSHMACHINE".ritta.local" $JDKVERSION/jmap -dump:live,file=$TMPDIRHEAPDUMPFILE $JVMPID
         ssh weblogic@suldeploy101.ritta.local mkdir -p /archive_sonas/dsl_logs/thread_dumps/$APP/$DIRTIME/$THREADDUMPTIME
         scp weblogic@$SSHMACHINE".ritta.local:"$TMPDIRHEAPDUMPFILE /archive_sonas/dsl_logs/thread_dumps/$APP/$DIRTIME/$THREADDUMPTIME
 
         ssh weblogic@$SSHMACHINE".ritta.local" rm $TMPDIRHEAPDUMPFILE
      fi


# Taking threaddumps
      info "A efetuar "$COUNT" dumps com um intervalo de "$SLEEP" segundos ao "$SERVERNAME" da aplicacao "$APP"."
      while [ $COUNTER -le $COUNT ]; do
         ssh weblogic@$SSHMACHINE".ritta.local" /usr/bin/top -b -n 1 -H -p $JVMPID >> $TOPFILE
         ssh weblogic@$SSHMACHINE".ritta.local" /usr/bin/kill -3 $JVMPID
         sleep $SLEEP
         COUNTER=$[$COUNTER+1]
      done

# Kill Remote TAIL PID
      ssh weblogic@$SSHMACHINE".ritta.local" /bin/kill $REMOTETAIL_PID

# Parsing threaddump file

      DIRTIME=`date +%Y%m%d`

      ssh weblogic@suldeploy101.ritta.local mkdir -p /archive_sonas/dsl_logs/thread_dumps/$APP/$DIRTIME/$THREADDUMPTIME
      scp $THREADDUMPFILE weblogic@suldeploy101.ritta.local:/archive_sonas/dsl_logs/thread_dumps/$APP/$DIRTIME/$THREADDUMPTIME
      scp $TOPFILE weblogic@suldeploy101.ritta.local:/archive_sonas/dsl_logs/thread_dumps/$APP/$DIRTIME/$THREADDUMPTIME
      scp $JMAPHEAPFILE weblogic@suldeploy101.ritta.local:/archive_sonas/dsl_logs/thread_dumps/$APP/$DIRTIME/$THREADDUMPTIME
      ssh weblogic@suldeploy101.ritta.local chmod -R 644 /archive_sonas/dsl_logs/thread_dumps/$APP/$DIRTIME/$THREADDUMPTIME/*
      rm $THREADDUMPFILE
      rm $TOPFILE

   done
fi
