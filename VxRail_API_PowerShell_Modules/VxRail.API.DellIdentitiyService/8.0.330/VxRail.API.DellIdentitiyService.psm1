# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"

. "$commonPath"


<#
.Synopsis
Initiate a new device code flow

.Description
Initiate a new device code flow. This API returns the verification URL and the user code. Go to the verification URL to authenticate a given support account with the DI token and activate access.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Notes
Initiate a new device code flow. This API returns the verification URL and the user code. Go to the verification URL to authenticate a given support account with the DI token and activate access.

.Example
Start-DeviceAuth -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password>

#>

function Start-DeviceAuth {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )
         
    $uri = '/rest/vxm/v1/device-auth/start'

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth
        }
        return $ret
    } catch {
        write-host $_
    }    
}


# <#
# .Synopsis
# Purge the existing support account configuration

# .Description
# Purge the existing support account configuration. This also revokes the refresh token cached by the token service. The access token used will not be revoked.

# .Parameter Server
# VxM IP or FQDN.

# .Parameter Username
# Valid vCenter username which has either Administrator or HCIA role.

# .Parameter Password
# Use corresponding password for username.

# .Notes
# Purge the existing support account configuration. This also revokes the refresh token cached by the token service. The access token used will not be revoked.

# .Example
# Logout-DeviceAuth -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password>

# #>

function Logout-DeviceAuth {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password
    )
         
    $uri = '/rest/vxm/v1/device-auth/logout'
        
    try {             
        doPost -Server $Server -Api $uri -Username $Username -Password $Password
    }
    catch {
        HandleInvokeRestMethodException -URL $uri
    }
}

<#
.Synopsis
Initiate a new device code flow

.Description
Initiate a new device code flow. This API returns the verification URL and the user code. Go to the verification URL to authenticate a given support account with the DI token and activate access.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Notes
Initiate a new device code flow. This API returns the verification URL and the user code. Go to the verification URL to authenticate a given support account with the DI token and activate access.

.Example
Query-DeviceAuth -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password>

#>

function Query-DeviceAuth {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )
         
    $uri = '/rest/vxm/v1/device-auth/query'

    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth
        }
        return $ret
    } catch {
        write-host $_
    }    
}
