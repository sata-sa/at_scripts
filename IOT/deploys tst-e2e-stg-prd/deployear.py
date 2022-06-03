import sys
import os
import re
from java.lang 
import System
import getopt
#Python Script to manage applications in weblogic server.
#This script takes input from command line and executes it.
#It can be used to check status,stop,start,deploy,undeploy of applications in weblogic server using weblogic wlst tool.


#========================
#Log file
#========================
#logfile = open('/tmp/WLST_application.log', 'a')

#========================
#Usage Section
#========================
def usage():

        print "Usage:"
        print "java weblogic.WLST deployear.py -u username -p password -a adminUrl [:] -n deploymentName -v deploymentNameValidation -f deploymentFile -t deploymentTarget\n"
        sys.exit(2)

#========================
#Connect To Domain
#========================
def connectToDomain():

        try:
                connect(username, password, adminUrl)
                print '\nSuccessfully connected to the domain\n'

        except:
                print '\nThe domain is unreacheable. Please try again\n'
                sys.exit(2)
#========================
#Checking Application Status Section
#========================

def appstatus():

        try:
                domainRuntime()
                cd('domainRuntime:/AppRuntimeStateRuntime/AppRuntimeStateRuntime')
                currentState = cmo.getCurrentState(deploymentValidation, deploymentTarget)
                return currentState
        except:
                print '\nError in getting current status of ',deploymentValidation,'\n'
                exit()
#========================
#Application undeployment Section
#========================

def undeployApplication():

        try:
                print '\nStopping and undeploying ..',deploymentName,'\n'
                stopApplication(deploymentName, targets=deploymentTarget)
                undeploy(deploymentName, targets=deploymentTarget)
        except:
                print '\nError during the stop and undeployment of ',deploymentName,'\n'
#========================
#Applications deployment Section
#========================

def deployApplication():

        try:
                print '\nDeploying the application ', deploymentName,'\n'
                deploy(deploymentName,deploymentFile,targets=deploymentTarget)
                startApplication(deploymentName)
        except:
                print '\nError during the deployment of ', deploymentName,'\n'
                sys.exit(2)

#========================
#Main Control Block For Operations
#========================

def deployUndeployMain():

                appList = re.findall(deploymentName, ls('/AppDeployments'))
                if len(appList) >= 1:
                        print 'Application', deploymentName,' Found on server ', deploymentTarget,', undeploying application..\n'
                        print '=============================================================================='
                        print 'Application Already Exists, Undeploying...'
                        print '=============================================================================='
                        undeployApplication()
                        print '=============================================================================='
                        print 'Redeploying Application ',deploymentName,' on', deploymentTarget,' server...'
                        print '=============================================================================='
                        deployApplication()
                else:
                        print '=============================================================================='
                        print 'No application with same name...'
                        print 'Deploying Application ', deploymentName,' on',deploymentTarget,' server...'
                        print '=============================================================================='
                        deployApplication()


#========================
#Input Values Validation Section
#========================

if __name__=='__main__' or __name__== 'main':

        try:
                opts, args = getopt.getopt(sys.argv[1:], "u:p:a:n:v:f:t:", ["username=", "password=", "adminUrl=", "deploymentName=", "deploymentValidation", "deploymentFile=", "deploymentTarget="])

        except getopt.GetoptError, err:
                print str(err)
                usage()

username = ''
password = ''
adminUrl = ''
deploymentName = ''
deploymentValidation = ''
deploymentFile = ''
deploymentTarget = ''

for opt, arg in opts:
        if opt == "-u":
                username = arg
        elif opt == "-p":
                password = arg
        elif opt == "-a":
                adminUrl = arg
        elif opt == "-n":
                deploymentName = arg
        elif opt == "-v":
                deploymentValidation = arg
        elif opt == "-f":
                deploymentFile = arg
        elif opt == "-t":
                deploymentTarget = arg

if username == "":
        print "\nMissing \"-u username\" parameter.\n"
        usage()
elif password == "":
        print "\nMissing \"-p password\" parameter.\n"
        usage()
elif adminUrl == "":
        print "\nMissing \"-a adminUrl\" parameter.\n"
        usage()
elif deploymentName == "":
        print "\nMissing \"-n deploymentName\" parameter.\n"
        usage()
elif deploymentValidation == "":
        print "\nMissing \"-v deploymentNameValidation\" parameter.\n"
        usage()
elif deploymentFile == "":
        print "\nMissing \"-c deploymentFile\" parameter.\n"
        usage()
elif deploymentTarget == "":
        print "\nMissing \"-c deploymentTarget\" parameter.\n"
        usage()

#========================
#Execute Block
#========================

print '=============================================================================='
print 'Connecting to Admin Server...'
print '=============================================================================='
connectToDomain()
print '=============================================================================='
print 'Starting Deployment...'
print '=============================================================================='
deployUndeployMain()
print '=============================================================================='
print 'Validate Deployment State...'
print '=============================================================================='
status = appstatus()
if status == "STATE_ACTIVE":
        print '\nStatus of', deploymentValidation,'with succesfull\n'
else:
        print '\nStatus of', deploymentValidation,'with failed\n'
#       sys.exit(130)
print '\n=============================================================================='
print 'Execution completed...'
print '=============================================================================='
logfile.close()
disconnect()
exit()
