Import-AzureRmContext -Path “D:\profile\autoload.json”

$vms = Get-AzureRmVM -ResourceGroupName "SG_IOT_GLOBAL-RG"

foreach ($vm in $vms) {
    Write-Host $vm.Name (Get-AzureRmVM -ResourceGroupName "SG_IOT_GLOBAL-RG" -Name $vm.Name -Status).VMAgent.VMAgentVersion
}