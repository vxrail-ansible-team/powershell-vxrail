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
Get a list of precheck report, list maximum not exceeding 10 available results.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to get the vxm system info.

.Example
C:\PS>Get-PrecheckResults -Server <vxm ip or FQDN> -Username <username> -Password <password>
Get a list of precheck report, report includes current running status and historical results, list maximum not exceeding 10 available results.
#>

function Get-PrecheckResults {
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
        [Switch] $Format
    )

    $url = "/rest/vxm/" + $Version.ToLower() + "/system/prechecks/results"

    # check Version
    # $pattern = "^v{1}[1|2|3]{1}$"
    if(($Version -ne "v1")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try {
        $ret = doGet -Server $Server -Api $url -Username $Username -Password $Password
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Get a precheck result with request_id.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to get the vxm system info.

.Example
C:\PS>Get-PrecheckResultById -Server <vxm ip or FQDN> -Username <username> -Password <password> -Request_id <request id>
Get a precheck result with specific request id, report could be current running status and specific historical result.
#>

function Get-PrecheckResultById {
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

        [Parameter(Mandatory = $true)]
        # The Request_id of precheck
        [String] $Request_id,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    # check Version
    # $pattern = "^v{1}[1|2|3]{1}$"
    if(($Version -ne "v1")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try{
        if($request_id) {
            $url = "/rest/vxm/" + $Version.ToLower() + "/system/prechecks/$request_id/result"
        }
        $ret = doGet -Server $server -Api $url -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth 4
        }
        return $ret
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Get current VxRail Precheck Service's version in the system.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to get the vxm system info.

.Example
C:\PS>Get-PrecheckServiceVersion -Server <vxm ip or FQDN> -Username <username> -Password <password>
Get current VxRail Precheck Service's version in the system
#>

function Get-PrecheckServiceVersion {
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
        [Switch] $Format
    )

    $url = "/rest/vxm/" + $Version.ToLower() + "/system/prechecks/precheck-service-version"

    # check Version
    # $pattern = "^v{1}[1|2|3]{1}$"
    if(($Version -ne "v1")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try {
        $ret = doGet -Server $Server -Api $url -Username $Username -Password $Password
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Get precheck available profiles in the system.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to get the vxm system info.

.Example
C:\PS>Get-PrecheckProfiles -Server <vxm ip or FQDN> -Username <username> -Password <password>
Get precheck available profiles in the system
#>

function Get-PrecheckProfiles {
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
        [Switch] $Format
    )

    $url = "/rest/vxm/" + $Version.ToLower() + "/system/prechecks/profiles"

    # check Version
    # $pattern = "^v{1}[1|2|3]{1}$"
    if(($Version -ne "v1")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try {
        $ret = doGet -Server $Server -Api $url -Username $Username -Password $Password
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Perform a system precheck

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to get the vxm system info.

.Example
C:\PS>Start-SystemPrecheck -Server <vxm ip or FQDN> -Username <username> -Password <password> -PrecheckConfigFile <Json file to the path>
Perform a precheck with profile config json file
#>

function Start-SystemPrecheck {
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

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $PrecheckConfigFile,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $url = "/rest/vxm/" + $Version.ToLower() + "/system/precheck"
    $body = Get-Content $PrecheckConfigFile

    # check Version
    # $pattern = "^v{1}[1|2|3]{1}$"
    if(($Version -ne "v1")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try {
        $ret = doPost -Server $Server -Api $url -Username $Username -Password $Password -Body $body -ContentType "application/json"
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
       HandleInvokeRestMethodException -URL $url
    }
}

