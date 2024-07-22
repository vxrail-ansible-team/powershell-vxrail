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
Satellite Node Expansion.

.Description
Starts a satellite node expansion job with the provided SatelliteNodeExpansionConfigFile.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter SatelliteNodeExpansionConfigFile
Host configure json file for satellite node expansion

.Parameter Format
Print JSON style format.

.Notes
Satellite node expansion, starts satellite node expansion job based on the provided expansion spec.

.Example
C:\PS>Add-SatelliteNode -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -SatelliteNodeExpansionConfigFile <Json file path>

Perform satellite node expansion.
#>
function Add-SatelliteNode {
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

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $SatelliteNodeExpansionConfigFile,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format

    )

    $uri = "/rest/vxm/v1/host-folder/expansion"
    $url = "https://" + $Server + $uri
    $body = Get-Content $SatelliteNodeExpansionConfigFile

    try {
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $body -ContentType "application/json"
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
Cancel previous failed satellite node expansion.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to cancel previous failed satellite node expansion.

.Example
C:\PS>Add-SatelliteNodeCancel -Server <vxm ip or FQDN> -Username <username> -Password <password>

Cancel previous failed satellite node expansion.
#>
function Add-SatelliteNodeCancel {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

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

    $uri = "/rest/vxm/v1/host-folder/expansion/cancel"

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS
Remove a satellite node from managed host folder.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter SerialNumber
Serial number of the satellite node to be removed

.NOTES
You can run this cmdlet to remove a satellite node from managed host folder.

.EXAMPLE
C:\PS>Remove-SatelliteNode -Server <VxM IP or FQDN> -Username <username> -Password <password> -SerialNumber <serial number>

Remove a satellite node from managed host folder.
#>
function Remove-SatelliteNode {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format,

        # Serial number
        [Parameter(Mandatory = $true)]
        [String] $SerialNumber
    )

    $uri = "/rest/vxm/v1/host-folder/hosts/" + $SerialNumber

    try{
        $ret = doDelete -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
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
Perform host folder LCM

.Description
Perform node upgrade for all eligible satellite nodes in the specific host folder

.Parameter Server
Required, VxM IP or FQDN.

.Parameter Username
Required, Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Required, Use corresponding password for username.

.Parameter Action
Required, Action options for host folder upgrade, STAGE or UPGRADE

.Parameter Host_folder_id
Required, The folder_id of Satellite Node folder

.Parameter Target_version
Required, The target version for host folder lcm

.Parameter Failure_rate
Optional, 0 < fail_rate <= 100, only valid for UPGRADE

.Parameter concurrent_size
Optional, 1=< concurrent_size <=30, only valid for UPGRADE

.Example
Start-HostFolderUpgrade -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -Action <Action> -Host_folder_id <folder_id> -Target_version <target_version>

#>
function Start-HostFolderUpgrade {
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

        [Parameter(Mandatory = $true, HelpMessage="Supported parameter: 'STAGE','UPGRADE'")]
        [String] $Action,

        # Satellite Node host folder
        [Parameter(Mandatory = $true)]
        [String] $Host_folder_id,

        [Parameter(Mandatory = $true)]
        [String] $Target_version,

        [Parameter(Mandatory = $false)]
        [String] $Failure_rate = '20',

        [Parameter(Mandatory = $false)]
        [String] $Concurrent_size = '20',

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/lcm/host-folder/upgrade"
    $url = "https://" + $Server + $uri

    if(($Action -ne "STAGE") -and ($Action -ne "UPGRADE")) {
        write-host "The inputted Action $Action is invalid." -ForegroundColor Red
        return
    }

    if ($Action.ToUpper() -eq "STAGE") {
         $Body = @{
            "action" = $Action.ToUpper()
            "host_folder_id" = $Host_folder_id
            "target_version" = $Target_version
         }  | ConvertTo-Json -Depth 4
    } else {
          $Body = @{
            "action" = $Action.ToUpper()
            "host_folder_id" = $Host_folder_id
            "target_version" = $Target_version
            "control" = @{
                "failure_rate" = [int]$Failure_rate
                "concurrent_size" = [int]$Concurrent_size
            }
         } | ConvertTo-Json -Depth 4
    }

	#write-host $Body

    try {
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body -ContentType "application/json"
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
       HandleInvokeRestMethodException -URL $url
    }
}
