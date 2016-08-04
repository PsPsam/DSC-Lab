configuration BuildLab
{
    $domainjoin = 'PsamJoin'
    #unsecure, not safe or recommended way to do this 
    $Creds = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
    $DomainUserCred = New-Object System.Management.Automation.PSCredential ("psam\$domainjoin", $Creds) 
    $DomainAdminCred = New-Object System.Management.Automation.PSCredential ("PsamAdm", $Creds) 
    $SafeModeAdminCred = New-Object System.Management.Automation.PSCredential ("Administrator", $Creds) 
    #- See more at: http://jacobbenson.com/?paged=2#sthash.o81190dr.dpuf
    
          
    Import-DscResource -ModuleName XActiveDirectory, xNetworking, xComputerManagement, PSDesiredStateConfiguration, xPendingReboot

    # One can evaluate expressions to get the node list
    # E.g: $AllNodes.Where("Role -eq Web").NodeName
    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename
    {
        LocalConfigurationManager
        {
            # This is false by default
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration' 
        } 
        xDhcpClient DisabledDhcpClient
        {
            State          = 'Disabled'
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily
        }

        xIPAddress NewIPAddress
        {
            IPAddress      = $node.ip
            InterfaceAlias = $node.InterfaceAlias
            SubnetMask     = $node.SubnetMask    
            AddressFamily  = $node.AddressFamily 
            DependsOn      = '[xDhcpClient]DisabledDhcpClient'
        }

        xDefaultGatewayAddress NewDefaultGateway
        {
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily 
            Address        = $node.gateway
            DependsOn      = '[xIPAddress]NewIPAddress'
        }
        xDnsServerAddress NewDnsServer
        {
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily 
            Address        = $node.DnsServers
            DependsOn      = '[xIPAddress]NewIPAddress'
        }

        xComputer NewName
        { 
            Name      = 'DC1'
            DependsOn = '[xDhcpClient]DisabledDhcpClient','[xIPAddress]NewIPAddress','[xDefaultGatewayAddress]NewDefaultGateway','[xDnsServerAddress]NewDnsServer'
        }
        xPendingReboot RebootCheck
        {
            Name      = "RebootCheck"
            DependsOn = '[xComputer]NewName'
        }
        WindowsFeature ADDSInstall
        {
            Ensure               = 'Present'
            Name                 = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
            DependsOn            = '[xComputer]NewName'
        }

        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure               = "Present"             
            Name                 = "RSAT-ADDS"
            IncludeAllSubFeature = $true
            DependsOn            = '[WindowsFeature]ADDSInstall'             
        } 

        xAddomain FirstDC
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $DomainAdminCred
            SafemodeAdministratorPassword = $SafeModeAdminCred
            #DomainNetbiosName             = 'PSAM'
            DependsOn                     = '[WindowsFeature]ADDSInstall'
        }
        
#        xWaitForADDomain DomainWait
#        {
#            DomainName           = $Node.DomainName
#            DomainUserCredential = $DomainAdminCred
#            RetryCount           = $Node.RetryCount
#            RetryIntervalSec     = $Node.RetryIntervalSec
#            DependsOn            = '[xADDomain]FirstDC'
#        }
        
        xPendingReboot RebootDomain
        {
            Name      = "RebootCheck"
            DependsOn = '[xADDomain]FirstDC'   
        }        
