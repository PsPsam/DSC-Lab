#requires -Version 4
configuration ServerConfig {
    Import-DscResource -ModuleName PSDesiredStateConfiguration, XActiveDirectory, xNetworking, xComputerManagement, xPendingReboot
    node $AllNodes.NodeName {
        $Node.LocalConfigurationManager.ForEach({
                LocalConfigurationManager {
                    # This is false by default
                    RebootNodeIfNeeded = $true
                    ActionAfterReboot  = 'ContinueConfiguration' 
                }
        })

        $Node.NIC.ForEach({
                xIPAddress $_.ID {
                    IPAddress = $_.IP
                    InterfaceAlias = $_.Adapter
                    SubnetMask = $_.SubnetMask
                    AddressFamily = $_.Family
                }
                xDNSServerAddress $_.ID {
                    Address = $_.DNS
                    InterfaceAlias = $_.Adapter
                    AddressFamily = $_.Family
                    DependsOn = $_.DependsOn
                }
                xDefaultGatewayAddress $_.ID
                {
                    InterfaceAlias = $_.InterfaceAlias
                    AddressFamily  = $_.AddressFamily 
                    Address        = $_.gateway
                    DependsOn      = $_.DependsOn
                }
        })

        $Node.xComputer.foreach({
            xComputer $_.Name {
                Name      = $_.Name
                DependsOn = $_.DependsOn
            }
        })

        $Node.WindowsFeature.ForEach({
            WindowsFeature $_ {
                Name = $_
                Ensure = 'Present'
                DependsOn = $_.DependsOn
            }
        })

        $Node.xPendingReboot.ForEach({ 
            Reboot $_.Name {
                Name      = "RebootCheck"
                DependsOn = '[xADDomain]FirstDC'   
            }
        }) 
    }
}