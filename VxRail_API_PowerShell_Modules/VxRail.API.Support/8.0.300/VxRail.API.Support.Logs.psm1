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
Queries the logs.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.

.Parameter Filter
Query conditions for the support logs

.Parameter LogId
The specific log that you want to query.

.Notes
You can run this cmdlet to Query the logs.

.Example
C:\PS>Get-SupportLogs -Server <vxm ip or FQDN> -Username <username> -Password <password>

Queries all of the support logs.

.Example
C:\PS>Get-SupportLogs -Server <vxm ip or FQDN> -Username <username> -Password <password> -Filter <filter> 

Queries the specified support logs by query condition.

.Example
C:\PS>Get-SupportLogs -Server <vxm ip or FQDN> -Username <username> -Password <password> -LogId <log id>

Queries the specified support logs by id.
#>
function Get-SupportLogs {
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
        [Switch] $Format,

        # Query conditions for requests. 
        [Parameter(Mandatory = $false)]
        [String] $Filter,

        # ID of the specific log 
        [Parameter(Mandatory = $false)]
        [String] $LogId
    )

    
    # if $LogId is true, execute get log by ID. If $Filter is true, execute get logs. 
    # Only one of $Id and $Filter can exist. 
    if ($LogId -and $Filter) {
        write-host "Filter and LogId can not exist simutaniously!" -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/v1/support/logs"

    # If $LogId is true, get logs by ID
    if ($LogId) {$uri = "/rest/vxm/v1/support/logs/$LogId"}

    # If $Filter is true, get logs and filter it. Add the filter string to HTTP query string
    if ($Filter) {$uri += '?$filter=' + $Filter}
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
Download the binary stream of a log.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Destination
Specify a path where you want the log to be saved to.

.Parameter LogId
The unique identifier of the log that you want to query.

.Notes
You can run this cmdlet to download the binary stream of a log.

.Example
C:\PS>Save-SupportLogsById -Server <vxm ip or FQDN> -Username <username> -Password <password> -LogId <log id> -Destination <path>

Download the log binary stream and save it to a local path.
#>
function Save-SupportLogsById {
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

        # ID of the specific log 
        [Parameter(Mandatory = $true)]
        [String] $LogId,

        # Locallocation to download log
        [Parameter(Mandatory = $true)]
        [string] $Destination
    )
    
    $header = getBasicAuthHeader -Username $Username -Password $Password
    $uri = -join("/rest/vxm/v1/support/logs/", $LogId, "/download")

	if  ($Server -match $IPV6_ADDR_PATTERN) {
        $downloadPath = "https://" + "[" + $Server + "]" + $uri
    }
    else {
        $downloadPath = "https://" + $Server + $uri
    }

    #$downloadPath = -join("https://", $Server, $uri)
    if ($Destination) {
        if ((Test-Path -Path $Destination) -eq $True) {
            $localFile = $Destination + $LogId + ".zip"
        } else {
            Write-Error "Given Path doesn't exist" -ErrorAction Stop
        }
    }
    try {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.Add('Authorization', $header['Authorization'])
        $WebClient.DownloadFile($downloadPath, $localFile)
    }     catch {
       write-host $_
    }
}


<#
.Synopsis
Collect the support log with the specified types.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter AutoClean
If disk space is not enough, auto clean the existing log files.

.Parameter Types
The types of the log to collect. Include: vxm, vcenter, esxi, idrac, ptagent. 
User can enter one or more types, and use comma "," to seperate the types. e.g. esxi,vxm

.Notes
You can run this cmdlet to collect the support log with the specified types.

.Example
C:\PS>New-SupportLogs -Server <vxm ip or FQDN> -Username <username> -Password <password> -Types <types>

Collect the log with the specified types. If '-Types' contain 'esxi' or 'idrac' or 'ptagent', parameter '-Nodes' must be supplied.

.Example
C:\PS>New-SupportLogs -Server <vxm ip or FQDN> -Username <username> -Password <password> -Types <types> -AutoClean

Collect the log with the specified types. If disk space is not enough, auto clean the existing log files.
#>
function New-SupportLogs {
    [CmdletBinding()]
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

        # AutoClean exsiting log file or not
        [Parameter(Mandatory = $false)]
        [Switch] $AutoClean,

        # The types of the log to collect.Include: vxm, vcenter, esxi, idrac, ptagent. 
        [parameter(Mandatory=$true, HelpMessage="Supported log bundle types: 'esxi','vcenter','idrac','ptagent','vxm'")]
        [ValidateSet('esxi','vcenter','idrac','ptagent','vxm')]
        [String[]] $Types
    )
    
    # for 'esxi','idrac' and 'ptagent', user need to provide host information
    DynamicParam {
        if ($Types -contains "esxi" -or $Types -contains "idrac" -or $Types -contains "ptagent") {
           # Define dynamic parameter named as socksVerion only when SOCKS is selected
           $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
           $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]

           # Define the parameter attribute
           $attribute = New-Object System.Management.Automation.ParameterAttribute
           $attribute.Mandatory = $true
           $attribute.ValueFromPipeline = $true
           $attribute.HelpMessage = "Dynamic Prameter 'Nodes': please supply the Host Service Tag"
           $attributeCollection.Add($attribute)

           # compose the dynamic -Nodes parameter
           $Name = 'Nodes'
           $dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($Name, [String[]], $attributeCollection)
           $paramDictionary.Add($Name, $dynParam)

           # return the collection of dynamic parameters
           $paramDictionary        
        }
    }
    
    Process {  
        $uri = "/rest/vxm/v1/support/logs"
        # Body content
        $Body = @{
            "types" = $Types
        }

        # Dynamic parameter values are contained in $PSBoundParameters
        if ($PSBoundParameters.Nodes) {
            $Body.nodes = $PSBoundParameters.Nodes
        }

        if ($AutoClean) {
            $Body.autoclean = "True"
        } else {$Body.autoclean = "False"}
        $Body = $Body | ConvertTo-Json

       try{ 
           $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
           return $ret
       } catch {
       write-host $_
       }   
    }
}
