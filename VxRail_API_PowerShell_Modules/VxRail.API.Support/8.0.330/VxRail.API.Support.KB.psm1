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
Retrieves the VxRail Support Knowledge Base (KB) home URL.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to retrieve the VxRail Support Knowledge Base (KB) home URL.

.Example
C:\PS>Get-SupportKB -Server <vxm ip or FQDN> -Username <username> -Password <password>

Retrieves the VxRail Support Knowledge Base (KB).
#>
function Get-SupportKB {
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

    $uri = "/rest/vxm/v1/support/kb"
    try{ 
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
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
Retrieves articles from VxRail Support Knowledge Base.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Use corresponding password for username. 

.Parameter Format
Print JSON style format.

.Parameter Keyword
The text that the user wants contained in the articles that are returned

.Parameter Count
The number of articles the user wants to receive. Default is 3.

.Notes
You can run this cmdlet to retrieve articles from VxRail Support Knowledge Base.

.Example
C:\PS>Get-SupportKbArticles -Server <vxm ip or FQDN> -Username <username> -Password <password> -Keyword <keyword> -Count <count>

Queries articles from VxRail Support knowledge base.
#>
function Get-SupportKbArticles {
    # The optional parameters and mandatory for users to search for
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
        
        # The optional key words/tests for users to search for
        [Parameter(Mandatory = $false)]
        [String] $Keyword,

        # The optional parameters for users to searach for, default = 3
        [Parameter(Mandatory = $false)]
        $Count = 3,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    process {
        $uri = "/rest/vxm/v1/support/kb/articles"
        
        if ($Count.GetType().name -notin @("Int32", "Int", "Int16", "Int64")) {
            Write-Error "Parameter -Count supports only integer" -ErrorAction Stop
        }
        if ($Keyword) {
            $uri = $uri + "?searchText=" + '"' + $Keyword +'"'  + "&limit=" + $Count
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
}
