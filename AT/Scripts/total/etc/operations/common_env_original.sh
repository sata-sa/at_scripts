##########################################
### NOTICE ###############################
### NOTICE ###############################
### NOTICE ###############################
### NOTICE ###############################
### NOTICE ###############################
### NOTICE ###############################
##########################################
# This series of scripts have been developed without any real engineering process 
# nor requirements have been provided by the clients of this environment.
# Nonetheless, it's the belief of this technitian that they provide a sufficientelly solid
# base to orchestrate and manage a high-availability Weblogic/OFM infrastructure as explained
# in http://10.191.33.246/mediawiki/index.php/Infra-estrutura_Weblogic (if you're in DGITA; if not you don't know #!"%)
# To solidify this salad, you should:
#   make sure the actions performed by these scripts become real transactions and rollback whenever there's a failure (such is not occurring)
#   make a checklist of all script dependencies and verify those previous to running the actions required for any given one
#   and last but not least, review code and DRY it
##########################################
##########################################

DEFAULT_JAVA_HOME=/opt/java
DEFAULT_JAVA_BIN=$DEFAULT_JAVA_HOME/bin
DEFAULT_JAVA_VENDOR=Sun
DEFAULT_CLASSPATH=

DEFAULT_ADMIN_USERNAME=weblogic
DEFAULT_ADMIN_PASSWORD=defaultadminpassword

DIR_WLSTEMPLATES=$HOME/var/wlstemplates
DIR_WLSTSCRIPTS=$HOME/var/py
DIR_WLSTSETUPDEFAULTS=$DIR_WLSTSCRIPTS/defaults

if [ "XZ${TRANSACTION}" == "XZ" ]; then
  TRANSACTION="NULL"
fi

OPERATIONS_LOGFILE=$HOME/var/log/operations.`hostname`.`date +%Y%m%d`.log
CENTRALIZED_LOGFILE=$HOME/var/log/operations.`hostname`.log

WLS_BASE=/weblogic
WLS_HOME=/opt/wls-10.3.3/wlserver_10.3
ANT_HOME=/opt/weblogic/modules/org.apache.ant_1.7.1

CLASSPATH=$WLS_HOME/server/lib/weblogic.jar:$WLS_HOME/server/lib/dgitacustom.jar:$CLASSPATH
#CLASSPATH=$WLS_HOME/server/lib/weblogic.jar:${WLS_BASE}/${DOMAIN_NAME}/servers/${SERVER_NAME}/config:$CLASSPATH

HTTPD_CONFBASE=/conf
VIRTUALHOSTDATA_BASEDIR=/data


decrypt_wlpass() {
  DOMAIN=$1
  DOMAINPW=$2
  EXEC="$DEFAULT_JAVA_HOME/bin/java -Dweblogic.RootDirectory=${WLS_BASE}/${DOMAIN} -cp ${CLASSPATH} Decrypt ${DOMAINPW}"
  eval ${EXEC}
  return 0
}

endpoint_open() {
  HOST=$1
  IP=`echo $HOST | awk -F: {'print $1'}`
  PORT=`echo $HOST | awk -F: {'print $2'}`
  /usr/bin/nmap $IP -p $PORT | grep $PORT | grep -i open
}

#TODO: refactor -> vhostname valid
vhostname_valid() {
  if [ `dig $1 +short|wc -l` -lt 1 ]; then
    return 1
  else
    return 0
  fi
}

element_exists() {
  ELEMENT=$1
  if [ -z $ELEMENT ]; then
    return 1
  fi
  COUNT=0
  for elem in $*; do
    if [ $COUNT -gt 0 ]; then
      if [ $elem == $ELEMENT ]; then
        return 0
      fi
    fi
    COUNT=`expr $COUNT + 1`
  done
  return 1
}

list_unique_values() {
  for item in $*; do
    if ! `element_exists $item $LIST`
    then
      if [ "ZZ${LIST}" == "ZZ" ]; then
        LIST=$item
      else
        LIST="${LIST} $item"
      fi
    fi
  done
  echo $LIST | sort
}

