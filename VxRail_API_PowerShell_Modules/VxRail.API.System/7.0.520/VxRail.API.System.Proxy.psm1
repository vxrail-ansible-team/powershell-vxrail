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
Get proxy settings.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes 
You can run this cmdlet to get proxy settings.

.Example
C:\PS>Get-SystemProxy -Server <vxm ip or FQDN> -Username <username> -Password <password>

Retrieves the VxRail Manager system proxy settings.
#>
function Get-SystemProxy {
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
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/system/proxy"
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
Enable proxy settings.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter EsrsPassword
Password of the esrs. When there is internal esrs enabled, password will be required since proxy will be set in esrs side together.

.Parameter ProxyServer
server/hostname of the proxy address.

.Parameter ProxyPort
Port of the proxy.

.Parameter ProxyType
Type of the proxy. HTTP/SOCKS.

.Parameter ProxyUserName
Username of the proxy credential.

.Parameter ProxyUserPassword
Password of the proxy credential.

.Notes
You can run this cmdlet to enable proxy settings.

.Example
C:\PS>Add-SystemProxy -Server <vxm ip or FQDN> -Username <username> -Password <password> -ProxyServer <proxy server ip> -ProxyPort <proxy port> -ProxyType <proxy type> -ProxyUsername <proxy username> -ProxyUserPassword <proxy password>

Enable proxy and set a proxy server with corresponding username and password. If '-ProxyType' is 'SOCKS',  parameter '-SocksVersion' must be supplied.

#>
function Add-SystemProxy {
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

       # The optional ESRS passwords
       [Parameter(Mandatory = $false)]
       [String] $EsrsPassword,

       # Proxy Server IP Address
       [Parameter(Mandatory = $true)]
       [string] $ProxyServer,

       # Proxy Server Port
       [Parameter(Mandatory = $true)]
       [int] $ProxyPort,

       # Proxy Server Protocol only HTTP and SOCKS are supported
       [Parameter(Mandatory = $true, HelpMessage = 'When SOCKS is selected, parameter SocksVersion must be supplied')]
       [ValidateSet('HTTP','SOCKS')]
       [string] $ProxyType,

       # Proxy Server Credentials proxy server user name
       [Parameter(Mandatory = $false)]
       [string] $ProxyUserName,

       # Proxy Server Credentials proxy server user password
       [Parameter(Mandatory = $false)]
       [string] $ProxyUserPassword
   )

   DynamicParam {
       $version = @{
           SOCKS = '4', '5'
       }

       if ($ProxyType -eq "SOCKS") {
           # Define dynamic parameter named as socksVerion only when SOCKS is selected
           $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
           $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]

           # Define the parameter attribute
           $attribute = New-Object System.Management.Automation.ParameterAttribute
           $attribute.Mandatory = $true
           $attributeCollection.Add($attribute)

           # Create the appropriate ValidateSet attribute, listing the legal values for
           # this dynamic parameter
           $attribute = New-Object System.Management.Automation.ValidateSetAttribute($version.$ProxyType)
           $attributeCollection.Add($attribute)

           # compose the dynamic -SocksVersion parameter
           $Name = 'SocksVersion'
           $dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($Name, [int], $attributeCollection)
           $paramDictionary.Add($Name, $dynParam)

           # return the collection of dynamic parameters
           $paramDictionary
       }
    }

    Begin {
        $SocksVersion = $PSBoundParameters.SocksVersion
    }

    process {
        $uri = '/rest/vxm/v1/system/proxy'

        $Body = @{
            "proxy_spec" = @{
	            "server" = $ProxyServer
	            "port" = $ProxyPort
	            "type" = $ProxyType.ToUpper() # vxManager don't accept lowercase 'http'/'socks'
            }
        } 
        
        if($EsrsPwd) {
        $Body["esrs_pwd"] = $EsrsPwd
        }
        if($ProxyUsername){
            $Body.proxy_spec["username"] = $ProxyUsername
        }
        if($ProxyUserPassword){
            $Body.proxy_spec["pwd"] = $ProxyUserPassword
        }
        if($SocksVersion){
            $Body.proxy_spec["socks_version"] = $SocksVersion
        }
        $body = $body | ConvertTo-Json

        try{
            $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
            return $ret
        } catch {
            write-host $_
        }
    }
}


<#
.Synopsis
Disable proxy settings.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter EsrsPassword
Password of the esrs. When there is internal esrs enabled, password will be required since proxy will be set in esrs side together.

.Notes
You can run this cmdlet to disable proxy settings.

