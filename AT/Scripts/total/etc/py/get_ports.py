################################################
#       Import variables from arguments.       #
################################################
import sys

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]

################################################
#              Connect WLS Admin.              #
################################################
def connectWLSAdmin() :
   try:
      connect('weblogic',WL_PASS,'t3://' + WL_HOST + ':' + WL_PORT)
      print('Successfully connected')
   except:
      print 'Unable to connect to admin server...'
      exit()

connectWLSAdmin()
################################################
#               Get info Ports                 #
################################################
domainConfig()
servers = cmo.getServers()
print "Server\t\tPort\t\tSSL"
for server in servers:
        print server.name + "\t" + str(server.getListenPort()) + "\t" + str(server.getSSL().getListenPort())
disconnect()
