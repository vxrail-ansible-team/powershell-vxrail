# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"
$depotCommonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Depot\" + $currentVersion + "\VxRail.API.Depot.ps1"
. "$commonPath"
. "$depotCommonPath"
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Text.Encoding
class FixedEncoder : System.Text.UTF8Encoding {
    FixedEncoder() : base($true) { }

    [byte[]] GetBytes([string] $s)
    {
        $s = $s.Replace('\', '/');
        return ([System.Text.UTF8Encoding]$this).GetBytes($s);
    }
}
function Initialize-PartialBundle {
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
        # upgrade bundle dir
        [String] $Source,
		[Parameter(Mandatory = $false)]
        # output partial bundle dir
        [String] $Output
    )
    try {
         # check paramter
        if(-not $Source.EndsWith(".zip")) {
            throw "Source file is invalid"
        }
        if($Output -and -not $Output.EndsWith(".zip")){
            throw "Output parameter should include filename"
        }
        if(-not (Test-Path $Source)) {
            throw "Source file is not found"
        }
        showProgress -Title 'Initialize-PartialBundle' -PercentComplete 1 -CurrentOperation 'Preparing'
        # check left space
        $message = deviceSpaceCheck -Source $Source -Times 2.5
        Write-Debug $message
        # check account
        $uri = "/rest/vxm/private/system/installed-components"
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        # prepare env
        $zipFileEntity = Get-Item $Source
        $target = getDateTarget
        $serverTarget = -join($server.Replace('.','-').Replace(':','-'), "-" ,$target)
        $unzipDir = -join($zipFileEntity.DirectoryName, "\", $serverTarget,"\");
        if (-not $Output){
            $Output = -join($zipFileEntity.DirectoryName, "\", $serverTarget,".zip");
        }
        Write-Debug '++Preparing enviroment'
        prepareDir -Path $unzipDir
        Write-Debug '++Unziping Bundle'
        
        Write-Debug '++Invoke ciphertext script'
        showProgress -Title 'Initialize-PartialBundle' -PercentComplete 10 -CurrentOperation 'Unzip Full Bundle'
        try{
            [System.IO.Compression.ZipFile]::ExtractToDirectory($Source, $unzipDir)
        } catch {
            throw "Source file is corrupted"
        }
        # collecting new bundle
        showProgress -Title 'Initialize-PartialBundle' -PercentComplete 50 -CurrentOperation 'Analyse Components'
        $responseComponents = @()
        $xmlComponents = @()
            
        if ($response.Count -le 0){
            throw "VxRail cluster is not healthy for upgrade, please try again later."
        }
        $responseComponents = parsingJSON -ret $response
        $manifestXml = -Join($unzipDir,'manifest.xml')
        $xmlComponents = parsingManifestFile -FilePath $manifestXml
        $filePathList += getDeleteBundlePathList -ResponseComponents $responseComponents -XmlComponents $xmlComponents

        Write-Debug '++Remove unwanted files'
        foreach ($path in $filePathList){
            $fileAbsolutePath = -join($unzipDir, $path.replace('/','\'))
            if(Test-Path $fileAbsolutePath){
                Remove-Item $fileAbsolutePath -Recurse -Force -Confirm:$false
            }

        }

        showProgress -Title 'Initialize-PartialBundle' -PercentComplete 70 -CurrentOperation 'Packing Components'
        $temp = @{}
        foreach($xmlComponent in $xmlComponents){
            try {
                $temp.add($xmlComponent.File, $true)
            }
            catch {}
        }
        if($temp.Count -gt $filePathList.Count){
            Write-Debug '++Package new upgrade zip file'
            if(Test-Path $Output){
                Remove-Item $Output -Recurse -Force -Confirm:$false
            }
            [System.IO.Compression.ZipFile]::CreateFromDirectory($unzipDir, $Output, [System.IO.Compression.CompressionLevel]::Optimal, $false, [FixedEncoder]::new())
            #[System.IO.Compression.ZipFile]::CreateFromDirectory($unzipDir, $Output)
        } else {
            $Output = ''
        }
        Write-Progress -Activity 'Initialize-PartialBundle' -PercentComplete 100
    }
    catch {
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            Write-Host $m2 -ForegroundColor Red
        } else {
            Write-Host $m1 -ForegroundColor Red
            Write-Host $m2 -ForegroundColor Red
        }
        $Output = ''
    }
    if ($unzipDir -and (Test-Path $unzipDir)){
        Write-Debug '++Clean temp folder'
        Remove-Item $unzipDir -Recurse -Force -Confirm:$false
    }
    if ($Output -and (Test-Path $Output)) {
        $Output = ($Output | Out-String).Trim()
        return $Output
    }
}
function Send-PartialBundle {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$True,Position=1)] [System.URI] $Server,
        [parameter(Mandatory=$True,Position=2)] [String] $Username,
        [parameter(Mandatory=$True,Position=3)] [String] $Password,
        [parameter(Mandatory=$True,Position=4)] [ValidateScript({ Test-Path -PathType Leaf $_ })] [String] $FilePath,
        [Switch]$Resume
    )
    try{
        $checkFile = Test-Path $FilePath;
        if (-not $checkFile) {
            throw "Invalid upload file."
        }
        showOuterProgress -Id 1 -Title 'Send-PartialBundle' -PercentComplete 1 -CurrentOperation 'Sync LCM Status With Cluster'
        $file = Get-Item $FilePath
        Write-Debug '++ Start uploading process'
        Write-Debug '++Invoke ciphertext script'
        
        & ($currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Depot\" + $currentVersion + "\cipher\VxRail.API.Depot.RS.ps1")
        
        $uri = '/rest/vxm/private/lcm/bundle'
        showOuterProgress -Id 1 -Title 'Send-PartialBundle' -PercentComplete 90 -CurrentOperation 'Deploy Bundle'
        $response= doGet -Server $Server -Api $uri -Username $Username -Password $Password
        $fileName = $response.file_name
        if ($fileName -eq '') {
            Write-Error '--> Get file name fail' -ErrorAction Stop
        }
        $uri = '/rest/vxm/private/lcm/bundle/deploy'
        $deployRequestBody = @{'file_name'=$fileName}
        $deployRequestBody = ConvertTo-Json $deployRequestBody -Depth 10
        Write-Debug '++ Deploy bundle start'
        $deployResponse = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $deployRequestBody
        Write-Debug '++ Deploy bundle complete'
        Write-Debug $deployResponse
        return $deployResponse
    } catch {
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            Write-Host $m2 -ForegroundColor Red
        } else {
            Write-Host $m1 -ForegroundColor Red
            Write-Host $m2 -ForegroundColor Red
        }
    }
}

