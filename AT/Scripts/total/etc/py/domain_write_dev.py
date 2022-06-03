#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

DOMAIN = sys.argv[1]
DOMAIN_HOME = sys.argv[2]
JAVA_HOME = sys.argv[3]
KRB_LOGIN_FILE = '/opt/sso/krb5login.' + DOMAIN + '.conf'
KRB_MAIN_FILE = '/opt/sso/krb5.' + DOMAIN + '.conf'

#PASSWORD = sys.argv[4]

#=======================================================================================
# Open a domain template.
#=======================================================================================
print('Opening the domain template file ' + DOMAIN_HOME + '/' + DOMAIN + '.jar.')
readTemplate(DOMAIN_HOME + '/' + DOMAIN + '.jar')
#readTemplate("/opt/weblogic/12.2.1.0/wlserver/common/templates/wls/wls.jar")

#=======================================================================================
# Set domain options
#=======================================================================================
setOption('OverwriteDomain', 'true')
setOption('JavaHome',JAVA_HOME)

#=======================================================================================
# Set the user password for weblogic.
#=======================================================================================
#print('Setting the password for user weblogic.')
#cd('/')
#cd('Security/base_domain/User/weblogic')
#cmo.setPassword(PASSWORD)

#=======================================================================================
# Create Managed Servers.
#=======================================================================================
cd('/Servers/' + DOMAIN + 'AdminServer')
DOMAIN_PORT=cmo.getListenPort()

cd('/Machines')
machinelist=ls(returnMap='true')
MACHINE=machinelist[0]

values = (1,2)
for i in values:
  print('Creating managed server ' + DOMAIN + 'Server0' + str(i))
  cd('/')
  #Bruno##
  #SERVER_DOMAIN_ROOT = cmo.getRootDirectory()
  #print SERVER_DOMAIN_ROOT + "My print"
  ##
  create(DOMAIN + 'Server0' + str(i), 'Server')
  cd('Servers/' + DOMAIN + 'Server0' + str(i))
  create(DOMAIN + 'Server0' + str(i), 'ServerStart')
  set('ListenPort',int(DOMAIN_PORT) + (3 * int(i)))
  set('Machine',MACHINE)
  cd('/Servers/' + DOMAIN + 'Server0' + str(i) + '/ServerStart/' + DOMAIN + 'Server0' + str(i))
  # Set ServerRootDirectory because WLS12.1.2 NodeManager - Bruno 11/06/2014
  cmo.setRootDirectory(DOMAIN_HOME + '/' + DOMAIN + '/servers/' + DOMAIN + 'Server0' + str(i))
  ########################################################
  #set('Arguments','-server -Xms512m -Xmx512m -XX:MaxPermSize=256m -Dserver.root=' + DOMAIN_HOME + '/' + DOMAIN + '/servers/' + DOMAIN + 'Server0' + str(i) + ' -Djava.security.auth.login.config=' + DOMAIN_HOME + '/' + DOMAIN + '/krb5login.conf -Djava.security.krb5.conf=' + DOMAIN_HOME + '/' + DOMAIN + '/krb5.conf -Djavax.security.auth.useSubjectCredsOnly=false -Dweblogic.security.enableNegotiate=true')
  set('Arguments','-server -Xms512m -Xmx512m -XX:MaxPermSize=256m -Dserver.root=' + DOMAIN_HOME + '/' + DOMAIN + '/servers/' + DOMAIN + 'Server0' + str(i) + ' -Djava.security.auth.login.config=' + KRB_LOGIN_FILE + ' -Djava.security.krb5.conf=' + KRB_MAIN_FILE + ' -Djavax.security.auth.useSubjectCredsOnly=false -Dweblogic.security.enableNegotiate=true')

#=======================================================================================
# Create cluster.
#=======================================================================================
print('Creating cluster ' + DOMAIN + 'Cluster01 and assigning servers.')
cd('/')
create(DOMAIN + 'Cluster01', 'Cluster')
for i in values:
  assign('Server', DOMAIN + 'Server0' + str(i), 'Cluster', DOMAIN + 'Cluster01')

#=======================================================================================
# Write the domain and close the domain template.
#=======================================================================================
print('Writing the domain information and closing the domain template.')
writeDomain(DOMAIN_HOME + '/' + DOMAIN)
closeTemplate()

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')

