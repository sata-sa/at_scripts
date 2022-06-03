#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]

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
set('ExalogicOptimizationsEnabled','true')
DOMAIN_NAME = cmo.getName()

ADMINSERVERNAME = cmo.getAdminServerName()
cd('/Servers/' + ADMINSERVERNAME)
set('ListenAddress',ADMIN_HOST + '-clu.ritta.local')

#=======================================================================================
# Set NodeManager parameters
#=======================================================================================
print('Set NodeManager parameters')
cd('/SecurityConfiguration/' + DOMAIN_NAME)
cmo.setNodeManagerUsername(DOMAIN_NAME + 'NodeManager')
cmo.setNodeManagerPassword(ADMIN_PASSWORD)

#=======================================================================================
# Create Network Channels
#=======================================================================================
print('Creating HTTPChannel')
cd('/Servers/' + ADMINSERVERNAME)
cmo.createNetworkAccessPoint(DOMAIN_NAME + 'HTTPChannel')
cd('/Servers/' + ADMINSERVERNAME + '/NetworkAccessPoints/' + DOMAIN_NAME + 'HTTPChannel')
cmo.setProtocol('t3')
cmo.setListenAddress(ADMIN_HOST + '.ritta.local')
cmo.setEnabled(true)
cmo.setHttpEnabledForThisProtocol(true)
cmo.setTunnelingEnabled(true)
cmo.setOutboundEnabled(false)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)
cmo.setSDPEnabled(false)

print('Creating HTTPMGMTChannel')
cd('/Servers/' + ADMINSERVERNAME)
cmo.createNetworkAccessPoint(DOMAIN_NAME + 'HTTPMGMTChannel')
cd('/Servers/' + ADMINSERVERNAME + '/NetworkAccessPoints/' + DOMAIN_NAME + 'HTTPMGMTChannel')
cmo.setProtocol('t3')
cmo.setListenAddress(ADMIN_HOST + '-mgmt.ritta.local')
cmo.setEnabled(true)
cmo.setHttpEnabledForThisProtocol(true)
cmo.setTunnelingEnabled(true)
cmo.setOutboundEnabled(false)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)
cmo.setSDPEnabled(false)

activate()
#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
