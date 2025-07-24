# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Network.Common\" + $currentVersion + "\VxRail.API.Network.Common.ps1"

. "$commonPath"


$INITIALIZE_HOST_NETWORK_SETTING_TIMEOUT = 180
$HOST_NETWORK_SETTING_TIMEOUT = 300
$INITIALIZE_VXM_SETTING_TIMEOUT = 180
$VXM_SETTING_TIMEOUT = 300
$APP_RAW_DATA_DEFAULT_VALUE = ""
$IPV4_PATTERN = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
$IPV6_PATTERN = "^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$"
$NETMASK_PATTERN = "^(254|252|248|240|224|192|128|0)\.0\.0\.0|255\.(254|252|248|240|224|192|128|0)\.0\.0|255\.255\.(254|252|248|240|224|192|128|0)\.0|255\.255\.255\.(255|254|252|248|240|224|192|128|0)$"
$MAX_VLANID = 4095
$MAX_PREFIXLEN = 128
function ConvertTo-IPv4Hex
{
<#
    .SYNOPSIS
        This function convert a IPv4 address string to a hex string.

    .PARAMETER
        IP string x.x.x.x

    .EXAMPLE
        ConvertTo-IPv4Hex("127.0.0.1")

        Output:
        "7f000001"
#>

    param
    (
        [parameter(Mandatory=$true)]
        [string] $ip
    )

    $error_str = "Parameter 'IP' is invalid. 'IP' must be a valid IPv4 for VxRail Manager."

    try{
        $ip_obj = [ipaddress]$IP
    }
    catch{
        $exception = New-Object -TypeName System.InvalidOperationException($error_str)
        throw $exception
    }

    try{
        [String] $HEXStr = ""
        ($ip.Split('.')) | ForEach-Object {
          $value = [System.Convert]::ToInt16($_)
          if ( $value -gt 255) {
            $exception = New-Object -TypeName System.InvalidOperationException($error_str)
            throw $exception
          }
          $temp = [System.Convert]::ToString($_,16).PadLeft(2,'0')
          $HEXStr += $temp
        }
        return $HEXStr
    }
    catch {
        throw $_.Exception
    }
}


function ConvertTo-Gateway
{
<#
    .SYNOPSIS
        This function convert a IPv4 Gateway string to a hex string.

    .PARAMETER
        IP string x.x.x.x

    .EXAMPLE
        ConvertTo-Gateway("255.255.255.0")

        Output:
        "ffffff00"
#>

    param
    (
        [parameter(Mandatory=$true)]
        [string] $Gateway
    )

    $error_str = "Parameter 'Gateway' is invalid. 'Gateway' must be a valid Gateway for VxRail Manager."

    try{
        $gateway_obj = [ipaddress]$Gateway
    }
    catch{
        $exception = New-Object -TypeName System.InvalidOperationException($error_str)
        throw $exception
    }

    try{
        [String] $HEXStr = ""
        ($Gateway.Split('.')) | ForEach-Object {
          $value = [System.Convert]::ToInt16($_)
          if ( $value -gt 255) {
            $exception = New-Object -TypeName System.InvalidOperationException($error_str)
            throw $exception
          }
          $temp = [System.Convert]::ToString($_,16).PadLeft(2,'0')
          $HEXStr += $temp
        }
        return $HEXStr
    }
    catch {
        throw $_.Exception
    }
}

function ConvertTo-IPv4MaskBits
{
<#
    .SYNOPSIS
        This function convert a network mask string to maskbits.
        '255.255.255.0' ->  '24'

    .PARAMETER
        network mask

    .EXAMPLE
        ConvertTo-IPv4MaskBits("255.255.254.0")

        Output:
        '23'
#>
    param
    (
        [parameter(Mandatory=$true)]
        [string] $MaskString
    )

    $error_str = "Parameter 'Netmask' is invalid. 'Netmask' must be a valid netmask for VxRail Manager."

    try{
        $netmask_obj = [ipaddress]$MaskString
    }
    catch{

        $exception = New-Object -TypeName System.InvalidOperationException($error_str)
        throw $exception
    }

    try{
        [UINT32] $mask = 0
        [UINT32] $count = 0
        ($MaskString.Split('.')) | ForEach-Object {
          $mask = $mask -shl 8
          $value = [System.Convert]::ToUInt32($_)
          if ($value -gt 255) {
            $exception = New-Object -TypeName System.InvalidOperationException($error_str)
            throw $exception
          }
          elseif (0 -lt $value -and $value -lt 128){
            $exception = New-Object -TypeName System.InvalidOperationException($error_str)
            throw $exception
          }
          $mask += $value
          $count++
        }

        $temp_mask = $mask
        for ($bits = 0; $temp_mask -ne 0 ; $bits++){
          $temp_mask = $temp_mask -band ($temp_mask - 1)
        }

        #caculate the mask via bits
        [UINT32]$new_mask = 0
        for ( $i = 0; $i -lt $bits ; $i++){
            $new_mask = $new_mask -shl 1
            $new_mask++
        }
        for ( $i = 0; $i -lt (32-$bits) ; $i++){
            $new_mask = $new_mask -shl 1
        }
        if($mask -eq $new_mask){
            return $bits
        }
        else{
            $exception = New-Object -TypeName System.InvalidOperationException($error_str)
            throw $exception
        }
    }
    catch {
        throw $_.Exception
    }
}

function Convert-VxmVlanID{
    param
    (
        [parameter(Mandatory=$true)]
        [UINT16] $VxmVlanID
    )


    if ($VxmVlanID -gt 4095){
        $error_str = "Parameter 'VlanID' is invalid. 'VlanID' must be from 0 to 4095, including 0 and 4095. Skip it or input 0 if no vLAN is used."
        $exception = New-Object -TypeName System.InvalidOperationException($error_str)
        throw $exception
    }

    return $VxmVlanID
}

function ConvertTo-NetLCString
{
<#
  .SYNOPSIS
      This function Convert vxmip,vxmgateway,vxmnetmask and vxmvlan to a hex string for VxRail LC.
#>
    param
    (
        [parameter(Mandatory=$true)]
        [String] $vxmIp,

        [parameter(Mandatory=$true)]
        [String] $vxmGateway,

        [parameter(Mandatory=$true)]
        [String] $vxmNetmask,

        [parameter(Mandatory=$true)]
        [UINT16] $vxmVLAN
    )

    try{
        $vxmIpHexStr = ConvertTo-IPv4Hex($vxmIp)
    }
    catch {
        throw $_.Exception
    }

    try {
        $vxmGatewayHexStr = ConvertTo-Gateway($vxmGateway)
    }
    catch {
        throw $_.Exception
    }

    try {
        $vxmNetmaskBits = ConvertTo-IPv4MaskBits($vxmNetmask)
    }
    catch {
        throw $_.Exception
    }

    try {
        $vlanID = Convert-VxmVlanID($vxmVLAN)
    }
    catch {
        throw $_.Exception
    }

    # Padleft the empty bytes with '0'
    $vxmIpHexStr = $vxmIpHexStr.PadLeft(8,'0')
    $vxmGatewayHexStr = $vxmGatewayHexStr.PadLeft(8,'0')
    $vxmNetmaskBitsStr = ([String]$vxmNetmaskBits).PadLeft(2,'0')
    $vxmVLANStr = ([String]$vlanID).PadLeft(4,'0')

    # add the return code in the end to indicate this Initial User request.
    $returnCode = '1'
    [String]::Format('{0}{1}{2}{3}{4}', $vxmIpHexStr, $vxmGatewayHexStr, $vxmNetmaskBitsStr, $vxmVLANStr,$returnCode)
}

