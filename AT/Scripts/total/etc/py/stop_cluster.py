################################################
#       Import variables from arguments.       #
################################################
import sys

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]

################################################
#              Build array of Clusters         #
################################################

if len(sys.argv[4]) > 1:
   CLUSTER_LIST = []
   for element in sys.argv[4:]:
      CLUSTER_LIST.append(element)


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
#              Shutdown Cluster                #
################################################
def stopClstr():
    for clstName in CLUSTER_LIST:
        try:
            shutdown(clstName,"Cluster",force='true')
            state(clstName,"Cluster")
        except Exception, e:
            print 'Error while shutting down cluster ',e
            dumpStack()
            return

connectWLSAdmin()
stopClstr()
