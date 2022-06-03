#!/bin/sh
#set -x 
#@Luis Mangerico
#Function enviroment selection
getenvir()
{
echo " Environment PRD [1]"
echo "             QUA [2]"
echo "             DEV [3]"
read ENVIRONMENT
case $ENVIRONMENT in
1)
   ENVIRONMENT="prd"
static_prd
;;
2)
   ENVIRONMENT="qua"
static_qua
;;
3)
   ENVIRONMENT="dev"
static_dev
;;
*)
   echo "One, Two or Three, just that..."
   return 1
esac
}

################# DEV
static_dev()
{
	read -p "Application Name: " app
        fqdn=`get-env-info.pl dev  -virtualhosts |grep -m1 -F "$app."`
        ssh weblogic@suhttp201 egrep -w "$fqdn" /httpd/conf/suhttp201/pfstatic.stinternetdev.ritta.local/pfstatic.aliases.conf >/dev/null
        if [ $? -eq 0 ]; then
                echo "$fqdn exists!"
                exit 1
        else
        echo "Creating  entry $fqdn in suhttp201"
        app=$(echo "$fqdn"  | awk -F"." '{print $1}')
	set-env-info.pl $ENVIRONMENT -u a,$app,DISABLE,ENABLE
	ssh weblogic@suhttp201 cp /httpd/conf/suhttp201/pfstatic.stinternetdev.ritta.local/pfstatic.aliases.conf /httpd/conf/suhttp201/pfstatic.stinternetdev.ritta.local/pfstatic.aliases.conf.$(date +"%Y%m%d_%H:%M")
	cat > /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf  << EOF  

######################## Application: $fqdn ############################################
Alias /app/${app}_static "/httpd/data/suhttp201/$fqdn/public_html"

  <Directory "/httpd/data/suhttp201/$fqdn/public_html">
    Options  +includes
    AllowOverride None
    Order allow,deny
    Allow from all
  </Directory>

EOF
	cat /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf | ssh weblogic@suhttp201 "cat >> /httpd/conf/suhttp201/pfstatic.stinternetdev.ritta.local/pfstatic.aliases.conf"
	sshpass -p "liquooo8" ssh root@suhttp201 service wlhttpd restart
	echo "Created Entry $fqdn in suhttp201"
	ssh weblogic@suhttp201 "cat /httpd/conf/suhttp201/pfstatic.stinternetdev.ritta.local/pfstatic.aliases.conf"
        fi
}

################### QUA
static_qua()
{
        read -p "Application Name: " app
        fqdn=`get-env-info.pl qua  -virtualhosts |grep -m1 -F "$app."`
        ssh weblogic@suhttp301 egrep -w "$fqdn" /httpd/conf/suhttp301/pfstatic.stinternetqua.ritta.local/pfstatic.aliases.conf >/dev/null
        if [ $? -eq 0 ]; then
                echo "$fqdn exists!"
                exit 1
        else
        echo "Creating  entry $fqdn in suhttp301"
        app=$(echo "$fqdn"  | awk -F"." '{print $1}')
        set-env-info.pl $ENVIRONMENT -u a,$app,DISABLE,ENABLE
        ssh weblogic@suhttp301 cp /httpd/conf/suhttp301/pfstatic.stinternetqua.ritta.local/pfstatic.aliases.conf /httpd/conf/suhttp301/pfstatic.stinternetqua.ritta.local/pfstatic.aliases.conf.$(date +"%Y%m%d_%H:%M")
        cat > /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf  << EOF  

######################## Application: $fqdn ############################################
Alias /app/${app}_static "/httpd/data/suhttp301/$fqdn/public_html"

  <Directory "/httpd/data/suhttp301/$fqdn/public_html">
    Options  +includes
    AllowOverride None
    Order allow,deny
    Allow from all
  </Directory>

EOF
        cat /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf | ssh weblogic@suhttp301 "cat >> /httpd/conf/suhttp301/pfstatic.stinternetqua.ritta.local/pfstatic.aliases.conf"
        sshpass -p "mamolgo8" ssh root@suhttp301 service wlhttpd restart
        echo "Created Entry $fqdn in suhttp301"
        ssh weblogic@suhttp301 "cat /httpd/conf/suhttp301/pfstatic.stinternetqua.ritta.local/pfstatic.aliases.conf"
        fi
}


################### PRD
static_prd()
{
        read -p "Application Name: "
        fqdn=`get-env-info.pl prd -virtualhosts |grep -m1 -F "$app."` 
        ssh weblogic@sulhttpstatic101 egrep -w "$fqdn" /httpd/conf/sulhttpstatic101/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf >/dev/null
        ssh weblogic@sulhttpstatic102 egrep -w "$fqdn" /httpd/conf/sulhttpstatic102/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf >/dev/null
        if [ $? -eq 0 ]; then
                echo "$fqdn exists!"
                exit 1
        else
	
	echo "#########################################"
        echo "Creating  entry $fqdn in sulhttpstatic101"
	echo "#########################################"
        app=$(echo "$fqdn"  | awk -F"." '{print $1}')
        set-env-info.pl $ENVIRONMENT -u a,$app,DISABLE,ENABLE
	ssh weblogic@sulhttpstatic101  cp  /httpd/conf/sulhttpstatic101/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf  /httpd/conf/sulhttpstatic101/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf.$(date +"%Y%m%d_%H:%M")
        cat > /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf  << EOF  

######################## Application: $fqdn ############################################
Alias /app/${app}_static "/httpd/data/sulhttpgold101/$fqdn/public_html"

  <Directory "/httpd/data/sulhttpgold101/$fqdn/public_html">
    Options +includes
    AllowOverride None
    Order allow,deny
    Allow from all
  </Directory>

EOF
        cat /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf | ssh weblogic@sulhttpstatic101 "cat >> /httpd/conf/sulhttpstatic101/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf"
        sshpass -p "I3iy56ox.8" ssh root@sulhttpstatic101 service wlhttpd restart
	echo "#########################################"
        echo "Created Entry $fqdn in sulhttpstatic101"
        ssh weblogic@sulhttpstatic101 "cat /httpd/conf/sulhttpstatic101/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf"

################################### Sulhttpstatic102 #################################################################################
        echo "Creating  entry $fqdn in sulhttpstatic102"
	echo "#########################################"
        app=$(echo "$fqdn"  | awk -F"." '{print $1}')
        echo "#########################################"
	ssh weblogic@sulhttpstatic102  cp  /httpd/conf/sulhttpstatic102/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf  /httpd/conf/sulhttpstatic102/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf.$(date +"%Y%m%d_%H:%M")
        cat > /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf  << EOF  

######################## Application: $fqdn ############################################
Alias /app/${app}_static "/httpd/data/sulhttpgold102/$fqdn/public_html"

  <Directory "/httpd/data/sulhttpgold102/$fqdn/public_html">
    Options +includes
    AllowOverride None
    Order allow,deny
    Allow from all
  </Directory>

EOF
        cat /home/weblogic/Host_scripts/Putpfstatic/pfstatic.aliases.conf | ssh weblogic@sulhttpstatic102 "cat >> /httpd/conf/sulhttpstatic102/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf"
        sshpass -p "s2OLN4DJ.8" ssh root@sulhttpstatic102 service wlhttpd restart
	echo "#########################################"
        echo "Created Entry $fqdn in sulhttpstatic102"
	echo "#########################################"
        ssh weblogic@sulhttpstatic102 "cat /httpd/conf/sulhttpstatic102/pfstatic.stinternet.ritta.local/pfstatic.aliases.conf"
        fi

}


getenvir
while [ $? -gt 0 ]; do
   getenvir
done
