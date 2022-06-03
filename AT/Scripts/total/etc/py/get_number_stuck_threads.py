################################################
#       Import variables from arguments.       #
################################################
import sys
import re
import datetime

currentdate = datetime.datetime.now()

#WL_HOST = sys.argv[1]
#WL_PORT = sys.argv[2]
#WL_PASS = sys.argv[3]
#WL_HOST = "suldomaingi10101-mgmt.ritta.local"
#WL_PORT = "40000"
#WL_PASS = "c1e5uck5or4"

################################################
#              Connect WLS Admin.              #
################################################
def connectWLSAdmin() :
   try:
      #connect('weblogic',WL_PASS,'t3://' + WL_HOST + ':' + WL_PORT)
      connect('weblogic','c1e5uck5or4','t3://suldomaingi10101-mgmt.ritta.local:40000')
      #print('Successfully connected')
      print str(currentdate)
   except:
      print 'Unable to connect to admin server...'
      exit()

#####################################################
# Get Number STUCK Threads over the time WLS Admin. #
#####################################################
def getStuckThreads() :
   try:
      domainRuntime()
      servers = ls('/ServerRuntimes','true','c')
      clean = dict()
      for server in servers:
         cd('/ServerRuntimes/' + server + '/ThreadPoolRuntime/ThreadPoolRuntime')
         clean[server] = get('StuckThreadCount')
      for servername in clean:
         checkadmin = re.search('gi10Server',servername)
         if checkadmin != None :
            print(servername + " has " + str(clean[servername]) + " STUCKTHREADS!!!")
      exit()
      disconnect()
   except Exception, inst:
      print inst
      print sys.exc_info()[0]
      exit()
      disconnect()

################################################
#              Connect WLS Admin.              #
################################################
#def connectWLSAdminsef() :
#   try:
#      #connect('weblogic',WL_PASS,'t3://' + WL_HOST + ':' + WL_PORT)
#      connect('weblogic','c1e5uck5or4','t3://suldomaingi10101-mgmt.ritta.local:40000')
#      #print('Successfully connected')
#      print str(currentdate)
#   except:
#      print 'Unable to connect to admin server...'
#      exit()

#####################################################
# Get Number STUCK Threads over the time WLS Admin. #
#####################################################
#def getStuckThreadssef() :
#   try:
#      domainRuntime()
#      servers = ls('/ServerRuntimes','true','c')
#      clean = dict()
#      for server in servers:
#         cd('/ServerRuntimes/' + server + '/ThreadPoolRuntime/ThreadPoolRuntime')
#         clean[server] = get('StuckThreadCount')
#      for servername in clean:
#         checkadmin = re.search('gi10Server',servername)
#         if checkadmin != None :
#            print(servername + " has " + str(clean[servername]) + " STUCKTHREADS!!!")
#      exit()
#      disconnect()
#   except Exception, inst:
#      print inst
#      print sys.exc_info()[0]
#      exit()
#      disconnect()

######################
# Run, Forrest, Run! #
######################
redirect('/dev/null','false')
connectWLSAdmin()
getStuckThreads()
#connectWLSAdminsef()
#getStuckThreadssef()
