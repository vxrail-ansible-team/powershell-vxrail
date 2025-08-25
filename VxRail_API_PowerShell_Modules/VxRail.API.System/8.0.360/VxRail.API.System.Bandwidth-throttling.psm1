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
Retrieves the bandwidth throttling Information.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.NOTES
You can run this cmdlet to retrieve the current bandwidth throttling level.

.EXAMPLE
C:\PS>Get-BandwidthThrottling -Server <VxM IP or FQDN> -Username <username> -Password <password>

Retrieves the current bandwidth throttling level.
#>
function Get-BandwidthThrottling {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [switch] $Format

    )

    $uri = "/rest/vxm/v1/system/bandwidth-throttling"
    try{ 
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
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
Change the bandwidth throttling level.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username.

.Parameter BandwidthThrottlingLevel
Bandwidth throttling level to be set.The bandwidth throttling levels are Enum: None, Basic, Medium, Advanced

.NOTES
You can run this cmdlet to update the bandwidth throttling level.

.EXAMPLE
PS> Update-BandwidthThrottling -Server <VxM IP or FQDN> -Username <username> -Password <password> -BandwidthThrottlingLevel <BandwidthThrottling level>

Update the bandwidth throttling level.
#>
function Update-BandwidthThrottling {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Bandwidth Throttling level to be set
        [Parameter(Mandatory = $true,HelpMessage="Supported bandwidth throttling level: 'None','Basic','Medium','Advanced'.")]
        [ValidateSet('None','Basic','Medium','Advanced')]
        [string] $BandwidthThrottlingLevel,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/system/bandwidth-throttling"

    $body = @{
        "level" = $BandwidthThrottlingLevel
    } | ConvertTo-Json

    try{
        $ret = doPut -Server $server -Api $uri -Username $username -Password $password -Body $body
        if($Format) {
            $ret = $ret | ConvertTo-Json 
        }
        return $ret
    } catch {
        write-host $_
    }
}
