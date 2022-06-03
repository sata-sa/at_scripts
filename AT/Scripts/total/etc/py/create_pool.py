################################################
#       Import variables from arguments.       #
################################################
import sys

WL_HOST = sys.argv[1]
WL_PORT = sys.argv[2]
WL_PASS = sys.argv[3]
DS_NAME = sys.argv[4]
DS_JNDI = sys.argv[5]
DB_HOST = sys.argv[6]
DB_PORT = sys.argv[7]
DB_SID  = sys.argv[8]
DB_USER = sys.argv[9]
DB_PASS = sys.argv[10]
JDBC_DRIVER = sys.argv[11]
CACHE_SIZE = sys.argv[12]
TRANSACTION = sys.argv[13]
INIT_SQL = sys.argv[14]
DS_TARGET = sys.argv[15]
DB2_SUBSYS = sys.argv[16]
DB2_APNA = sys.argv[17]
GRIDLINK = sys.argv[18]
DBPROTOCOL = sys.argv[19]
ONSSERVERS = sys.argv[20]
JDBCURL= sys.argv[21]
ENVIR= sys.argv[22]

################################################
#              Connect WLS Admin.              #
################################################
def connectWLSAdmin() :
   try:
      connect('weblogic',WL_PASS,'t3://' + WL_HOST + ':' + WL_PORT)
      print('Successfully connected')
      edit()
      startEdit()
   except:
      print 'Unable to connect to admin server...'
      exit()

