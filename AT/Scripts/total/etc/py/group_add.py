#=======================================================================================
# Import variables from arguments.
#=======================================================================================
import sys

ADMIN_HOST = sys.argv[1]
ADMIN_PORT = sys.argv[2]
ADMIN_PASSWORD = sys.argv[3]
APPNAME = sys.argv[4]
USERNAME = sys.argv[5]
GROUPNAME = sys.argv[6]

#=======================================================================================
# Connect to running domain.
#=======================================================================================
connect('weblogic',ADMIN_PASSWORD,'t3://' + ADMIN_HOST + ':' + ADMIN_PORT)

#=======================================================================================
# Check if group already exists
#=======================================================================================
atnr = cmo.getSecurityConfiguration().getDefaultRealm().lookupAuthenticationProvider("DefaultAuthenticator")
cursor = atnr.listGroups("*",0)

GROUPEXISTS="N"

while atnr.haveCurrent(cursor):
  group = atnr.getCurrentName(cursor)

  if group == GROUPNAME:
    GROUPEXISTS="Y"
    break
  else:
    atnr.advance(cursor)
atnr.close(cursor)

if GROUPEXISTS == "Y":
  print "Found group " + GROUPNAME + ", adding user " + USERNAME + " as member."
  atnr.addMemberToGroup(GROUPNAME,USERNAME) 
else:
  choice = "ND"

  while ( choice.lower() != "y" and choice.lower() != "n" ):
    choice = raw_input("No group named " + GROUPNAME + " found. Do you wish to create it?(y/n):")

  if (choice.lower() == "y"):
    atnr.createGroup(GROUPNAME,"Group for application " + APPNAME + ".")

    cursor = atnr.listGroups("*",0)

    GROUPEXISTS="N"

    while atnr.haveCurrent(cursor):
      group = atnr.getCurrentName(cursor)

      if group == GROUPNAME:
        GROUPEXISTS="Y"
        break
      else:
        atnr.advance(cursor)
    atnr.close(cursor)

    if GROUPEXISTS == "Y":
      print "Group " + GROUPNAME + " created successfully. Adding user " + USERNAME + " as member."
      atnr.addMemberToGroup(GROUPNAME,USERNAME)
    else:
      print "Unable to create group " + GROUPNAME + "."

#=======================================================================================
# Exit WLST.
#=======================================================================================
exit('y')

