#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys
from java.util import ArrayList

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
POOL_NAME = sys.argv[4]
ACTION = sys.argv[5]
POOL_FOUND = 0
SERVERS_LIST = ArrayList()

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Locate pool and related targets
#=======================================================================================
DSOURCES = cmo.getJDBCSystemResources()

for DATASOURCE in DSOURCES:
  DSNAME = DATASOURCE.getName()

  if DSNAME == POOL_NAME:
    POOL_FOUND = 1
    cd('/JDBCSystemResources/' + DSNAME + '/Targets')
    TARGETS = cmo.getTargets()

    for TARGET in TARGETS:
      OBJ_TYPE = TARGET.getType()

      if OBJ_TYPE == "Cluster":
        cd('/Clusters/' + TARGET.getName())

        SERVERS = cmo.getServers()

        for SERVER in SERVERS:
          SERVERS_LIST.add(SERVER)
      else:
        SERVERS_LIST.add(TARGET)

#=======================================================================================
# Apply action on pool
#=======================================================================================
if POOL_FOUND == 1:
  domainRuntime()

  for SERVER in SERVERS_LIST:
    SERVER_NAME = SERVER.getName()
    cd('/ServerRuntimes/' + SERVER_NAME + '/JDBCServiceRuntime/' + SERVER_NAME + '/JDBCDataSourceRuntimeMBeans/' + POOL_NAME)

    if ACTION.upper() == "SHUTDOWN":
      cmo.shutdown()
    elif ACTION.upper() == "START":
      cmo.start()
    elif ACTION.upper() == "SUSPEND":
      cmo.suspend()
    elif ACTION.upper() == "RESUME":
      cmo.resume()
else:
  print('Pool ' + POOL_NAME + ' not found.')

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
