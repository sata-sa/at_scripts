#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
MACHINE = sys.argv[4]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Register the machine with NodeManager
#=======================================================================================
edit()
startEdit()

print('Set NMType and ListenAddress')
cd('/Machines/' + MACHINE + '/NodeManager/' + MACHINE)
set('NMType', 'Plain')
set('ListenAddress', MACHINE + '-clu.ritta.local')

activate()
#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
