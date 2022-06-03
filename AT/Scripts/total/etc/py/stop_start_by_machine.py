################################################
#       Import variables from arguments.       #
################################################
import sys

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]
MACHINE = sys.argv[4]
STOPorSTART = sys.argv[5]
MANAGEDSERVER = []
MANAGEDSERVERW = []
TASKSSTH = []
TASKSSTR = []
COUNTER = 0

################################################
#              Connect WLS Admin.              #
################################################
def connectWLSAdmin():
    try:
        connect('weblogic', WL_PASS, 't3://' + WL_HOST + ':' + WL_PORT)
        print('Successfully connected')
    except:
        print 'Unable to connect to admin server...'
        exit()


################################################
#     Get ManagedServer Name for Machine       #
################################################
def getManagedServers():
    domainRuntime()

    SERVERS = domainRuntimeService.getServerRuntimes()
    for S in SERVERS:
        machine = S.getCurrentMachine()
        serverName = S.getName()
        if(machine == MACHINE):
            MANAGEDSERVER.append(serverName)


    for S2 in cmo.getServerLifeCycleRuntimes():
        serverName1 = S2.getName()
        domainConfig()
        cd('/')
        cd('Servers/' + serverName1)
        machine1 = cmo.getMachine()
        if MACHINE + "," in str(machine1):
            MANAGEDSERVERW.append(serverName1)
            domainRuntime()

################################################
#              Stop ManagedServer              #
################################################

def stopManagedServers():
    domainRuntime()
    global COUNTER
    for S1 in cmo.getServerLifeCycleRuntimes():
        serverName = S1.getName()
        if(serverName in MANAGEDSERVER):
            ManagedServerLifeCycleRuntime = cmo.lookupServerLifeCycleRuntime(serverName)
            TASKSSTH.append(ManagedServerLifeCycleRuntime.shutdown(5, true))

    return TASKSSTH

def waitCompleted(TASKSSTH):
    while len(TASKSSTH) > 0:
        for task in TASKSSTH:
            if task.getStatus() != 'TASK IN PROGRESS':
                TASKSSTH.remove(task)
                java.lang.Thread.sleep(3000)

################################################
#             Start ManagedServer              #
################################################

def startManagedServers():
    domainRuntime()
    global COUNTER
    for S1 in cmo.getServerLifeCycleRuntimes():
        serverName = S1.getName()
        if (serverName in MANAGEDSERVERW):
            ManagedServerLifeCycleRuntime = cmo.lookupServerLifeCycleRuntime(serverName)
            TASKSSTR.append(ManagedServerLifeCycleRuntime.start())

    return TASKSSTR

def waitCompleted(TASKSSTR):
    while len(TASKSSTR) > 0:
        for task in TASKSSTR:
            if task.getStatus() != 'TASK IN PROGRESS':
                TASKSSTR.remove(task)
                java.lang.Thread.sleep(3000)

################################################
#             Status ManagedServer             #
################################################

def showStatus():
    domainRuntime()
    for S2 in cmo.getServerLifeCycleRuntimes():
        print S2.getName() + " >> " + S2.getState()

################################################
#               Main Execution                 #
################################################
connectWLSAdmin()
getManagedServers()
if(STOPorSTART == 'stop'):
    TASKSTH = stopManagedServers()
    waitCompleted(TASKSSTH)
    print 'Shutdown process completed!!!'
    showStatus()
else:
    TASKSTR = startManagedServers()
    waitCompleted(TASKSSTR)
    print 'Startup process completed!!!'
    showStatus()
