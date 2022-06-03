#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

DOMAIN = sys.argv[1]
DOMAIN_PORT = sys.argv[2]
DOMAIN_PASSWORD = sys.argv[3]
MACHINE = sys.argv[4]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',DOMAIN_PASSWORD,'t3://' + MACHINE + ':' + DOMAIN_PORT)

#=======================================================================================
# Reorder Authentication Providers and configure DefaultAuthenticator.
#=======================================================================================
edit()
startEdit()

print('Reordering Authentication Providers.')
cd('/SecurityConfiguration/' + DOMAIN + '/Realms/myrealm')
set('AuthenticationProviders',jarray.array([ObjectName('Security:Name=myrealmNegotiateIdentityAsserter'), ObjectName('Security:Name=myrealmActiveDirectoryAuthenticator'), ObjectName('Security:Name=myrealmDefaultAuthenticator'), ObjectName('Security:Name=myrealmDefaultIdentityAsserter')], ObjectName))

print('Configuring DefaultAuthenticator.')
cd('/SecurityConfiguration/' + DOMAIN + '/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
set('ControlFlag','SUFFICIENT')

#=======================================================================================
# Set the password for the EmbeddedLDAP.
#=======================================================================================
print('Setting the password for the EmbeddedLDAP.')
cd('/EmbeddedLDAP/' + DOMAIN)
cmo.setCredential(DOMAIN_PASSWORD)

#=======================================================================================
# Set Invocation Timeout
#=======================================================================================
print ('Configure Invocation Timeout')
cd('/JMX/' + DOMAIN)
cmo.setInvocationTimeoutSeconds(15)

activate()
#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
