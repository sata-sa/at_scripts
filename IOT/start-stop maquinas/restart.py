import socket;

def validState(op, state):
        if (op=='start' and state == 'RUNNING'):
                return False
        elif (op=='stop' and state != 'RUNNING'):
                return False

        return True

def running(tasks):
        for task in tasks:
                if task.isRunning():
                        return True
        return False

def lifecycleOp(managedServersArray, op):
        serverLifecycles = cmo.getServerLifeCycleRuntimes()

        taskList = list()
        for serverLifecycle in serverLifecycles:
                if (validState(op, serverLifecycle.getState()) and serverLifecycle.getName() in managedServersArray):
                        if (op == 'start'):
                                taskList.append(serverLifecycle.start())
                                print 'Adding server ' + serverLifecycle.getName() + ' to start list'
                        else:
                                taskList.append(serverLifecycle.forceShutdown())
                                print 'Adding server ' + serverLifecycle.getName() + ' to stop list'

        while running(taskList):
                for task in taskList:
                        if (task.isRunning() == 1):
                                print 'Waiting for ' + task.getOperation() + ' operation on server ' + task.getServerName() + ' to complete'

                java.lang.Thread.sleep(2000)

print 'starting the script ....'
adminUrl = sys.argv[1]
print 'adminUrl=' + adminUrl
userName = sys.argv[2]
print 'userName=' + userName
password = sys.argv[3]
print 'password=' + password
managedServers = sys.argv[4]
print 'managedServers=' + managedServers
op = sys.argv[5]
print 'op=' + op

managedServersArray = managedServers.split(',')

print 'Connecting to admin server';
connect(userName, password, adminUrl);

domainRuntime();

if (op == 'restart'):
        lifecycleOp(managedServersArray, 'stop')
        java.lang.Thread.sleep(5000)
        lifecycleOp(managedServersArray, 'start')
else:
        lifecycleOp(managedServersArray, op)

print 'Finished'
print 'Disconnecting from the admin server';
disconnect();