antcall() {
  if [ -z $DEBUG ]; then
    info Calling: $ANT_HOME/bin/ant -f $HOME/etc/operations/weblogic.ant.operation.xml $*
    $ANT_HOME/bin/ant -f $HOME/etc/operations/weblogic.ant.operation.xml $*
  else
    info Calling: $ANT_HOME/bin/ant --execdebug -f $HOME/etc/operations/weblogic.ant.operation.xml $*
    $ANT_HOME/bin/ant --execdebug -f $HOME/etc/operations/weblogic.ant.operation.xml $*
  fi
}

antcall_save() {
  DATETIME=`date +%Y%m%d%H%M%S`
  ANTCALLID="${DATETIME}.${RANDOM}"
  TARGET=$1
  DOMAIN_NAME=$2
  PROPERTIES_FILE=$3
  PY_SCRIPT=$4
  if [ -f $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py.last ]; then
    if diff $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py.last $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py
    then
      info No manual changes done since last antcall save
    else
      cp $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py.`date +%Y%m%d%H%M%S`
    fi
  fi
  #TODO: pergica.....
  if [ -f $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py.last ]; then
    cp $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py $HOME/etc/wlreplay/${DOMAIN_NAME}/manual_operation.py.last
  fi
  cp $PROPERTIES_FILE $HOME/etc/wlreplay/${DOMAIN_NAME}/auto.${ANTCALLID}.properties
  cp $HOME/etc/operations/weblogic.ant.operation.xml $HOME/etc/wlreplay/${DOMAIN_NAME}/makefile.${ANTCALLID}.xml
  cat > $HOME/etc/wlreplay/${DOMAIN_NAME}/call.${ANTCALLID}.sh << EOF
#!/bin/sh

# Execution at `hostname`
# Target $TARGET called at $DATETIME
# Properties: $HOME/etc/wlreplay/${DOMAIN_NAME}/auto.${ANTCALLID}.properties
# Makefile used: $HOME/etc/wlreplay/${DOMAIN_NAME}/makefile.${ANTCALLID}.xml
# SSH_CONNECTION=$SSH_CONNECTION
# SSH_CLIENT=$SSH_CLIENT

$ANT_HOME/bin/ant --execdebug -f makefile.${ANTCALLID}.xml $TARGET

EOF
  if [ ! -z $PY_SCRIPT ]; then
    if [ -f $PY_SCRIPT ]; then
      cp $PY_SCRIPT $HOME/etc/wlreplay/${DOMAIN_NAME}/pyscript.${ANTCALLID}.py
    fi
  fi
}

#lib/jsch-0.1.43.jar
#logging functions....
log() {
  if [ "XZ${SSH_CLIENT}" == "XZ" ]; then
    CALLER="Empty ssh client information"
  else
    CALLER=${SSH_CLIENT}
  fi

  if [ ! -z $SSH_TTY ]; then
    #echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $* [$0] [${CALLER}]"
    echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $*"
  fi
  echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $* [$0] [${CALLER}]" >> $OPERATIONS_LOGFILE
  echo -e "[`date +%Y/%m/%d:%H:%M:%S`] [$TRANSACTION] $* [$0] [${CALLER}]" >> $CENTRALIZED_LOGFILE
}

info() {
  log ["\E[0;32m\033[1m"I"\033[0m"] ["\E[0;32m\033[1m"$*"\033[0m"]
}

warning() {
  log ["\E[0;34m\033[1m"W"\033[0m"] ["\E[0;34m\033[1m"$*"\033[0m"]
}

error() {
  log ["\E[0;31m\033[1m"E"\033[0m"] ["\E[0;31m\033[1m"$*"\033[0m"]
}

success() {
  log \[S\] \[$*\]
  if [ ! -z $LOCKFILE ]; then
  if [ -f $LOCKFILE ]; then
    if rm $LOCKFILE
    then
      echo Removed lockfile $LOCKFILE
    else
      echo Failed to remove lockfile $LOCKFILE
    fi
  fi
  fi
}

failure() {
  log ["\E[0;31m\033[1m"F"\033[0m"] ["\E[0;31m\033[1m"$*"\033[0m"]
  echo ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  usage
  exit 1
}









