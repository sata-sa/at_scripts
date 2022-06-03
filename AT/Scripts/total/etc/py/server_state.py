import os
import sys

class bcolors:
	HEADER = '\033[95m'
	OKBLUE = '\033[1;94m'
	OKGREEN = '\033[1;92m'
	WARNING = '\033[1;93m'
	UNKNOWN = '\033[1;38m'
	MISC = '\033[35m'
	FAIL = '\033[38m'
	ENDC = '\033[0m'

def disable(self):
	self.HEADER = ''
	self.OKBLUE = ''
	self.OKGREEN = ''
	self.WARNING = ''
	self.MISC = ''
	self.UNKNOWN = ''
	self.FAIL = ''
	self.ENDC = ''

def healthstate(server_name):
	try:
		cd('/ServerRuntimes/'+server_name+'/ThreadPoolRuntime/ThreadPoolRuntime')
		S=get('HealthState')
		X=S.toString().split(',')[1].split(':')[1]
		if X == "HEALTH_OK":
			print 'ServerHealth -> ' + bcolors.OKGREEN + X + bcolors.ENDC + '\n';
		elif X == "HEALTH_WARN":
			print 'ServerHealth -> ' + bcolors.WARNING + X + bcolors.ENDC + '\n';
		elif X == "HEALTH_FAILED":
			print 'ServerHealth -> ' + bcolors.FAIL + X + bcolors.ENDC + '\n';
		elif X == "HEALTH_CRITICAL":
			print 'ServerHealth -> ' + bcolors.FAIL + X + bcolors.ENDC + '\n';
		elif X == "HEALTH_OVERLOADED":
			print 'ServerHealth -> ' + bcolors.OKBLUE + X + bcolors.ENDC + '\n';
		elif X == "LOW_MEMORY_REASON":
			print 'ServerHealth -> ' + bcolors.WARNING + X + bcolors.ENDC + '\n';
	except WLSTException,e:
		print dumpStack()

#connect('weblogic','c1e5uck5or4','t3://10.191.33.88:22000')
#connect('weblogic','c1e5uck5or4','t3://10.191.33.88:16000')
#connect('weblogic','c1e5uck5or4','t3://10.191.33.88:10000')
#connect('weblogic','z6rp9gka1t5','t3://10.191.33.108:14000')
connect('weblogic','c1e5uck5or4','t3://10.191.33.88:14000')
#connect('weblogic','c1e5uck5or4','t3://10.191.33.88:16000')
#connect('weblogic','c1e5uck5or4','t3://10.191.33.88:12000')
domainConfig()
SERVERS = cmo.getServers()
domainRuntime()

for server in SERVERS:
	try:
		cd('/ServerLifeCycleRuntimes/' + server.getName())
		STATE = get('State');
		if STATE == "RUNNING":
			print '##### ' + server.getName() + ' #####'
			print 'ServerState -> ' + bcolors.OKGREEN + STATE + bcolors.ENDC
			healthstate(server.getName())
		elif STATE == "ADMIN":
			print '##### ' + server.getName() + ' #####'
			print 'ServerState -> ' + bcolors.WARNING + STATE + bcolors.ENDC
			healthstate(server.getName())
		elif STATE == "SHUTDOWN":
			print '##### ' + server.getName() + ' #####'
			print 'ServerState -> ' + bcolors.OKBLUE + STATE + bcolors.ENDC
			healthstate(server.getName())
	except WLSTException,e:
		print dumpStack()


disconnect()
