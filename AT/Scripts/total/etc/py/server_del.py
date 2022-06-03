#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
SERVER = sys.argv[4]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Delete Managed Server.
#=======================================================================================
edit()
startEdit()

print('Deleting managed server ' + SERVER)
cd('/Servers/' + SERVER)
cmo.setCluster(None)
cd('/')
cmo.destroyServer(getMBean('/Servers/' + SERVER))
cd('/')

activate()

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')