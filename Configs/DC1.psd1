#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName = 'DC1'
            WindowsFeature = 'AD-Domain-Services', 'RSAT-ADDS'
            PSDSCAllowPlainTextPassword     = $True 
            PSDscAllowDomainUser            = $True
            LCM = @(
                @{
                    RebootNodeIfNeeded = $true
                    ActionAfterReboot  = 'ContinueConfiguration'
                }
            )
            NIC = @(
                @{
                    ID             = 'NIC1'
                    IPAddress      = '192.168.100.2'
                    InterfaceAlias = 'Ethernet'
                    GatewayAdress  = '192.168.100.1'
                    SubnetMask     = '24'
                    AddressFamily  = 'IPv4'
                    DNSAdress      = '192.168.100.2'
                    DependsOn      = '[xIPAddress]NIC1'
                }
            )
            Rename = @( 
                @{
                    ID        = 'RenameComputer'
                    Name      = 'DC1'
                    DependsOn = '[xIPAddress]NIC1', '[xDefaultGatewayAddress]NIC1', '[xDnsServerAddress]NIC1'
                }
            )
            Reboot = @(
                @{
                    Name        = 'RebootRename'
                    DependsOn = '[xComputer]RenameComputer'
                }
                @{
                    Name        = 'RebootDomain'
                    DependsOn = '[xADDomain]FirstDC'
                }
            )
            Domain = @(
                @{
                    ID         = 'FirstDC'
                    DomainName = 'Dsc.Lab'
                    DependsOn  = '[WindowsFeature]AD-Domain-Services'
                }
            )
            OU = @(
                @{
                    ID                              = 'DscOU'
                    Name                            = 'Dsc'
                    Path                            = 'DC=Dsc,DC=Lab'
                    Description                     = 'Dsc lab OU'
                    ProtectedFromAccidentalDeletion = $true
                    DependsOn                       = '[xPendingReboot]RebootDomain'
                }
                @{
                    ID                              = 'DscOUUser'
                    Name                            = 'User'
                    Path                            = 'OU=Dsc,DC=Dsc,DC=Lab'
                    Description                     = 'Dsc User lab OU'
                    ProtectedFromAccidentalDeletion = $true
                    DependsOn                       = '[xADOrganizationalUnit]DscOU'
                }
                @{
                    ID                              = 'DscOUComputer'
                    Name                            = 'Computer'
                    Path                            = 'OU=Dsc,DC=Dsc,DC=Lab'
                    Description                     = 'Dsc Computer lab OU'
                    ProtectedFromAccidentalDeletion = $true
                    DependsOn                       = '[xADOrganizationalUnit]DscOU'
                }
                @{
                    ID                              = 'DscServerrOU'
                    Name                            = 'Server'
                    Path                            = 'OU=Dsc,DC=Dsc,DC=Lab'
                    Description                     = 'Dsc server lab OU'
                    ProtectedFromAccidentalDeletion = $true
                    DependsOn                       = '[xADOrganizationalUnit]DscOU'
                }
                @{
                    ID                              = 'DscAdminOU'
                    Name                            = 'Admin'
                    Path                            = 'OU=Dsc,DC=Dsc,DC=Lab'
                    Description                     = 'Dsc Admin lab OU'
                    ProtectedFromAccidentalDeletion = $true
                    DependsOn                       = '[xADOrganizationalUnit]DscOU'
                }
            )
            User = @(
                @{
                    ID                   = 'UserDscAdmin'
                    DomainName           = 'Dsc.Lab'
                    UserName             = 'DscJoin'
                    UserPrincipalName    = 'DscJoin@Dsc.lab'
                    DisplayName          = 'domainjoin'
                    Path                 = 'OU=Admin,OU=Dsc,DC=Dsc,DC=Lab'
                    Ensure               = 'Present'
                    PasswordNeverExpires = $true
                    CannotChangePassword = $true
                    DependsOn            = '[xADOrganizationalUnit]DscAdminOU'
                }
            )
            Group = @(
                @{
                    ID               = 'GroupDscAdmin'
                    GroupName        = 'Domain Admins'
                    MembersToInclude = 'DscJoin'
                    Ensure           = 'Present'
                    DependsOn        = '[xADUser]UserDscAdmin'
                }
            )
        }
    )
}