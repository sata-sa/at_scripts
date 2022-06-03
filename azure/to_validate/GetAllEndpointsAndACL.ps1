#Abrir o powershell e ligar a nossa conta
#colocar este script na pasta onde o powershell está a iniciar este script
#0. (só se tiver na rede da NB)
#Activar o proxy server no powershell, mandatorio através da Novabase
#[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
#
#1.
#p/ linkar com a conta do Azure a sessão:
#Add-AzureAccount
#tipicamente c:\Users\nbxxxxx>
#para executar fazer ./GetAllEndpointsAndACL.ps1

#set new logarray for holding the entry
$LogArray = @()
#get a list of azureVM's
$vmlist = get-azureVM 
foreach($vm in $vmlist){
    #get the endpoints for this VM
    $Port = Get-AzureEndpoint -vm $vm 
    #get the length of the portarray
    $PortLength = $Port.length
    #get the ACL's for this VM
    $acl = Get-AzureAclConfig -vm $vm
    #Number of ACL rules
    $AclLength = $acl.Rules.Count
    #Walk through the endpoints
    for($i=0; $i -lt $PortLength; $i++){
        #walk through the ACL for each endpoint and add them to an object
        for($n=0; $n -lt $AclLength; $N++){
            $output = new-object PSObject
            $output | add-member -Membertype NoteProperty -Name "Machine" -value "$($vm.name)"
            $output | add-member -Membertype NoteProperty -Name "PortName" -value "$($port[$i].name)"
            $output | add-member -Membertype NoteProperty -Name "ExternalPort" -value "$($port[$i].port)"
            $output | add-member -Membertype NoteProperty -Name "InternalPort" -value "$($port[$i].localport)"
            $output | add-member -Membertype NoteProperty -Name "protocol" -value "$($port[$i].protocol)"
            if($AclLength -gt 1){
                $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "$($acl.remotesubnet[$n])"
                $output | add-member -Membertype NoteProperty -Name "Description" -value "$($acl.Description[$n])"
                $output | add-member -Membertype NoteProperty -Name "Permission" -value "$($acl.Action[$n])"
            }
            else
            {
                $output | add-member -Membertype NoteProperty -Name "RemoteSubnet" -value "$($acl.remotesubnet)"
                $output | add-member -Membertype NoteProperty -Name "Description" -value "$($acl.Description)"
                $output | add-member -Membertype NoteProperty -Name "Permission" -value "$($acl.Action)"
            }
            $logarray += $output #add the current machinename, port and ACL to the array.
        }
    }
}
#write the logarray to a CSV file.
$logArray | convertto-Csv -NoTypeInformation | out-file AzureACL.csv -append -Encoding utf8