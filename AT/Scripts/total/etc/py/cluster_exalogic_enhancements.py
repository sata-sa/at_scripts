#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
CLUSTER = sys.argv[4]
MANAGEDSERVER = sys.argv[5]
MANAGEDSERVERPORT = sys.argv[6]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Enable Exalogic enhancements
#=======================================================================================
edit()
startEdit()

cd('/')
DOMAIN_NAME = cmo.getName()

print('Setting channels for cluster ' + CLUSTER)
cd('/Clusters/' + CLUSTER)
CLUSTER_ADDRESS = cmo.getClusterAddress()
if CLUSTER_ADDRESS == None:
   CLUSTER_ADDRESS = ""
else:
   CLUSTER_ADDRESS = CLUSTER_ADDRESS + "," 
# Automatic addition of the cluster address because of the DB2 access webservice - 2014.11.26 - Bruno
cmo.setClusterAddress(str(CLUSTER_ADDRESS) + MANAGEDSERVER + '.ritta.local:' + MANAGEDSERVERPORT)
####
cmo.setReplicationChannel(DOMAIN_NAME + 'REPLChannel' + CLUSTER)
cmo.setClusterBroadcastChannel(DOMAIN_NAME + 'CLUChannel' + CLUSTER)
cmo.setOneWayRmiForReplicationEnabled(true)

activate()
#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
