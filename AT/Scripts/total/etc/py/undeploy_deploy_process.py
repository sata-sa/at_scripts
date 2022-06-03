################################################
#       Import variables from arguments.       #
################################################
import sys

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]
APPNAME = sys.argv[4]
LIBRARY = sys.argv[5]
TARGETS = sys.argv[6:]
CLUSTERTARGET = (",".join(TARGETS))

################################################
#              Connect WLS Admin.              #
################################################
def connectWLSAdmin():
     try:
          connect('weblogic',WL_PASS,'t3://' + WL_HOST + ':' + WL_PORT)
          print('Successfully connected')
     except:
          print 'Unable to connect to admin server...'
          exit()

################################################
#              Undeploy New Library            #
################################################
def undeploylib():
     try:
          progress=undeploy(APPNAME,timeout=120000)
          progress.printStatus()
          print('Undeploy completed successfully')
     except:
          print('Undeploy unseccessfully')
          print dumpStack()
          return

################################################
#              Deploy New Library              #
################################################
def deploylib():
     try:
          progress=deploy(appName=APPNAME,path=LIBRARY,targets=CLUSTERTARGET,libraryModule='true',timeout=120000,upload='true')
          progress.printStatus()
          print('Deploy completed successfully')
     except:
          print('Deploy unseccessfully')
          print dumpStack()
          return

################################################
#              Main Execution                  #
################################################
connectWLSAdmin()
undeploylib()
deploylib()
