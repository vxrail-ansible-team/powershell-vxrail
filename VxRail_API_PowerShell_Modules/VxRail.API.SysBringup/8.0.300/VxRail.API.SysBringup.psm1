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
Start system bring up workflow

.PARAMETER Server
Required. VxRail Manager IP address (IPv4 format)

.PARAMETER Conf
Required. Json configuration file as the body of system bring up API

.PARAMETER Dryrun
Optional. Dryrun switch

.Notes
You can run this cmdlet to start system bring up or restart system bring up if failed.

.EXAMPLE  
PS> Start-SystemBringup -Server <VxM IP> -Conf <Json file to the path> -Dryrun

Starts system bring up on VxRail Manager (VxM IP) with the specified json configuration and the dryrun mode
#>
function Start-SystemBringup {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $Conf,

        [Parameter(Mandatory = $false)]
        # Dryrun switch
        [Switch] $Dryrun,

        [Parameter(Mandatory = $false)]
        # Steps to skip
        [String[]] $Skips
    )
    
    if ($Dryrun) {
        $url = Build-RestMethodURL -Server $Server -Skips $Skips -Dryrun
    } else {
        $url = Build-RestMethodURL -Server $Server -Skips $Skips
    }

    $body = Get-Content $Conf
    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method POST -Body $body -ContentType "application/json"

        if ($response -and $response.request_id) {
            Write-Host "Request ID  : "$response.request_id
        } else {
            $responseJson = $response | ConvertTo-Json
            Write-Host $responseJson
        }
    } catch {
        Handle-RestMethodInvokeException -URL $url
    }
}

<#
.SYNOPSIS
Build Rest API URL

.PARAMETER Server
Required. VxM IP address (IPv4 format)

.PARAMETER Dryrun
Optional. Dryrun switch

#>
function Build-RestMethodURL{
    param(
        [Parameter(Mandatory = $true)]
         # VxM IP
        [String] $Server,

        [Parameter(Mandatory = $false)]
        # Dryrun switch
        [Switch] $Dryrun,

        [Parameter(Mandatory = $false)]
        # Steps to skip
        [String[]] $Skips
    )
    $uri = "/rest/vxm/v1/system/initialize"
    $urlLeft = Get-Url -Server $Server -Uri $uri
    
    $hasSkips = $Skips.count -gt 0
    if ($hasSkips) {
        $skipString = ""
        foreach ($skip in $Skips) {
            $skipString = $skipString + "skip=" + $skip + "&"
        }
        $skipString = $skipString.Substring(0, $skipString.Length - 1)
    }

    $urlRight = ""
    if ($Dryrun -and $hasSkips) {
        $urlRight = "?dryrun=true&" + $skipString
    } elseif (!$Dryrun -and $hasSkips) {
        $urlRight = "?" + $skipString
    } elseif ($Dryrun -and !$hasSkips) {
        $urlRight = "?dryrun=true"
    }
    
    $url = $urlLeft + $urlRight

    return $url
}

<#
.SYNOPSIS
Handle exception of REST API calling

.PARAMETER URL
Required. Rest API URL

#>
function Handle-RestMethodInvokeException {
    param(
        [Parameter(Mandatory = $true)]
        # Rest API URL
        [String] $URL
    )

    $errorMessage = $_.Exception.Message
    $statuscode = $_.Exception.Response.StatusCode.value__
	if ($statuscode -eq "400" -and $_.ErrorDetails.Message.Contains("20101003")){
		Write-Host  $_.ErrorDetails
		break
	}
    if (Get-Member -InputObject $_.Exception -Name 'Response') {
        try {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
        } catch {
            Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Cannot get more information."
        }
    }
    Throw "An error occurred while calling REST method at: $URL. Error: $errorMessage. Response body: $responseBody"
}

<#
.SYNOPSIS
Get progress status of system bring up

.PARAMETER Server
Required. VxM IP address (IPv4 format)

.Notes
You can run this cmdlet to query progress status of system bring up

.EXAMPLE 
PS> Get-BringupProgressStatus -Server <VxM IP> 

