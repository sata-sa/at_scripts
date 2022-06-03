#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
MACHINE = sys.argv[4]
LISTEN_ADDRESS = sys.argv[5]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Prepare the machine to start via ssh
#=======================================================================================
ADMIN_NAME=cmo.getAdminServerName()
domainRuntime()
cd('/ServerRuntimes/' + ADMIN_NAME)
WL_HOME=cmo.getWeblogicHome()
serverConfig()

edit()
startEdit()

print('Set the machine ' + MACHINE + ' to start via ssh')
cd('/')
# Adicionado pelo Bruno 11/06/2014 devido a problemas com WLS 12.1.2
DOMAIN_ROOT = cmo.getRootDirectory()
####################################################################
cd('/Machines/' + MACHINE + '/NodeManager/' + MACHINE)
set('NMType', 'SSH')
set('ListenPort', 22)
set('ListenAddress', LISTEN_ADDRESS)
set('ShellCommand','ssh -o PasswordAuthentication=no -p %P %H ' + WL_HOME + '/common/bin/wlscontrol.sh -d %D -r ' + DOMAIN_ROOT + ' -s %S %C')

activate()

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