function ConvertTo-IPv4Str
{
<#
    .SYNOPSIS
        This function convert a IPv4 address string to a hex string.
        'fffffff0' -> '255.255.255.0'

    .PARAMETER
        IP HEX string

    .EXAMPLE
        ConvertTo-IPv4Str("fffffff0")

        Output:
        "255.255.255.0"
#>
    param
    (
        [parameter(Mandatory=$true)]
        [string] $ipHexStr
    )

    try{
        $ipArray = @()
        for($i=0; $i -lt 4; $i++){
            $ipElement = [int]('0x' + $ipHexStr.Substring($i*2 ,2))
            $ipArray += $ipElement
        }
        $ipStr = $ipArray -join "."
        return $ipStr
    }
    catch
    {
        Write-Verbose "Error encounted in ConvertTo-IPv4Str."  -ForegroundColor red -BackgroundColor white
        throw $_.Exception
    }
}


function ConvertTo-IPv4MaskString{
    param
    (
        [parameter(Mandatory=$true)]
        [UINT32] $IPv4MaskBits
    )

    #caculate the mask via bits
    [UINT32]$mask = 0
    for ( $i = 0; $i -lt $IPv4MaskBits ; $i++){
        $mask = $mask -shl 1
        $mask++
    }
    for ( $i = 0; $i -lt (32-$IPv4MaskBits) ; $i++){
        $mask = $mask -shl 1
    }
    $maskStr = [System.Convert]::ToString($mask,16).PadLeft(8,'0')
    return ConvertTo-IPv4Str($maskStr)
}

function ConvertTo-ReadableLCString{
<#
    .SYNOPSIS
        This function convert the value in LC into readable ip/netmask/gateway/vLAN.
#>
    param
    (
        [parameter(Mandatory=$true)]
        [String] $VirtualAddressManagementApplicationStr
    )

    $vxmIpHexStr = $VirtualAddressManagementApplicationStr.Substring(0,8)
    $vxmGatewayHexStr = $VirtualAddressManagementApplicationStr.Substring(8,8)
    $vxmNetmaskBitsStr = $VirtualAddressManagementApplicationStr.Substring(16,2)
    $vxmVLANStr = $VirtualAddressManagementApplicationStr.Substring(18,4)
    $returnCode = $VirtualAddressManagementApplicationStr.Substring(22,1)


    $ip = ConvertTo-IPv4Str($vxmIpHexStr)
    $gateway = ConvertTo-IPv4Str($vxmGatewayHexStr)
    $netmask = ConvertTo-IPv4MaskString($vxmNetmaskBitsStr)
    $vxmVLAN = [int]$vxmVLANStr

    return $returnCode,$ip,$gateway,$netmask,$vxmVLAN
}


function Test-InputParameter{
    <#
    .SYNOPSIS
        do basic verification for iDrac IP, vxm IP, vxm netmask, vxm gateway , vxm vLAN
    #>
    param(
        [parameter(Position = 0 , ParameterSetName="Set",Mandatory=$true)]
        [Switch] $Set,

        [parameter(ParameterSetName="Get")]
        [parameter(ParameterSetName="Set")]
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [parameter(ParameterSetName="Set",Mandatory=$true)]
        [String] $IP,

        [parameter(ParameterSetName="Set",Mandatory=$true)]
        [String] $Netmask,

        [parameter(ParameterSetName="Set",Mandatory=$true)]
        [String] $Gateway,

        [parameter(ParameterSetName="Set",Mandatory=$true)]
        [UINT16] $VlanID
    )

    $ErrorCount = 0
    $Pattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"

    if($Set){
        $InputParameterCheckList = @( 'IP', 'Gateway')
    }

    ForEach ($Item in $InputParameterCheckList) {
        $Value = Invoke-Expression('$'+$Item)
        if ($Value -notmatch $Pattern){
            $ErrorCount++
            $Error_Str += [String]::Format(
                "Parameter '{0}' has an invalid value '{1}'. It should be a valid IP address with IPv4 format.`n",
                 $Item,$Value)
        }
    }
    if ($ErrorCount -ne 0){
        Write-Warning $Error_Str
        return $ErrorCount
    }

    if($Set){
        try {
            $v = ConvertTo-NetLCString -vxmIp $IP -vxmNetmask $Netmask -vxmGateway $Gateway  -vxmVLAN $VlanID -ErrorAction Stop
            Write-Verbose "NetLCString:$v"
        }
        catch {
            $ErrorCount++
            $Error_Str = $_.Exception.Message
            Write-Warning $Error_Str
        }
    }

    return $ErrorCount
}


function Get-ServerModel
{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password
    )


    $uri = "/redfish/v1/Systems/System.Embedded.1"
    $specialHeader = @{"Accept"='*/*'}

    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password -SpecialHeaders $specialHeader
        $oem = $ret.Oem.Dell
        $model = $ret.Model
        $sku = $ret.SKU

        Write-Verbose "VxRail MODEL: $model"
        Write-Verbose "Service Tag : $sku"
        Write-Verbose "OEM  : $oem"
    } catch {
        throw $_.Exception
    }
    return $model, $sku
}

function Confirm-SupportedVxRailNode
{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password
    )

    #13G and before systems are not supported.
    $NOT_SUPPORTED_MODEL = @("VxRail E460", "VxRail E460F", "VxRail P470", "VxRail P470F","VxRail V470","VxRail V470F", "VxRail S470")

    Write-Verbose 'Confirming VxRail Node...'

    $model,$sku = Get-ServerModel -Server $Server -Username $Username -Password $Password

    if ($model -like 'VxRail*'){
        if ($model -in $NOT_SUPPORTED_MODEL){
            Write-Host "This system (Model:'$model', Service Tag :'$sku') is not supported." -ForegroundColor Yellow
            return $False
        }
        else{
            Write-Verbose "This System is supported."
            return $True
        }
    }
    else{
        Write-Host "This system is not a VxRail Server." -ForegroundColor Yellow
        return $False
    }
}

function Get-VxRailManagerNetwork{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password
    )

    $uri = "/redfish/v1/Managers/LifecycleController.Embedded.1/Attributes"
    $specialHeader = @{"Accept"='*/*'}
    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password -SpecialHeaders $specialHeader

        $value = $null
        $found = $false
        if ($ret.Id -eq 'LCAttributes'){
            $found = Get-Member -InputObject $ret.Attributes | Where-Object { $_.Name -eq 'LCAttributes.1.VirtualAddressManagementApplication'}
            if ($found){
                $value = $ret.Attributes.'LCAttributes.1.VirtualAddressManagementApplication'
                Write-Verbose "Get value:$value"
            }
        }
        return $value
    } catch {
        throw $_.Exception
    }
}

function Set-VxRailManagerNetworkLCAttributes{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password,

        [parameter(Mandatory=$false)]
        [String]$VxmNetworkConfigValue
    )

    $uri = "/redfish/v1/Managers/LifecycleController.Embedded.1/Attributes"
    $specialHeader = @{"Accept"='application/json'}
    if (-not $VxmNetworkConfigValue){
        $VxmNetworkConfigValue = ''
    }
    $lc_body = @{}
    $lc_body.Add('LCAttributes.1.VirtualAddressManagementApplication', $VxmNetworkConfigValue)
    $json_body = @{}
    $json_body.Add('Attributes',$lc_body )
    $json_body = ConvertTo-Json -InputObject $json_body

    Write-Verbose "Writing VirtualAddressManagementApplication with value '$VxmNetworkConfigValue'"

    try{
        $ret = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $json_body -SpecialHeaders $specialHeader
        return $ret
    } catch {
        throw $_.Exception
    }
}

