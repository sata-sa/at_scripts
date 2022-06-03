Import-AzureRmContext -Path �D:\profile\autoload.json�

$vms = Get-AzureRmVM -ResourceGroupName "SG_IOT_GLOBAL-RG"

foreach ($vm in $vms) {
    Write-Host $vm.Name (Get-AzureRmVM -ResourceGroupName "SG_IOT_GLOBAL-RG" -Name $vm.Name).HardwareProfile.VmSize
}

$vms = get-azurermvm
$nics = get-azurermnetworkinterface | where VirtualMachine -NE $null #skip Nics with no VM

foreach($nic in $nics)
{
    $vm = $vms | where-object -Property Id -EQ $nic.VirtualMachine.id
    $prv =  $nic.IpConfigurations | select-object -ExpandProperty PrivateIpAddress
    Write-Output "$($vm.Name) $prv"
}