# Copyright (c) 2015-2022 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

#Static field
$LOG_INFO = " INFO "
$LOG_WARN = " WARN "
$LOG_ERROR = " ERROR "

$reserved_bundle_type = @(
    'ESXi'
    'ESXi_VIB'
    'ESXI_VIB'
    'WITNESS'
    'BMC'
    'BIOS'
    'Backplane_Firmware'
    'BOSS_Firmware'
    'DCPM_Firmware'
    'DISK_CTLR_Firmware'
    'Disk_Firmware'
    'IDSDM_Firmware'
    'M2_SATA_Firmware'
    'NIC_Firmware'
    'PSU_Firmware'
    'M2_NVME_Firmware'
    'Chassis_Manager_Firmware'
    'Embedded_Witness_ESXi'
    'Witness_Manager'
    'Witness_M2_NVME_Firmware'
)

$reserved_bundle_name = @(
    'dcism'
    'dellptagent'
    'vmware-perccli64'
)

function ClusterInfo {
    param (
        $ID,
        $VxMAddress,
        $VxMPort,
        $VxMUsername,
        $VxMPassword,
        $VCAdminUsername,
        $VCAdminPassword,
        $SmartBundlePath,
        $SpeedLimit
    )
    $cluster = @{
        ID = $ID
        VxMAddress = $VxMAddress
        VxMPort=$VxMPort
        VxMUsername=$VxMUsername
        VxMPassword=$VxMPassword
        VCAdminUsername=$VCAdminUsername
        VCAdminPassword=$VCAdminPassword
        SpeedLimit=0
    }
    return $cluster
}

function ClusterUploadStatus {
    param (
        $ID,
        $VxMAddress,
        $Uploaded
    )
    $status = @{
        ID = $ID
        VxMAddress = $VxMAddress
        Uploaded = $Uploaded
    }
    return $status
}

function MetaDataContent {
    param (
        $BundleFileName,
        $BundleFileSize,
        $BundleVersion,
        $VXMProcessed
    )
    $content = @{
        BundleFileName = $BundleFileName
        BundleFileSize = $BundleFileSize
        BundleVersion = $BundleVersion
        VXMProcessed =$VXMProcessed
    }
    return $content
}



function VxRailComponet{
    param (
        $ComponentType,
        $SystemName,
        $Version,
        $Build,
        $NodeVendor,
        $NodeModel,
        $Model,
        $FilterFlag,
        $File
    )
    $component = @{ComponentType= $ComponentType
                                    SystemName= $SystemName
                                    Version= $Version
                                    Build= $Build
                                    NodeVendor= $NodeVendor
                                    NodeModel= $NodeModel
                                    Model= $Model
                                    FilterFlag= $FilterFlag
                                    File= $File}
    return $component
}

#------------Extract from Depot part to support SMART bundle generation-----------

function parsingXML{
    param ($Package, $array)
    foreach($item in $Package){
        $ComponentType = $item.ComponentType
        $SystemName = $item.SystemName
        $Version = $item.Version
        $Build = $item.Build
        $NodeVendor = $item.TargetHardwareInfo
        $File  = $item.File
        $NodeModle = @()
        $Model  = @()
        if ($item.TargetModelInfo.Model.Alias.Count -gt 0){
           foreach($i in $item.TargetModelInfo.Model){
               $NodeModle += $i.InnerText
           }
        }
        if ($item.TargetComponentModelInfo.Model.Count -gt 0){
            foreach($i in $item.TargetComponentModelInfo.Model){
               $Model += $i
           }
        }

        $component = VxRailComponet -ComponentType $ComponentType -SystemName $SystemName -Version $Version -Build $Build -NodeVendor $NodeVendor -NodeModel $NodeModle -Model $Model -FilterFlag '' -File $File
        $array += $component
    }
    return ,$array
}

function parsingLocalManifestFile {
    param (
        [parameter(Mandatory=$True,Position=1)] [String] $FilePath
    )
    $xml = New-Object -TypeName XML;
    if (-not (Test-Path $FilePath)){
        throw "manifest file does not exist"
    }
    $xml.Load($FilePath)
    $array = @()
    foreach($item in $xml.InstallManifest.Package){
       $array = parsingXML -Package $item -array $array
       foreach($i in $item.Package){
            $array = parsingXML -Package $i -array $array
       }
    }

    return ,$array
}

