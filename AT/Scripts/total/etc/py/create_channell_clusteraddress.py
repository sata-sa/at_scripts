# Ligacao ao dominio testeschannel
#connect('weblogic','weblogic1','t3://suvdomaingold101.ritta.local:41200')
# Ligacao ao dominio gi08
#connect('weblogic','DyT4kX8Hl53','t3://suvdomaingold101.ritta.local:41000')
# Ligacao ao dominio gci03
#connect('weblogic','c1e5uck5or4','t3://suvdomaingold101.ritta.local:27000')
# Ligacao ao dominio gci04
#connect('weblogic','c1e5uck5or4','t3://suvdomaingold101.ritta.local:32000')
# Ligacao ao dominio gi05
#connect('weblogic','c1e5uck5or4','t3://suvdomaingold101.ritta.local:29000')
# Ligacao ao dominio gi06
#connect('weblogic','c1e5uck5or4','t3://suvdomaingold101.ritta.local:33000')
# Ligacao ao dominio at02
#connect('weblogic','c1e5uck5or4','t3://suvdomaingold101.ritta.local:30000')
# Ligacao ao dominio gi07
#connect('weblogic','DyT4kX8Hl53','t3://suvdomaingold101.ritta.local:34000')
# Ligacao ao dominio gi10
connect('weblogic','c1e5uck5or4','t3://suldomaingi10101.ritta.local:40000')
# Ligacao ao dominio jff02
#connect('weblogic','c1e5uck5or4','t3://suvdomaingold101.ritta.local:31000')
# Ligacao ao dominio sa02
#connect('weblogic','c1e5uck5or4','t3://suvdomaingold101.ritta.local:26000')
# Ligacao ao dominio sa03
#connect('weblogic','cranEnt0','t3://suvdomaingold101.ritta.local:35500')
# Ligacao ao dominio gci04MSUL
#connect('weblogic','c1e5uck5or4','t3://suldomaingold101.ritta.local:32000')


edit()
startEdit()

mbServers = getMBean("Servers")
servers = mbServers.getServers()

for server in servers:
   cd('/')
   DOMAIN_NAME = cmo.getName()
   MANAGEDSERVER = server.getName()
   if MANAGEDSERVER == (DOMAIN_NAME + "AdminServer"):
      continue
   MACHINE = server.getListenAddress()
   NEWNAMEMACHINE = MACHINE.replace("-clu", "")
   LISTENPORT = server.getListenPort()
   CLUSTER = server.getCluster()
   NCLUSTER = str(CLUSTER).replace("[MBeanServerInvocationHandler]com.bea:Name=", "").replace(",Type=Cluster", "")


   print('>>> Creating HTTPEXTChannel <<<')
   cd('/Servers/' + MANAGEDSERVER)
   cd('/Servers/' + MANAGEDSERVER + '/NetworkAccessPoints/')
   CHANNELNAME = (DOMAIN_NAME + 'HTTPEXTChannel' + str(NCLUSTER))
   try:
      cmo.createNetworkAccessPoint(DOMAIN_NAME + 'HTTPEXTChannel' + str(NCLUSTER))
   except:
      print("=== Channel " + CHANNELNAME + " already created!!! ===")
      pass 
   cd('/Servers/' + MANAGEDSERVER + '/NetworkAccessPoints/' + DOMAIN_NAME + 'HTTPEXTChannel' + str(NCLUSTER))
   cmo.setProtocol('http')
   cmo.setListenAddress(NEWNAMEMACHINE)
   cmo.setPublicAddress(NEWNAMEMACHINE)
   cmo.setEnabled(true)
   cmo.setHttpEnabledForThisProtocol(true)
   cmo.setTunnelingEnabled(false)
   cmo.setOutboundEnabled(false)
   cmo.setTwoWaySSLEnabled(false)
   cmo.setClientCertificateEnforced(false)
 

   cd('/')
   print('>>> Setting channels for cluster ' + NCLUSTER + " <<<")
   cd('/Clusters/' + NCLUSTER)
   CLUSTERADDRESS = cmo.getClusterAddress()
   if NEWNAMEMACHINE in str(CLUSTERADDRESS):
      print("=== Cluster address already created!!! ===")
      pass
   else:
      NCLUSTERADDRESS = str(CLUSTERADDRESS) + ","
      cmo.setClusterAddress(str(NCLUSTERADDRESS) + str(NEWNAMEMACHINE) + ':' + str(LISTENPORT))
      RCLUSTERADDRESS = cmo.getClusterAddress()
      RRCLUSTERADDRESS = str(RCLUSTERADDRESS).replace("None,", "")
      cmo.setClusterAddress(str(RRCLUSTERADDRESS))
      
print("\n")
print("################################################################")
print("# All configuration in domain " + DOMAIN_NAME + " completed!!! #")
print("################################################################")
print("\n")


#save()
activate()
exit('y')
