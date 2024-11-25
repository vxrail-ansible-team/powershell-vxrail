# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0, $currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"

. "$commonPath"

<#
.Synopsis
Get the vxm system info.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username.

.Parameter Version
Optional,API version.Only support v1,v2,v3 or v4, default value is v1.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to get the vxm system info.

.Example
C:\PS>Get-SystemInfo -Server <vxm ip or FQDN> -Username <username> -Password <password>

Get the vxm system info.
#>
function Get-SystemInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Server,

        [Parameter(Mandatory = $true)]
        [String] $Username,
        
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",
        
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/system"

    # check Version
    if(("v1","v2","v3","v4","v5") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try { 
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        write-host $_
    }
}



<#
.Synopsis
Validates the supplied user credentials.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username.

.Parameter VxmRootUsername
VxRail Manager root user name.

.Parameter VxmRootPassword
VxRail Manager root user password.

.Parameter VcAdminUsername
vCenter admin user name.

.Parameter VcAdminPassword
vCenter admin user password.

.Parameter VcsaRootUsername
VCSA root user name.

.Parameter VcsaRootPassword
VCSA root user password.

.Parameter PscRootUsername
PSC root user name.

.Parameter PscRootPassword
PSC root user password.

.Parameter HostsSn
The serial number of the host to be validate.

.Parameter HostsUsername
Host user name.

.Parameter HostsPassword
Host user password.

.Parameter WitnessUsername
Witness user name.

.Parameter WitnessPassword
Witness user password.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to validate the supplied user credentials.

.Example
C:\PS>Confirm-SystemCredential -Server <vxm ip or FQDN> -Username <username> -Password <password> -VxmRootUsername <vxm root user> -VxmRootPassword <vxm root password>

Validates the one supplied user credential.

.Example
C:\PS>Confirm-SystemCredential -Server <vxm ip or FQDN> -Username <username> -Password <password> -Format <Format> -VxmRootUsername <vxm root user> -VxmRootPassword <vxm root password> -VcAdminUsername <vc admin user> -VcAdminPassword <vc admin password> -VcsaRootUsername <vcsa root username> -VcsaRootPassword <vcsa root password> -PscRootUsername <psc root user> -PscRootPassword <psc root password> -HostsSn <HostsSn> -HostsUsername <HostsUsername> -HostsPassword <HostsPassword> -WitnessUsername <witness username>  -WitnessPassword <witness password> 

Validates the multiple supplied user credentials.
#>

function Confirm-SystemCredential {
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

        # vCenter admin user name
        [Parameter(Mandatory = $false)]
        [String] $VcAdminUsername,

        # vCenter admin user password
        [Parameter(Mandatory = $false)]
        [String] $VcAdminPassword,

        # VCSA root user name
        [Parameter(Mandatory = $false)]
        [String] $VcsaRootUsername,

        # VCSA root user password
        [Parameter(Mandatory = $false)]
        [String] $VcsaRootPassword,
        
        # PSC root user name
        [Parameter(Mandatory = $false)]
        [String] $PscRootUsername,

        # PSC root user password
        [Parameter(Mandatory = $false)]
        [String] $PscRootPassword,

        # The serial number of the host to be validate
        [Parameter(Mandatory = $false)]
        [String] $HostsSn, 

        # Host user name
        [Parameter(Mandatory = $false)]
        [String] $HostsUsername, 
           
        # Host user password
        [Parameter(Mandatory = $false)]
        [String] $HostsPassword,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/system/validate-credential"
    
    # Add non-mandatory information to body, $Body.count must get 1
    $Body = @{ }

    # if user entered vcenter admin user account, add it to body
    if ($VcAdminUsername -and $VcAdminPassword) {
        $VcAdminObj = @{
            "vc_admin_user" = @{
                "username" = $VcAdminUsername
                "password" = $VcAdminPassword
            }
        }
        $Body.add("vcenter", $VcAdminObj)
    }

    # if user entered vcsa root user account, add it to body
    if ($VcsaRootUsername -and $VcsaRootPassword) {
        $VcsaRootObj = @{
            "vcsa_root_user" = @{
                "username" = $VcsaRootUsername
                "password" = $VcsaRootPassword
            }
        }
        $Body.add("vcenter", $VcsaRootObj)
    }

    # if user entered psc root user account, add it to body
    if ($PscRootUsername -and $PscRootPassword) {
        $PscRootObj = @{
            "psc_root_user" = @{
                "username" = $PscRootUsername
                "password" = $PscRootPassword
            }
        }
        $Body.add("vcenter", $PscRootObj)
    }

    # if user entered ESXi host info, add it to body
    if ($HostsSn -and $HostsUsername -and $HostsPassword) {
        $HostsObj = @{
            "sn" = $HostsSn
            "root_user" = @{
                "username" = $HostsUsername
                "password" = $HostsPassword
            }
        }
        $Body.add("hosts", @($HostsObj))
    }

    if ($Body.Count -lt 1) {
        Write-Host "Credentials input for validation is required."
        Break
    }

    # Convert Body to JSON format
    $Body = $Body | ConvertTo-Json -Depth 3

    # Write-Host $Body

    try {
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        write-host $_
    }
}