function getManifestSystemVersion {
    param (
        [parameter(Mandatory=$True,Position=1)] [String] $FilePath
    )
    $xml = New-Object -TypeName XML;
    if (-not (Test-Path $FilePath)){
        throw "manifest file does not exist"
    }
    $xml.Load($FilePath)
    return (-Join($xml.InstallManifest.Version,"-",$xml.InstallManifest.Build))
}

function ClusterTarget{
    param (
        $NodeVendorSet,
        $NodeModelSet,
        $ModelSet
    )
    $target =[PSCustomObject]@{NodeVendorSet= $NodeVendorSet
                                    NodeModelSet= $NodeModelSet
                                    ModelSet= $ModelSet}
    return $target
}

function parsingClusterTarget{
    param ($ResponseComponents)
    $nodeVendorSet = @{}
    $nodeModleSet = @{}
    $modeSet = @{}
    foreach ($rItem in $ResponseComponents){
        if ($rItem.NodeVendor -and -not $nodeVendorSet.ContainsKey($rItem.NodeVendor)){
            $nodeVendorSet.Add($rItem.NodeVendor, 1)
        }
        if ($rItem.NodeModel -and -not $nodeModleSet.ContainsKey($rItem.NodeModel)){
            $nodeModleSet.Add($rItem.NodeModel, 1)
        }
        if($rItem.Model){
            $modelArray = $rItem.Model -split ','
            foreach($item in $modelArray){
                $key = $item.Trim()
                if ($key -and -not $modeSet.ContainsKey($key)){
                    $modeSet.Add($key, 1)
                }
            }
        }
    }

    $target =  ClusterTarget -NodeVendorSet $nodeVendorSet -NodeModelSet $nodeModleSet -ModelSet $modeSet
    return $target
}

function versionCompare{
    param($v1,$v2)
    if(-not [String]::IsNullOrEmpty($v1)){
        if($v1.ToLower().CompareTo($v2.ToLower()) -eq 0){
            return 0;
        }
        if([String]::IsNullOrEmpty($v2)){
            return 1;
        }
        $v1Tokens = $v1 -split '\.'
        $v2Tokens = $v2 -split '\.'
        $len1 = $v1Tokens.Count;
        $len2 = $v2Tokens.Count;
        $index = 0
        for (;$len1 -gt $index -or $len2 -gt $index; ){

            if ($len1 -gt $index -and $len2 -gt $index){
                if($v1Tokens[$index] -match "^\d+$" -and $v2Tokens[$index] -match "^\d+$"){
                    $x = [int]$v1Tokens[$index]
                    $y = [int]$v2Tokens[$index]
                    if($x -ne $y){
                        if($x -gt $y){return 1}else{return -1}
                    }
                } else {
                  if($v1Tokens[$index] -ne $v2Tokens[$index]) {
                      return $v1Tokens[$index].CompareTo($v2Tokens[$index])
                  }
                }
                $index++
            } elseif($len1 -gt $index){
                return 1
            } else{
                return -1
            }

        }
        return 0
    } elseif(-not [String]::IsNullOrEmpty($v2)){
        return -1
    }

    return 0
}

function versionBuildCompare{
    param($v1,$b1,$v2,$b2)
    $vRet = versionCompare -v1 $v1 -v2 $v2
    if($vRet -eq 0){
        $bRet = versionCompare -v1 $b1 -v2 $b2
        return $bRet
    }
    return $vRet
}

