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
Get VC management account and ESXi host management accounts

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Component
Component type can be "ESXI" or "VC"

.Parameter Hostname
ESXi host name. If the ESXi host name is not provided, then the hosts for all accounts will be returned.

.DESCRIPTION
Synchronous API to get VC management account and ESXi host management accounts.

.Example
C:\PS>Get-SystemAccountManagement -Server <vxm ip or FQDN> -Username <username> -Password <password>

Get the system health information.
#>
function Get-SystemAccountManagement {
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

        [Parameter(Mandatory = $false)]
        [String] $Component,

        [Parameter(Mandatory = $false)]
        [String] $Hostname
    )
    # Add System.Web
    Add-Type -AssemblyName System.Web

    $nvCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    if ($Component) {
        $nvCollection.Add('component', $Component)
    }
    if ($Hostname) {
        $nvCollection.Add('hostname', $Hostname)
    }

    # Build the uri
    $param = $nvCollection.ToString()
    $uri = "/rest/vxm/v1/system/accounts/management"

    if ($param -ne "") {
        $uri += "?" + $param
    }

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