<#
.Synopsis
Updates the vCenter and ESXi hosts management user passwords stored in VxRail Manager.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter ComponentName
Component Name.

.Parameter ComponentHostName
Host Name for Component.

.Parameter ComponentUsername
Component user name.

.Parameter ComponentPassword
Use corresponding password for component user.

.Parameter Version
Optional. API version. Only input v1 or v2. Default value is v1.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to update the vCenter and ESXi hosts management user passwords stored in VxRail Manager.

.Example
C:\PS>Update-SystemCredential -Server <vxm ip or FQDN> -Username <username> -Password <password> -ComponentName <component name> -ComponentHostName <component host name> -ComponentUsername <component user name> -ComponentPassword <component user password>

Updates the vCenter and ESXi hosts management user passwords stored in VxRail Manager. 

.Example
C:\PS>Update-SystemCredential -Server <vxm ip or FQDN> -Username <username> -Password <password> -ComponentName c1,c2 -ComponentHostName h1,h2 -ComponentUsername u1,u2 -ComponentPassword p1,p2

Updates the vCenter and ESXi hosts management user passwords stored in VxRail Manager. 
#>
function Update-SystemCredential {
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

        # Component Name
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentName = "",

        # Host Name for Component
        [Parameter(Mandatory = $false)]
        [String[]] $ComponentHostName = "",

        # Component user name
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentUsername = "",

        # Use corresponding password for component user
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentPassword = "",

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [switch] $Format
    )

    # check Version
    if(($Version -ne "v1") -and ($Version -ne "v2")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/system/update-credential"
    
    # Add mandatory information to body
    $Body = @()

    $n = ($ComponentName.Count, $ComponentHostName.Count,$ComponentUsername.Count,$ComponentPassword.Count) | Measure-Object -Minimum -Maximum

    for ($i = 0; $i -lt $n.Maximum; $i++) {
            $ComponentObj = @{
                "component" = $ComponentName[$i]
                "hostname"  = $ComponentHostName[$i]
                "username"  = $ComponentUsername[$i]
                "password"  = $ComponentPassword[$i]
            } 
            $Body += $ComponentObj
        }

    $Body = ConvertTo-Json @($Body)

    try {
        # $ret = Invoke-RestMethod -Method 'POST' -Uri $url -Headers $headers -Body $Body -ContentType "application/json" -TimeoutSec 300
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        write-host $_
    }
}


<#
.Synopsis
Updates the vCenter and ESXi hosts management user passwords stored in VxRail Manager for V3 API.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username with Administrator or HCIA role.

.Parameter Password
Corresponding password for the vCenter username.

.Parameter ComponentName
Name of the component.

.Parameter ComponentHostName
Hostname for the component.

.Parameter ComponentUsername
Username for the component.

.Parameter ComponentCurrentPassword
Current password for the component user.

.Parameter ComponentNewPassword
New password for the component user.

.Parameter Format
Prints output in JSON format.

.Notes
This cmdlet can be used to update the vCenter and ESXi hosts management user passwords stored in VxRail Manager using the V3 API.

.Example
C:\PS>Update-SystemCredentialV3 -Server <vxm ip or FQDN> -Username <username> -Password <password> -ComponentName <component name> -ComponentHostName <component host name> -ComponentUsername <component user name> -ComponentCurrentPassword <current component user password> -ComponentNewPassword <new component user password>

This updates the vCenter and ESXi hosts management user passwords stored in VxRail Manager using the V3 API.
#>
function Update-SystemCredentialV3 {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username with Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Corresponding password for the username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Component name
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentName,

        # Hostname for the component
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentHostName,

        # Component username
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentUsername,

        # Current password for the component user
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentCurrentPassword,

        # New password for the component user
        [Parameter(Mandatory = $true)]
        [String[]] $ComponentNewPassword,

        # Print in JSON format
        [Parameter(Mandatory = $false)]
        [switch] $Format
    )

    $uri = "/rest/vxm/v3/system/credential"

    $Body = @()

    $n = ($ComponentName.Count, $ComponentHostName.Count, $ComponentUsername.Count, $ComponentCurrentPassword.Count, $ComponentNewPassword.Count) | Measure-Object -Minimum -Maximum

    for ($i = 0; $i -lt $n.Maximum; $i++) {
        $ComponentObj = @{
            "component"         = $ComponentName[$i]
            "hostname"          = $ComponentHostName[$i]
            "username"          = $ComponentUsername[$i]
            "current_password"  = $ComponentCurrentPassword[$i]
            "new_password"      = $ComponentNewPassword[$i]
        } 
        $Body += $ComponentObj
    }

    $Body = ConvertTo-Json @($Body)

    try {
        $ret = doPut -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        write-host $_
    }
}


