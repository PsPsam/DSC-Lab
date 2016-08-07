#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName                    = 'SQL2'
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
                    IPAddress      = '192.168.100.5'
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
                    Name       = 'SQL2'
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

        }
    )
}