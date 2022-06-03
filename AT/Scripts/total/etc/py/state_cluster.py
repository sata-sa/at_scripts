################################################
#       Import variables from arguments.       #
################################################
import sys

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]
CLUSTER = sys.argv[4]

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

################################################
#             Check Cluster State              #
################################################
def stateClstr(clstrName):
 try:
  state(clstrName,"Cluster")
 except Exception, e:
  print 'Error while starting cluster ',e
  dumpStack()
  return

connectWLSAdmin()
stateClstr(CLUSTER)