.Example
C:\PS>Remove-SystemProxy -Server <vxm ip or FQDN> -Username <username> -Password <password>

Disable proxy and remove proxy settings.
#>
function Remove-SystemProxy {
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

        # Password of the esrs
        [Parameter(Mandatory = $false)]
        [String] $EsrsPwd
    )

    if($EsrsPwd) {
        $Body = @{
            "esrs_pwd" = $EsrsPwd
        } | ConvertTo-Json
    } 

    $uri = "/rest/vxm/v1/system/proxy"
    try{ 
        if($EsrsPwd) {
            $ret = doDelete -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
        } 
        else {
            $ret = doDelete -Server $Server -Api $uri -Username $Username -Password $Password
        }
        if($Format)  {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }  
}


<#
.Synopsis
Update proxy settings.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter EsrsPassword
Password of the esrs. When there is internal esrs enabled, password will be required since proxy will be set in esrs side together.

.Parameter ProxyServer
server/hostname of the proxy address.

.Parameter ProxyPort
Port of the proxy.

.Parameter ProxyType
Type of the proxy. HTTP/SOCKS.

.Parameter ProxyUserName
Username of the proxy credential.

.Parameter ProxyUserPassword
Password of the proxy credential.

.Notes
You can run this cmdlet to update proxy settings.

.Example
C:\PS>Update-SystemProxy -Server <vxm ip or FQDN> -Username <username> -Password <password> -ProxyServer <proxy server ip> -ProxyPort <proxy port> -ProxyType <proxy type> -SocksVersion <socks version> -ProxyUsername <proxy username> -ProxyUserPassword <proxy password>                                                                         

Update proxy settings. If '-ProxyType' is 'SOCKS',  parameter '-SocksVersion' must be supplied.
#>
function Update-SystemProxy {
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

       # The optional ESRS passwords
       [Parameter(Mandatory = $false)]
       [String] $EsrsPassword,

       # Proxy Server IP Address
       [Parameter(Mandatory = $true)]
       [string] $ProxyServer,

       # Proxy Server Port
       [Parameter(Mandatory = $true)]
       [int] $ProxyPort,

       # Proxy Server Protocol only HTTP and SOCKS are supported
       [Parameter(Mandatory = $true)]
       [ValidateSet('HTTP','SOCKS')]
       [string] $ProxyType,

       # Proxy Server Credentials proxy server user name
       [Parameter(Mandatory = $false)]
       [string] $ProxyUserName,

       # Proxy Server Credentials proxy server user password
       [Parameter(Mandatory = $false)]
       [string] $ProxyUserPassword
   )

   DynamicParam {
       $version = @{
           SOCKS = '4', '5'
       }

       if ($ProxyType -eq "SOCKS") {
           # Define dynamic parameter named as socksVerion only when SOCKS is selected
           $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
           $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]

           # Define the parameter attribute
           $attribute = New-Object System.Management.Automation.ParameterAttribute
           $attribute.Mandatory = $false
           $attributeCollection.Add($attribute)

           # Create the appropriate ValidateSet attribute, listing the legal values for
           # this dynamic parameter
           $attribute = New-Object System.Management.Automation.ValidateSetAttribute($version.$ProxyType)
           $attributeCollection.Add($attribute)

           # compose the dynamic -SocksVersion parameter
           $Name = 'SocksVersion'
           $dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($Name, [int], $attributeCollection)
           $paramDictionary.Add($Name, $dynParam)

           # return the collection of dynamic parameters
           $paramDictionary
       }
    }

    Begin {
        $SocksVersion = $PSBoundParameters.SocksVersion
    }

    process {
        $uri = '/rest/vxm/v1/system/proxy'

        $Body = @{
            "proxy_spec" = @{
	            "server" = $ProxyServer
	            "port" = $ProxyPort
	            "type" = $ProxyType.ToUpper() # vxManager don't accept lowercase 'http'/'socks'
            }
        } 
        
        if($EsrsPwd) {
        $Body["esrs_pwd"] = $EsrsPwd
        }
        if($ProxyUsername){
            $Body.proxy_spec["username"] = $ProxyUsername
        }
        if($ProxyUserPassword){
            $Body.proxy_spec["pwd"] = $ProxyUserPassword
        }
        if($SocksVersion){
            $Body.proxy_spec["socks_version"] = $SocksVersion
        }
        $body = $body | ConvertTo-Json

        try{
            $ret = doPatch -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
            return $ret
        } catch {
            write-host $_
        }
    }
}
