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
Retrieves a list of the available iDRAC user slot IDs.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Sn
The serial number of the host to be queried.

.NOTES
You can run this cmdlet to retrieve a list of the available iDRAC user slot IDs.

.EXAMPLE
PS> Get-iDRACUserIds -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn>

Retrieves a list of the available iDRAC user slot IDs.
#>
function Get-iDRACUserIds {
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
        # The serial number of the host to be queried
        [String] $Sn
    )

    $uri = -join ("/rest/vxm/v1/hosts/",$sn,"/idrac/available-user-ids")

    try{
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
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
Retrieves a list of created iDRAC user accounts on the specified host.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Sn
The serial number of the host to be queried.

.NOTES
You can run this cmdlet to retrieve a list of created iDRAC user accounts on the specified host.

.EXAMPLE
PS> Get-iDRACUsers -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn>

Retrieves a list of created iDRAC user accounts on the specified host.
#>
function Get-iDRACUsers {
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
        # The serial number of the host to be queried
        [String] $Sn
    )

    $uri = -join ("/rest/vxm/v1/hosts/",$sn,"/idrac/users")

    try{
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
.Synopsis
Create an iDRAC user account.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Sn
The serial number of the host to be queried.

.Parameter UserId
The iDRAC user slot ID.

.Parameter iDRACUserName
The iDRAC user name.

.Parameter iDRACPassword
The iDRAC user password.

.Parameter iDRACPrivilege
The permissions (privilege) of the iDRAC user. Can be set to ADMIN, OPER, or READONLY.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to create an iDRAC user account.

.EXAMPLE
PS> New-iDRACUser -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn> -UserId <iDRAC user slot id> -iDRACUsername <iDRAC user name> -iDRACPasword <iDRAC user password> -iDRACPrivilege <iDRAC user privilege>

Create an iDRAC user account
#>
function New-iDRACUser {
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

        # The serial number of the host to be queried
        [Parameter(Mandatory = $true)]
        [String] $Sn,

        # The iDRAC user slot ID
        [Parameter(Mandatory = $false)]
        [String] $UserId,

        # The iDRAC user name
        [Parameter(Mandatory = $true)]
        [String] $iDRACUsername,

        # The iDRAC user password
        [Parameter(Mandatory = $true)]
        [String] $iDRACPassword,

        # The permissions (privilege) of the iDRAC user. Can be set to ADMIN, OPER, or READONLY.
        [Parameter(Mandatory = $true,HelpMessage="Supported privilege: 'ADMIN','OPER','READONLY'")]
        [ValidateSet('ADMIN','OPER','READONLY')]
        [String] $iDRACPrivilege,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = -join ("/rest/vxm/v1/hosts/",$sn,"/idrac/users")

    # Body content to post
    $body = @{
        "id" = $UserId
        "name" = $iDRACUsername
        "password" = $iDRACPassword
        "privilege" = $iDRACPrivilege
    } | ConvertTo-Json

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
Updates an iDRAC user account.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Sn
The serial number of the host to be queried.

.Parameter UserId
The unique identifier of the iDRAC user.
The user ID range is 3 through 16.

.Parameter iDRACUserName
The iDRAC user name.

.Parameter iDRACPassword
The iDRAC user password.

.Parameter iDRACPrivilege
The permissions (privilege) of the iDRAC user. Can be set to ADMIN, OPER, or READONLY.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to update an iDRAC user account.

.EXAMPLE
PS> Update-iDRACUser -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn> -UserId <iDRAC user Id> -iDRACUsername <iDRAC user name> -iDRACPasword <iDRAC user password> -iDRACPrivilege <iDRAC user privilege>

Updates an iDRAC user account.
#>
function Update-iDRACUser {
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

        # The serial number of the host to be queried
        [Parameter(Mandatory = $true)]
        [String] $Sn,

        # The unique identifier of the iDRAC user. The user ID range is 3 through 16.
        [Parameter(Mandatory = $true)]
        [String] $UserId,

        # The iDRAC user name
        [Parameter(Mandatory = $true)]
        [String] $iDRACUsername,

        # The iDRAC user password
        [Parameter(Mandatory = $true)]
        [String] $iDRACPassword,

        # User account privilege of the iDRAC
        [Parameter(Mandatory = $true,HelpMessage="Supported privilege: 'ADMIN','OPER','READONLY'")]
        [ValidateSet('ADMIN','OPER','READONLY')]
        [String] $iDRACPrivilege,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = -join ("/rest/vxm/v1/hosts/",$Sn,"/idrac/users/",$UserId)

    # Body content to put
    $body = @{
        "name" = $iDRACUsername
        "password" = $iDRACPassword
        "privilege" = $iDRACPrivilege
    } | ConvertTo-Json

    try{
        $ret = doPut -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
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
Updates an iDRAC user account using the V2 API.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username with either Administrator or HCIA role.
.Parameter Password
Corresponding password for username.
.Parameter Sn
The serial number of the host to be queried.
.Parameter UserId
The unique identifier of the iDRAC user. User ID range is 3 through 16.
.Parameter iDRACUserName
The iDRAC user name.
.Parameter iDRACCurrentPassword
The current password of the iDRAC user.
.Parameter iDRACNewPassword
The new password for the iDRAC user.
.Parameter iDRACPrivilege
The permissions (privilege) of the iDRAC user. Can be set to ADMIN, OPER, or READONLY.
.Parameter Format
Print JSON style format.
.Notes
You can run this cmdlet to update an iDRAC user account using the V2 API.
.EXAMPLE
PS> Update-iDRACUserV2 -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn> -UserId <iDRAC user Id> -iDRACUsername <iDRAC user name> -iDRACCurrentPassword <iDRAC current user password> -iDRACNewPassword <iDRAC new user password> -iDRACPrivilege <iDRAC user privilege>
Updates an iDRAC user account using the V2 API.
#>
function Update-iDRACUserV2 {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username with either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # The serial number of the host to be queried
        [Parameter(Mandatory = $true)]
        [String] $Sn,

        # The unique identifier of the iDRAC user. User ID range is 3 through 16.
        [Parameter(Mandatory = $true)]
        [String] $UserId,

        # The iDRAC user name
        [Parameter(Mandatory = $true)]
        [String] $iDRACUsername,

        # The current password of the iDRAC user
        [Parameter(Mandatory = $true)]
        [String] $iDRACCurrentPassword,

        # The new password for the iDRAC user
        [Parameter(Mandatory = $true)]
        [String] $iDRACNewPassword,

        # User account privilege of the iDRAC
        [Parameter(Mandatory = $true, HelpMessage = "Supported privileges: 'ADMIN', 'OPER', 'READONLY'")]
        [ValidateSet('ADMIN', 'OPER', 'READONLY')]
        [String] $iDRACPrivilege,

        # Print in JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = -join ("/rest/vxm/v2/hosts/", $Sn, "/idrac/users/", $UserId)

    $Body = @()
    $ComponentObj = @{
        "name" = $iDRACUsername
        "current_password" = $iDRACCurrentPassword
        "new_password" = $iDRACNewPassword
        "privilege" = $iDRACPrivilege
    }
    $Body += $ComponentObj

    $Body = ConvertTo-Json @($Body)

    try {
        $ret = doPut -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}


<#
.SYNOPSIS
Retrieves the iDRAC network settings on the specified host.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Sn
The serial number of the host to be queried.

.Parameter Format
Print JSON style format.

.NOTES
You can run this cmdlet to retrieve the iDRAC network settings on the specified host.

.EXAMPLE
PS> Get-iDRACNetwork -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn>

Retrieves the iDRAC network settings on the specified host.
#>
function Get-iDRACNetwork {
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

        [Parameter(Mandatory = $true)]
        # The serial number of the host to be queried
        [String] $Sn,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    #$uri = -join ("/rest/vxm/v1/hosts/",$sn,"/idrac/network")
    $uri = "/rest/vxm/" + $Version.ToLower() + "/hosts/" + $sn + "/idrac/network"
    $url = "https://" + $Server + $uri

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth 4
        }
        return $ret
    }  catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.Synopsis
Updates the iDRAC network settings on the specified host.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Sn
The serial number of the host to be queried.

.Parameter IdracConfigBody
Json configuration file path

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to update the iDRAC network settings on the specified host.

.Example
PS> Update-iDRACNetwork -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn> -IdracConfigBody <json file path>
e.g
PS> Update-iDRACNetwork -Server <VxM IP or FQDN> -Username <username> -Password <password> -Sn <sn> -IdracConfigBody c:\update_idrac.json

You can refer to the content of the JSON file through the API "PATCH /v2/hosts/{sn}/idrac/network" at https://developer.dell.com/apis/5538/

Content example:
{
  "ipv4": {
    "ip_address": "192.168.101.30",
    "netmask": "255.255.255.0",
    "gateway": "192.168.101.1",
    "dhcp_enabled": false
  },
  "ipv6": {
    "ip_address": "2001:db8:1ab:16::102",
    "prefix_length": 64,
    "gateway": "2001:db8:1ab:16::1",
    "auto_config_enabled": false
  },
  "vlan": {
    "vlan_id": 0,
    "vlan_priority": 0
  }
}
#>
function Update-iDRACNetwork {
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

        # The serial number of the host to be queried
        [Parameter(Mandatory = $true)]
        [String] $Sn,

        # The API version, default is v1
        [Parameter(Mandatory = $false, HelpMessage="Supported parameter: 'v1','v2'")]
        [String] $Version = "v1",

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $IdracConfigBody,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    if(("v1","v2") -notcontains $Version.ToLower()) {
            write-host "The inputted Version $Version is invalid." -ForegroundColor Red
            return
    }

	$uri = "/rest/vxm/" + $Version.ToLower() + "/hosts/" + $sn + "/idrac/network"
    $url = "https://" + $Server + $uri

    $body = Get-Content $IdracConfigBody
    try{
        $ret = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $body
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
       HandleInvokeRestMethodException -URL $url
    }
}