function getDeleteBundlePathList{
    param ($ResponseComponents, $XmlComponents)

    $clusterTarget = parsingClusterTarget -ResponseComponents $ResponseComponents
    $nodeVendorSet = $clusterTarget.NodeVendorSet
    $nodeModleSet = $clusterTarget.NodeModelSet
    $modeSet = $clusterTarget.ModelSet
    $deleteBundleItems = @()
    $xmlComponentDoublecheckItems = @{}
    $mustHave = @{}
    foreach($xItem in $XmlComponents){
        $filter = $false
        if ($xItem.NodeVendor){
            $filter = -not $nodeVendorSet.ContainsKey($xItem.NodeVendor)
        }
        if ($xItem.NodeModel){
            $filter = $true
            foreach ($nodeModel in $xItem.NodeModel){
                if($nodeModleSet.ContainsKey($nodeModel)){
                    $filter = $false
                    break
                }
            }
        }
        # In this part, the manifest object has passed node model and vendor check. ESXI related must be included because of vlcm issue.
        # For the iDRAC issue, due to the install component missing firmwares issue, it will cause some iDRAC not included in mustHave. And also due to iDRAC file may be included in many manifest object,
        # which causes iDRAC is excluded by node model check. So as in this part, this iDRAC manifest is fit current model, add it to mustHave to avoid missing.
        # For PTAgent and ISM, with the information, there will be several versions which need both two version. As general logic can't deal with special cases, just keep all files.
        # For heterogeneous cluster node addition, keep most drivers and firmwares
        if ($xItem.ComponentType -in $reserved_bundle_type -or $xItem.SystemName -in $reserved_bundle_name) {
            if (!$mustHave.ContainsKey($xItem.File)) {
                $mustHave.Add($xItem.File, $true)
            }
        } elseif ($filter){
            $deleteBundleItems += $xItem
        } else {
            $key = -join($xItem.ComponentType, '-', $xItem.SystemName)
            $value = @()
            if($xmlComponentDoublecheckItems.ContainsKey($key)){
                $value = $xmlComponentDoublecheckItems[$key]
                $value += $xItem
                $xmlComponentDoublecheckItems[$key] = $value
            } else {
                $value += $xItem
                $xmlComponentDoublecheckItems.Add($key, $value)
            }
        }
    }

    # need double check left xml components
    foreach ($rItem in $responseComponents){
        $key = -join($rItem.ComponentType, '-', $rItem.SystemName)
        if($xmlComponentDoublecheckItems.ContainsKey($key)){
           $items = $xmlComponentDoublecheckItems[$key]
           foreach($item in $items){

                if ($rItem.FilterFlag){
                    $deleteBundleItems += $item
                    continue;
                }

                $vbc = versionBuildCompare -v1 $item.Version -b1 $item.Build -v2 $rItem.Version -b2 $rItem.Build
                if($vbc -eq 1 -and -not $mustHave.ContainsKey($item.File)){
                    $mustHave.Add($item.File, $true)
                } elseif($vbc -ne 1) {
                    $deleteBundleItems += $item
                }
           }
        }
    }

    $filePathSet = @{}
    foreach($item in $deleteBundleItems){
        if(-not $filePathSet.ContainsKey($item.File) -and -not $mustHave.ContainsKey($item.File)){
            $filePathSet.Add($item.File, $true)
        }
    }
    return $filePathSet.Keys
}

function parsingJSON{
    param($ret)
    $responseComponents = @()
    foreach($item in $ret){
        $component = VxRailComponet -ComponentType $item.component_type -SystemName $item.system_name -Version $item.version -Build $item.build -NodeVendor $item.node_vendor -NodeModel $item.node_model -Model $item.model -FilterFlag $item.filter  -File ''
        $responseComponents += $component;
    }
    return ,$responseComponents;
}

function getCurrentUtilsLine {
    return ($MyInvocation.ScriptlineNumber).ToString()
}


function smartBundleDeviceSpaceCheck {
    param($Times, $Source, $Target)
    $zipFileEntity = Get-Item $Source
    $deviceChar = ($Target -split ':')[0].Trim().ToUpper()
    $device = $deviceChar+':'
    $disk = Get-WmiObject Win32_LogicalDisk -ComputerName localhost -Filter "DeviceID='$device'"
    if($zipFileEntity.Length * $Times -gt $disk.FreeSpace){
        throw (-Join("There is not enough storage space under disk ", $deviceChar ," to complete generating SMART bundles with requested task number."))
    } else {
        $notice = -join("The target disk with tag ",$deviceChar," left space is : [",[int]($disk.FreeSpace/1024/1024/1024), "GB]")
    }
    return $notice;
}


