#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName                    = 'DC2'
            WindowsFeature              = 'AD-Domain-Services', 'RSAT-ADDS'
            PSDSCAllowPlainTextPassword = $True 
            PSDscAllowDomainUser        = $True
            LCM = @(
                @{
                    RebootNodeIfNeeded = $true
                    ActionAfterReboot  = 'ContinueConfiguration'
                }
            )
            NIC = @(
                @{
                    ID             = 'NIC1'
                    IPAddress      = '192.168.100.3'
                    InterfaceAlias = 'Ethernet'
                    GatewayAdress  = '192.168.100.1'
                    SubnetMask     = '24'
                    AddressFamily  = 'IPv4'
                    DNSAdress      = '192.168.100.2'
                    DependsOn      = '[xIPAddress]NIC1'
                }
            )
            RenameComputerDomain = @( 
                @{
                    ID         = 'RenameComputer'
                    Name       = 'DC2'
                    DomainName = 'Dsc.Lab'
                    JoinOU     = 'OU=Server,OU=Dsc,DC=Dsc,DC=Lab'
                    DependsOn  = '[xWaitForADDomain]DomainWait'
                    
                }
            )
            Reboot = @(
                @{
                    Name      = 'RebootRename'
                    DependsOn = '[xComputer]RenameComputer'
                }
                @{
                    Name      = 'RebootDomain'
                    DependsOn = '[xADDomainController]DC'
                }
            )
            DomainWait = @(
                @{
                    ID               = 'DomainWait'
                    DomainName       = 'Dsc.Lab'
                    RetryCount       = 20
                    RetryIntervalSec = 30
                    DependsOn        = '[xIPAddress]NIC1', '[xDefaultGatewayAddress]NIC1', '[xDnsServerAddress]NIC1'
                }
            )
            DC = @(
                @{
                    ID         = 'DC'
                    DomainName = 'Dsc.Lab'
                    DependsOn  = '[WindowsFeature]AD-Domain-Services'
                }
            )
        }
    )
}