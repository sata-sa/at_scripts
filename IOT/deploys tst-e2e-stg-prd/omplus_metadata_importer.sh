#!/bin/bash

HOST=$1
PORT=$2
RELEASE=$3
PATH=$4
NOW=$(/bin/date +'%Y-%m-%dT%H:%M:%S') #current date in the format 'yyyy-mm-ddTHh:Mm:Ss'
YESTERDAY=$(/bin/date -d yesterday +'%Y-%m-%dT%H:%M:%S') #current date in the format 'yyyy-mm-ddTHh:Mm:Ss'
ARGNUM=$#

if [ "$ARGNUM" -ne "4" ];
then
{
echo
echo USAGE: $0 OMPLUS_SERVER_HOST OMPLUS_SERVER_PORT RELEASE_DESCRIPTION FILE_PATH
echo 
echo ex: $0 vitl000127 17004 FD18.5P1.3_DECOMPOSER /tmp/example_file
echo
exit 1
}
fi

echo -----------------------
echo - OM+ WebService Call -
echo -----------------------

# Call to the operation ImportMetadataFromFile on the OMPManager webservice
#/usr/bin/curl -s --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:\"\"" -d  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soap="http://soap.interfaces.ws.web.camel.omp.telco.com/"><soapenv:Header/><soapenv:Body><soap:importMetadataFromFile><!--Optional:--><arg0><!--type: boolean--><active>true</active><!--type: string--><comment>'$RELEASE'</comment><!--type: dateTime--><effectiveDate>'"$NOW"'</effectiveDate><!--type: string--><path>'$PATH'</path><!--type: string--><username>celfocus</username></arg0></soap:importMetadataFromFile></soapenv:Body></soapenv:Envelope>' http://$HOST:$PORT/omplus/services/soapManager > /tmp/output.xml
/usr/bin/curl -s --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:\"\"" -d  '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:soap="http://soap.interfaces.ws.web.camel.omp.telco.com/"><soapenv:Header/><soapenv:Body><soap:importMetadataFromFile><!--Optional:--><arg0><!--type: boolean--><active>true</active><!--type: string--><comment>'$RELEASE'</comment><!--type: dateTime--><effectiveDate>'"$YESTERDAY"'</effectiveDate><!--type: string--><path>'$PATH'</path><!--type: string--><username>celfocus</username></arg0></soap:importMetadataFromFile></soapenv:Body></soapenv:Envelope>' http://$HOST:$PORT/omplus/services/soapManager > /tmp/output.xml

#STATUS=$(/usr/bin/xmllint --xpath 'string(//statusCode)' /tmp/output.xml)
STATUS=$(/bin/grep -Po '(?<=<statusCode>)\w+(?=</statusCode>)' /tmp/output.xml)

#MESSAGE=$(/usr/openv/pdde/pdopensource/bin/xmllint --xpath 'string(//statusMessage)' /tmp/output.xml)
MESSAGE=$(/bin/grep -Po '(?<=<statusMessage>)\w+(?=</statusMessage>)' /tmp/output.xml)

echo Effective Date: $YESTERDAY
echo Status: $STATUS
echo Message: $MESSAGE

if [ "$STATUS" = "0" ]; then
  exit 0
else
  exit 1
fi