Gets progress status of system bring up on VxRail Manager (VxM IP)
#>
function Get-BringupProgressStatus{
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server
    )
    $uri = "/rest/vxm/v1/system/initialize/status"
    $url = Get-Url -Server $Server -Uri $uri
    try {
        $retryCount = 4000 
        for ($i=1; $i -le $retryCount; $i++) {
            $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method GET -ContentType "application/json"
            
            cls
            Write-Host "------------------------Response Begin------------------------"
            Write-Host "Query Seq          : "$i  
            Write-Host "ID                 : "$response.id
            Write-Host "State              : "$response.state
            Write-Host "Step               : "$response.step 
            Write-Host "Progress           : "$response.progress
            Write-Host "Error              : "$response.error
            
            $UserPSModuleLocation = "$HOME\Documents\WindowsPowerShell\Modules"
            $filePath = $UserPSModuleLocation + "\System_Bringup_Progress_Status.json"
            $fileExist = Test-Path $filePath
            if (-not $fileExist) {
                New-Item -Path $filePath -Type File -Force | Out-Null
            }
            $response | ConvertTo-Json -depth 100 | Out-File $filePath

            Write-Host "Detailed Response  : "$filePath
            Write-Host "------------------------Response End--------------------------"

            if ($response.state -eq "FAILED") {
                Write-Host "VxRail system bring up in failed status. Please check detailed response file for more or restart bring up process"
                break
            }
             if ($response.state -eq "COMPLETED") {
                Write-Host "VxRail system bring up successfully completed!"
                break
            }  
            Start-Sleep -s 3
        } 
    } catch {
        Handle-RestMethodInvokeException -URL $url
    }
}


<#
.SYNOPSIS
Start to get customer supplied hosts

.PARAMETER Server
Required. VxRail Manager IP address (IPv4 format)

.Parameter Version
Optional. API version. Default value is v1.

.PARAMETER Conf
Required. Customer supplied host connection info json file to query those hosts

.EXAMPLE
PS> Get-CustomerSuppliedHosts -Server <VxM IP> -Conf <Json file to the path>
#>
function Get-CustomerSuppliedHosts {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # customer supplied hosts file
        [String] $Conf
    )

    # check Version
    if(($Version -ne "v1") -and ($Version -ne "v2")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }
    $uri = "/rest/vxm/" + $Version.ToLower() + "/system/initialize/customer-supplied-hosts"
    $url = Get-Url -Server $Server -Uri $uri

    $body = Get-Content $Conf
    Write-Output $body
    try {
        $response = Invoke-RestMethod -Uri $url -UseBasicParsing -Method POST -Body $body -ContentType "application/json"
        $responseJson = $response | ConvertTo-Json -Depth 10
        Write-Output $responseJson

    } catch {
        Handle-RestMethodInvokeException -URL $url
    }
}

<#
.SYNOPSIS
Start to get auto discovery hosts

.PARAMETER Server
Required. VxRail Manager IP address (IPv4 format)

.Parameter Version
Optional. API version. Default value is v1.

.EXAMPLE
PS> Get-AutoDiscoveryHosts -Server <VxM IP>
#>
function Get-AutoDiscoveryHosts {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1"
    )

    # check Version
    if(($Version -ne "v1") -and ($Version -ne "v2")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }
    $uri = "/rest/vxm/" + $Version.ToLower() + "/system/initialize/nodes"
    $url = Get-Url -Server $Server -Uri $uri

    try {
        $response = Invoke-RestMethod -Uri $url -Method GET
        $responseJson = $response | ConvertTo-Json -Depth 10
        Write-Output $responseJson

    } catch {
        Handle-RestMethodInvokeException -URL $url
    }
}
function Get-Url{
        param(
        [String] $Server,

        [String] $Uri
    )
    if ($Server -match $IPV6_ADDR_PATTERN) {
        return "https://" + "[" + $Server + "]" + $Uri
    }
    else{
        return "https://" + $Server + $Uri
    }
}

