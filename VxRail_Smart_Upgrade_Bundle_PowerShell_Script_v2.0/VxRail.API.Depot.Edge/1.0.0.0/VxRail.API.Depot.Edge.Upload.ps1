# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.
Param(
    [parameter(Mandatory = $true)]
    #ID number for cluster. Same as order in cluster config file line number(Begin from 0)
    [int] $ID,
    [parameter(Mandatory = $true)]
    [string] $LCMUtilPath,
    [parameter(Mandatory = $true)]
    [string] $CommonPath,
    [Parameter(Mandatory = $true)]
    # Composite bundle file path
    [string] $CompositeBundleFilePath,
    [Parameter(Mandatory = $true)]
    # VxManager ip address or FQDN
    [string] $VxMAddress,
    [Parameter(Mandatory = $true)]
    # VxManager username
    [string] $VxMUsername,
    [Parameter(Mandatory = $true)]
    # VxManager password
    [string] $VxMPassword,
    [Parameter(Mandatory = $true)]
    # VCenter username
    [string] $VCAdminUsername,
    [Parameter(Mandatory = $true)]
    # VCenter password
    [string] $VCAdminPassword,
    [Parameter(Mandatory=$true)]
    [String] $LogFilePath,
    [Parameter(Mandatory = $true)]
    # VxManager ssh port
    [string] $VxMPort,
    [Parameter(Mandatory = $true)]
    # Smart bundle local parent folder
    [String] $SmartBundleLocalPath,
    [Parameter(Mandatory = $true)]
    # output partial bundle dir in vxrail manager
    [string] $TargetFolder,
    [Parameter(Mandatory = $true)]
    # winscp session option for this cluster
    $SessionOption,
    [Parameter(Mandatory = $false)]
    # have found the bundle files on target vxm or not
    [bool]$IsBundleExisted,
    [Parameter(Mandatory = $false)]
    # Upload speed limitationd
    [int] $SpeedLimit
)

. "$LCMUtilPath"
. "$CommonPath"

# static variable
$UploadLogPrefix="lcm-upload-"
$LOG_THREAD_WORKFLOW="UPLOAD_WORKFLOW"
$script:UploadProgress = 0
$script:SystemVersion = ""

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

function getCurrentWorkflowLine {
    return ($MyInvocation.ScriptlineNumber).ToString()
}

function fileTransferProgress {
    param($e)
    # Log the progress in log file
    $CurrentProcess = $e.FileProgress*100
    if ($CurrentProcess -ne $script:UploadProgress) {
        logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Current uploading progress ",($e.FileProgress*100).ToString()," under speed ",($e.CPS).ToString()," bytes per second")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
        $script:UploadProgress = $CurrentProcess
    }
}

function uploadToTargetVXM {
    param (
        [Parameter(Mandatory = $true)]
        # file path which need upload
        [string] $LocalFilePath,
        [Parameter(Mandatory = $true)]
        # VxManager ip address or FQDN
        [string] $VxMAddress,
        [Parameter(Mandatory = $true)]
        # VxManager ssh username
        [string] $VxMUsername,
        [Parameter(Mandatory = $true)]
        # VxManager ssh password
        [string] $VxMPassword,
        [Parameter(Mandatory = $true)]
        # Target folder in vxm
        [string] $TargetFolder,
        [Parameter(Mandatory = $true)]
        # log path in local
        [string] $ClusterLogPath,
        [Parameter(Mandatory = $true)]
        # winscp session options
        $SessionOption,
        [Parameter(Mandatory = $false)]
        # VxManager ssh port
        [string] $VxMPort,
        [Parameter(Mandatory = $false)]
        # Tranfer override mode
        [string] $OverrideMode,
        [Parameter(Mandatory = $false)]
        # Speed limit for uploading
        [int] $SpeedLimit
    )

    logInfo -LogFileName $ClusterLogPath -LogMsg "WinSCP executable path found. Establishing session ..." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)

    $TransferOption = New-WinSCPTransferOption -FilePermissions (New-WinSCPItemPermission -Octal "666") -OverwriteMode $OverrideMode
    if ($SpeedLimit) {        
        $TransferOption.SpeedLimit = $SpeedLimit
    }
    $Session = New-Object -TypeName WinSCP.Session -Property @{ExecutablePath = "$env:WinSCP_Path\winscp.exe"}
    $Session.add_FileTransferProgress( { fileTransferProgress($_) } )
    $Session.Open($SessionOption)
    $TestResult = Test-WinSCPPath -WinSCPSession $Session -Path $TargetFolder
    if ($TestResult) {
        try {
            logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Start uploading ",$LocalFilePath," to ",$TargetFolder)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
            # ("Start uploading " + $LocalFilePath + " to " + $TargetFolder)
            $TransferResult = $Session.PutFiles($LocalFilePath, $TargetFolder, $false, $TransferOption)
            $TransferResult.Check()
            # "`n"
            foreach ($Transfer in $TransferResult.Transfers) {
                logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Successfully uploaded ",$Transfer.FileName," to ",$TargetFolder)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
                # ("Successfully uploaded " + $transfer.FileName + " to " + $TargetFolder)
            }
            
        } catch {
            $ErrorMsg = "An error occurred in upload to vxm: "
            $m1 = $_.Exception.message
            $m2 = $_
            if ($m1 -eq $m2){
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
            } else {
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
            }
            $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
            logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Meet error in upload to vxm, detail: ",$ErrorMsg)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine) -ErrorLog
            throw $ErrorMsg
        }
        finally {
            $Session.Dispose()
        }
    }
    else {
        $ex = [System.IO.DirectoryNotFoundException]::new("Invalid remote path: " + $RemotePath)
        throw $ex
    }

}

