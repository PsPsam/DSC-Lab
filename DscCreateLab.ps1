$configData = @{
    AllNodes = @(
        @{
            NodeName = 'Psam-H01'
            Role     = 'VM'
            # Modules that is needed
            xNetworkingPath = "$(gmo xNetworking -ListAvailable | % modulebase | select -first 1)"
            xComputerManagementpath = "$(gmo xComputerManagement -ListAvailable | % modulebase | select -first 1)"
            xPendingReboot = "$(gmo xPendingReboot -ListAvailable | % modulebase | select -first 1)"
            XActiveDirectory = "$(gmo XActiveDirectory -ListAvailable | % modulebase | select -first 1)"
            xSQLServer = "$(gmo xSQLServer -ListAvailable | % modulebase | select -first 1)"
            unattendedFilePathToCopy = "$((Resolve-Path '.\unattend.xml').Path)"
        }
    )
}

Configuration Createlab
{
    Param
    (
        $BaseDir = (Get-Location).path,
        #[string[]]$NodeName = 'localhost',
        [string]$Name = 'Localhost',
        $BaseVhdPath = 'H:\SourceDisk\2012R2_201607.vhdx',
        $MinMemory = 1GB,   # amount of memory in mb
        $MaxMemory = 4GB,   # amount of memory in mb
        $StartupMemory = 2GB,   # amount of memory in mb
        $CPU = '2',       # number of CPUs to allocate
        $SwitchName = 'Lab', # Switch name for Lab
        $SourceBase = 'C:\Iso\Source'
    )
    
    # Files to be injected
    $DSCSourcePath = "$BaseDir\ServerConfig\$name.mof"
    $DSCRebootTrueSourcePath = "$BaseDir\ServerConfig\$name.meta.mof"

    # Where to inject te modules
    $ModuleTargetpath = "Program Files\WindowsPowerShell\Modules\"
        
    #DestinationPath
    $DestinationPath = "h:\Lab\$name"

    Import-DscResource -ModuleName xHyper-v, PSDesiredStateConfiguration
    Node $AllNodes.Where{$_.Role -eq "VM"}.Nodename
    {
        File Folder {
            Type = 'Directory'
            DestinationPath = $DestinationPath
            Ensure = "Present"
        }

        # Create a Switch to be used by the VM (Internal)
        xVMSwitch Lab
        {
            Ensure = 'Present'
            Name   = 'Lab'
            Type   = 'Internal'
        }

        # Create a differencing VHDX (Diff vhdx)
        xVHD NewVHD1
        {
            Ensure     = 'Present'
            Name       = $name
            Path       = $DestinationPath
            Generation = "VHDX"
            ParentPath = $BaseVhdPath
            DependsOn  = '[File]Folder'
        }
        xVhdFile Copyfiles
        {
            VhdPath = "$DestinationPath\$name.vhdx"

            FileDirectory = @(
                MSFT_xFileDirectory {
                                        SourcePath = $Node.unattendedFilePathToCopy
                                        DestinationPath = 'Unattend.xml'
                                    }
                MSFT_xFileDirectory {
                                        SourcePath = $Node.xNetworkingPath
                                        DestinationPath = "$ModuleTargetpath\xNetworking\"
                                    }
	            MSFT_xFileDirectory {
                                        SourcePath = $Node.xComputerManagementpath
                                        DestinationPath = "$ModuleTargetpath\xComputerManagement\"
                                    }
                MSFT_xFileDirectory {
                                        SourcePath = $Node.xPendingReboot
                                        DestinationPath = "$ModuleTargetpath\xPendingReboot\"
                                    }
                
                MSFT_xFileDirectory {
                                        SourcePath = $DSCSourcePath
                                        DestinationPath = "Windows\System32\Configuration\pending.mof"
                                    }
                MSFT_xFileDirectory {
                                        SourcePath = $DSCRebootTrueSourcePath
                                        DestinationPath = "Windows\System32\Configuration\metaconfig.mof"
                                    }
                if (($name -eq 'DC1') -or ($name -eq 'DC2')){
                    MSFT_xFileDirectory {
                                        SourcePath = $Node.XActiveDirectory
                                        DestinationPath = "$ModuleTargetpath\XActiveDirectory\"
                                    }
                }
                if (($name -eq 'SQL1') -or ($name -eq 'SQL2')){
                     MSFT_xFileDirectory {
                                        SourcePath = "$sourceBase\SQL2014"
                                        DestinationPath = "Install\SQL"
                                    }
                    MSFT_xFileDirectory {
                                        SourcePath = $Node.xSQLServer
                                        DestinationPath = "$ModuleTargetpath\xSQLServer"
                                    }
                }
            )
            DependsOn = "[xVHD]NewVhd1"
        }
 
        xVMHyperV Server
        {
            Name               = $name
            SwitchName         = $SwitchName
            VhdPath            = "$DestinationPath\$name.vhdx"
            MaximumMemory      = $MaxMemory
            MinimumMemory      = $MinMemory
            StartupMemory      = $StartupMemory
            EnableGuestService = $true
            RestartIfNeeded    = $true
            ProcessorCount     = $Cpu
            Path               = $Node.DestinationPath
            Generation         = 2
            State              = 'Running'
            DependsOn          = '[xVHD]NewVHD1','[xVMSwitch]Lab','[xvhdFile]CopyFiles','[File]Folder'
        }
    }
}

