#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
SERVER = sys.argv[4]
MACHINE = sys.argv[5]
SERVER_LISTEN_PORT = sys.argv[6]
KRB_LOGIN_FILE= sys.argv[7]
KRB_MAIN_FILE= sys.argv[8]
JAVA_HOME = sys.argv[9]

#Bruno
print ADMIN_HOST
print ADMIN_PORT
print ADMIN_PASSWORD
print SERVER
print MACHINE
print SERVER_LISTEN_PORT
print KRB_LOGIN_FILE
print KRB_MAIN_FILE
print JAVA_HOME
#

#=======================================================================================
# Connect to running domain.
#=======================================================================================
print connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Create Managed Server.
#=======================================================================================
ADMIN_NAME=cmo.getAdminServerName()
#Bruno
print ADMIN_NAME
#
domainRuntime()
cd('/ServerRuntimes/' + ADMIN_NAME)
WL_HOME=cmo.getWeblogicHome()
#Bruno
print WL_HOME
#
serverConfig()

edit()
startEdit()

print('Creating managed server' + SERVER)
cd('/')
DOMAIN_ROOT = cmo.getRootDirectory()
create(SERVER, 'Server')
cd('/Servers/' + SERVER)
cmo.setListenPort(int(SERVER_LISTEN_PORT))
cmo.setMachine(getMBean('/Machines/' + MACHINE))
cd('/Servers/' + SERVER + '/ServerStart/' + SERVER)
# Set ServerRootDirectory because WLS12.1.2 NodeManager - Bruno 24/06/2014
cmo.setRootDirectory(DOMAIN_ROOT + '/servers/' + SERVER)
########################################################
cmo.setArguments('-server -Xms512m -Xmx512m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC -XX:+ExplicitGCInvokesConcurrent -Dserver.root=' + DOMAIN_ROOT + '/servers/' + SERVER + ' -Djava.security.auth.login.config=' + KRB_LOGIN_FILE + ' -Djava.security.krb5.conf=' + KRB_MAIN_FILE + ' -Djavax.security.auth.useSubjectCredsOnly=false -Dweblogic.security.enableNegotiate=true -Djava.net.preferIPv4Stack=true')
cmo.setClassPath(DOMAIN_ROOT + '/servers/' + SERVER + '/config:' + WL_HOME + '/server/lib/wljmxclient.jar')
cd('/Servers/' + SERVER + '/ServerStart/' + SERVER)
cmo.setJavaHome(JAVA_HOME)

activate()

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
