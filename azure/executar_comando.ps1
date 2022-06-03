Import-AzureRmContext -Path “D:\profile\autoload.json”

foreach ($vm in Get-Content D:\storeit\Notas\azure\executar_comando_list.txt) {
write-host "Executing command on VM" $vm "."
az vm run-command invoke -g "SG_IOT_GLOBAL-RG" -n "$vm" --command-id RunShellScript --scripts "useradd emrmuser && echo emrmuser5arda5#2018 | passwd --stdin emrmuser && sed -i '$ a emrmuser ALL = (ALL) ALL' /etc/sudoers.d/waagent"
}

foreach ($vm in Get-Content D:\storeit\Notas\azure\list_tmp.txt) {
write-host "Executing command on VM" $vm "."
az vm run-command invoke -g "SG_IOT_GLOBAL-RG" -n "$vm" --command-id RunShellScript --scripts "touch /etc/sudoers.d/waagent && sed -i '$ a emrmuser ALL = (ALL) ALL' /etc/sudoers.d/waagent && chmod 440 /etc/sudoers.d/waagent "
}