################################################
#              Create DataSource.              #
################################################
def createDataSource() :
   try:
      print('Creating DataSource...')
      cd('/')
      cmo.createJDBCSystemResource(DS_NAME) 
      DSRESOURCE='/JDBCSystemResources/' + DS_NAME + '/JDBCResource/' + DS_NAME

      #Set DataSource Name
      cd(DSRESOURCE)
      set('Name',DS_NAME)
      
      #Set JNDI Name
      cd(DSRESOURCE + '/JDBCDataSourceParams/' + DS_NAME)
      set('JNDINames',jarray.array([String(DS_JNDI)], String)) 

      #Set URL and Driver and Properties
      if JDBC_DRIVER in ('com.ddtek.jdbc.shadow.ShadowDriver') :
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME)
         cmo.setUrl('jdbc:datadirect:shadow://' + DB_HOST + ':' + DB_PORT)
         cmo.setDriverName(JDBC_DRIVER)
         cmo.setPassword(DB_PASS)
      else :
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME)
         if GRIDLINK in ('y') :
            #cmo.setUrl('jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=' + DBPROTOCOL + ')(HOST=' + DB_HOST + ')(PORT=' + DB_PORT + ')))(CONNECT_DATA=(SERVICE_NAME=' + DB_SID + ')))')
            cmo.setUrl(JDBCURL)
            cmo.setDriverName(JDBC_DRIVER)
            cmo.setPassword(DB_PASS)
            cd('/JDBCSystemResources/' + DS_NAME + '/JDBCResource/' + DS_NAME + '/JDBCOracleParams/' + DS_NAME)
            cmo.setFanEnabled(true) 
            cmo.setOnsNodeList(ONSSERVERS)
         else :
            cmo.setUrl('jdbc:oracle:thin:@//' + DB_HOST + ':' + DB_PORT + '/' + DB_SID)
            cmo.setDriverName(JDBC_DRIVER)
            cmo.setPassword(DB_PASS)
 
      #Set Properties
      if JDBC_DRIVER in ('com.ddtek.jdbc.shadow.ShadowDriver') :
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('UID')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/UID')
         cmo.setValue(DB_USER)
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('PORT')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/PORT')
         cmo.setValue(DB_PORT)
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('dataSourceName')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/dataSourceName')
         cmo.setValue(DB_SID)
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('HOST')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/HOST')
         cmo.setValue(DB_HOST)
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('user')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/user')
         cmo.setValue(DB_USER)
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('DBTY')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/DBTY')
         cmo.setValue('DB2')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('SUBSYS')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/SUBSYS')
         cmo.setValue(DB2_SUBSYS)
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('APNA')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/APNA')
         cmo.setValue(DB2_APNA)
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('AUST')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/AUST')
         cmo.setValue('NO')
         #XAOP=JTS
         #XAEN=TWO-PHASE
      else :
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME)
         cmo.createProperty('user')
         cd(DSRESOURCE + '/JDBCDriverParams/' + DS_NAME + '/Properties/' + DS_NAME + '/Properties/user')
         cmo.setValue(DB_USER)


   #Set Connection Pool specific parameters and properties
      cd(DSRESOURCE + '/JDBCConnectionPoolParams/'+ DS_NAME)
      cmo.setStatementCacheSize(int(CACHE_SIZE))
      cmo.setTestConnectionsOnReserve(true)
      cmo.setTestFrequencySeconds(300)
      if JDBC_DRIVER in ('com.ddtek.jdbc.shadow.ShadowDriver') :
         #cmo.setInitialCapacity(0)
         cmo.setMinCapacity(10)
         cmo.setMaxCapacity(10)
         cmo.setSecondsToTrustAnIdlePoolConnection(0)
         cmo.setTestTableName('SYSIBM.SYSDUMMY1')
         cmo.setInactiveConnectionTimeoutSeconds(60)
         cd(DSRESOURCE + '/JDBCDataSourceParams/'+ DS_NAME)
         cmo.setGlobalTransactionsProtocol(TRANSACTION)
      elif ENVIR == 'qua' :
         #cmo.setInitialCapacity(0)
         cmo.setMinCapacity(3)
         cmo.setMaxCapacity(3)
         cmo.setSecondsToTrustAnIdlePoolConnection(0)
         cmo.setTestTableName('SQL SELECT 1 FROM DUAL')
         cmo.setInactiveConnectionTimeoutSeconds(60)
         cmo.setStatementTimeout(240)
         cd(DSRESOURCE + '/JDBCDataSourceParams/'+ DS_NAME)
         cmo.setGlobalTransactionsProtocol(TRANSACTION)
      else :
         cmo.setMinCapacity(10)
         cmo.setMaxCapacity(10)
         cmo.setSecondsToTrustAnIdlePoolConnection(0)
         cmo.setTestTableName('SQL SELECT 1 FROM DUAL')
         cmo.setInactiveConnectionTimeoutSeconds(60)
         cmo.setStatementTimeout(240)
         cd(DSRESOURCE + '/JDBCDataSourceParams/'+ DS_NAME)
         cmo.setGlobalTransactionsProtocol(TRANSACTION)
      if INIT_SQL in ('NONE') :
   #Set INIT_SQL DataSource
         cd('/JDBCSystemResources/' + DS_NAME)
         #set('Targets',jarray.array([ObjectName('com.bea:Name=' + DS_TARGET + ',Type=Cluster')], ObjectName))
      else :
         cd(DSRESOURCE + '/JDBCConnectionPoolParams/' + DS_NAME)
         cmo.setInitSql(INIT_SQL)
   #Set DataSource Target
      if DS_TARGET in ('NONE') : 
         cd('/JDBCSystemResources/' + DS_NAME)
      else :
         cd('/JDBCSystemResources/' + DS_NAME)
         set('Targets',jarray.array([ObjectName('com.bea:Name=' + DS_TARGET + ',Type=Cluster')], ObjectName))
         #dumpStack()
   except Exception, inst:
      #print inst
      #print sys.exc_info()[0]
      print ''
      print ''
      print ''
      print '###################################'
      print '#  Unable to create DataSource... #'
      print '###################################'
      print ''
      print 'Exception:'
      print inst
      print sys.exc_info()[0]
      print ''
      print ''
      print ''
      cancelEdit('y')
      exit()
      disconnect()
  


#MAIN
connectWLSAdmin()
createDataSource()
save()
activate()
disconnect()
