Rm .\ServerConfig\* -Confirm:$false
rm .\Createlab\* -Confirm:$false

. .\ServerConfig.ps1

ServerConfig -ConfigurationData .\Configs\DC1.psd1
ServerConfig -ConfigurationData .\Configs\DC2.psd1
ServerConfig -ConfigurationData .\Configs\SQL1.psd1
ServerConfig -ConfigurationData .\Configs\SQL2.psd1

. .\DscCreateLab.ps1 
    
$nodes = 'DC1','DC2','SQL1','SQL2'

foreach ($node in $nodes){
    Write-Output $node
    stop-vm  $node -TurnOff -force -Confirm:$false -ErrorAction SilentlyContinue
    Remove-VM $node -Force -confirm:$false -ErrorAction SilentlyContinue
    remove-item "H:\lab\$node" -Recurse -force -Confirm:$false -ErrorAction SilentlyContinue
    Createlab -ConfigurationData $ConfigData -Name $node
    Start-DscConfiguration -ComputerName Psam-h01 -Verbose -Wait -Path c:\iso\DSC1\Createlab -force
}