<#
.Synopsis
Retrieves information about cluster portgroups used by a node.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 
.Parameter Password
Use corresponding password for username. 
.Parameter Format
Print JSON style format.
.Parameter Node_FQDN
FQDN of the VxRail node.
.Example
C:\PS>Get-ClusterPortgroupsByNodeFQDN -Server <vxm ip or FQDN> -Username <username> -Password <password> -Node_FQDN <node's FQDN>
Retrieves information about cluster portgroups used by a node.
#>
function Get-ClusterPortgroupsByNodeFQDN {
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
        # Use corresponding password for username
        [String] $Node_FQDN,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/system/cluster-portgroups"
    if ($Node_FQDN) {$uri += "?node_fqdn=" + $Node_FQDN}
    $url = "https://" + $Server + $uri

    try { 
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.Synopsis
Retrieves information about the DNS servers for the cluster.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 
.Parameter Password
Use corresponding password for username. 
.Parameter Version
Optional,API version.Only support v1 or v2, default value is v1.
.Parameter Format
Print JSON style format.
.Example
C:\PS>Get-SystemDns -Server <vxm ip or FQDN> -Username <username> -Password <password>
Retrieves information about the DNS servers for the cluster.
#>
function Get-SystemDns {
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
        # The API version, default is v1
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/system/dns"
    $url = "https://" + $Server + $uri

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try { 
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.SYNOPSIS
Sets the DNS servers for the cluster.
.PARAMETER Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 
.Parameter Password
Use corresponding password for username. 
.PARAMETER Conf
Required. Json configuration file as the body of API
.Parameter Version
Optional,API version.Only support v1 or v2, default value is v1.
.Parameter Format
Print JSON style format.
.EXAMPLE  
PS> Set-SystemDns -Server <VxM IP> -Username <username> -Password <password> -Conf <Json file to the path>
Sets the DNS servers for the cluster.
#>
function Set-SystemDns {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $Conf,

        [Parameter(Mandatory = $false)]
        # The API version, default is v1
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/system/dns"
    $url = "https://" + $Server + $uri
    $body = Get-Content $Conf

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try {
        $response = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Retrieves information about the NTP servers for the cluster.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 
.Parameter Password
Use corresponding password for username. 
.Parameter Format
Print JSON style format.
.Example
C:\PS>Get-SystemNtp -Server <vxm ip or FQDN> -Username <username> -Password <password>
Retrieves information about the DNS servers for the cluster.
#>
function Get-SystemNtp {
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
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/system/ntp"
    $url = "https://" + $Server + $uri

    try { 
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.SYNOPSIS
Sets the NTP servers for the cluster.
.PARAMETER Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 
.Parameter Password
Use corresponding password for username. 
.PARAMETER Conf
Required. Json configuration file as the body of API
.Parameter Format
Print JSON style format.
.EXAMPLE  
PS> Set-SystemNtp -Server <VxM IP> -Username <username> -Password <password> -Conf <Json file to the path>
Sets the NTP servers for the cluster.
#>
function Set-SystemNtp {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $Conf,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/system/ntp"
    $url = "https://" + $Server + $uri
    $body = Get-Content $Conf

    try {
        $response = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

<#
.SYNOPSIS
Provision the primary storage for the dynamic node cluster.
.PARAMETER Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.PARAMETER PrimaryStorageName
Required. Primary datastore name.
.PARAMETER PrimaryStorageType
Optional. Primary datastore type, supported values are VSAN_HCI_MESH and EXTERNAL.
.PARAMETER StoragePolicyProfileName
Optional. Storage policy to be applied on VxM.
.EXAMPLE
PS> Invoke-StorageProvision -Server <VxM IP> -Username <username> -Password <password> -PrimaryStorageName <primary storage name> -PrimaryStorageType <primary storage name>
#>
function Invoke-StorageProvision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        # VxManager ip address or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # User name in vCenter
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Password in vCenter
        [String] $Password,

        [Parameter(Mandatory = $true)]
        # Primary datastore name
        [String] $PrimaryStorageName,

        [Parameter(Mandatory = $false)]
        # Primary datastore type
        [String] $PrimaryStorageType,

        [Parameter(Mandatory = $false)]
        # Storage policy profile name
        [String] $StoragePolicyProfileName,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $requestBody = @{
            "primary_storage_name" = $PrimaryStorageName
        }
    if($PrimaryStorageType){
        $requestBody.add("primary_storage_type",$PrimaryStorageType)
    }

    if($StoragePolicyProfileName){
        $requestBody.add("storage_policy_profile_name",$StoragePolicyProfileName)
    }

    $requestBody = $requestBody | ConvertTo-Json

    $uri = '/rest/vxm/v1/system/primary-storage'
    $url = "https://" + $Server + $uri

    try{
        $response = callAPI -Username $Username -Password $Password -Server $Server -Api $uri -Method 'POST' -ContentType "application/json" -Body $requestBody -TimeoutSec 600
        if($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

