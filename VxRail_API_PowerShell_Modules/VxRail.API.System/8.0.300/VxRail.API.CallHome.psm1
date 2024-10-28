# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0, $PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0, $currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"

. "$commonPath"
#. ".\VxRail.API.System.format.ps1xml"


<#
.Synopsis
Retrieves information about the call home servers.

.Parameter Server
VxM IP or FQDN.

.Description
Deprecated since 7.0.350 release for v1 version.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Version
Optional. API version. Only input v1 or v2. v1 is deprecated from 7.0.350. Default value is v1.

.NOTES
You can run this cmdlet to retrieve information about the call home servers.

.Example
C:\PS>Get-CallHomeInfo -Server <vxm ip or FQDN> -Username <username> -Password <password>

Retrieves information about the callhome servers.
#>
function Get-CallHomeInfo {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1"
    )

    # version check
    if (($Version -ne "v1") -and ($Version -ne "v2")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/callhome/info"

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
Deploys an internal call home server.

.Description
Deprecated since 7.0.350 release.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter IP
Callhome IP. Support in v1.

.Parameter Address
IP address for the SRS server

.Parameter SiteID
Site ID of the SRS server

.Parameter FirstName
First name of the support administrator

.Parameter LastName
Last name of the support administrator

.Parameter Email
Email address of the support account

.Parameter Phone
Phone number of the support administrator

.Parameter Company
Company name

.Parameter RootPassword
Root password for accessing the SRS server

.Parameter AdminPassword
Administrator password for accessing the SRS server

.Parameter Format
Print JSON style format.

.Parameter Version
Optional. API version. Only input v1 or v2. Default value is v1.

.NOTES
You can run this cmdlet to deploy an internal callhome server.

.Example
C:\PS>Publish-CallHomeServer -Server <vxm ip or FQDN> -Username <username> -Password <password> -IP <callhome ip> -SiteID <callhome site ID> -FirstName <callhome first name> -LastName <callhome last name> -Email <callhome email> -Phone <callhome phone> -Company <callhome company> -RootPassword <root user password> -AdminPassword <admin user password>

Deploys an internal callhome server.
#>
function Publish-CallHomeServer {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Callhome IP
        [Parameter(Mandatory = $false)]
        [String] $IP,

        # Callhome Address
        [Parameter(Mandatory = $false)]
        [String] $Address,

        # Callhome site ID
        [Parameter(Mandatory = $true)]
        [String] $SiteID,

        # Callhome first name
        [Parameter(Mandatory = $true)]
        [String] $FirstName,

        # Callhome last name
        [Parameter(Mandatory = $true)]
        [String] $LastName,

        # Callhome email
        [Parameter(Mandatory = $true)]
        [String] $Email,

        # Callhome phone
        [Parameter(Mandatory = $true)]
        [String] $Phone,

        # Callhome company
        [Parameter(Mandatory = $true)]
        [String] $Company,

        # Use corresponding password for root user
        [Parameter(Mandatory = $true)]
        [String] $RootPassword,

        # Use corresponding password for admin user
        [Parameter(Mandatory = $true)]
        [String] $AdminPassword,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1"
    )

    # version check
    if (($Version -ne "v1") -and ($Version -ne "v2")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    # argurment check
    if ($Version.ToLower() -eq "v1") {
        if ([string]::IsNullOrWhiteSpace($IP)) {
            write-host "The inputted IP is empty." -ForegroundColor Red
            return
        }
    } elseif ($Version.ToLower() -eq "v2") {
        if ([string]::IsNullOrWhiteSpace($Address)) {
            write-host "The inputted Address is empty." -ForegroundColor Red
            return
        }
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/callhome/deployment"

    $Body = ""
    if ($Version -eq "v1") {
        $Body = @{
            "ip"         = $IP
            "site_id"    = $SiteID
            "first_name" = $FirstName
            "last_name"  = $LastName
            "email"      = $Email
            "phone"      = $Phone
            "company"    = $Company
            "root_pwd"   = $RootPassword
            "admin_pwd"  = $AdminPassword
        } | ConvertTo-Json
    } elseif ($Version -eq "v2") {
        $Body = @{
            "address"    = $Address
            "site_id"    = $SiteID
            "first_name" = $FirstName
            "last_name"  = $LastName
            "email"      = $Email
            "phone"      = $Phone
            "company"    = $Company
            "root_pwd"   = $RootPassword
            "admin_pwd"  = $AdminPassword
        } | ConvertTo-Json
    }

    try {
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
Activates and registers an internal call home server.

.Description
Deprecated since 7.0.350 release.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter AccessCode
Access code to activate an internal call home server

.Parameter Format
Print JSON style format.

.NOTES
You can run this cmdlet to activate and register an internal call home server.

.Example
C:\PS>Register-InternalCallHomeServer -Server <vxm ip or FQDN> -Username <username> -Password <password> -AccessCode <access code>

Activates and registers an internal callhome server.
#>
function Register-InternalCallHomeServer {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Access code for activating an internal callhome server
        [Parameter(Mandatory = $true)]
        [String] $AccessCode,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/callhome/internal/register"

    $Body = @{
        "access_code" = $AccessCode
    } | ConvertTo-Json

    try {
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
Registers external call home servers.

.Description
Deprecated since 7.0.350 release.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter SiteID
Site ID of the SRS server

.Parameter IPList
Callhome IP list. Support in v1

.Parameter AddressList
Array of the IP address for each of the external SRS servers

.Parameter SupportUsername
Username for the support account. If the support account is not logged in, this parameter is required.

.Parameter SupportPassword
Password for the support account. If the support account is not logged in, this parameter is required.

.Parameter Format
Print JSON style format.

.Parameter Version
Optional. API version. Only input v1 or v2. Default value is v1.

.NOTES
You can run this cmdlet to register external call home servers.

.Example
C:\PS>Register-ExternalCallHomeServer -Server <vxm ip or FQDN> -Username <username> -Password <password> -SiteID <callhome site ID> -IPList <callhome IP list>

Registers the external callhome server(s) when support account log in.

.Example
C:\PS>Register-ExternalCallHomeServer -Server <vxm ip or FQDN> -Username <username> -Password <password> -SiteID <callhome site ID> -IPList <callhome IP list> -SupportUsername <support username> -SupportPassword <support password>

Registers the external callhome server(s) when support account not log in.
#>
function Register-ExternalCallHomeServer {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Callhome site ID
        [Parameter(Mandatory = $true)]
        [String] $SiteID,

        # Callhome IP list
        [Parameter(Mandatory = $true)]
        [String[]] $IPList,

        # Callhome Address list
        [Parameter(Mandatory = $false)]
        [String[]] $AddressList,

        # Callhome support username
        [Parameter(Mandatory = $false)]
        [String] $SupportUsername,

        # Callhome support password
        [Parameter(Mandatory = $false)]
        [String] $SupportPassword,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1"
    )

    # version check
    if (($Version -ne "v1") -and ($Version -ne "v2")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    # argurment check
    if ($Version.ToLower() -eq "v1") {
        if ([string]::IsNullOrWhiteSpace($IPList)) {
            write-host "The inputted IP List is empty." -ForegroundColor Red
            return
        }
    } elseif ($Version.ToLower() -eq "v2") {
        if ([string]::IsNullOrWhiteSpace($AddressList)) {
            write-host "The inputted Address List is empty." -ForegroundColor Red
            return
        }
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/callhome/external/register"

    $Body = ""
    
    if ($Version.ToLower() -eq "v1") {
        $Body = @{
        "site_id"          = $SiteID 
        "ip_list"          = $IPList
        "support_username" = $SupportUsername
        "support_pwd"      = $SupportPassword
        } | ConvertTo-Json
    } elseif ($Version.ToLower() -eq "v2") {
        $Body = @{
        "site_id"          = $SiteID 
        "address_list"     = $AddressList
        "support_username" = $SupportUsername
        "support_pwd"      = $SupportPassword
        } | ConvertTo-Json
    }
    
    Write-Host $Body
    
    try {
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
Generates an access code to activate the internal call home server. Note that the access code is emailed to the address specified for your support account.

.Description
.Deprecated since 7.0.350 release.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.NOTES
You can run this cmdlet to generate an access code to activate the internal call home server. Note that the access code is emailed to the address specified for your support account.

.Example
C:\PS>New-CallhomeAccessCode -Server <vxm ip or FQDN> -Username <username> -Password <password>

Generates an access code to activate the internal callhome server.
#>
function New-CallhomeAccessCode {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/callhome/access-code"

    try {
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password
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
Unregisters call home servers and deletes the SRS VE virtual machine if it exists.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.NOTES
You can run this cmdlet to unregister call home servers and delete the SRS VE virtual machine if it exists.

.Example
C:\PS>Unregister-CallhomeServer -Server <vxm ip or FQDN> -Username <username> -Password <password>

Unregisters the callhome server(s), and deletes the SRS VE virtual machine if it exists.
#>
function Unregister-CallhomeServer {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/callhome/disable"

    try {
        $ret = doDelete -Server $Server -Api $uri -Username $Username -Password $Password
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
Upgrades the internal SRS software.

.Description
Deprecated since 7.0.350 release

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter EsrsRootPassword
Root password for accessing the internal SRS server

.Parameter EsrsAdminPassword
Administrator password for accessing the internal SRS server

.Parameter Format
Print JSON style format.

.NOTES
You can run this cmdlet to upgrade the internal SRS instance.

.Example
C:\PS>Start-InternalSRSUpgrade -Server <VxM> -Username <account> -Password <password> -SrsRootPwd <srsRootPwd> -SrsAdminPwd <srsAdminPwd>

Upgrades the internal SRS instance.
#>
function Start-InternalSRSUpgrade {
    param(
        # VxM IP or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # Use corresponding password for username
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # password for SRS root username
        [Parameter(Mandatory = $true)]
        [String] $SrsRootPwd,

        # password for SRS admin username
        [Parameter(Mandatory = $true)]
        [String] $SrsAdminPwd,

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/callhome/internal/upgrade"

    # Body content: ESRS root and admin password
    $Body = @{
        "root_pwd"  = $SrsRootPwd
        "admin_pwd" = $SrsAdminPwd
    } | ConvertTo-Json

    try {
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
Enable Call home functinality

.Parameter Version
Optional. API version. Only input v1 or v2. Default value is v1.

.Description
Enable call home functionality by enabling remote connectivity service

.Parameter Server
VxRail Manager IP address or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter SerialNumber
Serial Number for the cluster

.Parameter ProxyType
Proxy type of remote connector. Example: USER or SYSTEM OR NA

.Parameter ProxyAddress
server/hostname of the proxy address.

.Parameter ProxyPort
Port of the proxy.

.Parameter ProxyUserName
Username of the proxy credential.

.Parameter ProxyUserPassword
Password of the proxy credential.

.Parameter CustomerContactInfo
Customer contact information. Example: @(@{contact_order=1;first_name= "Rob";last_name="Gordon";phone_number="XXXXX;email_address="rob@XXX.com";pref_language: "En"},@{contact_order=2;first_name= "Rob";last_name="Gordon";phone_number="XXXXX;email_address="rob@XXX.com";;pref_language: "En"})

.Parameter ConnectionType
Connection type of remote connector. Example: DIRECT or GATEWAY

.Parameter AccessKey
Access code to activate an internal call home server

.Parameter Pin
Pin code of remote connector

.Parameter Gateways
Gateways used in remote connector. Example:  @(@{host="xx.xx.xx.xx";port=9443},@{host="xx.xx.xx.xx";port=9443})

.Parameter IPVersion
Support since Version v2. IP version of remote connector. e.g. IPV4, IPV6. Version v1 is IPV4. 

.NOTES
You can run this cmdlet to enable the callhome.

.Example
C:\PS>Enable-CallHome -Server <vxm ip or FQDN> -Username <username> -Password <password> -SerialNumber <serial number> -UniversalKey $False -Pin <Pin number> -AccessKey <AccessKey> -ProxyType user -ProxyProtocol HTTP -ProxyHost <Proxy IP or FQDN> -ProxyUser <proxy user> -ProxyPassword <proxy password> -CustomerContactInfos @(@{contact_order=1;first_name="Rob";last_name="Gordon";phone_number="+1 (312) 555-7746";email_address="rob@championshipvinyl.biz"; pref_language="en-US"})

.Example
C:\PS>Enable-CallHome -Server <vxm ip or FQDN> -Username <username> -Password <password> -SerialNumber <serial number> -UniversalKey $True -CustomerContactInfos @(@{contact_order=1;first_name="Rob";last_name="Gordon";phone_number="+1 (312) 555-7746";email_address="rob@championshipvinyl.biz"; pref_language="en-US"}) -GateWays  @(@{host="xx.xx.xx.xx";port=9443},@{host="xx.xx.xx.xx";port=9443})

.Example
C:\PS>Enable-CallHome -Server <vxm ip or FQDN> -Username <username> -Password <password> -SerialNumber <serial number> -UniversalKey $True -CustomerContactInfos @(@{contact_order=1;first_name="Rob";last_name="Gordon";phone_number="+1 (312) 555-7746";email_address="rob@championshipvinyl.biz"; pref_language="en-US"})

.Example
C:\PS>Enable-CallHome -Version v2 -Server <vxm ip or FQDN> -Username <username> -Password <password> -SerialNumber <serial number> -UniversalKey $False -Pin <Pin number> -AccessKey <AccessKey> -ProxyType user -ProxyProtocol HTTP -ProxyHost <Proxy IP or FQDN> -ProxyUser <proxy user> -ProxyPassword <proxy password> -CustomerContactInfos @(@{contact_order=1;first_name="Rob";last_name="Gordon";phone_number="+1 (312) 555-7746";email_address="rob@championshipvinyl.biz"; pref_language="en-US"}) -IPVersion IPV6


#>
function Enable-CallHome {
    param(

         # API version. Default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        # VxManager ip address or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,
        
        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,
        
        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # SerialNumber for the cluster
        [Parameter(Mandatory = $true)]
        [String] $SerialNumber,

         # UniversalKey for the cluster
        [Parameter(Mandatory = $true)]
        [Bool] $UniversalKey,

         # Access key for the cluster
        [Parameter(Mandatory = $false)]
        [String] $AccessKey,

        # Proxy Type
       [Parameter(Mandatory = $false)]
       [ValidateSet('USER','SYSTEM','NA')]
       [string] $ProxyType,

       # Proxy Server IP Address
       [Parameter(Mandatory = $false)]
       [string] $ProxyAddress,

       # Proxy Server Port
       [Parameter(Mandatory = $false)]
       [int] $ProxyPort,

       # Proxy Server Protocol only HTTP and SOCKS are supported
       [Parameter(Mandatory =$false)]
       [ValidateSet('HTTP','SOCKS')]
       [string] $ProxyProtocol,

       # Proxy Server Credentials proxy server user name
       [Parameter(Mandatory = $false)]
       [string] $ProxyUserName,

       # Proxy Server Credentials proxy server user password
       [Parameter(Mandatory = $false)]
       [string] $ProxyUserPassword,

        # CustomerContactInfo of the customer,[{""},{""}]
        [Parameter(Mandatory = $true)]
        [System.Object[]] $CustomerContactInfos,
     
        # ConnectionType of the customer
        [Parameter(Mandatory = $true)]
        [ValidateSet('DIRECT','GATEWAY')]
        [String] $ConnectionType,

        # Pin of the access key
        [Parameter(Mandatory = $false)]
        [String] $Pin,

        # Gateways of the remote connector
        [Parameter(Mandatory = $false)]
        [System.Object[]]  $Gateways,
        
        # IP version of the remote connector
        [Parameter(Mandatory = $false)]
        [ValidateSet('IPV4','IPV6')]
        [String]  $IPVersion = "IPV4",

        # Print JSON style format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )
 
    # check Version
    # $pattern = "^v{1}[1|2]{1}$"
    if(("v1","v2") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }
    $uri = "/rest/vxm/" + $Version.ToLower() + "/callhome/enable"

    # Add mandatory information to body   
    $Body = @{
       "serial_number" = $SerialNumber
       "customer_contact_infos" = $CustomerContactInfos
        "connection_type" = $ConnectionType.ToUpper()
        } 
    if (!$UniversalKey){
        $Body["pin"]=$Pin
        $Body["access_key"]=$AccessKey
    }
    if($Version.ToLower() -eq "v2") {
        $Body["ip_version"]=$IPVersion.ToLower()
    }                         
    #If ues the proxy, add proxy information
    if($ProxyType) {
         $body["proxy_type"]=$ProxyType.ToUpper()
         $ProxyBody = @{
         "address" = $ProxyAddress
         "protocol" = $ProxyProtocol
         "port" = $ProxyPort
         }
         if($ProxyUserName){
         $ProxyBody["user"] = $ProxyUsername
         }
         if ($ProxyPassword){
         $ProxyBody["password"] = $ProxyUserPassword
         }
         $body["proxy"] = $ProxyBody
         }

      
    #If you use the Gateways, add gateway information
    if ($GateWays){
      $body["gateways"]=$GateWays
      }

    # Convert Body to Json format
    $Body = $Body | ConvertTo-Json 
  
          
    $url = "https://" + $Server + $uri

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