<#
.SYNOPSIS

Get VxRail Manager Network status for target Server machine

.PARAMETER Server
Required. iDrac IP address (IPv4 format)

.PARAMETER Username
Required. iDrac username

.PARAMETER Password
Required. Use corresponding password for iDrac username

.NOTES
You can run this cmdlet to get VxRail Manager Network status

.EXAMPLE
PS> Get-VxRailManagerNetworkStatus -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password>

#>
function Get-VxRailManagerNetworkStatus{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword
    )

    Check-ProxyJudge -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword

    Check-ServerJudge -Server $Server

    $supported = Confirm-SupportedVxRailNode -Server $Server -Username $Username -Password $Password
    if(-not $supported){
        return
    }

    $value = Get-VxRailManagerNetwork -Server $Server -Username $Username -Password $Password
    $AppRawData = Get-VxMAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    if($AppRawData -ne $null){
        if ($AppRawData.GetType().Name -eq "String"){$AppRawData = $AppRawData | ConvertFrom-Json}
    }
    if (($value -and $value.Trim()) -or ($AppRawData -and ($AppRawData.PSObject.Properties.Value.Count -ne 0))){
        $ExistingTimestamp = $AppRawData.VxMNetwork.timestamp
        if ($ExistingTimestamp -eq $null){
            Get-VxRailManageNetworkLCAttributesSettingStatus -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        }else{
            $CurrentTime = getCurrentTime -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
            $TimeDifference = GetTimeDifference -StartTime $ExistingTimestamp -EndTime $CurrentTime
            $StatusCode = $AppRawData.VxMNetwork.status_code
            if($StatusCode -ne 0){
                Get-VxRailManagerNetworkAppRawDataSettingStatus -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
            }else{
                Get-VxRailManageNetworkLCAttributesSettingStatus -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
            }
        }
    }else{
        Write-Host "The current staging values all cleared."
    }
}

<#
.SYNOPSIS

Set VxRail Manager Network address for target Server machine

.PARAMETER Server
Required. iDrac IP address (IPv4 format)

.PARAMETER Username
Required. iDrac username

.PARAMETER Password
Required. Use corresponding password for iDrac username

.PARAMETER IP
Optional. The valid IP address (IPv4 format) for VxRail Manager network

.PARAMETER Netmask
optional. The valid network mask (IPv4 format) for VxRail Manager network

.PARAMETER Gateway
Optional. The valid gateway (IPv4 format) for VxRail Manager network

.PARAMETER IPv6
Optional. The valid IPv6 address (IPv6 format) for VxRail Manager network

.PARAMETER PrefixLen
Optional. The valid PrefixLen for VxRail Manager network. The valid value is from 0 to 128 (including 0 and 128).

.PARAMETER Gatewayv6
Optional. The valid IPv6 gateway (IPv6 format) for VxRail Manager network

.PARAMETER VlanID
Optional. The valid vlan for VxRail Manager network. The valid value is from 0 to 4095 (including 0 and 4095). Skip it or input 0 if no vLAN is used

.NOTES
You can run this cmdlet to set VxRail Manager Network address

.EXAMPLE
PS> Set-VxRailManagerNetworkAddr -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -IP <IP> -Netmask <network mask> -Gateway <IPv4 gateway> -IPv6 <IPv6> -PrefixLen <prefixlen> -Gatewayv6 <IPv6 gateway> -VlanID <vlan ID>
Set VxRail Manager address with the valid VlanID.

.EXAMPLE
PS> Set-VxRailManagerNetworkAddr -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -IP <IP> -Netmask <network mask> -Gateway <gateway> -IPv6 <IPv6> -PrefixLen <prefixlen> -Gatewayv6 <IPv6 gateway>
Set VxRail Manager address when there is no Vlan for it.
#>
function Set-VxRailManagerNetworkAddr{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password,

        [String] $IP,

        [String] $Netmask,

        [String] $Gateway,

        [UINT16] $VlanID,

        # IPv6 address to be set
        [String] $IPv6,

        # PrefixLen  to be set
        [Uint16] $PrefixLen ,

        # IPv6 Gateway to be set
        [String] $Gatewayv6,

        # Proxy to access the iDrac
        [String] $Proxy,

        # Username of the proxy server
        [String] $ProxyUsername,

        # Password of the proxy server
        [String] $ProxyPassword
    )

    Check-ProxyJudge -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword

    Check-ServerJudge -Server $Server

    $supported = Confirm-SupportedVxRailNode -Server $Server -Username $Username -Password $Password
    if(-not $supported){
        return
    }

    if ( (-not $IP) -and (-not $IPv6)  ){
        Write-Error "Unrecognized VxRail Manager network configuration"
        return
    }

    if ($IP){
        Check-IPv4Judge -IP $IP -Netmask $Netmask -Gateway $Gateway
    }
    if ($IPv6){
        Check-IPv6Judge -IPv6 $IPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6
    }

    if (-not $VlanID){
        $VlanID = [UInt16]0
    }

    if ($VlanID -gt $MAX_VLANID){
        Write-Error "Invalid vlan, vlan should be integer and between 0-4095(including 0 and 4095), please correct it and try again"
        return
    }

    if($IP){
        $error_count = Test-InputParameter -Set -Server $Server -IP $IP -Netmask $Netmask -Gateway $Gateway -VlanID $VlanID
        if($error_count -ne 0){
            return
        }

        try {
            $new_value = ConvertTo-NetLCString -vxmIp $IP -vxmNetmask $Netmask -vxmGateway $Gateway -vxmVLAN $VlanID -ErrorAction Stop
        }catch{
            throw $_.Exception
        }
    }

    # 1. Read the current value
    Write-Verbose "Reading the current VxRail Manager network configuration..."
    $current_value = Get-VxRailManagerNetwork -Server $Server -Username $Username -Password $Password
    if ($IP -and (-not $IPv6)) {
        if($current_value){
            $str = [String]::Format("Success to get current VxRail Manager network configuration, Value: '{0}'", $current_value)
            Write-Verbose $str
            try{
                $returnCode,$ip_lca,$gateway_lca,$netmask_lca,$vxmVLAN_lca = ConvertTo-ReadableLCString($current_value)
                Switch($returnCode)
                {
                   '2' {
                        $msg = "configuration in progress, please try again after the current operation to finish."
                        Write-Host $msg -ForegroundColor Yellow
                        return
                    }
                }
            }catch{

            }
        }
        # 2. Write the new value
        Write-Verbose "Writing the new VxRail Manager network configuration..."
        $ret=Set-VxRailManagerNetworkLCAttributes -Server $Server -Username $Username -Password $Password -VxmNetworkConfigValue $new_value
        Write-Verbose "Write finished."

    }
    $ret=Set-VxRailManagerNetworkAppRawData -Server $Server -Username $Username -Password $Password -IP $IP -Netmask $Netmask -Gateway $Gateway -IPv6 $IPv6 -PrefixLen  $PrefixLen  -Gatewayv6 $Gatewayv6 -Vlan $VlanID -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword

    # 3. Read the new valie
    Write-Verbose "Reading the new VxRail Manager network configuration..."
    if ($IP){
        Write-Host "IP         : "$IP
        Write-Host "Netmask    : "$Netmask
        Write-Host "Gateway    : "$Gateway
    }
    if($IPv6){
        Write-Host "IPv6       : "$IPv6
        Write-Host "Prefixlen  : "$PrefixLen
        Write-Host "Gatewayv6  : "$Gatewayv6
    }
    Write-Host "vLAN       : "$VlanID

}


