# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"
. "$commonPath"

$IPV4_PATTERN = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"


<#
.SYNOPSIS
Set VxM network configuration

.PARAMETER Server
Required. VxM IP address (IPv4 format)

.PARAMETER IP
Required. VxM IP address to be configured

.PARAMETER Gateway
Required. VxM gateway to be configured

.PARAMETER Netmask
Required. VxM netmask to be configured

.PARAMETER VlanID
Required. VxM Lan Id to be configured

.Notes
You can run this cmdlet to configure VxM network including IP, Gateway, Netmask and VlanID

.EXAMPLE
PS> Set-VxmNetworkConfiguration -Server <VxM IP> -IP <new VxM IP> `
    -Gateway <new VxM gateway> -Netmask <new VxM netmask> -VlanID <new VxM vlan id>

Sets VxM network configuration on VxRail Manager (VxM IP) with the input of IP, gateway, netmask and vlanID
#>
function Set-VxmNetworkConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        # New Vxm IP address
        [String] $IP,

        # New Vxm gateway
        [String] $Gateway,

        # New Vxm netmask
        [String] $Netmask,

        [Parameter(Mandatory = $true)]
        # New Vxm vlan ID
        [Uint16] $VlanID,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        # IPv6 address to be set
        [String] $IPv6,

        # PrefixLen  to be set
        [Uint16] $PrefixLen ,

        # IPv6 Gateway to be set
        [String] $Gatewayv6

    )

    Check-ServerJudge -Server $Server

    if  ($Server -match $IPV6_ADDR_PATTERN) {
        $url = "https://" + "[" + $Server + "]" + "/rest/vxm/" + $Version.ToLower() + "/network/vxrail-manager"
    }
    else {
        $url = "https://" + $Server + "/rest/vxm/" + $Version.ToLower() + "/network/vxrail-manager"
    }

    if(($Version -ne "v1") -and ($Version -ne "v2")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    if ( (-not $IP) -and (-not $IPv6)  ){
        Write-Error "Unrecognized VxRail Manager network configuration"
        return
        }

    if ($IP -and $IPv6){
            Check-IPv4Judge -IP $IP -Netmask $Netmask -Gateway $Gateway
            Check-IPv6Judge -IPv6 $IPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6
            $body = @"
            {"ip": "$IP",
            "gateway": "$Gateway",
            "netmask": "$Netmask",
            "ipv6" : "$IPv6",
            "gateway_ipv6": "$Gatewayv6",
            "prefix_length_ipv6": $PrefixLen,
            "vlan_id": "$VlanID"
            }
"@
        }
    elseif(-not $IPv6 ){
            Check-IPv4Judge -IP $IP -Netmask $Netmask -Gateway $Gateway
            $body = @"
            {"ip": "$IP",
            "gateway": "$Gateway",
            "netmask": "$Netmask",
            "vlan_id": "$VlanID"
            }
"@
    }
    else{
            Check-IPv6Judge -IPv6 $IPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6
            $body = @"
            {"ipv6" : "$IPv6",
            "gateway_ipv6":"$Gatewayv6",
            "prefix_length_ipv6": $PrefixLen,
            "vlan_id": "$VlanID"
            }
"@
    }

    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method POST -Body $body -ContentType "application/json"

        if ($response -and $response.state) {
            Write-Host "------------------------Response Begin------------------------"
            Write-Host "State    : "$response.state
            Write-Host "Message  : "$response.message
            Write-Host "------------------------Response End--------------------------"
        } else {
            $responseJson = $response | ConvertTo-Json
            Write-Host $responseJson
        }
    } catch {
        Handle-RestMethodInvokeException -URL $url
    }


}



function Check-IPv4Judge {
    param(
        [String] $IP,

        [String] $Netmask,

        [String] $Gateway
    )

    if (-not($IP -match $IPV4_PATTERN))
    {
        Write-Error "Vxm IPv4 is invalid, please correct it and try again"
        return
    }
    if (-not$Netmask)
    {
        Write-Error "Netmask cannot be empty"
        return
    }
    if (-not$Gateway)
    {
        Write-Error "IPv4 Gateway cannot be empty"
        return
    }
}

function Check-IPv6Judge {
    param(
        # IPv6 address to be set
        [String] $IPv6,

        # PrefixLen  to be set
        [Uint16] $PrefixLen ,

        # IPv6 Gateway to be set
        [String] $Gatewayv6
    )

    if (-not ($IPv6 -match $IPV6_PATTERN)) {
        Write-Error "Vxm IPv6 is invalid, please correct it and try again"
        return
        }
    if (-not $PrefixLen){
        Write-Error "PrefixLen cannot be empty"
        return
    }
    if (-not $Gatewayv6){
        Write-Error "IPv6 Gateway cannot be empty"
        return
    }
}


function Check-ServerJudge {
    param(
        [Parameter(Mandatory = $true)]
        # VXM's IP
        [String] $Server
    )
    #IPV4 and IPV6 cannot be empty at the same time.  You can upload IPV4 or IPV6, or both, but ensure that the parameters are complete
    if ((-not ($Server -match $IPV4_PATTERN)) -and (-not ($Server -match $IPV6_PATTERN))){
        Write-Error "Server IP is invalid, please correct it and try again"
        return
    }
}


<#
.SYNOPSIS
Handle exception of REST API calling

.PARAMETER URL
Required. Rest API URL

#>
function Handle-RestMethodInvokeException {
    param(
        [Parameter(Mandatory = $true)]
        # Rest API URL
        [String] $URL
    )

    $errorMessage = $_.Exception.Message
    if (Get-Member -InputObject $_.Exception -Name 'Response') {
        try {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
        } catch {
            Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Cannot get more information."
        }
    }
    Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Response body: $responseBody"
}