function Invoke-VxRailUpgrade {
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
        [Parameter(Mandatory = $false)]
        # upgrade account config
        [String] $Config
    )
    try {
        Write-Debug "++ Invoke upgrade start"
        if($Config){
            $hasConfig = $true
        }else{
            $hasConfig = $false
        }
        $specUri = '/rest/vxm/private/lcm/upgrade-spec'
        $upgradeUri = '/rest/vxm/v1/lcm/upgrade'
        ## to get the upload spec
        $specResponse = doGet -Server $Server -Api $specUri -Username $Username -Password $Password
        $result = @{};
        foreach ($item in $specResponse){
            $result += generateItem -Item $item -HasConfig $hasConfig
        }
        if($hasConfig){
            Write-Debug '++ Read config file'
            if (-not(Test-Path $Config)) {
                throw 'config file does not existing'
            }
            $result = configSetup -Config $Config -Table $result
        }
        
        $requestBody = ConvertTo-Json $result -Depth 10
        Write-Debug $requestBody
        $upgradeResponse = doPost -Server $Server -Api $upgradeUri -Username $Username -Password $Password -Body $requestBody
        Write-Debug "++ Invoke upgrade start"
        Start-Sleep 3
        ##
        while ($true) {
            $stateUri = '/rest/vxm/private/lcm/status'
            $stateResponse = doGet -Server $Server -Api $stateUri -Username $Username -Password $Password
            $state = $stateResponse.state
            $requestId = $stateResponse.request_id
            if($state -eq 'UPGRADE_PRECHECK_ERROR'){
                Write-Error "VxRail Upgrade Fail, please check the account information"
                break
            }
            if($state -eq 'UPGRADING'){
                Write-Debug "++ VxRail upgrade process start."
                break
            }
            if (-not $requestId){
                throw "can't get request id."
            }
            $uri = -join('/rest/vxm/v1/requests/', $requestId)
            $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
            if ($response.state -eq 'FAILED') {
                return $response
            }
            Write-Progress -Activity $stateResponse.state -PercentComplete $response.progress
            Start-Sleep 3
        }
        ##
        return $upgradeResponse
    }
    catch {
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            Write-Host $m2 -ForegroundColor Red
        } else {
            Write-Host $m1 -ForegroundColor Red
            Write-Host $m2 -ForegroundColor Red
        }
    }
    
}

function Get-VxRailUpgradeStatus {
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
        [switch] $Auto
    )
    try{
        while ($true) {
            Write-Debug "++ LCM status"
            $stateUri = '/rest/vxm/private/lcm/status'
            $stateResponse = doGet -Server $Server -Api $stateUri -Username $Username -Password $Password
            $state = $stateResponse.state
            $requestId = $stateResponse.request_id
            if($state -eq 'NONE' -or $state -eq 'UPGRADED'){
                return "The remote server cannot find the active upgrade process. Please make sure upgrade has started."
            }
            if (-not $requestId){
                throw "The remote server cannot find the active upgrade process. Please make sure upgrade has started."
            }
            Write-Debug "++ Upgrade status"
            $uri = -join('/rest/vxm/v1/requests/', $requestId)
            $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
            if (!$Auto){
                break
            }
            if ($response.state -eq 'FAILED') {
                return $response
                break
            }
            if ($response.state -eq "UPGRADED"){
                return $response
                break
            }
            Write-Progress -Activity $stateResponse.state -PercentComplete $response.progress
            Start-Sleep 3
        }
        return $response
    } catch {
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            Write-Host $m2 -ForegroundColor Red
        } else {
            Write-Host $m1 -ForegroundColor Red
            Write-Host $m2 -ForegroundColor Red
        }
    }
}

function Invoke-VxRailUpgradeRetry {
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
        [String] $Password
    )
    try{
        $stateUri = '/rest/vxm/private/lcm/status'
        $stateResponse = doGet -Server $Server -Api $stateUri -Username $Username -Password $Password
        $requestId = $stateResponse.request_id
        $state = $stateResponse.state
        if($state -ne 'UPGRADE_ERROR' -and $state -ne 'UPGRADE_PRECHECK_ERROR'){
            throw "can not retry the upgrade process"
        }
        if (-not $requestId){
            throw "can't get request id"
        }
        $uri = -join('/rest/vxm/private/requests/', $RequestId, '/retry')
        Write-Debug "++ Invoke upgrade retry start"
        ## get the upgrade status
        $response = doPost -Server $Server -Api $uri -Username $Username -Password $Password
        Write-Debug "++ Invoke upgrade retry complete"
        Write-Debug $response
        return $response
    } catch {
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            Write-Host $m2 -ForegroundColor Red
        } else {
            Write-Host $m1 -ForegroundColor Red
            Write-Host $m2 -ForegroundColor Red
        }
    }
}


