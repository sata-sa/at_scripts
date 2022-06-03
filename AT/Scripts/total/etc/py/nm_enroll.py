#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
MACHINE = sys.argv[4]
NODE_MANAGER_PATH = sys.argv[5]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Register the machine with NodeManager
#=======================================================================================
print('Register machine ' + MACHINE + ' with NodeManager')
DOMAIN_ROOT=cmo.getRootDirectory()
nmEnroll(DOMAIN_ROOT, NODE_MANAGER_PATH + '/' + MACHINE)

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
