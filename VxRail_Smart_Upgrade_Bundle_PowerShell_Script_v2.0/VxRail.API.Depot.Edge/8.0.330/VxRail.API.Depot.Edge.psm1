# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Depot.Edge.Common\" + $currentVersion + "\VxRail.API.Depot.Edge.Common.ps1"
$lcmUtilPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Depot.Edge\" + $currentVersion + "\VxRail.API.Depot.Edge.Utils.ps1"

$LOG_THREAD_NAME_MAIN = "MAIN"

. "$lcmUtilPath"

function getCurrentLine {
    return ($MyInvocation.ScriptlineNumber).ToString()
}

<# 
Example: 
Send-SMARTBundle -ConfigFilePath "C:\Users\user1\Documents\configClusters.csv" -CompositeBundleFilePath "C:\Users\user1\Documents\VXRAIL_COMPOSITE-7.0.300-27204669_for_7.0.x.zip" -SmartBundleLocalPath "C:\Users\user1\Documents\" -TaskNum 2
#>
function Send-SMARTBundle {
    param (
        [Parameter(Mandatory = $true)]
        # Cluster configuration file local path
        [string] $ConfigFilePath,
        [Parameter(Mandatory = $true)]
        # upgrade bundle file path
        [String] $CompositeBundleFilePath,
        [Parameter(Mandatory = $true)]
        # Smart bundle local parent folder
        [String] $SmartBundleLocalPath,
        # Task numbers to run at same time
        [Parameter(Mandatory = $true)]
        [Int32] $TaskNum
    )

    # Init jobs project first in order the finally clean up
    $Jobs = New-Object System.Collections.ArrayList
    $AllClusterUploaded = $false

    try {
        #Input validation
        if(-not (Test-Path $ConfigFilePath)) {
            throw "Cluster configuration file is not found"
        }
        if(-not $ConfigFilePath.EndsWith(".csv")) {
            throw "Cluster configuration file is invalid"
        }
        if(-not (Test-Path $CompositeBundleFilePath)) {
            throw "Source file is not found"
        }
        if(-not $CompositeBundleFilePath.EndsWith(".zip")) {
            throw "Source file is invalid"
        }

        #Create winscp session for this cluster
        if (-Not [Environment]::GetEnvironmentVariable("WinSCP_Path", "machine")) {
            $getPath = Read-Host -Prompt "Provide WinSCP Executable Path"
            [Environment]::SetEnvironmentVariable("WinSCP_Path", $getPath, "machine")
            $env:WinSCP_Path = [Environment]::GetEnvironmentVariable("WinSCP_Path", "machine")
        }

        #Prepare parent folder
        $UserFolder = $env:UserName
        $LogFilePath = -Join("C:\Users\",$UserFolder,"\Documents\VxrailBundleLog\")
        if (-not (Test-Path $LogFilePath)) {
            New-Item -ItemType "directory" -Path $LogFilePath | Out-Null
        }

        if ($SmartBundleLocalPath -notmatch "\\$") {
            $SmartBundleLocalPath += "\"
        }
        
        if (-not (Test-Path $SmartBundleLocalPath)) {
            New-Item -ItemType "directory" -Path $SmartBundleLocalPath | Out-Null
        }

        $UploadProcessLogPath = -Join($LogFilePath,"bundle_upload.log")

        $SpaceBufferTimes = 2.5 * $TaskNum
        $message = smartBundleDeviceSpaceCheck -Source $CompositeBundleFilePath -Target $SmartBundleLocalPath -Times $SpaceBufferTimes
        logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join($message," Begin to do the process.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print

        # Read csv configuration
        $Contents=Import-Csv $ConfigFilePath
        $Clusters=@()
        $ClustersUploadStatus=@()
        if ($Contents -is [Array]) {
            for ($i = 0; $i -lt $Contents.Count; $i++) {
                $Info = ClusterInfo -ID $i -VxMAddress $Contents[$i].VxMAddress -VxMUsername $contents[$i].VxMUsername -VxMPassword $Contents[$i].VxMPassword -VCAdminUsername $Contents[$i].VCAdminUsername -VCAdminPassword $Contents[$i].VCAdminPassword
                if ($Contents[$i].SpeedLimit) {
                    $Info.SpeedLimit = $Contents[$i].SpeedLimit
                }
                if ($Contents[$i].TargetFolder) {
                    if ($Contents[$i].TargetFolder -notmatch '\/$') {
                        $Info.TargetFolder = $Contents[$i].TargetFolder + "/"
                    } else {
                        $Info.TargetFolder = $Contents[$i].TargetFolder
                    }
                } else {
                    $Info.TargetFolder = "/home/mystic/vxrail_smart_bundles/"
                }

                if ($Contents[$i].VxMPort) {
                    $Info.VxMPort = $Contents[$i].VxMPort
                } else {
                    $Info.VxMPort = "22"  
                }

                # Validate whether session is valid and target folder is existed
                checkTargetFolderInCSV -VxMAddress $Info.VxMAddress -VxMUsername $Info.VxMUsername -VxMPassword $Info.VxMPassword -VxMPort $Info.VxMPort

                $Clusters = $Clusters + $Info
                $ClusterUploadStatus = ClusterUploadStatus -ID $i -VxMAddress $Contents[$i].VxMAddress -Uploaded $false
                $ClustersUploadStatus = $ClustersUploadStatus + $ClusterUploadStatus
            }
        } else {
            #Only one cluster need to deal
            $Info = ClusterInfo -ID 0 -VxMAddress $Contents.VxMAddress -VxMPort $Contents.VxMPort -VxMUsername $Contents.VxMUsername -VxMPassword $Contents.VxMPassword -VCAdminUsername $Contents.VCAdminUsername -VCAdminPassword $Contents.VCAdminPassword
            if ($Contents.SpeedLimit) {
                $Info.SpeedLimit = $Contents.SpeedLimit
            }
            if ($Contents.TargetFolder) {
                if ($Contents.TargetFolder -notmatch '\/$') {
                    $Info.TargetFolder = $Contents.TargetFolder + "/"
                } else {
                    $Info.TargetFolder = $Contents.TargetFolder
                }
            } else {
                $Info.TargetFolder = "/home/mystic/vxrail_smart_bundles/"
            }

            if ($Contents.VxMPort) {
                $Info.VxMPort = $Contents.VxMPort
            } else {
                $Info.VxMPort = "22"  
            }

            # Validate whether session is valid and target folder is existed
            checkTargetFolderInCSV -VxMAddress $Info.VxMAddress -VxMUsername $Info.VxMUsername -VxMPassword $Info.VxMPassword -VxMPort $Info.VxMPort

            $Clusters = $Clusters + $Info
            $ClusterUploadStatus = ClusterUploadStatus -ID 0 -VxMAddress $Contents.VxMAddress -Uploaded $false
            $ClustersUploadStatus = $ClustersUploadStatus + $ClusterUploadStatus
        }

        #Begin to trigger multi-threads upload
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $TaskNum)
        $RunspacePool.Open()

        $ExecutionPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Depot.Edge\" + $currentVersion + "\VxRail.API.Depot.Edge.Upload.ps1"
        $LCMUtilPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Depot.Edge\" + $currentVersion + "\VxRail.API.Depot.Edge.Utils.ps1"
        $ScriptBlock = [System.IO.File]::ReadAllText($ExecutionPath)
        
        $OverallTry = 1;
        while ($true) {
            $UnfinishedClustersCount = ($ClustersUploadStatus | Where {!$_.Uploaded}).Length
            if ($UnfinishedClustersCount -eq 0) {
                logInfo -LogFileName $UploadProcessLogPath -LogMsg "All the clusters are uploaded, this function is finished." -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                $AllClusterUploaded = $true
                break
            }
            else {
                #Re-init the jobs array in new try
                $Jobs.Clear()
                $Jobs.TrimToSize()
                logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Begin upload process. The overall try is ",$OverallTry)) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                foreach($ClusterInfo in $Clusters) {
                    $ThisClusterStatus = $ClustersUploadStatus | Where {$_.ID -eq $ClusterInfo.ID}
                    if ($ThisClusterStatus.Uploaded) {
                        logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("The cluster ",$ClusterInfo.ID,"-",$ClusterInfo.VxMAddress," SMART bundle has been uploaded" )) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                    } else {
                        #Judge if the bundle has already been uploaded in server side
                        $TempSplit = $CompositeBundleFilePath -split "\\"
                        $TestFilePath = -Join($ClusterInfo.TargetFolder,$TempSplit[-1])
                        
                        $IsBundleExisted = $false
                        $ThisClusterSessionOptions = $null
                        try {
                            $ThisClusterSessionOptions = createWinSCPSessionOption -VxMAddress $ClusterInfo.VxMAddress -VxMUsername $ClusterInfo.VxMUsername -VxMPassword $ClusterInfo.VxMPassword -VxMPort $ClusterInfo.VxMPort
                            $IsBundleExisted = TestFileInRemote -SessionOption $ThisClusterSessionOptions -TestFilePath $TestFilePath
                            if ($IsBundleExisted) {
                                logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Find bundle in cluster",$ClusterInfo.ID,"-",$ClusterInfo.VxMAddress,". Only will reset the meta data file.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                            }
                        } catch {
                            $ErrorMsg = "An error occurred: "
                            $m1 = $_.Exception.message
                            $m2 = $_
                            if ($m1 -eq $m2){
                                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
                            } else {
                                $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
                            }
                            $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
                            logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Check the file exists on target vxm failed, detail: ",$ErrorMsg)) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine)
                            logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Check the file exists on ",$ClusterInfo.ID,"-",$ClusterInfo.VxMAddress," failed. Detail refer to log file. Treat it as not exists in this try." )) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                        }

                        if ($ThisClusterSessionOptions) {
                            #Upload process begin
                            logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Begin to trigger upload for cluster ",$ClusterInfo.ID,"-",$ClusterInfo.VxMAddress)) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                            $PowerShell = [powershell]::Create()
                            $PowerShell.RunspacePool = $RunspacePool

                            $Job = $PowerShell.AddScript($ScriptBlock).AddParameters($ClusterInfo).AddParameter("LCMUtilPath",$LCMUtilPath).AddParameter("CompositeBundleFilePath",$CompositeBundleFilePath).AddParameter("LogFilePath",$LogFilePath).AddParameter("CommonPath",$commonPath).AddParameter("SmartBundleLocalPath",$SmartBundleLocalPath).AddParameter("SessionOption",$ThisClusterSessionOptions).AddParameter("IsBundleExisted",$IsBundleExisted)
                            $JobObj = New-Object -TypeName PSObject -Property @{
                                Job = $Job
                                Result = $PowerShell.BeginInvoke()
                                PowerShell = $PowerShell
                                ClusterIP = $ClusterInfo.VxMAddress
                            }
                            $Jobs.Add($JobObj) | Out-Null
                            logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Has add upload task for cluster ",$ClusterInfo.ID,"-",$ClusterInfo.VxMAddress," to thread pool succesfully and wait to be triggered by thread pool. Please check the related log under ",$LogFilePath," for detail progress if needed.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                        } else {
                            logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Cluster ",$ClusterInfo.ID,"-",$ClusterInfo.VxMAddress," failed to get session information. Maybe it has network issue. Please check. In this try time, it won't be added to upload tasks pool.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print -WarnLog
                        }
                    }
                }
        
                #Monitor uploading thread finish situation
                $UnfinishedCount = -1
                $LoggedClusterInThisTry = @()
                while ($Jobs -and $UnfinishedCount -ne 0) {
                    $UnfinishedTasks = ($Jobs | Where {$_.Result.IsCompleted -ne $true})
                    if ($UnfinishedTasks) {
                        if ($UnfinishedTasks -is [Array]) {
                            $UnfinishedCount = $UnfinishedTasks.Count
                        } else {
                            # In only one record, it will tranfers to a map object
                            $UnfinishedCount = 1   
                        }   
                    } else {
                        $UnfinishedCount = 0
                    }
                    logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Remaining tasks: ",$unfinishedCount)) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                    $Finished = ($Jobs | Where {$_.Result.IsCompleted -eq $true})
                    foreach ($r in $Finished) {
                        $Result = $r.Job.EndInvoke($r.Result)
                        
                        $r.PowerShell.Dispose()
                        
                        if ($Result.Success) {
                            if (!$LoggedClusterInThisTry.Contains($Result.ID)) {
                                $ThisClusterStatus = $ClustersUploadStatus | Where {$_.ID -eq $Result.ID}
                                $ThisClusterStatus.Uploaded = $true
                                $ClustersUploadStatus[$Result.ID] = $ThisClusterStatus
                                logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Cluster whose ID is ",$Result.ID," and cluster address is ",$Result.VxMAddress," has been uploaded successfully.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                                $LoggedClusterInThisTry += $Result.ID   
                            }
                        } 
                        else {
                            if (!$LoggedClusterInThisTry.Contains($Result.ID)) {
                                if ($Result.ErrorMsg -and "" -ne $Result.ErrorMsg) {
                                    logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Cluster whose ID is ",$Result.ID," and cluster address is ",$Result.VxMAddress," upload failed. Meets general error: ",$Result.ErrorMsg,". Detail please check related log.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print -ErrorLog
                                } else {
                                    logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("Cluster whose ID is ",$Result.ID," and cluster address is ",$Result.VxMAddress," upload failed. Detail please check related log.")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print -ErrorLog
                                }
                                $LoggedClusterInThisTry += $Result.ID
                            }
                        }
                    }
                    if ($UnfinishedCount -ne 0) {
                        Start-Sleep -seconds 300   
                    }
                }
                $OverallTry += 1       
            }
            
        }

    } catch {
        $ErrorMsg = "An error occurred: "
        $m1 = $_.Exception.message
        $m2 = $_
        if ($m1 -eq $m2){
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1)
        } else {
            $ErrorMsg = -Join($ErrorMsg,"`r`n",$m1,"`r`n",$m2)
        }
        $ErrorMsg = -Join($ErrorMsg,"`r`nDetail stack trace: `r`n",$_.ScriptStackTrace)
        if (!$UploadProcessLogPath) {
           Write-Host "LogFile path hasn't been inited, the following error message won't be contained in log. Please aware." -ForegroundColor Red
           Write-Host $ErrorMsg -ForegroundColor Red
        } else {
            logInfo -LogFileName $UploadProcessLogPath -LogMsg $ErrorMsg -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print -ErrorLog
        }
    } finally {
        if ($Jobs -and $Jobs.Count -gt 0 -and !$AllClusterUploaded) {
            $ToDealedTasks = @()
            $UnfinishedTasks = ($Jobs | Where {$_.Result.IsCompleted -ne $true})
            if ($UnfinishedTasks) {
                if ($UnfinishedTasks -is [Array]) {
                    $ToDealedTasks = $UnfinishedTasks
                } else {
                    # In only one record, it will tranfers to a map object
                    $ToDealedTasks += $UnfinishedTasks
                }   
            }

            logInfo -LogFileName $UploadProcessLogPath -LogMsg "The main command is stopped by error or user cancel action, will terminate all running or to be run tasks. It may cost few minutes, please wait." -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print

            foreach ($t in $ToDealedTasks) {
                logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("The cluster ",$t.ClusterIP," task hasn't been completed, terminate it")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
                $t.PowerShell.Dispose()
                logInfo -LogFileName $UploadProcessLogPath -LogMsg (-Join("The cluster ",$t.ClusterIP," task terminates complete")) -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
            }

            logInfo -LogFileName $UploadProcessLogPath -LogMsg "All unfinished tasks terminated" -Name $LOG_THREAD_NAME_MAIN -Line (getCurrentLine) -Print
        }
    }
}




