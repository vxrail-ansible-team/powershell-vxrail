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

<#
.Synopsis
Create the VC management account

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Component
Component type only "VC"

.Parameter NewUsername
New username to be created

.Parameter NewPassword
The password required to create the management account

.Parameter VcAdminUserName
Username of VC Administrator

.Parameter VcAdminPassword
Password of VC Administrator

.DESCRIPTION
Synchronous API to get VC management account and ESXi host management accounts.

.Example
C:\PS>Add-SystemAccountManagement -Server <vxm ip or FQDN> -Username <username> -Password <password> -Component VC -NewUsername <new_username> \
-NewPassword <new_password> -VcAdminUserName <vc_admin_user> -VcAdminPassword <vc_admin_password>

Create the VC management account.
#>
function Add-SystemAccountManagement {
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

        [Parameter(Mandatory = $true)]
        [String] $Component,

        [Parameter(Mandatory = $true)]
        [String] $NewUsername,

        [Parameter(Mandatory = $true)]
        [String] $NewPassword,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminUserName,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminPassword
    )

    $Body = @{
        "component" = $Component
        "new_username" = $NewUsername
        "new_password" =  $NewPassword
        "vc_admin_user" = @{
            "username" = $VcAdminUserName
            "password" = $VcAdminPassword
        }
    } | ConvertTo-Json

    $uri = "/rest/vxm/v1/system/accounts/management"

    try{ 
         $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
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
Delete the VC management account

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Component
Component type only "VC"

.Parameter VcManagementUsername
The username to be deleted

.Parameter VcAdminUserName
Username of VC Administrator

.Parameter VcAdminPassword
Password of VC Administrator

.DESCRIPTION
Synchronous API to get VC management account and ESXi host management accounts.

.Example
C:\PS>Remove-SystemAccountManagement -Server <vxm ip or FQDN> -Username <username> -Password <password> -Component VC -VcManagementUsername <vc_managemen_username> \
-VcAdminUserName <vc_admin_user> -VcAdminPassword <vc_admin_password>

Delete the VC management account.
#>
function Remove-SystemAccountManagement {
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

        [Parameter(Mandatory = $true)]
        [String] $Component,

        [Parameter(Mandatory = $true)]
        [String] $VcManagementUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminUserName,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminPassword
    )

    $Body = @{
        "component" = $Component
        "username" = $VcManagementUsername
        "vc_admin_user" = @{
            "username" = $VcAdminUserName
            "password" = $VcAdminPassword
        }
    } | ConvertTo-Json

    $uri = "/rest/vxm/v1/system/accounts/management"

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