#        xADRecycleBin RecyclyBin
#        {
#            ForestFQDN                        = $Node.DomainName
#            EnterpriseAdministratorCredential = $DomainAdminCred
#            DependsOn                         = '[xADDomain]FirstDC'
#        }

        xADOrganizationalUnit PsamOU
        {
            Name                            = 'Psam'
            Path                            = 'DC=Psam,DC=Lab'
            Description                     = 'Psam lab OU'
            ProtectedFromAccidentalDeletion = $node.ProtectedFromAccidentalDeletion
            DependsOn                       = '[xPendingReboot]RebootDomain'
        }
        xADOrganizationalUnit PsamUserOU
        {
            Name                            = 'User'
            Path                            = 'OU=Psam,DC=Psam,DC=Lab'
            Description                     = 'Psam User lab OU'
            ProtectedFromAccidentalDeletion = $node.ProtectedFromAccidentalDeletion
            DependsOn                       = '[xADOrganizationalUnit]PsamOU'
        }
        xADOrganizationalUnit PsamComputerOU
        {
            Name                            = 'Computer'
            Path                            = 'OU=Psam,DC=Psam,DC=Lab'
            Description                     = 'Psam Computer lab OU'
            ProtectedFromAccidentalDeletion = $node.ProtectedFromAccidentalDeletion
            DependsOn                       = '[xADOrganizationalUnit]PsamOU'
        }
        xADOrganizationalUnit PsamServerrOU
        {
            Name                            = 'Server'
            Path                            = 'OU=Psam,DC=Psam,DC=Lab'
            Description                     = 'Psam server lab OU'
            ProtectedFromAccidentalDeletion = $node.ProtectedFromAccidentalDeletion
            DependsOn                       = '[xADOrganizationalUnit]PsamOU'
        }
        xADOrganizationalUnit PsamAdminOU
        {
            Name                            = 'Admin'
            Path                            = 'OU=Psam,DC=Psam,DC=Lab'
            Description                     = 'Psam Admin lab OU'
            ProtectedFromAccidentalDeletion = $node.ProtectedFromAccidentalDeletion
            DependsOn                       = '[xADOrganizationalUnit]PsamOU'
        }
        xADUser UserPsamAdmin
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $domaincred
            UserName                      = $domainjoin
            Password                      = $DomainUserCred
            UserPrincipalName             = "$domainjoin@psam.lab"
            DisplayName                   = $domainjoin
            Path                          = 'OU=Admin,OU=Psam,DC=Psam,DC=Lab'
            Ensure                        = "Present"
            PasswordNeverExpires          = $true
            CannotChangePassword          = $true
            DependsOn                     = '[xADOrganizationalUnit]PsamAdminOU'
        }
        xADGroup GroupPsamAdmin
        
        {
            GroupName        = 'Domain Admins'
            MembersToInclude = $domainjoin
            Ensure           = 'Present'
            DependsOn        = '[xADUser]UserPsamAdmin'
        }
    }
    Node $AllNodes.Where{$_.Role -eq "Secondary DC"}.Nodename
    {

        LocalConfigurationManager
        {
            # This is false by default
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration' 
        } 
# Network
        xDhcpClient DisabledDhcpClient
        {
            State          = 'Disabled'
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily
        }
        xIPAddress NewIPAddress
        {
            IPAddress      = $node.ip
            InterfaceAlias = $node.InterfaceAlias
            SubnetMask     = $node.SubnetMask    
            AddressFamily  = $node.AddressFamily 
            DependsOn      = '[xDhcpClient]DisabledDhcpClient'
        }
        xDefaultGatewayAddress NewDefaultGateway
        {
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily 
            Address        = $node.gateway
            DependsOn      = '[xIPAddress]NewIPAddress'
        }
        xDnsServerAddress NewDnsServer
        {
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily 
            Address        = $node.DnsServers
            DependsOn      = '[xIPAddress]NewIPAddress'
        }
        xWaitForADDomain DomainWait
        {
            DomainName           = $Node.DomainName
            DomainUserCredential = $DomainUserCred
            RetryCount           = $Node.RetryCount
            RetryIntervalSec     = $Node.RetryIntervalSec
        }
#Name
        xComputer NewName
        { 
            Name          = $node.nodename
            DomainName    = $node.DomainName
            JoinOU        = $node.JoinOU
            Credential    = $DomainUserCred            
            DependsOn     = '[xWaitForADDomain]DomainWait'
        }
        xPendingReboot RebootCheck
        {
            Name      = "RebootCheck"
            DependsOn = '[xComputer]NewName'  
        }

#Domain        
        WindowsFeature ADDSInstall
        {
            Ensure               = 'Present'
            Name                 = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
            DependsOn            = '[xComputer]NewName'
        }

        
        xADDomainController SecondDC
        {
            DomainName                    = $Node.DomainName
            DomainAdministratorCredential = $DomainUserCred
            SafemodeAdministratorPassword = $SafeModeAdminCred
            #DomainNetbiosName             = 'PSAM'
            DependsOn                     = '[WindowsFeature]ADDSInstall'
        }
        xPendingReboot RebootDomain
        {
            Name      = "RebootCheck"
            DependsOn = '[xADDomainController]SecondDC' 
        }
         
        # Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure               = "Present"             
            Name                 = "RSAT-ADDS"
            IncludeAllSubFeature = $true
            DependsOn            = '[xADDomainController]SecondDC'              
        }       
        

    }
    Node $AllNodes.Where{$_.Role -eq "SQL"}.Nodename
    {

        LocalConfigurationManager
        {
            # This is false by default
            RebootNodeIfNeeded = $true
            ActionAfterReboot  = 'ContinueConfiguration' 
        } 
# Network
        xDhcpClient DisabledDhcpClient
        {
            State          = 'Disabled'
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily
        }
        xIPAddress NewIPAddress
        {
            IPAddress      = $node.ip
            InterfaceAlias = $node.InterfaceAlias
            SubnetMask     = $node.SubnetMask    
            AddressFamily  = $node.AddressFamily 
            DependsOn      = '[xDhcpClient]DisabledDhcpClient'
        }
        xDefaultGatewayAddress NewDefaultGateway
        {
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily 
            Address        = $node.gateway
            DependsOn      = '[xIPAddress]NewIPAddress'
        }
        xDnsServerAddress NewDnsServer
        {
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily 
            Address        = $node.DnsServers
            DependsOn      = '[xIPAddress]NewIPAddress'
        }
        xNetBIOS DisableNetBIOS 
        {
            InterfaceAlias   = $node.InterfaceAlias
            Setting          = 'Disable'
        }

#Domain        
        xWaitForADDomain DomainWait
        {
            DomainName           = $Node.DomainName
            DomainUserCredential = $DomainUserCred
            RetryCount           = $Node.RetryCount
            RetryIntervalSec     = $Node.RetryIntervalSec
        }

#Name Domain Join
        xComputer NewName
        { 
            Name          = $node.nodename
            DomainName    = $node.DomainName
            JoinOU        = $node.JoinOU
            Credential    = $DomainUserCred
            DependsOn     = '[xDefaultGatewayAddress]NewDefaultGateway','[xDnsServerAddress]NewDnsServer','[xNetBIOS]DisableNetBIOS'
        }
        xPendingReboot RebootCheck
        {
            Name      = "RebootCheck"
            DependsOn = '[xComputer]NewName'  
        }
    }
}

# Compile the configuration file to a MOF format
#BuildLab -configuration $configuration

# Run the configuration on localhost
#Start-DscConfiguration -Path .\LabDC1 –ComputerName localhost -Wait -Force -Verbose 