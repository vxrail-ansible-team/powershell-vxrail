# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"

. "$commonPath"
#. ".\VxRail.API.System.format.ps1xml"


<#
.Synopsis
Retrieves the last heartbeat status and system configuration.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to retrieve the last heartbeat status and system configuration.

.Example
C:\PS>Get-SupportHeartbeat -Server <vxm ip or FQDN> -Username <username> -Password <password>

Retrieves the heartbeat information.
#>
function Get-SupportHeartbeat {
    param(
        # VxManager ip address or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,
        
        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,
        
        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,
        
        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/support/heartbeat"
    try{ 
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json | % {[regex]::unescape($_)}
        }
        return $ret
    } catch {
        write-host $_
    }
}