#------------WinSCP related Part-----------

function createWinSCPSessionOption {
    param (
        [Parameter(Mandatory = $true)]
        # VxManager ip address or FQDN
        [string] $VxMAddress,
        [Parameter(Mandatory = $true)]
        # VxManager ssh username
        [string] $VxMUsername,
        [Parameter(Mandatory = $true)]
        # VxManager ssh password
        [string] $VxMPassword,
        [Parameter(Mandatory = $false)]
        # VxManager ssh port
        [string] $VxMPort
    )
    $secpass = $VxMPassword | ConvertTo-SecureString -AsPlainText -Force
    if ($VxMPort) {
        $sessionOption = New-WinSCPSessionOption -HostName $VxMAddress -Credential (New-Object System.Management.Automation.PSCredential($VxMUsername, $secpass)) -PortNumber $VxMPort
    } else {
        $sessionOption = New-WinSCPSessionOption -HostName $VxMAddress -Credential (New-Object System.Management.Automation.PSCredential($VxMUsername, $secpass))
    }
    $fingerPrint = Get-WinSCPHostKeyFingerprint -SessionOption $sessionOption -Algorithm "SHA-256"
    $sessionOption.SshHostKeyFingerprint = $fingerPrint
    return $sessionOption
}

function TestFileInRemote {
    param (
        [Parameter(Mandatory = $true)]
        # winscp session options
        $SessionOption,
        [Parameter(Mandatory = $true)]
        # To checked file path in VxManager
        [string] $TestFilePath
    )

    try {
        $Session = New-Object -TypeName WinSCP.Session -Property @{ExecutablePath = "$env:WinSCP_Path\winscp.exe"}
        $Session.Open($SessionOption)
        $TestResult = Test-WinSCPPath -WinSCPSession $Session -Path $TestFilePath
        return $TestResult
    } catch {
        throw $_
    } finally {
        $Session.Dispose()
    }
}

function checkTargetFolderInCSV {
    param (
        [Parameter(Mandatory = $true)]
        # VxManager ip address or FQDN
        [string] $VxMAddress,
        [Parameter(Mandatory = $true)]
        # VxManager ssh username
        [string] $VxMUsername,
        [Parameter(Mandatory = $true)]
        # VxManager ssh password
        [string] $VxMPassword,
        [Parameter(Mandatory = $false)]
        # VxManager ssh port
        [string] $VxMPort
    )

    try {
        $TestClusterSessionOptions = createWinSCPSessionOption -VxMAddress $Info.VxMAddress -VxMUsername $Info.VxMUsername -VxMPassword $Info.VxMPassword -VxMPort $Info.VxMPort
        $IsTargetFolderExist = TestFileInRemote -SessionOption $TestClusterSessionOptions -TestFilePath $Info.TargetFolder
        if (!$IsTargetFolderExist) {
            logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Target folder for cluster ",$Info.VxMAddress," is not found. Please check cluster and csv configuration file.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print -ErrorLog
            throw [System.IO.FileNotFoundException]::new("Target folder hasn't been found")
        }
    }
    catch {
        logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Failed to check target folder for cluster ",$Info.VxMAddress,". Please double check log and related cluster info and target folder setting in CSV configuration file. Detail stack trace refers to follow's message.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print -ErrorLog
        throw $_
    }

}

