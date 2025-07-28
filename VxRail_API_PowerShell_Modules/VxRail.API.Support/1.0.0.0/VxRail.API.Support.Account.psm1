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
Retrieves the current support account set in VxRail.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Username for the support account 

.Parameter Password
Password for the support account 

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to retrieve the current support account set in VxRail.

.Example
C:\PS>Get-SupportAccount -Server <vxm ip or FQDN> -Username <username> -Password <password>

Get support account information.
#>
function Get-SupportAccount {
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

    $uri = "/rest/vxm/v1/support/account"
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
Adds a support account to VxRail Manager.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.

.Parameter SupportAccountName
Username for the support account

.Parameter SupportAccountPassword
Password for the support account

.Notes
You can run this cmdlet to add a support account to VxRail Manager.

.Example
C:\PS>Add-SupportAccount -Server <vxm ip or FQDN> -Username <username> -Password <password> -SupportAccountName <support account name> -SupportAccountPassword <support account password>

Add support account settings.
#>
function Add-SupportAccount {
    param (
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
        [Switch] $Format,

        # a new support account User Name
        [Parameter(Mandatory = $true)]
        [string] $SupportAccountName,

        # Password for the new support account
        [Parameter(Mandatory = $true)]
        [String] $SupportAccountPassword
    )
    
    $uri = "/rest/vxm/v1/support/account"
    
    # Body content: Support Account user name and password to post
    $Body = @{
        "username" = $SupportAccountName
        "password" = $SupportAccountPassword
    } | ConvertTo-Json

    try{ 
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
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
Updates the support account in VxRail Manager.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.

.Parameter SupportAccountName
Username for the support account

.Parameter SupportAccountPassword
Password for the support account

.Notes
You can run this cmdlet to update the support account in VxRail Manager.

.Example
C:\PS>Update-SupportAccount -Server <vxm ip or FQDN> -Username <username> -Password <password> -SupportAccountName <support account name> -SupportAccountPassword <support account password>

Update support account settings.
#>
function Update-SupportAccount {
    param (
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
        [Switch] $Format,

        # a new support account User Name
        [Parameter(Mandatory = $true)]
        [string]
        $SupportAccountName,

        # a new support account Password
        [Parameter(Mandatory = $true)]
        [String]
        $SupportAccountPassword
    )
    
    $uri = "/rest/vxm/v1/support/account"
    
    # Body content: Support Account user name and password to put
    $Body = @{
        "username" = $SupportAccountName
        "password" = $SupportAccountPassword
    } | ConvertTo-Json

    try{ 
        $ret = doPut -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
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
Removes a support account in VxRail Manager.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to remove a support account in VxRail Manager.

.Example
C:\PS>Remove-SupportAccount -Server <vxm ip or FQDN> -Username <username> -Password <password>

Remove support account settings.
#>
function Remove-SupportAccount {
    param (
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
    
    $uri = "/rest/vxm/v1/support/account"

    try{ 
        $ret = doDelete -Server $Server -Api $uri -Username $Username -Password $Password 
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}
