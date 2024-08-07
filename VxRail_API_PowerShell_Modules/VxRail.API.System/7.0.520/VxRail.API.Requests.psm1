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
Query the requests.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Filter
Query conditions for requests.
The following operators are supported: equal (eq), in (in), not equal (ne), greater
than (gt), less than (lt), greater or equal to (ge), less or equal to (le) on the
following fields: id, state, owner, target, step. for example: "owner eq LOG_BUNDLE and state in (FAILED,IN_PROGRESS)"

.Parameter Id
The request ID of any long running operation.

.Notes
You can run this cmdlet to query all of the requests or a specific request.

.Example
C:\PS>Get-Requests -Server <vxm ip or FQDN> -Username <username> -Password <password>

Queries all of the requests.

.Example
C:\PS>Get-Requests -Server <vxm ip or FQDN> -Username <username> -Password <password> -Id <request id>

Retrieves the operation status and progress report of the specified request.

.Example
C:\PS>Get-Requests -Server <vxm ip or FQDN> -Username <username> -Password <password> -Filter <filter>

Queries specified requests by query condition. example filter: -Filter "owner eq LOG_BUNDLE and state in (FAILED,IN_PROGRESS)" 

#>
function Get-Requests {
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
    
        # Query conditions for requests. 
        [Parameter(Mandatory = $false)]
        [String] $Filter,

        # The request ID of any long running operation
        [Parameter(Mandatory = $false)]
        [String] $Id

    )

    # if $Id is true, execute get request by ID. If $Filter is true, execute get requests. 
    # Only one of $Id and $Filter can exist. 
    if ($Id -and $Filter) {
        write-host "Filter and Id can not exist simutaniously!" -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/v1/requests"
    
    #If $Id is true, get request by ID
    if ($Id) {$uri = "/rest/vxm/v1/requests/$Id"}

    #If $Filter is true, get requests and filter it. Add the filter string to HTTP query string
    if ($Filter) {$uri += '?$filter=' + $Filter}
    
    try{ 
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth 100
        }
        return $ret
    } catch {
        write-host $_
    }
}