# Just extract VxRail.API.Depot partial bundle part out for new upload logic. 
function createSMARTBundle {
    param(
        [Parameter(Mandatory = $true)]
        # VxManager ip address or FQDN
        [string] $Server,
        [Parameter(Mandatory = $true)]
        # User name in vCenter
        [String] $VCAdminUsername,
        [Parameter(Mandatory = $true)]
        # Password in vCenter
        [String] $VCAdminPassword,
        [Parameter(Mandatory = $true)]
        # Log file path for this cluster
        [String] $CompositeBundleFilePath,
        [Parameter(Mandatory = $true)]
        # upgrade bundle dir
        [String] $ClusterLogPath,
		[Parameter(Mandatory = $true)]
        # output partial bundle dir(include file name)
        [String] $LocalSmartTargetFilePath
    )

    $LocalSmartTargetFolderPath = $LocalSmartTargetFilePath.Substring(0,$LocalSmartTargetFilePath.LastIndexOf("\"))
    #Clean up all the folder at first
    logInfo -LogFileName $ClusterLogPath -LogMsg "Clean up local folder at first" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
    if (Test-Path $LocalSmartTargetFolderPath) {
        Remove-Item -Path ($LocalSmartTargetFolderPath + "\*") -Recurse -Force -Confirm:$false
    }
    $LocalSmartTargetUnzipFolderPath = $LocalSmartTargetFolderPath + "\unpack\"
    if (-not (Test-Path $LocalSmartTargetUnzipFolderPath)) {
        New-Item -ItemType "directory" -Path $LocalSmartTargetUnzipFolderPath | Out-Null
    }

    try {
        logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Start to create smart bundle for cluster ",$Server)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
        logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Prepare to get cluster ",$Server," component information")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
        $uri = "/rest/vxm/private/system/installed-components"
        $response = doGet -Server $Server -Api $uri -Username $VCAdminUsername -Password $VCAdminPassword
        logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Unzip bundle from ",$CompositeBundleFilePath," to ",$LocalSmartTargetFolderPath)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
        
        #Unzip composite bundle
        try{
            [System.IO.Compression.ZipFile]::ExtractToDirectory($CompositeBundleFilePath, $LocalSmartTargetUnzipFolderPath)
        } catch {
            $ErrorMsg = "Error in unpacking composite bundle: "
            $m1 = $_.Exception.message
            $m2 = $_
            if ($m1 -eq $m2){
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
            } else {
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
            }
            $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
            throw $ErrorMsg
        }
        # collecting new bundle
        logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Analyse Components for cluster ",$Server)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
        $responseComponents = @()
        $xmlComponents = @()
            
        if ($response.Count -le 0){
            throw "VxRail cluster is not healthy for upgrade, please try again later."
        }
        $responseComponents = parsingJSON -ret $response
        $manifestXml = -Join($LocalSmartTargetUnzipFolderPath,'manifest.xml')
        #Extract system version first
        $script:SystemVersion = getManifestSystemVersion -FilePath $manifestXml
        $xmlComponents = parsingLocalManifestFile -FilePath $manifestXml
        $filePathList += getDeleteBundlePathList -ResponseComponents $responseComponents -XmlComponents $xmlComponents

        logInfo -LogFileName $ClusterLogPath -LogMsg "Remove unwanted files" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
        foreach ($path in $filePathList){
            $fileAbsolutePath = -join($LocalSmartTargetUnzipFolderPath, $path.replace('/','\'))
            if(Test-Path $fileAbsolutePath){
                Remove-Item $fileAbsolutePath -Recurse -Force -Confirm:$false
                logInfo -LogFileName $ClusterLogPath -LogMsg (-Join($fileAbsolutePath," has been removed")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
            }

        }

        logInfo -LogFileName $ClusterLogPath -LogMsg "Packing Components for cluster" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
        $temp = @{}
        foreach($xmlComponent in $xmlComponents){
            try {
                $temp.add($xmlComponent.File, $true)
            } catch {}
        }
        if($temp.Count -gt $filePathList.Count){
            logInfo -LogFileName $ClusterLogPath -LogMsg "Begin to package smart bundle, it may need over 10 minutes. Please wait." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
            if(Test-Path $LocalSmartTargetFilePath){
                logInfo -LogFileName $ClusterLogPath -LogMsg "Find one existed smart bundle, remove it." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
                Remove-Item $LocalSmartTargetFilePath -Recurse -Force -Confirm:$false
            }
            [System.IO.Compression.ZipFile]::CreateFromDirectory($LocalSmartTargetUnzipFolderPath, $LocalSmartTargetFilePath, [System.IO.Compression.CompressionLevel]::Optimal, $false, [FixedEncoder]::new())
            #[System.IO.Compression.ZipFile]::CreateFromDirectory($unzipDir, $Output)
        } else {
            throw "manifest partial file list count check is not equal with actual file situation."
        }
        
        if ($LocalSmartTargetFilePath -and (Test-Path $LocalSmartTargetFilePath)) {
            $LocalSmartTargetFilePath = ($LocalSmartTargetFilePath | Out-String).Trim()
            if ($LocalSmartTargetUnzipFolderPath -and (Test-Path $LocalSmartTargetUnzipFolderPath)) {
                logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Succesfully generating the smart bundle, clean up the temp unpack files in ",$LocalSmartTargetUnzipFolderPath)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
                Remove-Item $LocalSmartTargetUnzipFolderPath -Recurse -Force -Confirm:$false
            }
            logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Successfully finish creating smart bundle for cluster ",$Server)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine)
            return $LocalSmartTargetFilePath
        } else {
            throw "Haven't found the smart bundle in the target position. Please check authory or other issue."
        }
    }
    catch {
        $ErrorMsg = "An error occurred: "
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
        } else {
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
        }
        $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
        logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("Meet error in create smart bundle, detail: ",$ErrorMsg)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine) -ErrorLog
        if ($LocalSmartTargetFolderPath -and (Test-Path $LocalSmartTargetFolderPath)) {
            logInfo -LogFileName $ClusterLogPath -LogMsg (-Join("In error case, clean up whole folder for ",$LocalSmartTargetFolderPath)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentUtilsLine) -ErrorLog
            Remove-Item $LocalSmartTargetFolderPath -Recurse -Force -Confirm:$false
        }
        throw $ErrorMsg
    }
}

function resetVXMProcessedInRemoteVXM {
    param (
        [Parameter(Mandatory = $true)]
        # winscp session options
        $SessionOption,
        [Parameter(Mandatory = $true)]
        # Target Folder which contains meta data and bundle file
        [string] $TargetFolder,
        [Parameter(Mandatory = $true)]
        # Local SMART bundle folder path, Like "C:\User\user1\Documents\0-172-16-10-200\"
        [string] $SMARTBundleFolderPath,
        [Parameter(Mandatory = $false)]
        # Speed limit for uploading
        [int] $SpeedLimit,
        [Parameter(Mandatory = $true)]
        # VxManager ip address or FQDN
        [string] $VxMAddress,
        [Parameter(Mandatory = $true)]
        # VxManager ssh username
        [string] $VxMUsername,
        [Parameter(Mandatory = $true)]
        # VxManager ssh password
        [string] $VxMPassword,
        [Parameter(Mandatory = $true)]
        # log path in local
        [string] $ClusterLogPath,
        [Parameter(Mandatory = $false)]
        # VxManager ssh port
        [string] $VxMPort
    )
    $LocalFormerMetaDataFolder = -Join($SMARTBundleFolderPath,"former-metadata")
    try {
        $VXMMetaDataFilePath = -Join($TargetFolder,"edge_metadata.json")
        $HasMetaData = TestFileInRemote -SessionOption $SessionOption -TestFilePath $VXMMetaDataFilePath
        if ($HasMetaData) {
            logInfo -LogFileName $ThisClusterLogPath -LogMsg "Begin to download meta data in cluster to local temporary folder" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
            if (-not (Test-Path $LocalFormerMetaDataFolder)) {
                New-Item -ItemType "directory" -Path $LocalFormerMetaDataFolder | Out-Null
            }
            $LocalFormerMetaDataFilePath = $LocalFormerMetaDataFolder + "\edge_metadata.json"
            $TransferOption = New-WinSCPTransferOption -FilePermissions (New-WinSCPItemPermission -Octal "766") -OverwriteMode "Overwrite"
            if ($SpeedLimit) {        
                $TransferOption.SpeedLimit = $SpeedLimit
            }
            $Session = New-Object -TypeName WinSCP.Session -Property @{ExecutablePath = "$env:WinSCP_Path\winscp.exe"}
            $Session.Open($SessionOption)
            $ReceiveResult = Receive-WinSCPItem -WinSCPSession $Session -RemotePath $VXMMetaDataFilePath -LocalPath $LocalFormerMetaDataFilePath -TransferOptions $TransferOption -Remove
            $ReceiveResult.Check()
            logInfo -LogFileName $ThisClusterLogPath -LogMsg "Download former meta data successfully. Begin to change this meta data VXMProcessed in local." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
            $FormerMetaData = (Get-Content $LocalFormerMetaDataFilePath) | ConvertFrom-Json
            $FormerMetaData.VXMProcessed = $false
            $FormerMetaJson = $FormerMetaData | ConvertTo-Json
            $FormerMetaJson | Out-File $LocalFormerMetaDataFilePath
        } else {
            throw "Find bundle file. But remote meta data file hasn't been found. It is an irregular environment for data center uploading function. Not quite sure remote bundle file is valid. Please contact edge admin for check. If no need to use, please let edge admin delete it manually. Skip this upload try."
        }
    } catch {
        logInfo -LogFileName $ThisClusterLogPath -LogMsg "Remove temporary folder and file since meets error." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
        Remove-Item -Path $LocalFormerMetaDataFolder -Recurse -Force -Confirm:$false
        Remove-Item -Path $ThisClusterSmartBundleFolderPath -Recurse -Force -Confirm:$false
        throw $_
    } finally {
        if ($Session) {
            $Session.Dispose()   
        }
    }

    if ($SpeedLimit) {
        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Reset meta data file to ",$TargetFolder," with speed limitation ", $SpeedLimit)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
        uploadToTargetVXM -LocalFilePath $LocalFormerMetaDataFilePath -VxMAddress $VxMAddress -VxMPort $VxMPort -VxMUsername $VxMUsername -VxMPassword $VxMPassword -SpeedLimit $SpeedLimit -TargetFolder $TargetFolder -ClusterLogPath $ThisClusterLogPath -SessionOption $SessionOption -OverrideMode "Overwrite"
    } else {
        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Reset meta data file to ",$TargetFolder)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
        uploadToTargetVXM -LocalFilePath $LocalFormerMetaDataFilePath -VxMAddress $VxMAddress -VxMPort $VxMPort -VxMUsername $VxMUsername -VxMPassword $VxMPassword -TargetFolder $TargetFolder -ClusterLogPath $ThisClusterLogPath -SessionOption $SessionOption -OverrideMode "Overwrite"
    }
    logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Reset Meta data to ",$TargetFolder," finished. Treat this cluster upload task finished. Begin to remove temporary files in local.")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
    Remove-Item -Path $LocalFormerMetaDataFolder -Recurse -Force -Confirm:$false
    Remove-Item -Path $ThisClusterSmartBundleFolderPath -Recurse -Force -Confirm:$false
    return New-Object PSObject -Property @{ 
        Success = $true
        ID = $ID
        VxMAddress = $VxMAddress
    }
}


#--------------Begin workflow----------------

#eg 0-172-16-10-200
$ThisClusterID = -Join($ID.ToString(), "-", ($VxMAddress.Replace('.','-').Replace(':','-')))
$ThisClusterLogPath = -Join($LogFilePath, $UploadLogPrefix, $ThisClusterID,".log")
#eg C:\User\user1\xxx\0-172-16-10-200\VXRAIL_COMPOSITE-7.0.350-xxxx_for_7.0.x.zip
$ThisClusterSmartBundlePath = $SmartBundleLocalPath + $ThisClusterID + '\' + ($CompositeBundleFilePath -split "\\")[-1]
$ThisClusterSmartBundleFolderPath = $SmartBundleLocalPath + $ThisClusterID + '\'
if (-not (Test-Path $ThisClusterSmartBundleFolderPath)) {
    New-Item -ItemType "directory" -Path $ThisClusterSmartBundleFolderPath | Out-Null
}
$CreateSmartBundleTryTimes = 1
$CreatedSmartBundle = $false
$SmartBundleFilePath = ""
$ReturnObject = ""

if ($IsBundleExisted) {
    # Found the bundle file, reset the VXMProcessed to false and skip upload again
    try {
        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Find existed bundle file on ",$VxMAddress,", just reset the meta data file.")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
        $ReturnObject = resetVXMProcessedInRemoteVXM -VxMAddress $VxMAddress -VxMUsername $VxMUsername -VxMPassword $VxMPassword -VxMPort $VxMPort -ClusterLogPath $ThisClusterLogPath -SMARTBundleFolderPath $ThisClusterSmartBundleFolderPath -TargetFolder $TargetFolder -SpeedLimit $SpeedLimit -SessionOption $SessionOption
        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Reset Meta data to ",$VxMAddress," workflow finished successfully.")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
    }
    catch {
        $ErrorMsg = "An error occurred reset meta data file in target cluster: "
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
        } else {
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
        }
        $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
        logInfo -LogFileName $ThisClusterLogPath -LogMsg $ErrorMsg -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
        $ReturnObject = New-Object PSObject -Property @{ 
            Success = $false
            ID = $ID
            VxMAddress = $VxMAddress
            ErrorMsg = -Join("Failed to reset meta data file on ",$VxMAddress,".")
        }
    }
    return $ReturnObject
}

#Create smart bundle for this cluster
while (($CreateSmartBundleTryTimes -lt 6) -and (!$CreatedSmartBundle)) {
    try {
        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Begin to create SMART bundle on ",$ThisClusterSmartBundlePath," with try times ", $CreateSmartBundleTryTimes.ToString())) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
        $SmartBundleFilePath = createSMARTBundle -Server $VxMAddress -VCAdminUsername $VCAdminUsername -VCAdminPassword $VCAdminPassword -CompositeBundleFilePath $CompositeBundleFilePath -ClusterLogPath $ThisClusterLogPath -LocalSmartTargetFilePath $ThisClusterSmartBundlePath
        $CreatedSmartBundle = $true
    } catch {
        $ErrorMsg = "An error occurred in creating SMART bundle: "
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
        } else {
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
        }
        $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
        logInfo -LogFileName $ThisClusterLogPath -LogMsg $ErrorMsg -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
        $CreateSmartBundleTryTimes += 1
    }
}

#Check if the SMART bundle created and go next
if (!$CreatedSmartBundle) {
    logInfo -LogFileName $ThisClusterLogPath -LogMsg "Failed to create SMART bundle, return error." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
    $ReturnObject = New-Object PSObject -Property @{ 
        Success = $false
        ID = $ID
        VxMAddress = $VxMAddress
        ErrorMsg = -Join("Failed to create SMART bundle on ",$VxMAddress,".")
    }
} else {
    if ($SmartBundleFilePath -and $SmartBundleFilePath -ne "") {
        $UploadSmartBundleTryTimes = 1
        $UploadedSmartBundle = $false
        # Clean up meta data and bundle files in the target vxm
        try{
            logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Try to clean up target vxm ",$VxMAddress," former upload bundle file and meta data file if exists")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
            cleanUpFilesInTargetVXM -SessionOption $SessionOption -TargetFolder $TargetFolder -SMARTBundleFolderPath $ThisClusterSmartBundleFolderPath -SpeedLimit $SpeedLimit
            logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Have cleaned up target vxm ",$VxMAddress," former upload bundle file and meta data file if exists")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
        } catch {
            $ErrorMsg = "An error occurred in cleaning former uploaded files in target vxm. Please remove manually if it is needed. Detail error: "
            $m1 = $_.Exception.message
            $m2 = $_
            if ($m1 -eq $m2){
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
            } else {
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
            }
            $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
            logInfo -LogFileName $ThisClusterLogPath -LogMsg $ErrorMsg -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
        }

        # Check the remote path volume to avoid upload timeout error when space is not enough under current vxm setting
        $SmartBundleFileSize = (Get-Item $SmartBundleFilePath).Length
        $SpaceEnough = $null
        try {
            logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Try to check available space for cluster ",$VxMAddress," path ", $TargetFolder)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
            $SpaceEnough = checkTargetFolderAvailableSpace -SessionOption $SessionOption -TargetFolder $TargetFolder -SmartBundleFileSize $SmartBundleFileSize
            if ($SpaceEnough) {
                logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Check space pass for ",$VxMAddress,". Continue upload process.")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
            } else {
                $RequiredSpace = $SmartBundleFileSize + 5242880
                logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("The available volume for ",$VxMAddress," path ", $TargetFolder," is not enough. Required available space is greater than ",$RequiredSpace.ToString()," bytes. Mark it as upload error at this time.")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
            }
        }
        catch {
            $ErrorMsg = "An error occurred in checking available space. Detail error: "
            $m1 = $_.Exception.message
            $m2 = $_
            if ($m1 -eq $m2){
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
            } else {
                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
            }
            $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
            logInfo -LogFileName $ThisClusterLogPath -LogMsg $ErrorMsg -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
        }

        if ($SpaceEnough) {
            while (($UploadSmartBundleTryTimes -lt 6) -and (!$UploadedSmartBundle)) {
                try {
                    logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Begin to upload SMART bundle on ",$ThisClusterSmartBundlePath," with try times ", $UploadSmartBundleTryTimes.ToString())) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)    
                    # Create meta bundle first. Get file name and file size
                    logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Created SMART bundle on ",$SmartBundleFilePath,". Begin to upload meta data file.")) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                    $MetaDataFileLocalPath = $SmartBundleLocalPath + $ThisClusterID + '\edge_metadata.json'
                    if (Test-Path $MetaDataFileLocalPath) {
                        logInfo -LogFileName $ThisClusterLogPath -LogMsg "Find former meta data file, remove it" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                        Remove-Item -Path $MetaDataFileLocalPath -Force -Confirm:$false
                    }

                    $MetaDataConent = MetaDataContent -BundleFileName (($CompositeBundleFilePath -split "\\")[-1]) -BundleFileSize $SmartBundleFileSize -BundleVersion $script:SystemVersion -VXMProcessed $false
                    logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Created meta data content, value is ",$MetaDataConent)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                    $MetaDataJson = $MetaDataConent | ConvertTo-Json
                    $MetaDataJson | Out-File $MetaDataFileLocalPath
                    logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Meta bundle file has been created on ",$MetaDataFileLocalPath)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                    if ($SpeedLimit) {
                        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Upload meta data file to ",$TargetFolder," with speed limitation ", $SpeedLimit)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                        uploadToTargetVXM -LocalFilePath $MetaDataFileLocalPath -VxMAddress $VxMAddress -VxMPort $VxMPort -VxMUsername $VxMUsername -VxMPassword $VxMPassword -SpeedLimit $SpeedLimit -TargetFolder $TargetFolder -ClusterLogPath $ThisClusterLogPath -SessionOption $SessionOption -OverrideMode "Overwrite"
                        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Meta data uploaded. Try to upload SMART bundle to ",$TargetFolder," with speed limitation ", $SpeedLimit)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                        uploadToTargetVXM -LocalFilePath $SmartBundleFilePath -VxMAddress $VxMAddress -VxMPort $VxMPort -VxMUsername $VxMUsername -VxMPassword $VxMPassword -SpeedLimit $SpeedLimit -TargetFolder $TargetFolder -ClusterLogPath $ThisClusterLogPath -SessionOption $SessionOption -OverrideMode "Resume"
                        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("SMART bundle has been uploaded to ",$TargetFolder," with speed limitation ", $SpeedLimit)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                        $UploadedSmartBundle = $true
                        $ReturnObject = New-Object PSObject -Property @{ 
                            Success = $true
                            ID = $ID
                            VxMAddress = $VxMAddress
                        }
                        break
                    } else {
                        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Upload meta data file to ",$TargetFolder)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                        uploadToTargetVXM -LocalFilePath $MetaDataFileLocalPath -VxMAddress $VxMAddress -VxMPort $VxMPort -VxMUsername $VxMUsername -VxMPassword $VxMPassword -TargetFolder $TargetFolder -ClusterLogPath $ThisClusterLogPath -SessionOption $SessionOption -OverrideMode "Overwrite"
                        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("Meta data uploaded. Try to upload SMART bundle to ",$TargetFolder)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                        uploadToTargetVXM -LocalFilePath $SmartBundleFilePath -VxMAddress $VxMAddress -VxMPort $VxMPort -VxMUsername $VxMUsername -VxMPassword $VxMPassword -TargetFolder $TargetFolder -ClusterLogPath $ThisClusterLogPath -SessionOption $SessionOption -OverrideMode "Resume"
                        logInfo -LogFileName $ThisClusterLogPath -LogMsg (-Join("SMART bundle has been uploaded to ",$TargetFolder)) -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
                        $UploadedSmartBundle = $true
                        $ReturnObject = New-Object PSObject -Property @{ 
                            Success = $true
                            ID = $ID
                            VxMAddress = $VxMAddress
                        }
                        break
                    }
                } catch {
                    $ErrorMsg = "An error occurred in uploading SMART bundle, Please double check cluster configuration file and target vxm environment. Detail error: "
                    $m1 = $_.Exception.message
                    $m2 = $_
                    if ($m1 -eq $m2){
                        $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
                    } else {
                        $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
                    }
                    $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
                    logInfo -LogFileName $ThisClusterLogPath -LogMsg $ErrorMsg -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
                    $UploadSmartBundleTryTimes += 1
                }
            }

            if (!$UploadedSmartBundle) {
                logInfo -LogFileName $ThisClusterLogPath -LogMsg "Failed to upload SMART bundle, return error." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
                $ReturnObject = New-Object PSObject -Property @{ 
                    Success = $false
                    ID = $ID
                    VxMAddress = $VxMAddress
                    ErrorMsg = -Join("Failed to upload SMART bundle on ",$VxMAddress,".")
                }
            }

            #Clean the local SMART bundle related file
            logInfo -LogFileName $ThisClusterLogPath -LogMsg "Begin to remove local SMART bundle and meta data file" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
            Remove-Item -Path $MetaDataFileLocalPath -Force -Confirm:$false
            Remove-Item -Path $SmartBundleFilePath -Force -Confirm:$false
            Remove-Item -Path $ThisClusterSmartBundleFolderPath -Recurse -Force -Confirm:$false
            logInfo -LogFileName $ThisClusterLogPath -LogMsg "Removed local SMART bundle and meta data file" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
        } else {
            $SpaceErrorMsg = ""
            if ($null -eq $SpaceEnough) {
                $SpaceErrorMsg = -Join("Meet error in check target upload path ",$TargetFolder," available space on ",$VxMAddress,", check related log for details.")
            } else {
                $RequiredSpace = $SmartBundleFileSize + 5242880
                $SpaceErrorMsg = -Join("Not enough space in target upload path ",$TargetFolder," on ",$VxMAddress,". Required available space is greater than ",$RequiredSpace.ToString(), " bytes. Please check environment.")
            }
            $ReturnObject = New-Object PSObject -Property @{ 
                Success = $false
                ID = $ID
                VxMAddress = $VxMAddress
                ErrorMsg = $SpaceErrorMsg
            }

            #Clean the local SMART bundle related file
            logInfo -LogFileName $ThisClusterLogPath -LogMsg "Begin to remove created SMART bundle" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine)
            Remove-Item -Path $SmartBundleFilePath -Force -Confirm:$false
            Remove-Item -Path $ThisClusterSmartBundleFolderPath -Recurse -Force -Confirm:$false
            logInfo -LogFileName $ThisClusterLogPath -LogMsg "Removed created SMART bundle" -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) 
        }
    } else {
        logInfo -LogFileName $ThisClusterLogPath -LogMsg "SMART bundle file path is empty, return error." -Name $LOG_THREAD_WORKFLOW -Line (getCurrentWorkflowLine) -ErrorLog
        $ReturnObject = New-Object PSObject -Property @{ 
            Success = $false
            ID = $ID
            VxMAddress = $VxMAddress
            ErrorMsg = -Join("SMART bundle file path is empty on ",$VxMAddress,", check related log for details.")
        }
    }
}

return $ReturnObject