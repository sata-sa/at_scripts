################################################
#       Import variables from arguments.       #
################################################
import sys

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]
WL_ADMINSERVER = sys.argv[4]

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

####################################################
#              Shutdown AdminServer                #
####################################################
def stopServerAdmin(serverAdminName):
 try:
  shutdown(serverAdminName,'Server','true',1000,force='true',block='true')
 except Exception, e:
  print 'Error while shutting down AdminServer ',e
  dumpStack()
  return

connectWLSAdmin()
stopServerAdmin(WL_ADMINSERVER)
