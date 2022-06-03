#!/bin/bash
set -x

NEWDOMAINMACHINE=$1
RUNDATE=`date +%Y%m%d_%H%M%S`

EVENORODD=`echo ${NEWDOMAINMACHINE} | tail -c 4`

/bin/ping -c 3 ${NEWDOMAINMACHINE}

if [ $? -ne 0 ]; then
   echo "Unrecognized Host!!!! Over and Out Bitches!!!!!"
   exit 1
fi

if [ $((EVENORODD%2)) -eq 0 ];
then
    EXPORTZFSWEBLOGIC="Admin2"
else
    EXPORTZFSWEBLOGIC="Admin1"
fi


ssh root@${NEWDOMAINMACHINE}-mgmt.ritta.local "mkdir -p {/weblogic,/logs/weblogic,/logs/nodemgr,/opt/drivers,/opt/java,/opt/nodemgr,/opt/sso,/opt/weblogic,/u01/oracle/agent/${NEWDOMAINMACHINE}}; chown -R weblogic:weblogic /weblogic; cp /etc/fstab /etc/fstab.${RUNDATE}; cp /etc/hosts /etc/hosts.${RUNDATE}"

# Preencher com o novo hosts!!!!!!!!!!!!!!!!!!!!
cat <<EOF | ssh root@${NEWDOMAINMACHINE}-mgmt.ritta.local 'cat -> /etc/hosts'
# Do not remove the following line, or various programs
# that require network functionality will fail.
127.0.0.1       localhost.localdomain localhost
::1             localhost6.localdomain6 localhost6

# EXALOGIC OVMM & ZFSSA vor vservers
172.18.0.117    ecu-ec-IPoIB-virt-admin
172.17.0.117    IPoIB-vserver-shared-storage

# LDAP
10.191.149.212  sulldap101.ritta.local sulldap101
10.191.149.215  sulldap102.ritta.local sulldap102
10.191.152.212  sulldap101-mgmt.ritta.local sulldap101-mgmt
10.191.152.215  sulldap102-mgmt.ritta.local sulldap102-mgmt

# Clock
10.191.10.193   clock clock.ritta.local

# Gold Environment
10.191.168.10 suldomaingold101.ritta.local      suldomaingold101
10.191.164.10 suldomaingold101-mgmt.ritta.local suldomaingold101-mgmt
192.168.6.10  suldomaingold101-clu.ritta.local  suldomaingold101-clu
10.191.168.30 suldomaingold102.ritta.local      suldomaingold102
10.191.164.30 suldomaingold102-mgmt.ritta.local suldomaingold102-mgmt
192.168.6.100  suldomaingold102-clu.ritta.local  suldomaingold102-clu

10.191.168.11 suljvmgold101.ritta.local         suljvmgold101
10.191.164.11 suljvmgold101-mgmt.ritta.local    suljvmgold101-mgmt
192.168.6.11  suljvmgold101-clu.ritta.local     suljvmgold101-clu
192.168.7.11  suljvmgold101-app.ritta.local     suljvmgold101-app
10.191.168.12 suljvmgold102.ritta.local         suljvmgold102
10.191.164.12 suljvmgold102-mgmt.ritta.local    suljvmgold102-mgmt
192.168.6.12  suljvmgold102-clu.ritta.local     suljvmgold102-clu
192.168.7.12  suljvmgold102-app.ritta.local     suljvmgold102-app
10.191.168.13 suljvmgold103.ritta.local         suljvmgold103
10.191.164.13 suljvmgold103-mgmt.ritta.local    suljvmgold103-mgmt
192.168.6.13  suljvmgold103-clu.ritta.local     suljvmgold103-clu
192.168.7.13  suljvmgold103-app.ritta.local     suljvmgold103-app
10.191.168.14 suljvmgold104.ritta.local         suljvmgold104
10.191.164.14 suljvmgold104-mgmt.ritta.local    suljvmgold104-mgmt
192.168.6.14  suljvmgold104-clu.ritta.local     suljvmgold104-clu
192.168.7.14  suljvmgold104-app.ritta.local     suljvmgold104-app
10.191.168.15 suljvmgold105.ritta.local         suljvmgold105
10.191.164.15 suljvmgold105-mgmt.ritta.local    suljvmgold105-mgmt
192.168.6.15  suljvmgold105-clu.ritta.local     suljvmgold105-clu
192.168.7.15  suljvmgold105-app.ritta.local     suljvmgold105-app
10.191.168.16 suljvmgold106.ritta.local         suljvmgold106
10.191.164.16 suljvmgold106-mgmt.ritta.local    suljvmgold106-mgmt
192.168.6.16  suljvmgold106-clu.ritta.local     suljvmgold106-clu
192.168.7.16  suljvmgold106-app.ritta.local     suljvmgold106-app
10.191.168.17 suljvmgold107.ritta.local         suljvmgold107
10.191.164.17 suljvmgold107-mgmt.ritta.local    suljvmgold107-mgmt
192.168.6.17  suljvmgold107-clu.ritta.local     suljvmgold107-clu
192.168.7.17  suljvmgold107-app.ritta.local     suljvmgold107-app
10.191.168.18 suljvmgold108.ritta.local         suljvmgold108
10.191.164.18 suljvmgold108-mgmt.ritta.local    suljvmgold108-mgmt
192.168.6.18  suljvmgold108-clu.ritta.local     suljvmgold108-clu
192.168.7.18  suljvmgold108-app.ritta.local     suljvmgold108-app
10.191.168.19 suljvmgold109.ritta.local         suljvmgold109
10.191.164.19 suljvmgold109-mgmt.ritta.local    suljvmgold109-mgmt
192.168.6.19  suljvmgold109-clu.ritta.local     suljvmgold109-clu
192.168.7.19  suljvmgold109-app.ritta.local     suljvmgold109-app
10.191.168.27 suljvmgold110.ritta.local         suljvmgold110
10.191.164.27 suljvmgold110-mgmt.ritta.local    suljvmgold110-mgmt
192.168.6.20  suljvmgold110-clu.ritta.local     suljvmgold110-clu
192.168.7.200  suljvmgold110-app.ritta.local     suljvmgold110-app

