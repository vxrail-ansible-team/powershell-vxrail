# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0, $currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"

. "$commonPath"

<#
.Synopsis
Retrieve information related to STIG regulations.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username.

.Parameter Version
Optional, API version. Only support v1, default value is v1.

.Parameter Compress 
Print JSON style in compress format.

.Notes
You can run this cmdlet to get the STIG regulations. 

.Example
C:\PS>Get-STIGInfo -Server <vxm ip or FQDN> -Username <username> -Password <password>

Get the STIG regulations. 
#>
function Get-STIGInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Server,

        [Parameter(Mandatory = $true)]
        [String] $Username,
        
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

	[Parameter(Mandatory = $false)]
        [Switch] $Compress
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/stig/info"

    # check Version
    if(("v1") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try {
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
	if ($Compress) {
	    $ret = $ret | ConvertTo-Json -Depth 6 -Compress
	} else {
	    $ret = $ret | ConvertTo-Json -Depth 6
	}
        return $ret
    }
    catch {
        write-host $_
    }
}

