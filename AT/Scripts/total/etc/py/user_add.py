#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
APPNAME = sys.argv[4]
USERNAME = sys.argv[5]
PASSWORD = sys.argv[6]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Check if user already exists
#=======================================================================================
atnr = cmo.getSecurityConfiguration().getDefaultRealm().lookupAuthenticationProvider("DefaultAuthenticator")
cursor = atnr.listUsers("*",0)

while atnr.haveCurrent(cursor):
  user = atnr.getCurrentName(cursor)

  if user == USERNAME:
    print "User already exists."
    atnr.close(cursor)
    exit()
  else:
    atnr.advance(cursor)

atnr.close(cursor)

#=======================================================================================
# Create User
#=======================================================================================
atnr.createUser(USERNAME,PASSWORD,'User for application ' + APPNAME)

USERCREATED="N"

cursor = atnr.listUsers("*",0)

while atnr.haveCurrent(cursor):
  user = atnr.getCurrentName(cursor)

  if user == USERNAME:
    USERCREATED="Y"
    break
  else:
    atnr.advance(cursor)

atnr.close(cursor)

if USERCREATED == "Y":
  print "User " + USERNAME + " created successfully."
else:
  print "Unable to create user " + USERNAME + "."

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')
