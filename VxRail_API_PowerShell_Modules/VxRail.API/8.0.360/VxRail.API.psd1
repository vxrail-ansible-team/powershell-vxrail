# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

#
# Module manifest for module 'VxRail.API'

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '8.0.360'

# ID used to uniquely identify this module
GUID = 'ea1a9aa8-88ae-425c-a1ea-fdd44dd45348'

# Company or vendor of this module
CompanyName = 'Dell EMC'

# Copyright statement for this module
Copyright = '(c) 2019 Dell EMC. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
@{"ModuleName"="VxRail.API.Chassis";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.Cluster";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.Disk";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.Host";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.LCM";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.Support";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.System";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.Certificate";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.Telemetry";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.VC";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.SysBringup";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.SatelliteNode";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.STIG";"ModuleVersion"="8.0.360"}
@{"ModuleName"="VxRail.API.DellIdentitiyService";"ModuleVersion"="8.0.360"}
)

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @()

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