security_webservice_GetAccountPassword() {
  USER=$1
  TMPFILE=/tmp/wscall.${RANDOM}
cat > ${TMPFILE} << EOF
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:dgit="http://www.dgita.min-financas.pt/">
   <soap:Header/>
   <soap:Body>
      <dgit:GetAccountPassword>
         <!--Optional:-->
         <dgit:strUserAccount>${USER}</dgit:strUserAccount>
      </dgit:GetAccountPassword>
   </soap:Body>
</soap:Envelope>
EOF
  #PWD=`curl -H 'Content-type: text/xml;charset=UTF-8;action="http://www.dgita.min-financas.pt/GetAccountPassword"' -d@${TMPFILE} http://10.191.39.108/SecurityWebServices.asmx 2>/dev/null | awk -F\< {'print $6'} | awk -F\> {'print $2'}`
  #OUT=`curl -k -H 'Content-type: text/xml;charset=UTF-8;action="http://www.dgita.min-financas.pt/GetAccountPassword"' -d@${TMPFILE} https://10.191.139.100:667/SecurityWebServices.asmx > ${TMPFILE}.out`
  PWD=`curl -m 30 -k -H 'Content-type: text/xml;charset=UTF-8;action="http://www.dgita.min-financas.pt/GetAccountPassword"' -d@${TMPFILE} https://wsusersservice.ritta.local:667/SecurityWebServices.asmx 2>/dev/null | awk -F\< {'print $5'} | awk -F\> {'print $2'}`
  if [ -z $PWD ]; then
    echo UNABLE_TO_GET_PWD_FROM_WS_DSS_AREA_SEGURANCA
    warning UNABLE TO OBTAIN PASSWORD FOR USER $USER 1>&2
    #sleep 300
  else
    echo $PWD
  fi
  rm ${TMPFILE}
}






#returns the list of weblogic managed server farm machines
get_wlsmachines() {
  cat $HOME/etc/operations/WLSMACHINES
}
MACHINES=`get_wlsmachines`

get_frontends() {
  cat $HOME/etc/operations/FRONTENDS
}
FRONTENDS=`get_frontends`

domain_exists() {
  NAME=$1
  if [ -z $NAME ]; then
    return 1
  fi
  if [ "XZ${NAME}" != "XZ" ]; then
    if [ -d $WLS_BASE/$1 ]; then
      return 0
    fi
  fi
  return 1
}

server_exists() {
  DOMAIN=$1
  SERVER=$2
  if [ -z $SERVER ]; then
    return 1
  fi
  if [ -d $WLS_BASE/$1/servers/$2 ]; then
    return 0
  fi
  return 1
}

cluster_exists() {
  DOMAIN=$1
  CLUSTER=$2
  if [ -z $CLUSTER ]; then
    return 1
  fi
  if [ -z $DOMAIN ]; then
    return 1
  fi
  if [ -d $WLS_BASE/$1/clusters/$2 ]; then
    return 0
  fi
  return 1
}

cluster_domain() {
  CLUSTER=$1
  find $WLS_BASE/*/clusters -maxdepth 1 -mindepth 1 -type d -name $CLUSTER | awk -F\/ {'print $3'}
}

server_domain() {
  SERVER=$1
  find $WLS_BASE/*/servers -maxdepth 1 -mindepth 1 -type d -name $SERVER | awk -F\/ {'print $3'}
}

virtualhost_exists() {
  if [ -d $VIRTUALHOSTDATA_BASEDIR/$1 ]; then
    return 0
  fi
  return 1
}

list_all_domains() {
  find $WLS_BASE -maxdepth 1 -mindepth 1 -type d | sed s\|${WLS_BASE}/\|\|g | sort
}

#TODO: review this shit; use one method; avoid repetition
list_all_servers() { #list all servers from all domains
  DOMAIN=$1
  if [ -z $DOMAIN ]; then
    LIST=`list_all_domains`
  else
    LIST=$DOMAIN
  fi

  for domain in $LIST; do
    #perl -e "use XML::Simple; my \$config = XMLin(\"/weblogic/$DOMAIN/config/config.xml\"); for \$key (keys %{\$config->{server}}) { print \"\$key\n\"; }"
    #find $WLS_BASE/$domain/servers -maxdepth 1 -mindepth 1 -type d | awk -F\/ {'print $5'}
    perl -e "use XML::Simple; my \$config = XMLin(\"/weblogic/$domain/config/config.xml\"); for \$key (sort { \$a cmp \$b } keys %{\$config->{server}}) { print \"\$key\n\"; }"
  done
}

