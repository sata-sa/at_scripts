#!/bin/bash
#fuck it

IP=$1
STATUS=0
Gre='\e[0;32m';
Red='\e[0;31m';
RESET='\e[0m'
IYel='\e[0;93m';

usage()
{
  echo "Usage: `basename $0` host_ip"
  echo -e "\nhost_ip example: 10.191.10.220 \n"
}

if [ "$#" \< 1 ]; then
  usage
  exit 0
fi

#Check Services
check_dns()
{
 DNS=$(nslookup $IP | grep -i name | awk '{print $4}' | cut -d\. -f1)
 echo -e "DNS: \033[33;33m $DNS $RESET"
# echo $DNS
}


check_ping()
{
  PING=$(ping -c 1 -w 3 $IP | gawk -F'[()]' '/PING/{print $2}')
  RESULT_PING=$PING
 
}


check_ssh()
{
 PORTSSH=`nc -z $IP 22 > /dev/null 2>&1`
 TEST_SSH=`echo $?`
 if [ $TEST_SSH = $STATUS ];then
  echo -e "SSH: $Gre   OPEN $RESET"
 else
 echo -e "SSH: $Red   CLOSE $RESET"
 fi
}


check_http()
{
 PORTHTTP=`nc -z $IP 80 > /dev/null 2>&1`
 TEST_HTTP=`echo $?`
 if [ $TEST_HTTP = $STATUS ];then
   echo -e "HTTP: $Gre  OPEN" $RESET
   else
   echo -e "HTTP: $Red  CLOSE $RESET"
 fi
}

check_telnet()
{
  PORTTELNET=`nc -z $IP 23 > /dev/null 2>&1`
  TEST_TELNET=`echo $?`
  if [ $TEST_TELNET = $STATUS ];then
   echo -e "TELNET:$Gre OPEN $RESET"
   else
   echo -e "TELNET:$Red CLOSE $RESET"
   fi
  }

check_rdp()
{
  PORTRDP=`nc -z $IP 3389 > /dev/null 2>&1`
  TEST_RDP=`echo $?`
  if [ $TEST_RDP = $STATUS ];then
  echo -e "RDP: $Gre   OPEN $RESET"
  else
  echo -e "RDP: $Red   CLOSE $RESET"
  fi
}

check_ftp()
{
  PORTFTP=`nc -z $IP 21 > /dev/null 2>&1`
  TEST_FTP=`echo $?`
  if [ $TEST_FTP = $STATUS ];then
  echo -e "FTP: $Gre   OPEN $RESET"
  else
  echo -e "FTP: $Red  CLOSE $RESET"
  fi
}

check_https()
{
 PORTHTTPS=`nc -z $IP 443 > /dev/null 2>&1`
 TEST_HTTPS=`echo $?`
 if [ $TEST_HTTPS = $STATUS ];then
   echo -e "HTTPS: $Gre  OPEN" $RESET
   else
   echo -e "HTTPS: $Red  CLOSE $RESET"
 fi
}

check_ds()
{
  PORTFTP=`nc -z $IP 445 > /dev/null 2>&1`
  TEST_FTP=`echo $?`
  if [ $TEST_FTP = $STATUS ];then
  echo -e "DS: $Gre   OPEN $RESET"
  else
  echo -e "DS: $Red CLOSE $RESET"
  fi
}


echo -e " # HOSTNAME #"
check_dns
check_ping
echo -e " "
echo -e " # CHECK PORTS #"
echo -e " "
check_ssh
check_http
check_telnet
check_rdp
check_https
check_ds
check_ftp
