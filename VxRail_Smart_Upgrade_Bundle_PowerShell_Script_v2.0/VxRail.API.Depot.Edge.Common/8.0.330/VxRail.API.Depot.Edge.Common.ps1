# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$IPV6_ADDR_PATTERN = "^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:)|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){5}(:[0-9A-Fa-f]{1,4}){1,2})|(([0-9A-Fa-f]{1,4}:){4}(:[0-9A-Fa-f]{1,4}){1,3})|(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){1,4})|(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){1,5})|([0-9A-Fa-f]{1,4}:(:[0-9A-Fa-f]{1,4}){1,6})|(:(:[0-9A-Fa-f]{1,4}){1,7})|(([0-9A-Fa-f]{1,4}:){6}(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){5}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){4}(:[0-9A-Fa-f]{1,4}){0,1}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){0,2}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){0,3}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|([0-9A-Fa-f]{1,4}:(:[0-9A-Fa-f]{1,4}){0,4}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})|(:(:[0-9A-Fa-f]{1,4}){0,5}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3}))$"

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function doHttpStatusCheck{
    param($Response)
    if($Response.StatusCode.value__ -eq 401){
        throw "adminit account is invalid"
    }

    if($Response.StatusCode.value__ -eq 404){
        throw "URL not found"
    }

    if($Response.StatusCode.value__ -ge 500 ){
        throw "Server Error"
    }
    
    if($Response.StatusCode.value__ -ge 400){
        throw "bad request"
    }

}
    
function getBasicAuthHeader {
    param (
        [Parameter(Mandatory = $true)] $Username,
        [Parameter(Mandatory = $true)] $Password
    )

    # Make "username:password" string
    $UserNameColonPassword = "{0}:{1}" -f $Username, $Password
    # Could also be accomplished like:
    # $UserNameColonPassword = "$($Username):$($Password)"

    # Ensure it's ASCII-encoded
    $InAscii = [Text.Encoding]::ASCII.GetBytes($UserNameColonPassword)

    # Now Base64-encode:
    $InBase64 = [Convert]::ToBase64String($InAscii)

    # The value of the Authorization header is "Basic " and then the Base64-encoded username:password
    $Authorization = "Basic {0}" -f $InBase64
    # Could also be done as:
    # $Authorization = "Basic $InBase64"

    #This hash will be returned as the value of the function and is the Powershell version of the basic auth header
    $BasicAuthHeader = @{ Authorization = $Authorization }

    # Return the header
    return $BasicAuthHeader
}

function callAPI {
    param(
        [Parameter(Mandatory = $true)] $Username,
        [Parameter(Mandatory = $true)] $Password,
        [Parameter(Mandatory = $true)] $Server,
        [Parameter(Mandatory = $true)] $Api,
        [Parameter(Mandatory = $true)] $Method,
        [Parameter(Mandatory = $false)] $SpecialHeaders,
        [Parameter(Mandatory = $false)] $Body,
        [Parameter(Mandatory = $false)] $ContentType,
        [Parameter(Mandatory = $false)] $TimeoutSec
    )

    if([string]::IsNullOrEmpty($Method)) {
        throw [System.ArgumentNullException] "Method $Method can't be empty."
    }

    $supportedMethods = 'GET','POST','PUT','DELETE','PATCH'
    $m = $Method.Trim().ToUpper()
    if(!$supportedMethods.Contains($m)) {
        throw [System.ArgumentNullException] "Method $Method is not supported."
    }

    if  ($Server -match $IPV6_ADDR_PATTERN) {
        $url = "https://" + "[" + $Server + "]" + $Api
    }
    else {
        $url = "https://" + $Server + $Api
    }

    $headers = getBasicAuthHeader -Username $Username -Password $Password
    $headers = getBasicAuthHeader -Username $Username -Password $Password
	if($SpecialHeaders){
		$headers += $SpecialHeaders
	}
	if(-not $ContentType){
		$ContentType = "application/json" 
    }
    if(-not $TimeoutSec) {
        $TimeoutSec = 180
    }
    try{
        if($m -like "GET") {
            $response = Invoke-RestMethod -Method $m -Uri $url -Headers $headers -ContentType $ContentType -TimeoutSec $TimeoutSec
        } else {
            $response = Invoke-RestMethod -Method $m -Uri $url -Headers $headers -Body $Body -ContentType $ContentType -TimeoutSec $TimeoutSec
        }
    }catch{
        if ((-not $_.Exception) -or (-not $_.Exception.Status) ){
            throw $_
        }
        if ($_.Exception.Status.Equals([System.Net.WebExceptionStatus]::NameResolutionFailure) -or $_.Exception.Status.Equals([System.Net.WebExceptionStatus]::ConnectFailure)) {
            throw "Invalid FQDN or IP"
        } elseif ($_.Exception.Status.Equals([System.Net.WebExceptionStatus]::Timeout)) {
            throw "Remote server connection timeout."
        }
        throw $_
    }
    doHttpStatusCheck -Response $response
    return $response
}

