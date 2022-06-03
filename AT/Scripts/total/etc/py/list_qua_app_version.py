import sys
import re

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]
APP_NAME = sys.argv[4]
VERSION_TO_DEPLOY = sys.argv[5]
PATTERN = re.compile(APP_NAME + '#[0-9].*')
VERSION_TO_DEPLOYPARSED = re.sub('\D', '', VERSION_TO_DEPLOY)
TEMPLASTVERSION = 0

################################################
#              Connect WLS Admin.              #
################################################
def connectWLSAdmin() :
   try:
      connect('weblogic',WL_PASS,'t3://' + WL_HOST + ':' + WL_PORT)
      print('Successfully connected')
      edit()
      startEdit()
   except:
      print 'Unable to connect to admin server...'
      exit()
def listAppsAndCheck() :
   try:
      DEPLOY_APP_NAMES = []
      APP_DEPLOYED = cmo.getAppDeployments()
      for app_deploy in APP_DEPLOYED:
         APP_NAME = app_deploy.getName()
         APP_REAL_VERSION = app_deploy.getAbsoluteSourcePath()
         APP_REAL_VERSION_PARSED = APP_REAL_VERSION.split('/')[-1]
         if PATTERN.match(APP_NAME):
            global TEMPLASTVERSION
            VERSION_WITHOUT_POINTS = re.sub('\D', '', APP_REAL_VERSION_PARSED)
            if TEMPLASTVERSION < VERSION_WITHOUT_POINTS:
               TEMPLASTVERSION = VERSION_WITHOUT_POINTS
            DEPLOY_APP_NAMES.append(app_deploy.getName())
      if VERSION_WITHOUT_POINTS < VERSION_TO_DEPLOYPARSED:
         stopEdit(defaultAnswer='y')
         sys.exit(1)

      stopEdit(defaultAnswer='y')
   except Exception, inst:
      print('Exception: ')
      print inst
      stopEdit()
      dumpStack()

########
# Main #
########
connectWLSAdmin()
listAppsAndCheck()