list_all_clusters() { #list all clusters from all domains
  DOMAIN=$1
  if [ -z $DOMAIN ]; then
    LIST=`list_all_domains`
  else
    LIST=$DOMAIN
  fi

  for domain in $LIST; do
    find $WLS_BASE/$domain/clusters -maxdepth 1 -mindepth 1 -type d | awk -F\/ {'print $5'}
    perl -e "use XML::Simple; my \$config = XMLin(\"/weblogic/$domain/config/config.xml\"); for \$key (keys %{\$config->{cluster}}) { \$val = \$config->{cluster}->{\$key}; print \"\$val\n\" if (\$key =~ /name/i); }"
  done
}

list_all_cluster_servers() { #lists all servers belonging to a cluster
  cluster=$1
  if [ -z $cluster ]; then 
    return 1
  fi
  for domain in `list_all_domains`; do
    if cluster_exists $domain $cluster
    then
      perl -e "use XML::Simple; my \$config = XMLin(\"/weblogic/$domain/config/config.xml\"); for \$key (sort { \$a cmp \$b } keys %{\$config->{server}}) { print \"\$key\n\" if (\$config->{server}->{\$key}->{cluster} eq $cluster); }"
    fi
  done
}

list_all_virtualhosts() {
  find $VIRTUALHOSTDATA_BASEDIR -maxdepth 1 -mindepth 1 -type d | awk -F\/ {'print $3'}
}

