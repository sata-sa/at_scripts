#!/bin/bash
# Add User Sftp
#@Luis Mangerico
# Remote user Add SFTP

RED="\E[0;31m\033[1m"
GREEN="\E[0;32m\033[1m"
NC='\033[0m'


if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
        read -p "Enter Company : " enterprise      
ssh weblogic@suftp101 'egrep -w "$username" /etc/passwd >/dev/null'
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		mkdir -p /sonas_apps/sftp/$username/$(date +"%Y%m%d")/upload
		useradd  -g users -G sftponly $username -d /sonas_apps/sftp/$username/$(date +"%Y%m%d") -s /bin/false
                echo "sftp"$username$(date +"%Y")  | passwd --stdin $username
		chown root:users /sonas_apps/sftp/$username
		chmod 750 /sonas_apps/sftp/$username/
		chown  root:users /sonas_apps/sftp/$username/$(date +"%Y%m%d")
		chown  weblogic:sftponly /sonas_apps/sftp/$username/$(date +"%Y%m%d")/upload
		chmod 750 /sonas_apps/sftp/$username/
		chmod 750  /sonas_apps/sftp/$username/$(date +"%Y%m%d")
	        chmod 775  /sonas_apps/sftp/$username/$(date +"%Y%m%d")/upload

		#Cria link para apache - logs  
		mkdir -p  /archive_sonas/dsl_logs/$username
		mkdir -p  /archive_sonas/dsl_logs/Empresas/${enterprise,,}
                ln -s /archive_sonas/dsl_logs/$username /archive_sonas/dsl_logs/Empresas/${enterprise,,}/$username
		chown -R weblogic:bin /archive_sonas/dsl_logs/$username

		setenforce 0
                echo -e "\e[36m"
		echo ==================================================================================================
		echo "username: "$username 
		echo "password": "sftp"$username$(date +"%Y")
		echo "Informar a equipa que os ficheiros deverão ser colocados atraves: sftp" $username"@suftp101:/upload"
		echo "Folder PATH:"
		tree -p /sonas_apps/sftp/$username
		echo "Database Updated ===== Application Name:"$username "|| Company Name:" ${enterprise,,}
		echo ================================================================================================== 
		echo "| Updated Apache PATH Logs Name:"$username""	
                echo "| Company Name:" ${enterprise,,}  " URL:::http://suftp101.ritta.local/logs/${enterprise,,}/$username"
		echo ==================================================================================================
                echo -e "${NC}"
		[ $? -eq 0 ] && echo -e "${GREEN}User has been added to system! ${NC}" || echo -e "${RED}Failed to add a user! ${NC}"
	fi
else
	echo -e "${RED}Only root may add a user to the system ${NC}"
	exit 2
fi
