# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.
#
# Module manifest for module 'VxRail.PowerCLI'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'VxRail.API.Depot.psm1'

# Version number of this module.
ModuleVersion = '8.0.360'

# ID used to uniquely identify this module
GUID = 'db9c99b2-821e-4b85-b24d-f109ac3c9b79'

# Company or vendor of this module
CompanyName = 'Dell EMC'

# Copyright statement for this module
Copyright = '(c) 2019 Dell EMC. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
@{"ModuleName"="VxRail.API.Depot.Common";"ModuleVersion"="8.0.360"}
)

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = "*-*"

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = "*"


# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

}