list_all_applications() {
  VIRTUAL_HOST=$1
  if [ -z $VIRTUAL_HOST ]; then
    find $VIRTUALHOSTDATA_BASEDIR/*/applications -maxdepth 1 -mindepth 1 -type d | awk -F\/ {'print $5'}
  else
    if [ -d $VIRTUALHOSTDATA_BASEDIR/$VIRTUAL_HOST ]; then
      find $VIRTUALHOSTDATA_BASEDIR/$VIRTUAL_HOST/applications -maxdepth 1 -mindepth 1 -type d | awk -F\/ {'print $5'} | sort
    fi
  fi
}

#lists all the applications associated with a target
list_all_target_applications() {
  TARGET=$1
  VIRTUAL_HOST=$2
  if [ -z $TARGET ]; then
    return 1
  fi

  if [ -z $VIRTUAL_HOST ]; then
    VIRTUAL_HOST="*"
  fi

  for target_file in `find $VIRTUALHOSTDATA_BASEDIR/$VIRTUAL_HOST/applications/*/.targets -name .targets`; do
    if grep $TARGET $target_file > /dev/null
    then
      app=`echo $target_file | awk -F\/ {'print $5'}`
      APPLICATIONS="${APPLICATIONS} $app"
    fi
  done
  echo $APPLICATIONS
  return 0
}

#TODO: deprecate this one below
list_all_targets_applications() {
  TARGET=$1
  if [ -z $TARGET ]; then
    return 1
  fi
  for target_file in `find $VIRTUALHOSTDATA_BASEDIR/*/applications/*/.targets`; do
    if grep $TARGET $target_file > /dev/null
    then
      app=`echo $target_file | awk -F\/ {'print $5'}`
      APPLICATIONS="${APPLICATIONS} $app"
    fi
  done
  echo $APPLICATIONS
  return 0
}

list_all_application_targets() {
  VIRTUAL_HOST=$1
  APPLICATION=$2
  if [ -z $VIRTUAL_HOST ]; then
    return 1
  fi
  if [ -z $APPLICATION ]; then
    return 2
  fi
  targets_file=$VIRTUALHOSTDATA_BASEDIR/$VIRTUAL_HOST/applications/$APPLICATION/.targets
  if [ -f $targets_file ]; then
    cat $targets_file
    return 0
  fi
  return 3
}

list_all_application_virtualhosts() {
  APPLICATION=$1
  if [ -z $APPLICATION ]; then
    return 2
  fi
  unset LIST
  for vhost in `list_all_virtualhosts`; do
    if [ -d $VIRTUALHOSTDATA_BASEDIR/$vhost/applications/$APPLICATION ]; then
      if [ -z $LIST ]; then
        LIST=${vhost}
      else
        LIST="${LIST} ${vhost}"
      fi
    fi
  done
  list_unique_values $LIST
  return 0
}

target_valid() { #checks if a target name is a valid one (does not exists as one server or cluster)
  targetlist="`list_all_servers` `list_all_clusters`"
  for i in $targetlist; do
    if [ "x$i" == "x$1" ]; then
      return 0;
    fi
  done
  return 1;
}

target_num() { #returns the number of targets of an application in a virtual host
  VIRTUALHOST=$1
  APPLICATION=$2
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST
  cat $VHOSTBASE/applications/$APPLICATION/.targets | wc -l
}

target_exists() { #checks if a target (third argument) exists in VIRTUALHOST for APPLICATION
  VIRTUALHOST=$1
  APPLICATION=$2
  TARGET=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST
  if grep $TARGET $VHOSTBASE/applications/$APPLICATION/.targets
  then
    return 0
  fi
  return 1
}

target_list() { #returns a list with all targets assigned to an application in a virtual host
  VIRTUALHOST=$1
  APPLICATION=$2
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST
  cat $VHOSTBASE/applications/$APPLICATION/.targets
}

target_path() { #returns the path of a target
  TARGET=$1
  #echo find /weblogic -mindepth 3 -maxdepth 3 -type d -name \*${TARGET} \| egrep servers\|clusters
  find /weblogic -mindepth 3 -maxdepth 3 -type d -name \*${TARGET} | egrep servers\|clusters
}

target_domain() { #returns the domain where the target belongs
  TARGET=$1
  if [ -z $TARGET ]; then
    return 1
  fi
  echo `target_path $TARGET | awk -F \/ {'print $3'}`
}

target_change() { #signal target change in application
  VIRTUALHOST=$1
  APPLICATION=$2
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST
  touch $VHOSTBASE/applications/$APPLICATION/.targets.changed
}

targets_changed() { #checks if targets have changed for an application
  VIRTUALHOST=$1
  APPLICATION=$2
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST
  if [ -f $VHOSTBASE/applications/$APPLICATION/.targets.changed ]; then
    return 0
  fi
  return 1
}

targets_sanitize() { #disambiguates target list
  INPUT_LIST=$*
  #find clusters
  CLUSTER_LIST=`list_all_clusters`
  for cluster in $CLUSTER_LIST; do
    for target in $INPUT_LIST; do
      if [ $target == $cluster ]; then
        if [ -z $LIST ]; then
          LIST=${cluster}
        else
          LIST="${LIST} ${cluster}"
        fi
        TABU_LIST="${TABU_LIST} `list_all_cluster_servers $cluster`"
        continue;
      fi
    done
  done

  #do not add element from the input list that belongs to these clusters
  for target in $INPUT_LIST; do
    IS_TABU=0
    for tabu in $TABU_LIST; do
      if [ $target == $tabu ]; then
        IS_TABU=1
        break;
      fi
    done
    if [ $IS_TABU -eq 0 ]; then
      LIST="${LIST} ${target}"
    fi
  done

  echo $LIST | perl -ne 'chomp; @list = split; for $target (@list) { $hash->{$target} += 1; } print join " ", keys %$hash;'
  return 0
}

name_exists() { #check if a name exists in the global configuration
  targetlist="`list_all_domains` `list_all_servers` `list_all_clusters` `list_all_applications`"
  for i in $targetlist; do
    if [ "x$i" == "x$1" ]; then
      return 0;
    fi
  done
  return 1
}

machine_exists() { #check if a machine is registered on the global configuration
  MACHINE=$1
  for machine in `get_wlsmachines`; do
    if [ $machine == $MACHINE ]; then
      return 0;
    fi
  done
  return 1
}

name_valid() { #check the validity of a given name
  #check if a name is valid
  return 0
}

#TODO: review
get_target_address() { #gets a target address based on it's name
  NAME=$1
  for config_file in `find $WLS_BASE/*/config -type f -name config.xml`; do perl -e "use XML::Simple; my \$config = XMLin(\"$config_file\"); my \$hostname=\$config->{server}->{$NAME}->{\"listen-address\"} || \$config->{server}->{$NAME}->{\"machine\"}; 
my \$port = \$config->{server}->{$NAME}->{\"listen-port\"} || \$config->{server}->{\"listen-port\"};
print \$hostname.\":\".\$port.\"\" if \$hostname;"; done
}

#TODO: transform to include clusters
get_machine_name() { #gets a target address based on it's name
  NAME=$1
  for config_file in `find $WLS_BASE/*/config -type f -name config.xml`; do perl -e "use XML::Simple; my \$config = XMLin(\"$config_file\"); print \$config->{server}->{$NAME}->{\"machine\"};"; done
}


get_password() {
  # gets the password for a server or domain specified as the first argument
  SERVER=$1
  echo `get_admin_password`
}

get_admin_password() {
  # gets the password for a server or domain specified as the first argument
  SERVER=$1
  if [ -f $HOME/.default_password ]; then
    cat $HOME/.default_password
  else
    echo $DEFAULT_ADMIN_PASSWORD
  fi
}

get_admin_password2() {
  # gets the password for a server or domain specified as the first argument
  DOMAIN=$1
  if [ -z ${DOMAIN} ]; then 
    if [ -f $HOME/.default_password ]; then
      cat $HOME/.default_password
    else
      echo $DEFAULT_ADMIN_PASSWORD
    fi
  else
    DOMAINPWD=`cat /weblogic/${DOMAIN}/servers/AdminServer/security/boot.properties | grep password | awk -F password= '{print($2)}'`
    decrypt_wlpass ${DOMAIN} ${DOMAINPWD}
  fi
}

get_admin_port() {
  # gets the password for a domain specified as the first argument
  DOMAIN=$1
  if [ -d $WLS_BASE/$DOMAIN ]; then
    perl -e "use XML::Simple; my \$config = XMLin(\"/weblogic/$DOMAIN/config/config.xml\"); print \$config->{server}->{AdminServer}->{\"listen-port\"} || \$config->{server}->{\"listen-port\"};"
  fi
}

get_listen_ports() {
  PORTS=""
  for config_file in `find $WLS_BASE/*/config -type f -name config.xml`; do
    LISTEN_PORTS=`grep -i \<listen-port\> $config_file|sed 's/ \+<listen-port>\([0-9]*\).*/\1/g'`
    ADMIN_PORTS=`grep -i \<administration-port\> $config_file|sed 's/ \+<administration-port>\([0-9]*\).*/\1/g'`
    PORTS="${LISTEN_PORTS} ${ADMIN_PORTS} ${PORTS}"
  done
  echo $PORTS
}


