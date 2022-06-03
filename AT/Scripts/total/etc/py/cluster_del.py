#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
CLUSTER = sys.argv[4]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Delete Managed Server.
#=======================================================================================
edit()
startEdit()

print('Deleting cluster ' + CLUSTER)
editService.getConfigurationManager().removeReferencesToBean(getMBean('/Clusters/' + CLUSTER))
cd('/')
cmo.destroyCluster(getMBean('/Clusters/' + CLUSTER))

activate()

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
