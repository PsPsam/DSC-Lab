#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName       = ''
            WindowsFeature = 'AD-Domain-Services', 'RSAT-ADDS'
            PSDSCAllowPlainTextPassword     = $True 
            PSDscAllowDomainUser            = $True
            LCM = @(
                @{
                    RebootNodeIfNeeded = $true
                    ActionAfterReboot  = 'ContinueConfiguration'
                }
            )
            NIC            = @(
                @{
                    ID             = 'NIC1'
                    IPAddress      = '192.168.100.'
                    InterfaceAlias = 'Ethernet'
                    GatewayAdress  = '192.168.100.1'
                    SubnetMask     = '24'
                    AddressFamily  = 'IPv4'
                    DNSAdress      = '192.168.100.2'
                    DependsOn      = '[xIPAddress]NIC1'
                }
            )
            Rename        = @( 
                @{
                    ID         = 'RenameComputer'
                    Name       = ''
                    DomainName = 'Psam.Lab'
                    JoinOU     = 'OU=Server,OU=Psam,DC=Psam,DC=Lab'
                    #Credential
                    DependsOn = '[xIPAddress]NIC1', '[xDefaultGatewayAddress]NIC1', '[xDnsServerAddress]NIC1'
                }
            )
            Reboot         = @(
                @{
                    Name        = 'RebootRename'
                    DependsOn = '[xComputer]RenameComputer'
                }
                @{
                    Name        = 'RebootDomain'
                    DependsOn = '[xADDomain]DC'
                }
            )
            DomainWait = @(
                @{
                    ID                   = 'DomainWait'
                    DomainName           = 'Psam.Lab'
                    #DomainUserCredential = $DomainUserCred
                    RetryCount           = 20
                    RetryIntervalSec     = 30
                }
            )

        }
    )
}