decompress_file() {
  file=$1
  dest=$2
  if [ ! -f $file ]; then
    return 1
  fi
  if [ ! -d $dest ]; then
    return 2
  fi
  fileextension=`echo $file | awk -F . {'print $NF'}`

  info Decompressing $file to $dest

  case $fileextension in
    zip)
      unzip -u $file -d $dest
      ;;
    tgz)
      cd $dest && tar xzf $file
      ;;
    bz2)
      cd $dest && tar xjf $file
      ;;
  esac

  #TODO: rsync here?
  return $?
}

application_exists() {
  APPLICATION=$1
  if [ `find $VIRTUALHOSTDATA_BASEDIR/*/applications -type d -name $APPLICATION | wc -l` -lt 1 ]; then
    return 1
  fi
  return 0
}

application_target_file() {
  return 0
}

application_plan_file() {
  return 0
}

application_get_next_version() {
  VIRTUALHOST=$1
  APPLICATION=$2
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST
  COUNT=1

  if [ -f $VHOSTBASE/applications/$APPLICATION/.count ]; then
    CURRENT_COUNT=`cat $VHOSTBASE/applications/$APPLICATION/.count`
    COUNT=`expr $CURRENT_COUNT + 1`
    echo $COUNT > $VHOSTBASE/applications/$APPLICATION/.count
  else
    echo $COUNT > $VHOSTBASE/applications/$APPLICATION/.count
  fi

  application_version="`date +%Y%m%d%H%M%S`.${COUNT}"
  echo $application_version
}


