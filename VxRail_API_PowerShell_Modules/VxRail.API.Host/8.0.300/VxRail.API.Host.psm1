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

Get a list of host & each subcomponent info.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Sn
The serial number of the host to be queried.

.Parameter Version
Optional,API version. Supported Version v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16 default version is v1.

.Parameter Format
Print JSON style format.

.NOTES

You can run this cmdlet to get host info.

.EXAMPLE

PS> Get-Hosts -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get a list of host & each subcomponent info.

.EXAMPLE

PS> Get-Hosts -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn>

Get a specific host & each subcomponent info.

#>
function Get-Hosts {
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
        # The sn of node
        [String] $Sn,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/hosts"

    # check Version
    if(("v1","v2","v3","v4","v5","v6","v7","v8","v9","v10","v11","v12","v13","v14","v15","v16") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try{
        if($Sn) {
            $uri = "/rest/vxm/" + $Version.ToLower() + "/hosts/$Sn"
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

<#
.SYNOPSIS

Host shutdown with dryrun.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Sn
The serial number of the host to be queried.

.Parameter Dryrun
To run disk addition validation only.

.Parameter EvacuatePoweredOffVms
Evacuate powered off vms for this node.

.Parameter Format
Print JSON style format.

.NOTES

You can run this cmdlet to shutdown host or dryrun.

.EXAMPLE

PS> Start-HostsShutDown -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn> -Dryrun -EvacuatePoweredOffVms

Shutdown host with dryrun.
#>
function Start-HostsShutDown {
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

        [Parameter(Mandatory = $true)]
        # The sn of node
        [String] $Sn,

        [Parameter(Mandatory = $false)]
        # To run disk addition validation only
        [switch] $Dryrun,

        [Parameter(Mandatory = $false)]
        # Evacuate powered off vms for this node
        [switch] $EvacuatePoweredOffVms
    )

    $uri = -join ("/rest/vxm/v1/hosts/",$sn,"/shutdown")
	# write-host "This is URL $uri"

    $body = @{
        "dryrun" = if ($Dryrun) {"true"} else {"false"}
	    "evacuatePoweredOffVms" = if ($EvacuatePoweredOffVms) {"true"} else {"false"}
    }

    $body = $body | ConvertTo-Json
	# write-host "This is the body $body"
    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body
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
Update host related information.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Sn
The serial number of the host to be queried.

.Parameter RackName
Rack name in geo-location.

.Parameter OrderNumber
Rack slot in geo-location.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to update host related information, for example, geographic location.

.Example
C:\PS>Update-Hosts -Server <vxm ip or FQDN> -Username <username> -Password <password> -RackName <RackName in geolocation> -OrderNumber <OrderNumber in geolocation>

Update host related information.
#>
function Update-Hosts {
    [CmdletBinding()]
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

        [Parameter(Mandatory = $true)]
        # The sn of node
        [String] $Sn,

        # The optional ESRS passwords
        [Parameter(Mandatory = $false)]
        [String] $RackName,

        # Proxy Server IP Address
        [Parameter(Mandatory = $false)]
        [string] $OrderNumber,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/hosts/$Sn"

    # Body content to patch
    $body = @{
    }

    if($RackName -or $OrderNumber){
        $geoLocation = @{
        }
        $body.add("geo_location",$geoLocation)
        if($RackName){
            $body.geo_location.add("rack_name",$RackName)
        }
        if($OrderNumber){
            $body.geo_location.add("order_number",$OrderNumber)
        }
    }

    $body = $body | ConvertTo-Json

    try{
        $ret = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $body
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}
