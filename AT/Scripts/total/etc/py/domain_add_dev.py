#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys
####
DOMAIN_TEMPLATE= sys.argv[1]
DOMAIN = sys.argv[2]
DOMAIN_PORT = sys.argv[3]
DOMAIN_PASSWORD = sys.argv[4]
MACHINE = sys.argv[5]
#PRINCIPAL = MACHINE.split('.')
PRINCIPAL = 'kbwlsdev'
DOMAIN_HOME = sys.argv[6]
JAVA_HOME = sys.argv[7]
WL_HOME = sys.argv[8]
DOMAIN_ROOT = '/weblogic/' + DOMAIN
#Bruno##################
print DOMAIN_TEMPLATE
print DOMAIN
print DOMAIN_PORT
print DOMAIN_PASSWORD
print MACHINE
print PRINCIPAL
print DOMAIN_HOME
print JAVA_HOME
print WL_HOME
print DOMAIN_ROOT
###########################
#debug("true")
#redirect('/home/weblogic/debug_domain_add.log')

#=======================================================================================
# Open a domain template.
#=======================================================================================
print('Opening the domain template file ' + DOMAIN_TEMPLATE)
readTemplate(DOMAIN_TEMPLATE)
#print dumpStack()
#mangerico:

#selectTemplate('Basic WebLogic Server Domain', '12.2.1.3.0')
#loadTemplates()

#readTemplate("/opt/weblogic/12.2.1.2/wlserver/common/templates/wls/wls.jar")

#=======================================================================================
# Configure the Administration Server.
#=======================================================================================
print('Configuring the Administration Server.')
set('AdminServerName',DOMAIN + 'AdminServer')
cd('Servers/AdminServer')
set('Name',DOMAIN + 'AdminServer')
set('ListenAddress','')
set('ListenPort', int(DOMAIN_PORT))

#=======================================================================================
# Set the user password for weblogic.
#=======================================================================================
print('Setting the password for user weblogic.')
cd('/')
cd('Security/base_domain/User/weblogic')
cmo.setPassword(DOMAIN_PASSWORD)

#=======================================================================================
# Create Machine.
#=======================================================================================
print('Creating Machine ' + MACHINE + '.')
cd('/')
create(MACHINE, 'Machine')
cd('/Machines/' + MACHINE)
create(MACHINE, 'NodeManager')
cd('NodeManager/' + MACHINE)
set('NMType', 'SSH')
set('ListenPort', 22)
set('ShellCommand','ssh -o PasswordAuthentication=no -p %P %H ' + WL_HOME + '/common/bin/wlscontrol.sh -d %D -r ' + DOMAIN_ROOT + ' -s %S %C')

#=======================================================================================
# Set AdminConsole CookieName.
#=======================================================================================
print('Setting the AdminConsole CookieName to ' + DOMAIN + '_ADMINCONSOLESESSION.')
cd('/')
create(DOMAIN,'AdminConsole')
cd('/AdminConsole/' + DOMAIN)
set('CookieName',DOMAIN + '_ADMINCONSOLESESSION')

#=======================================================================================
# Disable on-demand deployment of internal applications.
#=======================================================================================
print('Disabling the on-demand deployment of internal applications parameter.')
cd('/')
set('InternalAppsDeployOnDemandEnabled','false')

#=======================================================================================
# Activate Configuration Archive
#=======================================================================================
print('Activating Configuration Archive')
set('ConfigBackupEnabled',true)
set('ArchiveConfigurationCount',3)

#=======================================================================================
# Create additional Providers.
#=======================================================================================
print('Creating Active Directory Provider.')
create(DOMAIN,'SecurityConfiguration')
cd('/SecurityConfiguration/' + DOMAIN + '/Realms/myrealm')
create('ActiveDirectoryAuthenticator','weblogic.security.providers.authentication.ActiveDirectoryAuthenticator','AuthenticationProvider')
cd('/SecurityConfiguration/' + DOMAIN + '/Realms/myrealm/AuthenticationProviders/ActiveDirectoryAuthenticator')
set('ControlFlag','SUFFICIENT')
set('Host','rittahubdcs.ritta.local')
set('Port',389)
#set('Principal',PRINCIPAL[0])
set('Principal',PRINCIPAL)
set('GroupBaseDN','DC=RITTA,DC=LOCAL')
set('UserBaseDN','DC=RITTA,DC=LOCAL')
set('UserNameAttribute','SAMAccountName')
set('UserFromNameFilter','(&(SAMAccountName=%u)(objectclass=user))')
set('GroupMembershipSearching','limited')
set('MaxGroupMembershipSearchLevel',500)
set('UseTokenGroupsForGroupMembershipLookup',true)
set('IgnoreDuplicateMembership',true)

print('Creating NegotiateIdentityAsserter Provider.')
cd('/SecurityConfiguration/' + DOMAIN + '/Realms/myrealm')
create('NegotiateIdentityAsserter','weblogic.security.providers.authentication.NegotiateIdentityAsserter','AuthenticationProvider')

#=======================================================================================
# Write the domain and close the domain template.
#=======================================================================================
print('Writing the domain information and closing the domain template.')
writeTemplate(DOMAIN_HOME + '/' + DOMAIN + '.jar')
closeTemplate()

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
