readDomain('/weblogic/gci02q')

installDir = /opt/wls-10.3.3/wlserver_10.3/wlserver_10.3
templateLocation = installDir + '/common/templates/applications/wls_webservice_jaxws.jar'
addTemplate(templateLocation)

updateDomain()
closeDomain()

readDomain('/weblogic/gci02q')

setDistDestType('WseeJaxwsJmsModule', 'UDD')


