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
      edit()
      startEdit()
   except:
      print 'Unable to connect to admin server...'
      exit()

connectWLSAdmin() 

################################################
#              Get Information                 #
################################################
allDataSources = cmo.getJDBCSystemResources()
for dataSource in allDataSources:
   dsname = dataSource.getName()
   print 'NAME | JNDI NAME | URL'
   print '-----------------------------'
   print dsname,'| ' + dataSource.getJDBCResource().getJDBCDataSourceParams().getJNDINames()[0],'| ' + dataSource.getJDBCResource().getJDBCDriverParams().getUrl()
   print '-----------------------------'
   print ''
