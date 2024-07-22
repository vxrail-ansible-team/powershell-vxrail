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
Get the vxm system network status.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to get the vxm system network status.

.Example
C:\PS>Get-SystemInternetMode -Server <vxm ip or FQDN> -Username <username> -Password <password>

Get system internet mode status.
#>
function Get-SystemInternetMode {
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
        
        # need good format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/system/internet-mode"
    try{ 
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}


<#
.Synopsis
Update the vxm system network status.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter IsDarkSite
To indicate system network is darksite or not.

.Notes
You can run this cmdlet to update the vxm system network status.

.Example
PS> Update-SystemInternetMode -Server <vxm ip or FQDN> -Username <username> -Password <password> -IsDarkSite

Update 'is_dark_site' of system internet mode to 'true'  

.Example
PS> Update-SystemInternetMode -Server <vxm ip or FQDN> -Username <username> -Password <password>

Update 'is_dark_site' of system internet mode to 'false'  
#>
function Update-SystemInternetMode {
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
        
        # need good format
        [Parameter(Mandatory = $false)]
        [Switch] $Format,

        # specify the "is_dark_site" property for callhome Mode
        [Parameter(Mandatory = $false)]
        [Switch] $IsDarkSite
    )

    $uri = "/rest/vxm/v1/system/internet-mode"

    # Body content: Support PUT "is_dark_site" property 
    $Body = @{
        "is_dark_site" = if($IsDarkSite) {"true"} else{"false"}
    } | ConvertTo-Json

    try{  
        $ret = doPut -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}