10.191.168.20 sulhttpgold101.ritta.local        sulhttpgold101
10.191.164.20 sulhttpgold101-mgmt.ritta.local   sulhttpgold101-mgmt
192.168.7.20  sulhttpgold101-app.ritta.local    sulhttpgold101-app
10.191.168.21 sulhttpgold102.ritta.local        sulhttpgold102
10.191.164.21 sulhttpgold102-mgmt.ritta.local   sulhttpgold102-mgmt
192.168.7.21  sulhttpgold102-app.ritta.local    sulhttpgold102-app
10.191.168.22 sulhttpgold103.ritta.local        sulhttpgold103
10.191.164.22 sulhttpgold103-mgmt.ritta.local   sulhttpgold103-mgmt
192.168.7.22  sulhttpgold103-app.ritta.local    sulhttpgold103-app
10.191.168.23 sulhttpgold104.ritta.local        sulhttpgold104
10.191.164.23 sulhttpgold104-mgmt.ritta.local   sulhttpgold104-mgmt
192.168.7.23  sulhttpgold104-app.ritta.local    sulhttpgold104-app
10.191.168.24 sulhttpgold105.ritta.local        sulhttpgold105
10.191.164.24 sulhttpgold105-mgmt.ritta.local   sulhttpgold105-mgmt
192.168.7.24  sulhttpgold105-app.ritta.local    sulhttpgold105-app
10.191.168.25 sulhttpgold106.ritta.local        sulhttpgold106
10.191.164.25 sulhttpgold106-mgmt.ritta.local   sulhttpgold106-mgmt
192.168.7.25  sulhttpgold106-app.ritta.local    sulhttpgold106-app
10.191.168.26 sulhttpgold107.ritta.local        sulhttpgold107
10.191.164.26 sulhttpgold107-mgmt.ritta.local   sulhttpgold107-mgmt
192.168.7.26  sulhttpgold107-app.ritta.local    sulhttpgold107-app
# end Gold Environment

### Exadata SDP access by IB  ###
192.168.10.240 sudm1db01-ibvip.ritta.local  sudm1db01-ibvip
192.168.10.241 sudm1db02-ibvip.ritta.local  sudm1db02-ibvip
192.168.10.242 sudm1db03-ibvip.ritta.local  sudm1db03-ibvip
192.168.10.243 sudm1db04-ibvip.ritta.local  sudm1db04-ibvip
### Exadata SDP access by IB  ###
### Old Exadata SDP access by IB  ###
192.168.10.72   sdm1db01-ibvip.ritta.local sdm1db01-ibvip
192.168.10.73   sdm1db02-ibvip.ritta.local sdm1db02-ibvip
192.168.10.74   sdm1db03-ibvip.ritta.local sdm1db03-ibvip
192.168.10.75   sdm1db04-ibvip.ritta.local sdm1db04-ibvip
### Old Exadata SDP access by IB  ###
EOF

cat <<EOF | ssh root@${NEWDOMAINMACHINE}-mgmt.ritta.local 'cat ->> /etc/fstab'

# Shares ${NEWDOMAINMACHINE}
172.17.0.117:/export/ATDomains/ExaSto-GOLD-WLD-${EXPORTZFSWEBLOGIC}           /weblogic                               nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATDomains/ExaSto-LOG                       /logs/weblogic                          nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATDomains/ExaSto-NODEMGR-LOG               /logs/nodemgr                           nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATGold/ExaSto-GOLD-DRV-1                   /opt/drivers                            nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATGold/ExaSto-GOLD-JAV-1                   /opt/java                               nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATGold/ExaSto-GOLD-NODEMGR                 /opt/nodemgr                            nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATGold/ExaSto-GOLD-ORAINVENTORY            /opt/oraInventory                       nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATGold/ExaSto-GOLD-SSO-1                   /opt/sso                                nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
172.17.0.117:/export/ATGold/ExaSto-GOLD-WLS-1                   /opt/weblogic                           nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0

# OEM Agent share
172.17.0.117:/export/ATOEMA/ExaSto-OEMA-${NEWDOMAINMACHINE}        /u01/oracle/agent/${NEWDOMAINMACHINE}      nfs4 rw,bg,hard,nointr,rsize=131072,wsize=131072 0 0
EOF

ssh root@${NEWDOMAINMACHINE}-mgmt.ritta.local "mount -a"
