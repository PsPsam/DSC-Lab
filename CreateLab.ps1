rm .\BuildLab\* -force -Confirm:$false

. .\DscBuildLab.ps1
BuildLab -ConfigurationData $ConfigData 

. .\DscCreateLab.ps1

$nodes = 'DC1','DC2','SQL1','SQL2'

foreach ($node in $nodes){
    stop-vm $node -TurnOff -force -Confirm:$false -ErrorAction SilentlyContinue ; Remove-VM $node -Force -confirm:$false -ErrorAction SilentlyContinue; rm "h:\lab\$node" -Recurse -force -Confirm:$false -ErrorAction SilentlyContinue
    Createlab -Name $node
    Start-DscConfiguration -ComputerName localhost -Verbose -Wait -Path C:\ISO\DSC\Createlab\ -force
}



#stop-vm dc1 -force -Confirm:$false; Remove-VM DC1 -Force -confirm:$false; rm h:\lab\dc1 -Recurse -force -Confirm:$false
#Createlab -Name DC1
#Start-DscConfiguration -ComputerName localhost -Verbose -Wait -Path C:\ISO\DSC\Createlab\ -force
#
#
#stop-vm dc2 -force -Confirm:$false; Remove-VM DC2 -Force -confirm:$false; rm h:\lab\dc2 -Recurse -force -Confirm:$false
#Createlab -Name DC2
#Start-DscConfiguration -ComputerName localhost -Verbose -Wait -Path C:\ISO\DSC\Createlab\ -force