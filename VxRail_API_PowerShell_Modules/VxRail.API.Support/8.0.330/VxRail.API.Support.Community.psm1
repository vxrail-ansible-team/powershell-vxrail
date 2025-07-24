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
Retrieves the home URL for accessing the VxRail community.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.
 
.Notes
You can run this cmdlet to retrieve the home URL for accessing the VxRail community.

.Example
C:\PS>Get-SupportCommunity -Server <vxm ip or FQDN> -Username <username> -Password <password>

Get the VxRail community home URL
#>
function Get-SupportCommunity {
    param(
        # VxRail Manager IP address or FQDN
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

    $uri = "/rest/vxm/v1/support/community"
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
Retrieves VxRail community messages.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.

.Parameter Count
The number of messages the user wants to receive. Default is 3.

.Notes 
You can run this cmdlet to retrieve VxRail community messages.

.Example
C:\PS>Get-SupportCommunityMessages -Server <vxm ip or FQDN> -Username <username> -Password <password> -Count <count>

Retrieves VxRail community messages.
#>
function Get-SupportCommunityMessages {
    # The optional and mandatory parameters for users to query
    [CmdletBinding()]
    param (
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,
        
        # User name from vCenter Server
        [Parameter(Mandatory = $true)]
        [String] $Username,
        
        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # The optional parameters for users to query, default = 3
        [Parameter(Mandatory = $false)]
        $Count = 3,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    process {
        $uri = "/rest/vxm/v1/support/community/messages"
        $uri = $uri + "?limit=" + $Count
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password

        try{
            if ($Count.GetType().name -notin @("Int32", "Int", "Int16", "Int64")) {
                Write-Error "Parameter -Count supports only integer" -ErrorAction Stop
            }

            if($Format) {
                $ret = $ret | ConvertTo-Json
            }
            return $ret
        } catch {
            write-host $_
        }
    }
}

