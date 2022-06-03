#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
SERVER = sys.argv[4]
MACHINE = sys.argv[5]
CLUSTER_NAME = sys.argv[6]

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
DOMAIN_ROOT = cmo.getRootDirectory()
DOMAIN_NAME = cmo.getName()
cd('/Servers/' + SERVER + '/ServerStart/' + SERVER)
ARGUMENTS = cmo.getArguments()
#cmo.setArguments(ARGUMENTS + ' -Doracle.net.SDP=true -DUseSunHttpHandler=true -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.Stdout=/logs' + DOMAIN_ROOT + '/' + SERVER + '/' + SERVER + '.out -Dweblogic.Stderr=/logs' + DOMAIN_ROOT + '/' + SERVER + '/' + SERVER + '.out')
cmo.setArguments(ARGUMENTS + ' -Dweblogic.security.allowCryptoJDefaultJCEVerification=true -Doracle.net.SDP=true -DUseSunHttpHandler=true -Dweblogic.security.SSL.ignoreHostnameVerification=true -Dweblogic.Stdout=/logs' + DOMAIN_ROOT + '/' + SERVER + '/' + SERVER + '.out -Dweblogic.Stderr=/logs' + DOMAIN_ROOT + '/' + SERVER + '/' + SERVER + '.out')

cd('/Servers/' + SERVER)
cmo.setListenAddress(MACHINE + '-clu.ritta.local')
cmo.setStuckThreadMaxTime(300)
LISTEN_PORT=cmo.getListenPort()

#=======================================================================================
# Create Network Channels
#=======================================================================================
print('Creating CLUChannel')
cd('/Servers/' + SERVER)
cmo.createNetworkAccessPoint(DOMAIN_NAME + 'CLUChannel' + CLUSTER_NAME)
cd('/Servers/' + SERVER + '/NetworkAccessPoints/' + DOMAIN_NAME + 'CLUChannel' + CLUSTER_NAME)
cmo.setProtocol('cluster-broadcast')
cmo.setListenPort(int (LISTEN_PORT) + 1)
cmo.setListenAddress(MACHINE + '-clu.ritta.local')
cmo.setPublicAddress(MACHINE + '-clu.ritta.local')
cmo.setEnabled(true)
cmo.setHttpEnabledForThisProtocol(false)
cmo.setTunnelingEnabled(false)
cmo.setOutboundEnabled(true)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)

print('Creating REPLChannel')
cd('/Servers/' + SERVER)
cmo.createNetworkAccessPoint(DOMAIN_NAME + 'REPLChannel' + CLUSTER_NAME)
cd('/Servers/' + SERVER + '/NetworkAccessPoints/' + DOMAIN_NAME + 'REPLChannel' + CLUSTER_NAME)
cmo.setProtocol('t3')
cmo.setListenPort(int (LISTEN_PORT) + 2)
cmo.setListenAddress(MACHINE + '-clu.ritta.local')
cmo.setPublicAddress(MACHINE + '-clu.ritta.local')
cmo.setEnabled(true)
cmo.setHttpEnabledForThisProtocol(false)
cmo.setTunnelingEnabled(false)
cmo.setOutboundEnabled(true)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)
cmo.setSDPEnabled(true)

print('Creating HTTPChannel')
cd('/Servers/' + SERVER)
cmo.createNetworkAccessPoint(DOMAIN_NAME + 'HTTPChannel' + CLUSTER_NAME)
cd('/Servers/' + SERVER + '/NetworkAccessPoints/' + DOMAIN_NAME + 'HTTPChannel' + CLUSTER_NAME)
cmo.setProtocol('http')
cmo.setListenAddress(MACHINE + '-app.ritta.local')
cmo.setPublicAddress(MACHINE + '-app.ritta.local')
cmo.setEnabled(true)
cmo.setHttpEnabledForThisProtocol(true)
cmo.setTunnelingEnabled(false)
cmo.setOutboundEnabled(false)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)

print('Creating HTTPMGMTChannel')
cd('/Servers/' + SERVER)
cmo.createNetworkAccessPoint(DOMAIN_NAME + 'HTTPMGMTChannel' + CLUSTER_NAME)
cd('/Servers/' + SERVER + '/NetworkAccessPoints/' + DOMAIN_NAME + 'HTTPMGMTChannel' + CLUSTER_NAME)
cmo.setProtocol('http')
cmo.setListenAddress(MACHINE + '-mgmt.ritta.local')
cmo.setPublicAddress(MACHINE + '-mgmt.ritta.local')
cmo.setEnabled(false)
cmo.setHttpEnabledForThisProtocol(true)
cmo.setTunnelingEnabled(false)
cmo.setOutboundEnabled(false)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)

print('Creating HTTPEXTChannel')
cd('/Servers/' + SERVER)
cmo.createNetworkAccessPoint(DOMAIN_NAME + 'HTTPEXTChannel' + CLUSTER_NAME)
cd('/Servers/' + SERVER + '/NetworkAccessPoints/' + DOMAIN_NAME + 'HTTPEXTChannel' + CLUSTER_NAME)
cmo.setProtocol('http')
cmo.setListenAddress(MACHINE + '.ritta.local')
cmo.setPublicAddress(MACHINE + '.ritta.local')
cmo.setEnabled(true)
cmo.setHttpEnabledForThisProtocol(true)
cmo.setTunnelingEnabled(false)
cmo.setOutboundEnabled(false)
cmo.setTwoWaySSLEnabled(false)
cmo.setClientCertificateEnforced(false)

#=======================================================================================
# Replication Ports
#=======================================================================================
print('Setting Replication Ports')
cd('/Servers/' + SERVER)
START_REPL_PORT = int(LISTEN_PORT) + 100
END_REPL_PORT = int(LISTEN_PORT) + 102
cmo.setReplicationPorts(str(START_REPL_PORT) + '-' + str(END_REPL_PORT))

activate()
#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
