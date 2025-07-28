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
.SYNOPSIS

Change VC from internal mode to external mode.

.NOTES

You can run this cmdlet to update vCenter & PSC mode.


.EXAMPLE

PS> Update-VCenterMode -Server <VxM IP or FQDN> -Username <username> -Password <password> -VCenterUsername <vCenter username> -VCenterPassword <vCenter password> -VCenterMode EMBEDDED -PSCMode EMBEDDED

This is to change VC from internal mode to external mode.
#>
function Update-VCenterMode {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $true)]
        # Username of vCenter
        [String] $VCenterUsername,

        [Parameter(Mandatory = $true)]
        # Password of vCenter
        [String] $VCenterPassword,

        [Parameter(Mandatory = $true)]
        # VCenter mode
        [ValidateNotNullOrEmpty()]
        [ValidateSet("EMBEDDED","EXTERNAL")]
        [String] $VCenterMode,

        [Parameter(Mandatory = $true)]
        # PSC mode
        [ValidateNotNullOrEmpty()]
        [ValidateSet("EMBEDDED","EXTERNAL")]
        [String] $PSCMode 
    )

    $Body = @{
        "vc_admin_user" = @{
            "username" = $VCenterUsername
            "password" = $VCenterPassword
        }
        "vc_mode" = $VCenterMode
        "psc_mode" = $PSCMode
    } | ConvertTo-Json

    $uri = "/rest/vxm/v1/vc/mode"
    try{
        $ret = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth
        }
        return $ret
    } catch {
        write-host $_
    }

}


<#
.SYNOPSIS

Get current VC mode and PSC mode.

.NOTES

You can run this cmdlet to get VC mode and PSC mode.

.EXAMPLE

PS> Get-VCenterMode -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get current VC mode and PSC mode.
#>
function Get-VCenterMode {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/vc/mode"
    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth 4
        }
        return $ret
    } catch {
        write-host $_
    }

}