application_set_version() {
  VIRTUALHOST=$1
  APPLICATION=$2
  application_version=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  echo $application_version > $VHOSTBASE/applications/$APPLICATION/.version
}

application_add_retiree() {
  VIRTUALHOST=$1
  APPLICATION=$2
  application_version=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  touch $application_version $VHOSTBASE/applications/$APPLICATION/.retire
  if ! grep $application_version $VHOSTBASE/applications/$APPLICATION/.retire
  then
    echo $application_version >> $VHOSTBASE/applications/$APPLICATION/.retire
  fi
}

application_list_retirees() {
  VIRTUALHOST=$1
  APPLICATION=$2
  application_version=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  cat $VHOSTBASE/applications/$APPLICATION/.retire
}

application_count_retirees() {
  VIRTUALHOST=$1
  APPLICATION=$2
  application_version=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  if [ -f $VHOSTBASE/applications/$APPLICATION/.retire ]; then
    wc -l $VHOSTBASE/applications/$APPLICATION/.retire | awk {'print $1'}
  else
    echo 0
  fi
}

application_del_retiree() {
  VIRTUALHOST=$1
  APPLICATION=$2
  application_version=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  grep -v $application_version $VHOSTBASE/applications/$APPLICATION/.retire > $VHOSTBASE/applications/$APPLICATION/.retire_new
  rm $VHOSTBASE/applications/$APPLICATION/.retire
  mv $VHOSTBASE/applications/$APPLICATION/.retire_new $VHOSTBASE/applications/$APPLICATION/.retire
}

application_head_retiree() {
  VIRTUALHOST=$1
  APPLICATION=$2
  application_version=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  head -n1 $VHOSTBASE/applications/$APPLICATION/.retire
}

update_retiree_list() {
  DOMAIN=$1
  VIRTUALHOST=$2
  APPLICATION=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  VERSION_LIST="$DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port ${DOMAIN}` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -listapps | grep -w ${APPLICATION} | awk -F = '{print(\$2)}' | awk -F ] '{print(\$1)}' | sort -n"

  eval ${VERSION_LIST} > $VHOSTBASE/applications/$APPLICATION/.retire

  info `echo "Updated retiree list: "``cat $VHOSTBASE/applications/$APPLICATION/.retire`
}

application_undeploy() {
  return 0
}

application_deploy() {
  return 0
}

application_start() {
  return 0
}

