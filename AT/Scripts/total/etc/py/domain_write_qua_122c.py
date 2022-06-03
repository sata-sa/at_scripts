#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

DOMAIN = sys.argv[1]
DOMAIN_HOME = sys.argv[2]
JAVA_HOME = sys.argv[3]
PASSWORD = sys.argv[4]

#=======================================================================================
# Open a domain template.
#=======================================================================================
print('Opening the domain template file ' + DOMAIN_HOME + '/' + DOMAIN + '.jar.')
readTemplate(DOMAIN_HOME + '/' + DOMAIN + '.jar')

#=======================================================================================
# Write the domain and close the domain template.
#=======================================================================================
print('Writing the domain information and closing the domain template.')
setOption('OverwriteDomain', 'true')
setOption('JavaHome',JAVA_HOME)
setOption('ServerStartMode', 'prod')

#=======================================================================================
# Set the user password for weblogic.
#=======================================================================================
print('Setting the password for user weblogic.')
cd('/')
cd('Security/base_domain/User/weblogic')
cmo.setPassword(PASSWORD)

#=======================================================================================
# Finalize the domain creation.
#=======================================================================================
writeDomain(DOMAIN_HOME + '/' + DOMAIN)
closeTemplate()

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
