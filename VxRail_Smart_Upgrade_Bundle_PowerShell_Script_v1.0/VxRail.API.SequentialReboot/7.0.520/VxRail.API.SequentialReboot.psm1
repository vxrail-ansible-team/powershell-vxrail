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
Do sequntial reboot precheck( + apply).

.Description
Start a sequential reboot precheck( + apply) job with the provided list of hostnames. 

.Parameter Server
VxM IP or FQDN. 

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter All
Do sequntial reboot precheck( + apply) for all cluster hosts.

.Parameter Dryrun
Do sequential reboot precheck only.

.Parameter Hosts
List of hostnames for reboot precheck( + apply).

.Notes
Start a sequential reboot precheck( + apply) job based on the provided list of hostnames.

.Example
Reboot -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -Format -Dryrun -Hosts <list of hostnames>

Do sequential reboot precheck only for the provided list of hosts.
#>

function Start-Reboot {
    [CmdletBinding()]
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

        [Parameter(Mandatory = $false)]
        # Do sequential reboot precheck only
        [switch] $All,

        [Parameter(Mandatory = $false)]
        # Do sequential reboot precheck only
        [switch] $Dryrun,

        [Parameter(Mandatory = $false)]
        # Do a sequential reboot job for the provided list of hosts
        [String[]] $Hosts
    )

    $uri = "/rest/vxm/v1/sequential-reboot/apply"
    if ($Hosts){
        $hosts = $Hosts -split ','
    }
    $hostnames = @()
    foreach ($h in $hosts) {
        $hostnames += @{
            "hostname" = $h
        }
    }  

    $body = @{
        "all" = if ($All) {$true} else {$false}
        "dry_run" = if ($Dryrun) {$true} else {$false}
	"hosts" = $hostnames
    } 
        
    $body = $body | ConvertTo-Json

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body -ContentType "application/json"
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
Retry sequntial reboot.

.Description
Retry a sequential reboot job with the provided list of hostnames. 

.Parameter Server
VxM IP or FQDN. 

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Id
Valid request id of sequential reboot operation.

.Parameter Hosts
List of hostnames for reboot retry.

.Notes
Retry a sequential reboot job based on the provided list of hostnames.

.Example
Reboot -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -Format -Id <sequential reboot request id> -Hosts <list of hostnames>

Retry a specified sequential reboot operation for the provided list of hosts.
#>

function Start-RetryReboot {
    [CmdletBinding()]
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

        [Parameter(Mandatory = $false)]
        # Retry all failed hosts
        [switch] $All,

        [Parameter(Mandatory = $true)]
        # Retry a specified sequential reboot operation
        [String] $Id,

        [Parameter(Mandatory = $false)]
        # Retry a sequential reboot job for the provided list of hosts
        [String[]] $Hosts
    )

    $uri = "/rest/vxm/v1/sequential-reboot/"+$Id+"/retry"
    if ($Hosts){
        $hosts = $Hosts -split ','
    }
    $hostnames = @()
    foreach ($h in $hosts) {
        $hostnames += @{
            "hostname" = $h
        }
    }

    $body = @{
        "all" = if ($All) {$true} else {$false}
	"hosts" = $hostnames
    } 
        
    $body = $body | ConvertTo-Json

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body -ContentType "application/json"
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
Cancel sequntial reboot.

.Description
Cancel a sequential reboot job with the provided list of hostnames. 

.Parameter Server
VxM IP or FQDN. 

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter All
Cancel sequntial reboot for all cluster hosts.

.Parameter Id
Valid request id of sequential reboot operation.

.Parameter Hosts
List of hostnames for reboot cancel.

.Notes
Cancel a sequential reboot job based on the provided list of hostnames.

.Example
Reboot -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -Format -Id <sequential reboot request id> -Hosts <list of hostnames>

Cancel a specified sequential reboot operation for the provided list of hosts.
#>

function Start-CancelReboot {
    [CmdletBinding()]
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

        [Parameter(Mandatory = $false)]
        # Cancel all failed hosts
        [switch] $All,

        [Parameter(Mandatory = $true)]
        # Cacncel a specified sequential reboot operation
        [String] $Id,

        [Parameter(Mandatory = $false)]
        # Cancel a sequential reboot job for the provided list of hosts
        [String[]] $Hosts
    )

    $uri = "/rest/vxm/v1/sequential-reboot/"+$Id+"/cancel"
    if ($Hosts){
        $hosts = $Hosts -split ','
    }
    $hostnames = @()
    foreach ($h in $hosts) {
        $hostnames += @{
            "hostname" = $h
        }
    }

    $body = @{
        "all" = if ($All) {$true} else {$false}
	"hosts" = $hostnames
    } 
        
    $body = $body | ConvertTo-Json

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body -ContentType "application/json"
        if($Format) {
            $ret = $ret | ConvertTo-Json 
        }
        return $ret
    } catch {
        write-host $_
    }
}
