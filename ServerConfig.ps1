#requires -Version 4
configuration ServerConfig {
    $domainjoin = 'DscJoin'
    #unsecure, not safe or recommended way to do this 
    $Creds = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
    #$DomainUserCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("Dsc\$domainjoin", $Creds) 
    $DomainUserCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("Dsc\Administrator", $Creds) 
    $DomainAdminCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('DscAdm', $Creds) 
    $SafeModeAdminCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ('Administrator', $Creds)

    Import-DscResource -ModuleName PSDesiredStateConfiguration, XActiveDirectory, xNetworking, xComputerManagement, xPendingReboot
    node $AllNodes.NodeName {
        $Node.LCM.ForEach({
                LocalConfigurationManager  {
                    RebootNodeIfNeeded = $_.RebootNodeIfNeeded
                    ActionAfterReboot = $_.ActionAfterReboot
                }    
        })
        $Node.NIC.ForEach({
                xIPAddress $_.ID {
                    InterfaceAlias = $_.InterfaceAlias
                    AddressFamily  = $_.AddressFamily
                    IPAddress      = $_.IPAddress
                    SubnetMask     = $_.SubnetMask
                    
                }
                xDefaultGatewayAddress $_.ID
                {
                    
                    InterfaceAlias = $_.InterfaceAlias
                    AddressFamily  = $_.AddressFamily
                    Address        = $_.GatewayAdress 
                    DependsOn      = $_.DependsOn
                }
                xDNSServerAddress $_.ID 
                {
                    InterfaceAlias = $_.InterfaceAlias
                    AddressFamily  = $_.AddressFamily
                    Address        = $_.DNSAdress
                    DependsOn      = $_.DependsOn
                }
        })
        $Node.Rename.ForEach({
                xComputer $_.id {
                    Name        = $_.Name
                    DependsOn   = $_.DependsOn
                }
        })
        $Node.RenameComputerDomain.ForEach({
                xComputer $_.id {
                    Name        = $_.Name
                    DomainName  = $_.DomainName
                    JoinOU      = $_.JoinOU
                    Credential  = $DomainUserCred
                    DependsOn   = $_.DependsOn
                }
        })
        $Node.Reboot.ForEach({
                xPendingReboot $_.name {
                    Name        = $_.name
                    DependsOn   = $_.DependsOn
                }
        })
        $Node.WindowsFeature.ForEach({
                WindowsFeature $_ {
                    Name   = $_
                    Ensure = 'Present'
                }
        })
        $Node.Service.ForEach({
                Service $_.Name {
                    Name        = $_.Name
                    StartupType = 'Automatic'
                    State       = 'Running'
                    DependsOn   = $_.DependsOn
                }
        })
        $Node.Domain.ForEach({
                xAddomain $_.ID {
                    DomainName  = $_.DomainName
                    DomainAdministratorCredential = $DomainAdminCred
                    SafemodeAdministratorPassword = $SafeModeAdminCred
                    DependsOn   = $_.DependsOn
                }
        })
        $Node.OU.ForEach({
                xADOrganizationalUnit $_.ID {
                    Name                             = $_.Name
                    Path                             = $_.Path
                    Description                      = $_.Description
                    ProtectedFromAccidentalDeletion  = $_.ProtectedFromAccidentalDeletion
                    DependsOn                        = $_.DependsOn
                }
        })
        $Node.User.ForEach({
                xADUser $_.ID {
                    UserName             = $_.UserName
                    Password             = $DomainUserCred
                    DomainName           = $_.DomainName
                    UserPrincipalName    = $_.UserPrincipalName
                    DisplayName          = $_.DisplayName
                    Path                 = $_.Path
                    Ensure               = $_.Ensure
                    PasswordNeverExpires = $_.PasswordNeverExpires
                    CannotChangePassword = $_.CannotChangePassword
                    DependsOn            = $_.DependsOn
                }
        })
        $Node.Group.ForEach({
                xADGroup $_.ID {
                    GroupName        = $_.GroupName       
                    MembersToInclude = $_.MembersToInclude
                    Ensure           = $_.Ensure          
                    DependsOn        = $_.DependsOn       
                }
        })
        $Node.DomainWait.ForEach({
                xWaitForADDomain $_.ID {
                    DomainName           = $_.DomainName       
                    DomainUserCredential = $DomainUserCred
                    RetryCount           = $_.RetryCount
                    RetryIntervalSec     = $_.RetryIntervalSec          
                }
        })
        $Node.DC.ForEach({
                xADDomainController $_.ID {
                    DomainName                    = $_.DomainName       
                    DomainAdministratorCredential = $DomainUserCred
                    SafemodeAdministratorPassword = $SafeModeAdminCred          
                    DependsOn                     = $_.DependsOn       
                }
        })
    }
}