deploy_file() {
  virtual_host=$1
  application_name=$2
  target=$3
  file=$4

  new_application_version=`application_get_next_version $virtual_host $application_name`

  if ! virtualhost_exists $virtual_host
  then
    return 1
  fi
  if [ ! -f $file ]; then
    return 1
  fi
  if [ -z $target ]; then
    return 3
  fi
  if ! application_exists $application_name
  then
    return 4
  fi
  if [ -z $virtual_host ]; then
    return 5
  fi
  if [ -z $application_name ]; then
    return 5
  fi

  #targets may be sepparated by commas
  targets=`echo $target | sed 's/,/ /g'`
  MULTIPLE_DOMAINS=0
  t1=$RANDOM
  for t in $targets; do
    if [ ! -z $t ]; then
      if [ $t1 != $t ]; then
        MULTIPLE_DOMAINS=1
      fi
    fi
    t1=$t
    domain=`target_domain $t`
  done

  #TODO: deal with cross-domain deploys... should they exist?
  #TODO: check if targets changed and deal with it...
  #TODO: deal with plans if they exist

  # Update application version list
  update_retiree_list $domain $virtual_host $application_name

  if [ $MULTIPLE_DOMAINS -gt 1 ]; then
    failure Multiple targets in multiple domains... Can\'t deal with that yet!
    return 2
  elif [ $MULTIPLE_DOMAINS -eq 1 ]; then
    if [ `application_count_retirees $virtual_host $application_name` -gt 1 ]; then
      application_version=`application_head_retiree $virtual_host $application_name`
      info Trying to retire the old version $application_version of $application_name
      info $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -undeploy -name ${application_name} -appversion ${application_version}
      if $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -undeploy -name ${application_name} -appversion ${application_version}
      then
        application_del_retiree $virtual_host $application_name $application_version
        info Stopping currently active version of $application_name
        info $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -name ${application_name} -stop
        $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -name ${application_name} -stop
      fi
    elif [ `application_count_retirees $virtual_host $application_name` -eq 1 ]; then
      info Stopping currently active version of $application_name
      info $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -name ${application_name} -stop
      $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -name ${application_name} -stop
    fi
#    for application_version in `application_list_retirees $virtual_host $application_name`; do
#    done

    info Deploying $file to $target in $domain
    info $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -deploy -name ${application_name} -appversion ${new_application_version} -remote -upload $file -targets $target
    if $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -deploy -name ${application_name} -appversion ${new_application_version} -remote -upload $file -targets $target
    then
      #TODO: try and start app.... redundant... rethink
      $DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port $domain` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -start -name ${application_name} -appversion ${new_application_version}
      application_set_version $virtual_host $application_name $new_application_version
      application_add_retiree $virtual_host $application_name $new_application_version
    else
      return 1
    fi
  else
    failure No domains found for $targets
    return 1
  fi
  return 0
}

process_xml_properties() {
  FILE=$1
  DEST=$2
#echo $FILE zZZZZZZZZZZZZZZZZZ
#echo $DEST HDHASHDASHDASZZZZZZZZZZZZZZ
  if [ -f $FILE ]; then
    if [ -f $LOCKFILE ]; then
      echo cat $FILE \| application_deploy_xml_properties_rewrite.pl \> $DEST
      if cat $FILE | application_deploy_xml_properties_rewrite.pl > $DEST/`basename $FILE`
      then
        info Wrote affected properties file $FILE to $DEST
        return 0
      else
        error Unable to process properties file \(variable loading failed in $0 ?\)
      fi
    fi
  fi
  #TODO: rsync here?
  return 1
}

process_properties() {
  FILE=$1
  DEST=$2
#echo $FILE zZZZZZZZZZZZZZZZZZ
#echo $DEST HDHASHDASHDASZZZZZZZZZZZZZZ
  if [ -f $FILE ]; then
    if [ -f $LOCKFILE ]; then
      echo cat $FILE \| application_deploy_properties_rewrite.pl \> $DEST
      if cat $FILE | application_deploy_properties_rewrite.pl > $DEST/`basename $FILE`
      then
        info Wrote affected properties file $FILE to $DEST
        return 0
      else
        error Unable to process properties file \(variable loading failed in $0 ?\)
      fi
    fi
  fi
  #TODO: rsync here?
  return 1
}

get_application_machine_name() {
  APPLICATION=$1
  VIRTUAL_HOST=`list_all_application_virtualhosts ${APPLICATION}`
  CLUSTER_NAME=`target_list ${VIRTUAL_HOST} ${APPLICATION}`

  for WLSERVER in `list_all_cluster_servers ${CLUSTER_NAME}`
  do
    MACHINE_LIST="`get_machine_name ${WLSERVER}` ${MACHINE_LIST}"
  done

  echo -e "${MACHINE_LIST}" | sed 's/.$//' | sed 's/ /\n/g' | sort | uniq
}

update_retire_list() {
  DOMAIN=$1
  VIRTUALHOST=$2
  APPLICATION=$3
  VHOSTBASE=$VIRTUALHOSTDATA_BASEDIR/$VIRTUALHOST

  VERSION_LIST="$DEFAULT_JAVA_HOME/bin/java -cp ${WLS_HOME}/server/lib/weblogic.jar weblogic.Deployer -adminurl `hostname`:`get_admin_port ${DOMAIN}` -username ${DEFAULT_ADMIN_USERNAME} -password `get_admin_password` -listapps | grep ${APPLICATION} | awk -F = '{print(\$2)}' | awk -F ] '{print(\$1)}' | sort -n"

  eval ${VERSION_LIST} > $VHOSTBASE/applications/$APPLICATION/.retire
}