function Set-VxmNetworkAddr{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password
    )
    $Body = @{}
    $AppRawData = Get-VxMAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    # The return of Get-VxMAppRawData is PSCustomobject. Convert to Hashtable for further operation like add keys or update values.
    $AppRawDataHash = @{}
    $AppRawData.psobject.properties | Foreach { $AppRawDataHash[$_.Name] = $_.Value }
    # if AppRawDataHash include VxMNetwork, update it. If not include, add it.
    $AppRawDataHash.VxMNetwork = $Body

    $Body = $AppRawDataHash | ConvertTo-Json
    $BodyAscii = [Text.Encoding]::ASCII.GetBytes($Body)
    $BodyBasic64 = [Convert]::ToBase64String($BodyAscii)
    $Body = @{
        "Attributes" = @{
            "ConvergedInfra.1.AppRawData" = $BodyBasic64
        }
    }
    $Body = $Body | ConvertTo-Json
    $uri = "/redfish/v1/Managers/iDRAC.Embedded.1/Attributes"
    $url = Get-Url -Server $Server -Uri $uri
    $specialHeader = @{"Accept"='*/*'}

    try{
        $response = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $body -SpecialHeaders $specialHeader `
        -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        $response = $response | ConvertTo-Json
        return $response
    }catch{
        HandleInvokeRestMethodException -URL $url
    }

}

<#
.SYNOPSIS

Clear VxRail Manager Network configuration for the target Server machine

.PARAMETER Server
Required. iDrac IP address (IPv4 format)

.PARAMETER Username
Required. iDrac username

.PARAMETER Password
Required. Use corresponding password for iDrac username

.PARAMETER Force
Optional. Use it to confirm Clear action without user interaction

.NOTES
You can run this cmdlet to clear VxRail Manager Network status

.EXAMPLE
PS> Clear-VxRailManagerNetworkAddr -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password>

.EXAMPLE
PS> Clear-VxRailManagerNetworkAddr -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -Force

#>
function Clear-VxRailManagerNetworkAddr{
    param(
        [Parameter(Mandatory = $true)]
        # iDrac IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDrac username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for iDrac username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword,

        [Parameter(Mandatory = $false)]
        # Optional parameter. Use it to confirm Clear action without user interaction
        [Switch] $Force
    )

    Check-ProxyJudge -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword

    Check-ServerJudge -Server $Server

    $supported = Confirm-SupportedVxRailNode -Server $Server -Username $Username -Password $Password
    if(-not $supported){
        return
    }

    if (!$Force){
        $message  = 'Please confirm:'
        $question = 'Are you sure You want to Clear the VxRail Manager network configuration value on this Server?'
        $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes', "Clear the VxRail Manager network configuration."))
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No', "Do nothing and exit."))
        $confirmation = $Host.UI.PromptForChoice($message, $question, $choices, 1)
        if ($confirmation -eq 0) {
            Write-Host 'Confirmed.'
        }else{
            Write-Host 'Cancelled.'
            return
        }
    }else{
        Write-Verbose "non-interactive model."
    }

    try{
        Write-Verbose "Clearing the current VxRail Manager network configuration..."
        $ret = Set-VxRailManagerNetworkLCAttributes -Server $Server -Username $Username -Password $Password
        $ret = Set-VxmNetworkAddr -Server $Server -Username $Username -Password $Password
        Write-Host "Success to clear VxRail Manager network configuration." -ForegroundColor Green
    }catch{
        throw $_.Exception
    }
}


function SetAppRawData{
    param(
        [Parameter(Mandatory = $true)]
        # iDRAC's IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # iDRAC's password
        [String] $Password,

        # IPv4 address to be set
        [String] $HostIP,

        # Netmask to be set
        [String] $Netmask,

        # Gateway IPv4 to be set
        [String] $Gateway,

        # IPv6 address to be set
        [String] $HostIPv6,

        # Prefix Length to be set
        [int] $PrefixLen,

        # Gateway IPv6 to be set
        [String] $Gatewayv6,

        [Parameter(Mandatory = $true)]
        # Vlan to be set
        [int] $Vlan,

        [Parameter(Mandatory = $true)]
        # Status_code to be set
        [int] $StatusCode,

        [Parameter(Mandatory = $true)]
        # Message to be set
        [String] $Message,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword
    )

    $CurrentTime = getCurrentTime -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    # Before set AppRawData, Get it first and only set "NodeManagementNetwork", should not change other key and values.
    $AppRawData = GetAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    # The return of GetAppRawData is PSCustomobject or empty string "". Convert to Hashtable for further operation like add keys or update values.
    $AppRawDataHash = @{}
    if ($AppRawData -and ($AppRawData -ne $APP_RAW_DATA_DEFAULT_VALUE)){
        $AppRawData.psobject.properties | ForEach-Object { $AppRawDataHash[$_.Name] = $_.Value }
    }

    if ($HostIP -and $HostIPv6){
        $AppRawDataHash.NodeManagementNetwork = @{
            "timestamp" = $CurrentTime
            'IP' = $HostIP
            'netmask' = $Netmask
            'gateway' = $Gateway
            "IPv6" = $HostIPv6
            "prefixlen" = $PrefixLen
            "gatewayv6" = $Gatewayv6
            "vLAN" = $Vlan
            "status_code" = $StatusCode
            "message" = $Message
        }
    }elseif(-not $HostIP){
        $AppRawDataHash.NodeManagementNetwork = @{
            "timestamp" = $CurrentTime
            "IPv6" = $HostIPv6
            "prefixlen" = $PrefixLen
            "gatewayv6" = $Gatewayv6
            "vLAN" = $Vlan
            "status_code" = $StatusCode
            "message" = $Message
        }
    }else{
        $AppRawDataHash.NodeManagementNetwork = @{
            "timestamp" = $CurrentTime
            'IP' = $HostIP
            'netmask' = $Netmask
            'gateway' = $Gateway
            "vLAN" = $Vlan
            "status_code" = $StatusCode
            "message" = $Message
        }   
    }
    
    Write-Verbose "AppRawData: $AppRawData.NodeManagementNetwork"
    $Body = $AppRawDataHash
    $Body = $Body | ConvertTo-Json
    $BodyAscii = [Text.Encoding]::ASCII.GetBytes($Body)
    $BodyBasic64 = [Convert]::ToBase64String($BodyAscii)
    $Body = @{
        "Attributes" = @{
            "ConvergedInfra.1.AppRawData" = $BodyBasic64
        }
    }
    $Body = $Body | ConvertTo-Json

    $uri = "/redfish/v1/Managers/iDRAC.Embedded.1/Attributes"
    $url = "https://" + $Server + $uri
    $specialHeader = @{"Accept"='*/*'}

    try{
        $response = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $body -SpecialHeaders $specialHeader `
        -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        $response = $response | ConvertTo-Json
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

function Set-VxMAppRawData{
    param(
        # iDRAC's IP
        [String] $Server,

        # iDRAC's username
        [String] $Username,

        # iDRAC's password
        [String] $Password,

        [String] $IP,

        [String] $Netmask,

        [String] $Gateway,

        # IPV6 address to be set
        [String] $IPv6,

        # PrefixLen to be set
        [int] $PrefixLen,

        # IPv6 GW to be set
        [String] $Gatewayv6,

        # Vlan to be set
        [int] $Vlan,

        # Status_code to be set
        [int] $StatusCode,

        # Message to be set
        [String] $Message,

        # Proxy to access the iDrac
        [String] $Proxy,

        # Username of the proxy server
        [String] $ProxyUsername,

        # Password of the proxy server
        [String] $ProxyPassword
    )
    $CurrentTime = getCurrentTime -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    $AppRawData = Get-VxMAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    # The return of Get-VxMAppRawData is PSCustomobject. Convert to Hashtable for further operation like add keys or update values.
    $AppRawDataHash = @{}
    if ($AppRawData.VxMNetwork -and ($AppRawData.VxMNetwork -ne $APP_RAW_DATA_DEFAULT_VALUE)){
        $AppRawData.psobject.properties | Foreach { $AppRawDataHash[$_.Name] = $_.Value }
    }
    if ($IP -and $IPv6){
        $AppRawDataHash.VxMNetwork = @{
            "timestamp" = $CurrentTime
            "IPv4" = $IP
            "netmask" = $Netmask
            "gw4" = $Gateway
            "IPv6" = $IPv6
            "prefix" = $PrefixLen
            "gw6"=$Gatewayv6
            "vLAN" = $Vlan
            "status_code" = $StatusCode
            "message" = $Message
        }
    }elseif(-not $IP){
        $AppRawDataHash.VxMNetwork = @{
            "timestamp" = $CurrentTime
            "IPv6" = $IPv6
            "prefix" = $PrefixLen
            "gw6"=$Gatewayv6
            "vLAN" = $Vlan
            "status_code" = $StatusCode
            "message" = $Message
        }
    }else{
        $AppRawDataHash.VxMNetwork = @{
            "timestamp" = $CurrentTime
            "IPv4" = $IP
            "netmask" = $Netmask
            "gw4" = $Gateway
            "vLAN" = $Vlan
            "status_code" = $StatusCode
            "message" = $Message
        }
    }

    $Body = $AppRawDataHash
    $Body = $Body | ConvertTo-Json
    $BodyAscii = [Text.Encoding]::ASCII.GetBytes($Body)
    $BodyBasic64 = [Convert]::ToBase64String($BodyAscii)
    $Body = @{
        "Attributes" = @{
            "ConvergedInfra.1.AppRawData" = $BodyBasic64
        }
    }
    $Body = $Body | ConvertTo-Json
    $uri = "/redfish/v1/Managers/iDRAC.Embedded.1/Attributes"
    $url = Get-Url -Server $Server -Uri $uri
    $specialHeader = @{"Accept"='*/*'}

    try{
        $response = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $body -SpecialHeaders $specialHeader `
        -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        $response = $response | ConvertTo-Json
        return $response
    }catch{
        HandleInvokeRestMethodException -URL $url
    }
}

function GetAppRawData{
    param(
        [Parameter(Mandatory = $true)]
        # iDRAC's IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword
    )

    $uri = "/redfish/v1/Managers/iDRAC.Embedded.1/Attributes?%24select=ConvergedInfra.1.AppRawData"
    $url = "https://" + $Server + $uri
    $specialHeader = @{"Accept"='*/*'}

    try{
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password -SpecialHeaders $specialHeader `
         -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        $AppRawData = $response.Attributes."ConvergedInfra.1.AppRawData"
        if ($AppRawData -and ($AppRawData -ne $APP_RAW_DATA_DEFAULT_VALUE)){
            $DecodedAppRawData = DecodeBase64 -EncodedText $AppRawData
            Return $DecodedAppRawData
        }
        else {
            Return $AppRawData
        }
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

function Get-VxMAppRawData{
    param(
        [Parameter(Mandatory = $true)]
        # iDRAC's IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword
    )

    $uri = "/redfish/v1/Managers/iDRAC.Embedded.1/Attributes?%24select=ConvergedInfra.1.AppRawData"
    $url = Get-Url -Server $Server -Uri $uri
    $specialHeader = @{"Accept"='*/*'}

    try{
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password -SpecialHeaders $specialHeader `
         -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        $AppRawData = $response.Attributes."ConvergedInfra.1.AppRawData"
        if ($AppRawData -and ($AppRawData.VxMNetwork -ne $APP_RAW_DATA_DEFAULT_VALUE)){
            $DecodedAppRawData = DecodeBase64 -EncodedText $AppRawData
            Return $DecodedAppRawData
        }else{
            Return $AppRawData
        }
    }catch{
        HandleInvokeRestMethodException -URL $url
    }
}

function GetCurrentTime {
    param(
        [Parameter(Mandatory = $true)]
        # iDRAC's IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword
    )

    $uri = "/redfish/v1/Managers/iDRAC.Embedded.1/Oem/Dell/DellTimeService/Actions/DellTimeService.ManageTime"
    $url = Get-Url -Server $Server -Uri $uri
    $specialHeader = @{"Accept"='*/*'}
    $Body = @{
        "GetRequest" = $true
    }
    $Body = $Body | ConvertTo-Json

    try {
        $response = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body -SpecialHeaders $specialHeader `
         -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        return $response.TimeData
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

function GetTimeDifference {
    param(
        [Parameter(Mandatory = $true)]
        # StartTime string represented in ISO8601 format
        [String] $StartTime,

        [Parameter(Mandatory = $true)]
        # EndTime string represented in ISO8601 format
        [String] $EndTime
    )

    # Transform Time from ISO8601 to Powershell datetime format, and then transform to Unix Time in seconds
    $StartTime = [datetime]::Parse($StartTime)
    $StartTime = ([DateTimeOffset]$StartTime).ToUnixTimeSeconds()
    $EndTime = [datetime]::Parse($EndTime)
    $EndTime = ([DateTimeOffset]$EndTime).ToUnixTimeSeconds()

    return $EndTime - $StartTime
}

function DecodeBase64{
    param(
        [Parameter(Mandatory = $true)]
        # Base64 string
        [String] $EncodedText
    )
    try{
        $DecodedText = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($EncodedText)) | ConvertFrom-Json
        return $DecodedText
    }
    catch {
        Write-Verbose "appRawData can't be decoded"
        return ""
    }
}

 <#
.SYNOPSIS
Set the host network via iDrac IP address

.PARAMETER Server
Required. iDrac IP address (IPv4 format)

.PARAMETER Username
Required. iDrac username

.PARAMETER Password
Required. Use corresponding password for iDrac username

.PARAMETER HostIP
Required. IP address to be configured to the host

.PARAMETER HostIPv6
Optional. IPv6 address to be configured to the host

.PARAMETER Netmask
Required. Netmask to be configured to the host

.PARAMETER PrefixLen
Optional. Prefix Length to be configured to the host

.PARAMETER Gateway
Required. Gateway IP to be configured to the host

.PARAMETER Gatewayv6
Required. Gateway IPv6 to be configured to the host

.PARAMETER Vlan
Optional. The vlan for the host. The valid value is from 0 to 4095 (including 0 and 4095). Skip it or input 0 if no vlan is used

.PARAMETER Proxy
Optional. Proxy to access the iDrac. It should be formatted as: http://<proxy_ip>:<port>.

.PARAMETER ProxyUsername
Optional. Username of the proxy server

.PARAMETER ProxyPassword
Optional. Password of the proxy server

.NOTES
You can run this cmdlet to configure the host network via iDrac IP address

.EXAMPLE
PS> Set-HostNetwork -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -HostIP <Host IP> -Netmask <Netmask> -Gateway <Gateway> -Vlan <Vlan>
Set the host network with vlan

.EXAMPLE
PS> Set-HostNetwork -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -HostIPv6 <Host IPv6> -PrefixLen <PrefixLen> -Gatewayv6 <Gateway IPv6>
Set the IPv6 host network when there is no vlan for it

.EXAMPLE
PS> Set-HostNetwork -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -HostIP <Host IP> -Netmask <Netmask> -Gateway <Gateway> -HostIPv6 <Host IPv6> -PrefixLen <PrefixLen> -Gatewayv6 <Gateway IPv6>
Set the Dualstack host network when there is no vlan for it

.EXAMPLE
PS> Set-HostNetwork -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -HostIP <Host IP> -Netmask <Netmask> -Gateway <Gateway>
Set the host network when there is no vlan for it

.EXAMPLE
PS> Set-HostNetwork -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -HostIP <Host IP> -Netmask <Netmask> -Gateway <Gateway> -Vlan <Vlan> -Proxy <Proxy>
Set the host network via proxy

.EXAMPLE
PS> Set-HostNetwork -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -HostIP <Host IP> -Netmask <Netmask> -Gateway <Gateway> -Vlan <Vlan> -Proxy <Proxy> -ProxyUsername <ProxyUsername> -ProxyPassword <ProxyPassword>
Set the host network via proxy which enabled authentication
#>
function Set-HostNetwork{
    param(
        [Parameter(Mandatory = $true)]
        # iDRAC's IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Password,

        # IPv4 address to be set
        [String] $HostIP,

        # Netmask to be set
        [String] $Netmask,

        # Gateway IP to be set
        [String] $Gateway,

        # IPv6 address to be set
        [String] $HostIPv6,

        # prefix length to be set
        [int] $PrefixLen,

        # IPv6 Gateway IP to be set
        [String] $Gatewayv6,

        [Parameter(Mandatory = $false)]
        # Optional. The Vlan to be set.
        [Uint16]$Vlan,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword
    )

if ($Proxy) {
    if ($ProxyUsername){
        if (-not $ProxyPassword) {
            Write-Error "You can't use ProxyUsername without ProxyPassword parameter, please input ProxyPassword"
            return
        }
    }
    if ($ProxyPassword){
        if (-not $ProxyUsername) {
            Write-Error "You can't use ProxyPassword without ProxyUsername parameter, please input ProxyUsername"
            return
        }
    }
}
else {
    if (($ProxyUsername) -or ($ProxyPassword)) {
        Write-Error "You can't use ProxyUsername or ProxyPassword without Proxy parameter"
        return
    }
}

# validate the IP, mask and GW.
if (-not ($Server -match $IPV4_PATTERN)) {
    Write-Error "Server IP is invalid, please correct it and try again"
    return
}

if ((-not $HostIP) -and (-not $HostIPv6)){
    Write-Error "Unrecognized Host network configuration"
    return
}

if ($HostIP){
    Check-IPv4Judge -IP $HostIP -Netmask $Netmask -Gateway $Gateway
}

if ($HostIPv6){
    Check-IPv6Judge -IPv6 $HostIPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6
}

# If didn't input value for vlan, set vlan to 0
if (-not $Vlan){
    $Vlan = [Uint16]0
}

if ($Vlan -gt $MAX_VLANID){
    Write-Error "Invalid vlan, vlan should be integer and between 0-4095(including 0 and 4095), please correct it and try again"
    return
}

$AppRawData = GetAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword

if ($AppRawData -and ($AppRawData -ne $APP_RAW_DATA_DEFAULT_VALUE)) {
    $StatusCode = $AppRawData.NodeManagementNetwork.status_code
    $ExistingTimestamp = $AppRawData.NodeManagementNetwork.timestamp
    $CurrentTime = getCurrentTime -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    $TimeDifference = GetTimeDifference -StartTime $ExistingTimestamp -EndTime $CurrentTime

    Switch($StatusCode)
        {
            '0' {
                if ($TimeDifference -le $INITIALIZE_HOST_NETWORK_SETTING_TIMEOUT) {
                    Write-Warning "there is another task being executed, please try again later."
                    return
                }
                else {
                    Write-Verbose "there is a timeout task."
                    SetAppRawData -Server $Server -Username $Username -Password $Password -HostIP $HostIP -Netmask $Netmask -Gateway $Gateway -HostIPv6 $HostIPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6 -Vlan $Vlan -StatusCode 0 -Message "init" `
                     -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                    return
                }
            }
            '1' {
                if ($TimeDifference -le $HOST_NETWORK_SETTING_TIMEOUT) {
                        Write-Warning "there is another task being executed, please try again later."
                        return
                    }
                    else {
                        Write-Verbose "there is a timeout task."
                        SetAppRawData -Server $Server -Username $Username -Password $Password -HostIP $HostIP -Netmask $Netmask -Gateway $Gateway -HostIPv6 $HostIPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6 -Vlan $Vlan -StatusCode 0 -Message "init" `
                         -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                        return
                    }
            }
            '200' {
                    Write-Verbose "The existing status_code in idrac is: $StatusCode"
                    SetAppRawData -Server $Server -Username $Username -Password $Password -HostIP $HostIP -Netmask $Netmask -Gateway $Gateway -HostIPv6 $HostIPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6 -Vlan $Vlan -StatusCode 0 -Message "init" `
                     -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                    return
            }
            '400' {
                    Write-Verbose "The existing status_code in idrac is: $StatusCode"
                    SetAppRawData -Server $Server -Username $Username -Password $Password -HostIP $HostIP -Netmask $Netmask -Gateway $Gateway -HostIPv6 $HostIPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6 -Vlan $Vlan -StatusCode 0 -Message "init" `
                     -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                    return
            }
            '500' {
                Write-Verbose "The existing status_code in idrac is: $StatusCode"
                SetAppRawData -Server $Server -Username $Username -Password $Password -HostIP $HostIP -Netmask $Netmask -Gateway $Gateway -HostIPv6 $HostIPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6 -Vlan $Vlan -StatusCode 0 -Message "init" `
                 -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                return
            }
        }
    }
    else {
        Write-Verbose "There is no AppRawdata existing in idrac"
        SetAppRawData -Server $Server -Username $Username -Password $Password -HostIP $HostIP -Netmask $Netmask -Gateway $Gateway -Vlan $Vlan -HostIPv6 $HostIPv6 -PrefixLen $PrefixLen -Gatewayv6 $Gatewayv6 -StatusCode 0 -Message "init" `
         -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        return
    }
}

 <#
.SYNOPSIS
Get the host network setting status.

.PARAMETER Server
Required. iDrac IP address (IPv4 format)

.PARAMETER Username
Required. iDrac username

.PARAMETER Password
Required. Use corresponding password for iDrac username

.PARAMETER Proxy
Optional. Proxy to access the iDrac. It should be formatted as: http://<proxy_ip>:<port>.

.PARAMETER ProxyUsername
Optional. Username of the proxy server

.PARAMETER ProxyPassword
Optional. Password of the proxy server

.NOTES
You can run this cmdlet to get the host network setting status.

.EXAMPLE
PS> Get-HostNetworkSettingStatus -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password>

.EXAMPLE
PS> Get-HostNetworkSettingStatus -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -Proxy <Proxy>

.EXAMPLE
PS> Get-HostNetworkSettingStatus -Server <iDrac IP> -Username <iDrac username> -Password <iDrac password> -Proxy <Proxy> -ProxyUsername <ProxyUsername> -ProxyPassword <ProxyPassword>
#>
function Get-HostNetworkSettingStatus{
    param(
        [Parameter(Mandatory = $true)]
        # iDRAC's IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # iDRAC's username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Proxy to access the iDrac
        [String] $Proxy,

        [Parameter(Mandatory = $false)]
        # Username of the proxy server
        [String] $ProxyUsername,

        [Parameter(Mandatory = $false)]
        # Password of the proxy server
        [String] $ProxyPassword
    )

    if ($Proxy) {
        if ($ProxyUsername){
            if (-not $ProxyPassword) {
                Write-Error "You can't use ProxyUsername without ProxyPassword parameter, please input ProxyPassword"
                return
            }
        }
        if ($ProxyPassword){
            if (-not $ProxyUsername) {
                Write-Error "You can't use ProxyPassword without ProxyUsername parameter, please input ProxyUsername"
                return
            }
        }
    }
    else {
        if (($ProxyUsername) -or ($ProxyPassword)) {
            Write-Error "You can't use ProxyUsername or ProxyPassword without Proxy parameter"
            return
        }
    }

    $AppRawData = GetAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword

    if ($AppRawData -and ($AppRawData -ne $APP_RAW_DATA_DEFAULT_VALUE)) {
        $StatusCode = $AppRawData.NodeManagementNetwork.status_code
        $Message = $AppRawData.NodeManagementNetwork.message
        $ExistingTimestamp = $AppRawData.NodeManagementNetwork.timestamp
        $CurrentTime = getCurrentTime -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        $TimeDifference = GetTimeDifference -StartTime $ExistingTimestamp -EndTime $CurrentTime

        Switch($StatusCode)
        {
            '0' {
                if ($TimeDifference -le $INITIALIZE_HOST_NETWORK_SETTING_TIMEOUT) {
                    Write-Host "Status code: $StatusCode, message: $message"
                    Write-Host "The network setting is initializing."
                    return
                }else{
                    Write-Host "Status code: $StatusCode, message: $message"
                    Write-Host "The network setting initialization is timed out. If timeout persists after each retry, please contact VxRail technical support."
                    return
                }
            }
            '1' {
                if ($TimeDifference -le $HOST_NETWORK_SETTING_TIMEOUT) {
                    Write-Host "Status code: $StatusCode, message: $message"
                    Write-Host "The network setting configuration is in progress."
                    return
                }else{
                    Write-Host "Status code: $StatusCode, message: $message"
                    Write-Host "The network setting configuration is timed out. Please try again. If the error occurs again, please collect logs and contact VxRail technical support."
                    return
                }
            }
            '200' {
                Write-Host "Status code: $StatusCode, message: $message"
                Write-Host "The network setting is successful"
                return
            }
            '400' {
                Write-Host "Status code: $StatusCode, message: $message"
            }
            '500' {
                Write-Host "Status code: $StatusCode, message: $message"
            }
        }
    }
    else {
        Write-Host "There's no network setting information."
        return
    }
}

function Set-VxRailManagerNetworkAppRawData{
    param(
        # iDRAC's IP
        [String] $Server,

        # iDRAC's username
        [String] $Username,

        # iDRAC's username
        [String] $Password,

        [String] $IP,

        [String] $Netmask,

        [String] $Gateway,

        # IPv6 address to be set
        [String] $IPv6,

        # PrefixLen  to be set
        [Uint16] $PrefixLen ,

        # IPv6 Gateway to be set
        [String] $Gatewayv6,

        # Optional. The Vlan to be set.
        [Uint16]$Vlan,

        # Proxy to access the iDrac
        [String] $Proxy,

        # Username of the proxy server
        [String] $ProxyUsername,

        # Password of the proxy server
        [String] $ProxyPassword
    )

$AppRawData = Get-VxMAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
if ($AppRawData.VxMNetwork -ne $null) {
    if ($AppRawData.VxMNetwork.GetType().Name -eq "String") {
        $AppRawData = $AppRawData | ConvertFrom-Json
    }
}
if ($AppRawData.VxMNetwork -and ($AppRawData.VxMNetwork.PSObject.Properties.Value.Count -ne 0)) {
    $StatusCode = $AppRawData.VxMNetwork.status_code
    $CurrentTime = getCurrentTime -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    $ExistingTimestamp = $AppRawData.VxMNetwork.timestamp
    $TimeDifference = GetTimeDifference -StartTime $ExistingTimestamp -EndTime $CurrentTime
    Switch($StatusCode)
    {
        '0' {
            if ($TimeDifference -le $INITIALIZE_HOST_NETWORK_SETTING_TIMEOUT) {
                Write-Warning "there is another task being executed, please try again later."
                return
            }else{
                Write-Verbose "there is a timeout task."
                Set-VxMAppRawData -Server $Server -Username $Username -Password $Password -IP $IP -Netmask $Netmask -Gateway $Gateway -IPv6 $IPv6 -PrefixLen  $PrefixLen  -Gatewayv6 $Gatewayv6 -Vlan $VlanID -StatusCode 0 -Message "init" `
                -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                return
            }
        }
        '1' {
            if ($TimeDifference -le $HOST_NETWORK_SETTING_TIMEOUT) {
                Write-Warning "there is another task being executed, please try again later."
                return
            }else{
                Write-Verbose "there is a timeout task."
                Set-VxMAppRawData -Server $Server -Username $Username -Password $Password -IP $IP -Netmask $Netmask -Gateway $Gateway -IPv6 $IPv6 -PrefixLen  $PrefixLen  -Gatewayv6 $Gatewayv6 -Vlan $VlanID -StatusCode 0 -Message "init" `
                -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                return
                }
            }
        '200' {
            Write-Verbose "The existing status_code in idrac is: $StatusCode"
            Set-VxMAppRawData -Server $Server -Username $Username -Password $Password -IP $IP -Netmask $Netmask -Gateway $Gateway -IPv6 $IPv6 -PrefixLen  $PrefixLen  -Gatewayv6 $Gatewayv6 -Vlan $VlanID -StatusCode 0 -Message "init" `
            -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
            return
        }
        '400' {
            Write-Verbose "The existing status_code in idrac is: $StatusCode"
            Set-VxMAppRawData -Server $Server -Username $Username -Password $Password -IP $IP -Netmask $Netmask -Gateway $Gateway -IPv6 $IPv6 -PrefixLen  $PrefixLen  -Gatewayv6 $Gatewayv6 -Vlan $VlanID -StatusCode 0 -Message "init" `
            -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        }
        '500' {
            Write-Verbose "The existing status_code in idrac is: $StatusCode"
            Set-VxMAppRawData -Server $Server -Username $Username -Password $Password -IP $IP -Netmask $Netmask -Gateway $Gateway -IPv6 $IPv6 -PrefixLen  $PrefixLen  -Gatewayv6 $Gatewayv6 -Vlan $VlanID -StatusCode 0 -Message "init" `
            -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
            return
        }
    }

    }else {
        Write-Verbose "There is no AppRawdata existing in idrac"
        Set-VxMAppRawData -Server $Server -Username $Username -Password $Password -IP $IP -Netmask $Netmask -Gateway $Gateway -IPv6 $IPv6 -PrefixLen  $PrefixLen  -Gatewayv6 $Gatewayv6 -Vlan $VlanID -StatusCode 0 -Message "init" `
        -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
        return
    }
}

function Get-VxRailManagerNetworkAppRawDataSettingStatus{
    param(
        # iDRAC's IP
        [String] $Server,

        # iDRAC's username
        [String] $Username,

        # iDRAC's username
        [String] $Password,

        # Proxy to access the iDrac
        [String] $Proxy,

        # Username of the proxy server
        [String] $ProxyUsername,

        # Password of the proxy server
        [String] $ProxyPassword
    )
    $AppRawData = Get-VxMAppRawData -Server $Server -Username $Username -Password $Password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    $StatusCode = $AppRawData.VxMNetwork.status_code
    $Message = $AppRawData.VxMNetwork.message
    $ExistingTimestamp = $AppRawData.VxMNetwork.timestamp
    $CurrentTime = getCurrentTime -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
    $TimeDifference = GetTimeDifference -StartTime $ExistingTimestamp -EndTime $CurrentTime

    if ($AppRawData.VxMNetwork.IPv4){
        Write-Host "IP       : "$AppRawData.VxMNetwork.IPv4
        Write-Host "Netmask  : "$AppRawData.VxMNetwork.netmask
        Write-Host "Gateway  : "$AppRawData.VxMNetwork.gw4
    }
    if($AppRawData.VxMNetwork.IPv6){
        Write-Host "IPv6       : "$AppRawData.VxMNetwork.IPv6
        Write-Host "Prefixlen  : "$AppRawData.VxMNetwork.prefix
        Write-Host "Gatewayv6  : "$AppRawData.VxMNetwork.gw6
    }
    Write-Host "vLAN     : "$AppRawData.VxMNetwork.vLAN
    Switch($StatusCode)
    {
        '0' {
            if ($TimeDifference -le $INITIALIZE_VXM_SETTING_TIMEOUT) {
                Write-Host "Status code: $StatusCode, message: $message"
                Write-Host "The network setting is initializing."
                return
            }else{
                Write-Host "Status code: $StatusCode, message: $message"
                Write-Host "The network setting initialization is timed out. If timeout persists after each retry, please contact VxRail technical support."
                return
            }
        }
        '1' {
            if ($TimeDifference -le $VXM_SETTING_TIMEOUT) {
                Write-Host "Status code: $StatusCode, message: $message"
                Write-Host "The network setting configuration is in progress."
                return
            }else{
                Write-Host "Status code: $StatusCode, message: $message"
                Write-Host "The network setting configuration is timed out. Please try again. If the error occurs again, please collect logs and contact VxRail technical support."
                return
            }
        }
        '200' {
            Write-Host "Status code: $StatusCode, message: $message"
            Write-Host "The network setting is successful"
            return
        }
        '400' {
            Write-Host "Status code: $StatusCode, message: $message"
            Write-Error "AppRawData cannot be found when the user version is too low"
        }
        '500' {
            Write-Host "Status code: $StatusCode, message: $message"
        }
    }
}


function Get-VxRailManageNetworkLCAttributesSettingStatus{
    param(
        # iDrac IP
        [String] $Server,

        # iDrac username
        [String] $Username,

        # Use corresponding password for iDrac username
        [String] $Password,

        # Proxy to access the iDrac
        [String] $Proxy,

        # Username of the proxy server
        [String] $ProxyUsername,

        # Password of the proxy server
        [String] $ProxyPassword
    )

    $value = Get-VxRailManagerNetwork -Server $Server -Username $Username -Password $Password
    if($value){
        $str = [String]::Format("Success to get VxRail Manager network configuration, Value: '{0}'", $value)
        Write-Verbose $str
        if($value.Trim()){
            try{
                Write-Verbose "Parsing VxRail Manager network configuration:"
                $returnCode, $ip_lca, $gateway_lca, $netmask_lca, $vxmVLAN_lca = ConvertTo-ReadableLCString($value)
                Write-Verbose "returnCode: $returnCode"
                if ($returnCode -ne 1){
                    Switch($returnCode)
                    {
                        '0' {
                            $status_str = "configuration is set successfully."
                        }
                        '1' {
                            $status_str = "configuration in progress."
                        }
                        '2' {
                            $status_str = "configuration in progress."
                        }
                        '3' {
                            $status_str = "Error: configuration are found in multiple nodes."
                        }
                        '4' {
                            $status_str = "Error: configuration error " + $returncode
                        }
                        default
                        {
                            $status_str = "Error: Internal errorcode " + $returnCode
                        }
                    }
                    Write-Host "IP       : $ip_lca"
                    Write-Host "Netmask  : $netmask_lca"
                    Write-Host "Gateway  : $gateway_lca"
                    Write-Host "vLAN     : $vxmVLAN_lca"
                    Write-Host "Status   : $status_str"
                }else{
                    Get-VxRailManagerNetworkAppRawDataSettingStatus -Server $server -Username $username -Password $password -Proxy $Proxy -ProxyUsername $ProxyUsername -ProxyPassword $ProxyPassword
                }
            }catch {
                Write-Host "Unrecognized VxRail Manager network configuration." -ForegroundColor Yellow
            }
        }else{
            Write-Host "The current staging values all cleared."
        }
    }else {
        Write-Host "The current staging values all cleared."
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
        Write-Error "IPv4 address is invalid, please correct it and try again"
        return
    }
    if (-not$Netmask)
    {
        Write-Error "Netmask cannot be empty"
        return
    }else{
        if (-not($Netmask -match $NETMASK_PATTERN))
        {
            Write-Error "Netmask is invalid, please correct it and try again"
            return
        }
    }
    if (-not$Gateway)
    {
        Write-Error "IPv4 Gateway cannot be empty"
        return
    }else{
        if (-not($Gateway -match $IPV4_PATTERN))
        {
            Write-Error "IPv4 Gateway is invalid, please correct it and try again"
            return
        }
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
        Write-Error "IPv6 address is invalid, please correct it and try again"
        return
        }
    if (-not $PrefixLen){
        Write-Error "PrefixLen cannot be empty"
        return
    }else{
        if ($PrefixLen  -gt $MAX_PREFIXLEN){
            Write-Error "Invalid PrefixLen , PrefixLen  should be integer and between 0-128(including 0 and 128), please correct it and try again"
            return
        }
    }
    if (-not $Gatewayv6){
        Write-Error "IPv6 Gateway cannot be empty"
        return
    }else{
        if (-not ($Gatewayv6 -match $IPV6_PATTERN)) {
            Write-Error "IPv6 Gateway is invalid, please correct it and try again"
            return
        }
    }
}

function Check-ServerJudge {
    param(
        [Parameter(Mandatory = $true)]
        # iDRAC's IP
        [String] $Server
    )
    #IPV4 and IPV6 cannot be empty at the same time.  You can upload IPV4 or IPV6, or both, but ensure that the parameters are complete
    if ((-not ($Server -match $IPV4_PATTERN)) -and (-not ($Server -match $IPV6_PATTERN))){
        Write-Error "Server IP is invalid, please correct it and try again"
        return
    }
}

function Check-ProxyJudge{
    param(
        # Proxy to access the iDrac
        [String] $Proxy,

        # Username of the proxy server
        [String] $ProxyUsername,

        # Password of the proxy server
        [String] $ProxyPassword
    )
    if ($Proxy) {
        if ($ProxyUsername){
            if (-not $ProxyPassword) {
                Write-Error "You can't use ProxyUsername without ProxyPassword parameter, please input ProxyPassword"
                return
            }
        }
        if ($ProxyPassword){
            if (-not $ProxyUsername) {
                Write-Error "You can't use ProxyPassword without ProxyUsername parameter, please input ProxyUsername"
                return
            }
        }
    }else{
        if (($ProxyUsername) -or ($ProxyPassword)) {
            Write-Error "You can't use ProxyUsername or ProxyPassword without Proxy parameter"
            return
        }
    }
}

function Get-Url{
        param(
        # iDRAC's IP
        [String] $Server,

        [String] $Uri
    )
    if ($Server -match $IPV6_PATTERN) {
        return "https://" + "[" + $Server + "]" + $Uri
    }else{
        return "https://" + $Server + $Uri
    }
}