function doGet {
    param(
        [Parameter(Mandatory = $true)] $Username,
        [Parameter(Mandatory = $true)] $Password,
        [Parameter(Mandatory = $true)] $Server,
        [Parameter(Mandatory = $true)] $Api,
        [Parameter(Mandatory = $false)] $SpecialHeaders
    )
    return callAPI -Username $Username -Password $Password -Server $Server -Api $Api -Method 'GET' -SpecialHeaders $SpecialHeaders
}

function doDelete {
    param(
        [Parameter(Mandatory = $true)] $Username,
        [Parameter(Mandatory = $true)] $Password,
        [Parameter(Mandatory = $true)] $Server,
        [Parameter(Mandatory = $true)] $Api,
        [Parameter(Mandatory = $false)] $Body
    )
    return callAPI -Username $Username -Password $Password -Server $Server -Api $Api -Method 'DELETE' -Body $Body
}

function doPost {
    param(
        [Parameter(Mandatory = $true)] $Username,
        [Parameter(Mandatory = $true)] $Password,
        [Parameter(Mandatory = $true)] $Server,
        [Parameter(Mandatory = $true)] $Api,
		[Parameter(Mandatory = $false)] $SpecialHeaders,
		[Parameter(Mandatory = $false)] $Body,
		[Parameter(Mandatory = $false)] $ContentType
    )
	return callAPI -Username $Username -Password $Password -Server $Server -Api $Api -Method 'POST' -SpecialHeaders $SpecialHeaders -ContentType $ContentType -Body $Body
}

function doPut {
    param(
        [Parameter(Mandatory = $true)] $Username,
        [Parameter(Mandatory = $true)] $Password,
        [Parameter(Mandatory = $true)] $Server,
        [Parameter(Mandatory = $true)] $Api,
        [Parameter(Mandatory = $true)] $Body
    )
    return callAPI -Username $Username -Password $Password -Server $Server -Api $Api -Method 'PUT' -Body $Body
}

function doPatch {
    param(
        [Parameter(Mandatory = $true)] $Username,
        [Parameter(Mandatory = $true)] $Password,
        [Parameter(Mandatory = $true)] $Server,
        [Parameter(Mandatory = $true)] $Api,
        [Parameter(Mandatory = $false)] $SpecialHeaders,
        [Parameter(Mandatory = $true)] $Body
    )
    return callAPI -Username $Username -Password $Password -Server $Server -Api $Api -Method 'PATCH' -SpecialHeaders $SpecialHeaders -Body $Body
}

function deviceSpaceCheck {
    param($Times, $Source)
    $zipFileEntity = Get-Item $Source
    $device = ($Source -split ':')[0].Trim().ToUpper()+':'
    $disk = Get-WmiObject Win32_LogicalDisk -ComputerName localhost -Filter "DeviceID='$device'"
    if($zipFileEntity.Length * $Times -gt $disk.FreeSpace){
        throw "There is not enough depot storage space available to complete this operation."
    } else {
        $notice = -join("--> This device left space is : [",[int]($disk.FreeSpace/1024/1024/1024), "GB]")
    }
    return $notice;
}

function getDateTarget {
    param(
        [Parameter(Mandatory = $false)] $Formate = "yyyyMMddhhmmss"
    )
   return Get-Date -Format $Formate 
}

function showInnerProgress {
    param ($ParentId, $Title, $PercentComplete, $CurrentOperation)
    Write-Progress -ParentId $ParentId -Activity $Title -Status $PercentComplete'%' -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation
}

function showOuterProgress {
    param ($Id, $Title, $PercentComplete, $CurrentOperation)
    Write-Progress -Id $Id -Activity $Title -Status $PercentComplete'%' -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation
}

function showProgress {
    param ($Title, $PercentComplete, $CurrentOperation)
    showOuterProgress -Id 1 -Title $Title -PercentComplete $PercentComplete -CurrentOperation $CurrentOperation
}

function HandleInvokeRestMethodException {
    param(
        [Parameter(Mandatory = $true)]
        # Rest API URL
        [String] $URL
    )

    #In order not to modify the upper cmdlet code, handle ipv6 url display issue here
    $items = $URL -split '/', 4
    $ServerIP = $items[2].Trim()
    $Api = '/' + $items[3].Trim()
    if  ($ServerIP -match $IPV6_ADDR_PATTERN) {
        $URL = "https://" + "[" + $Server + "]" + $Api
    }
    else {
        $URL = "https://" + $Server + $Api
    }

    $errorMessage = $_.Exception.Message
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

