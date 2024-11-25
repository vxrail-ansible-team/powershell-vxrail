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

Get chassis list & every node info for each chassis.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter ChassisId
The chassis id of the chassis to be queried.

.Parameter Version
Optional,API version.Only support v1,v2,v3,v4,v5,v6,v7 default value is v1.

.Parameter Format
Print JSON style format.

.NOTES

You can run this cmdlet to get chassis info.

.EXAMPLE

PS> Get-Chassis -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get chassis list & every node info for each chassis.

.EXAMPLE

PS> Get-Chassis -Server <VxM IP or FQDN> -Username <username> -Password <password> -ChassisId <chassisId>

Get specific chassis info.
#>
function Get-Chassis {
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
        # Chassis id
        [String] $ChassisId,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/chassis"

    # check Version
     if(("v1","v2","v3","v4","v5","v6","v7") -notcontains $Version.ToLower()){
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try{ 
        if($ChassisId){
            $uri = "/rest/vxm/" + $Version.ToLower() + "/chassis/$ChassisId"
        }
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth 4
        }
        return $ret
    } catch {
        write-host $_
    }

}