function cleanUpFilesInTargetVXM {
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
        [int] $SpeedLimit
    )
    # Check meta data file situation
    $LocalFormerMetaDataFolder = -Join($SMARTBundleFolderPath,"former-metadata")
    try {
        $VXMMetaDataFilePath = -Join($TargetFolder,"edge_metadata.json")
        $HasMetaData = TestFileInRemote -SessionOption $SessionOption -TestFilePath $VXMMetaDataFilePath
        if ($HasMetaData) {
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
            $FormerMetaData = (Get-Content $LocalFormerMetaDataFilePath) | ConvertFrom-Json
            $RemoteBundleFilePath = -Join($TargetFolder,$FormerMetaData.BundleFileName)
            $RemoteBundleFileResult = Test-WinSCPPath -WinSCPSession $Session -Path $RemoteBundleFilePath
            if ($RemoteBundleFileResult) {
                # Have found in remote file, remove it.
                Remove-WinSCPItem -WinSCPSession $Session -Path $RemoteBundleFilePath -Confirm:$false
                # Remove local former meta data file and related temp folder
                Remove-Item -Path $LocalFormerMetaDataFolder -Recurse -Force -Confirm:$false
            } else {
                # Haven't found in remote file, try to find if the filepart is existed and remove it
                $RemoteBundleFilePartPath = -Join($TargetFolder,$FormerMetaData.BundleFileName.replace('.zip','.zip.filepart'))
                $RemoteBundleFilePartResult = Test-WinSCPPath -WinSCPSession $Session -Path $RemoteBundleFilePartPath
                if ($RemoteBundleFilePartResult) {
                    # Have found in remote filepart, remove it.
                    Remove-WinSCPItem -WinSCPSession $Session -Path $RemoteBundleFilePartPath -Confirm:$false
                    # Remove local former meta data file and related temp folder
                    Remove-Item -Path $LocalFormerMetaDataFolder -Recurse -Force -Confirm:$false
                }
            }
        }
    } catch {
        Remove-Item -Path $LocalFormerMetaDataFolder -Recurse -Force -Confirm:$false
        throw $_
    } finally {
        if ($Session) {
            $Session.Dispose()
        }
    }
}

function checkTargetFolderAvailableSpace {
    param (
        [Parameter(Mandatory = $true)]
        # winscp session options
        $SessionOption,
        [Parameter(Mandatory = $true)]
        # Target Folder which contains meta data and bundle file
        [string] $TargetFolder,
        [Parameter(Mandatory = $true)]
        [long] $SmartBundleFileSize
    )
    try {
        $session = New-Object -TypeName WinSCP.Session -Property @{ExecutablePath = "$env:WinSCP_Path\winscp.exe"}
        $session.Open($sessionOption)
        $CheckCommand = -Join("df ",$TargetFolder," --output=avail --block-size=1")
        $DiskInfo = Invoke-WinSCPCommand -WinSCPSession $session -Command $CheckCommand
        $DiskInfo.Check()
        $CommandOutPut = $DiskInfo.Output
        $CommandOutPut = ($CommandOutPut.Trim()) -replace "Avail",""
        $MountDiskAvailableSize = [long] $CommandOutPut
        # With check available space change, it always need more volume than actually file size. (Several KB with experiment). So add 5MB buffer size for meta data file and this situation as ensurance
        $NeededSpace = $SmartBundleFileSize + 5242880
        if ($MountDiskAvailableSize -gt $NeededSpace) {
            return $true
        } else {
            return $false
        }
    }
    catch {
        throw $_
    } finally {
        if ($Session) {
            $Session.Dispose()
        }
    }
}

#------------Log part-------------
function logInfo {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $LogMsg,
        [Parameter(Mandatory=$true)]
        [String] $LogFileName,
        [Parameter(Mandatory=$true)]
        [String] $Line,
        [Parameter(Mandatory=$true)]
        [String] $Name,
        [Parameter(Mandatory=$false)]
        [Switch] $Print,
        [Parameter(Mandatory=$false)]
        [Switch] $ErrorLog,
        [Parameter(Mandatory=$false)]
        [Switch] $WarnLog
    )
    if ($print) {
        if ($ErrorLog) {
            Write-Host $LogMsg -ForegroundColor Red
        } elseif ($WarnLog) {
            Write-Host $LogMsg -ForegroundColor Yellow
        } else {
            Write-Host $LogMsg
        }
    }
    if ($ErrorLog) {
        $out = (Get-Date -Format o) + $LOG_ERROR + "[" + $Name + ":" + $Line + "] " + $LogMsg
    } elseif ($WarnLog) {
        $out = (Get-Date -Format o) + $LOG_WARN + "[" + $Name + ":" + $Line + "] " + $LogMsg
    } else {
        $out = (Get-Date -Format o) + $LOG_INFO + "[" + $Name + ":" + $Line + "] " + $LogMsg
    }
    $out | Out-File -FilePath $LogFileName -Append
}

