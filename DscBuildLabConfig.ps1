$ConfigData =@{
    AllNodes = @(
        @{
            NodeName         = '*'
            DnsServers       = '192.168.100.10','192.168.100.11'
            InterfaceAlias   = 'Ethernet'
            SubnetMask       = 24
            AddressFamily    = 'IPv4'
            Gateway          = '192.168.100.1'
            DomainName       = "Psam.Lab"
            RetryCount       = 20
            RetryIntervalSec = 30
        }, 
        @{
            Nodename                        = "DC1"
            Role                            = "Primary DC"
            IP                              = '192.168.100.10'
            PSDSCAllowPlainTextPassword     = $True 
            PSDscAllowDomainUser            = $True
            ProtectedFromAccidentalDeletion = $true            
         },
        @{
            Nodename                    = 'DC2'
            Role                        = 'Secondary DC'
            IP                          = '192.168.100.11'

            PSDSCAllowPlainTextPassword = $True 
            PSDscAllowDomainUser        = $True
        },
        @{
            Nodename                    = 'SQL1'
            Role                        = 'SQL'
            IP                          = '192.168.100.12'
            JoinOU                      = 'OU=Server,OU=Psam,DC=Psam,DC=Lab'
            PSDSCAllowPlainTextPassword = $True 
            PSDscAllowDomainUser        = $True
        },
         @{
            Nodename                    = 'SQL2'
            Role                        = 'SQL'
            IP                          = '192.168.100.13'
            JoinOU                      = 'OU=Server,OU=Psam,DC=Psam,DC=Lab'
            PSDSCAllowPlainTextPassword = $True 
            PSDscAllowDomainUser        = $True
        }
    ) 
 } 