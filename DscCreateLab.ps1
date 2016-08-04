Configuration Createlab
{
    Param
    (
        #[string[]]$NodeName = 'localhost',
        $Name = 'Lab',
        $BaseVhdPath = 'H:\SourceDisk\2012R2_201607.vhdx',
        $MinMemory = 1GB,   # amount of memory in mb
        $MaxMemory = 4GB,   # amount of memory in mb
        $StartupMemory = 2GB,   # amount of memory in mb
        $CPU = '2',       # number of CPUs to allocate
        $SwitchName = 'Lab', # Switch name for Lab
        [validatescript({Test-Path $_})]
        $unattendedFilePathToCopy = (Resolve-Path '.\unattendNoRunas.xml').Path,
        
        # Modules that is needed
        $xNetworkingPath = "$(gmo xNetworking -ListAvailable | % modulebase | select -first 1)",
        $xComputerManagementpath = "$(gmo xComputerManagement -ListAvailable | % modulebase | select -first 1)",
        $xPendingReboot = "$(gmo xPendingReboot -ListAvailable | % modulebase | select -first 1)",
        $XActiveDirectory = "$(gmo XActiveDirectory -ListAvailable | % modulebase | select -first 1)",
        
        # Files to be injected
        
        $DSCSourcePath = "c:\iso\dsc\buildlab\$($name).mof",
        $DSCRebootTrueSourcePath = "c:\iso\dsc\BuildLab\$($name).meta.mof",
        #$DSCRebootFalseSourcePath = "c:\iso\dsc\RebootFalse\localhost.meta.mof",
        $DSCps1 = "c:\iso\dsc\DscBuildLab.ps1",

        $ModuleTargetpath = "Program Files\WindowsPowerShell\Modules\"
        
    )

    Import-DscResource -ModuleName xHyper-v, PSDesiredStateConfiguration

    File Folder {
        Type = 'Directory'
        DestinationPath = "h:\Lab\$($name)"
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
        Path       = "h:\Lab\$($name)\"
        Generation = "VHDX"
        ParentPath = $BaseVhdPath
        DependsOn  = '[File]Folder'
    }

    xVhdFile CopyUnattendXML
    {
        VhdPath = "h:\Lab\$($name)\$($name).vhdx"
        FileDirectory = @(
            MSFT_xFileDirectory {
                                    SourcePath = $unattendedFilePathToCopy
                                    DestinationPath = 'Unattend.xml'
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $xNetworkingPath
                                    DestinationPath = "$ModuleTargetpath\xNetworking\"
                                }
	        MSFT_xFileDirectory {
                                    SourcePath = $xComputerManagementpath
                                    DestinationPath = "$ModuleTargetpath\xComputerManagement\"
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $xPendingReboot
                                    DestinationPath = "$ModuleTargetpath\xPendingReboot\"
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $XActiveDirectory
                                    DestinationPath = "$ModuleTargetpath\XActiveDirectory\"
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $DSCSourcePath
                                    DestinationPath = "Windows\System32\Configuration\pending.mof"
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $DSCSourcePath
                                    DestinationPath = "Windows\System32\Configuration\pending.mof.old"
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $DSCRebootTrueSourcePath
                                    DestinationPath = "Windows\System32\Configuration\metaconfig.mof"
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $DSCRebootTrueSourcePath
                                    DestinationPath = "Windows\System32\Configuration\metaconfig.mof.old"
                                }
            MSFT_xFileDirectory {
                                    SourcePath = $DSCps1
                                    DestinationPath = "DSC\lab.ps1"
                                }
        )
        DependsOn = "[xVHD]NewVhd1"
    }
 
    xVMHyperV Server
    {
        Name               = "$($name)"
        SwitchName         = $SwitchName
        VhdPath            = "h:\Lab\$($name)\$($name).vhdx"
        MaximumMemory      = $MaxMemory
        MinimumMemory      = $MinMemory
        StartupMemory      = $StartupMemory
        EnableGuestService = $true
        RestartIfNeeded    = $true
        ProcessorCount     = $Cpu
        DependsOn          = '[xVHD]NewVHD1','[xVMSwitch]Lab','[xvhdFile]CopyUnattendXML','[File]Folder'
#        DependsOn          = '[xVHD]NewVHD1','[xVMSwitch]Lab','[File]Folder'
        Path               = "H:\Lab\$($name)\"
        Generation         = 2
        State              = 'Running'
    }
}

