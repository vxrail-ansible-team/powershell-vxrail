# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.


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
    $component =[PSCustomObject]@{ComponentType= $ComponentType
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

function ClusterNode{
    param (
        $Vendor,
        $Model
    )
    $clusterNode =[PSCustomObject]@{Vendor = $Vendor
                                    Model= $Model}
    return $clusterNode
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
function parsingJSON{
    param($ret)
    $responseComponents = @()
    foreach($item in $ret){
        $component = VxRailComponet -ComponentType $item.component_type -SystemName $item.system_name -Version $item.version -Build $item.build -NodeVendor $item.node_vendor -NodeModel $item.node_model -Model $item.model -FilterFlag $item.filter  -File ''
        $responseComponents += $component;
    }
    return ,$responseComponents;
}

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

function parsingManifestFile {
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

function getDeleteBundlePathList{
    param ($ResponseComponents, $XmlComponents)
    
    $clusterTarget = parsingClusterTarget -ResponseComponents $ResponseComponents
    $nodeVendorSet = $clusterTarget.NodeVendorSet
    $nodeModleSet = $clusterTarget.NodeModelSet
    $modeSet = $clusterTarget.ModelSet
    $deleteBundleItems = @()
    $xmlComponentDoublecheckItems = @{}
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
        if ($filter){
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
    $mustHave = @{}
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
function prepareDir{
    param($Path)
    if (Test-Path $Path) {
		Remove-Item $Path
        Write-Host 'clean path:'$Path
    }
    mkdir -Path $Path | Out-Null
}

function bufferSize{
    param ($File)
    $fileMBSize = [int]($File.Length/1mb)
    if ($fileMBSize -gt 20){
        return 20mb
    } else {
        return $File.Length  
    }
}

function getOffset{
    param (
        [parameter(Mandatory=$True,Position=1)] [System.URI] $Server,
        [parameter(Mandatory=$True,Position=2)] [String] $Uri,
        [parameter(Mandatory=$True,Position=3)] [String] $Username,
        [parameter(Mandatory=$True,Position=4)] [String] $Password,
        [parameter(Mandatory=$True,Position=5)] [String] $FileName
    )
    $response = doGet -Server $Server -Api $Uri -Username $Username -Password $Password
    $status = $response.lcm_state
    $restartStates = @('NONE', 'RECEIVED', 'DOWNLOAD_ERROR', 'NORMAL_UPLOAD_ERROR', 'RESUMABLE_UPLOAD_ERROR', 'UPGRADE_ABORTED')
    $responseFileName = $response.file_name;
    if($restartStates -contains $status){
        return 0
    } elseif($status -eq 'RESUMABLE_UPLOADING_PARTIAL'){
        if ($responseFileName -and $responseFileName -ne $FileName) {
            return 0
        }
        return ($response.range -split '-')[0] 
    }
    throw "can not upload upgrade bundle"
}

function canDeleteRemoteBundle{
    param (
        [parameter(Mandatory=$True,Position=1)] [System.URI] $Server,
        [parameter(Mandatory=$True,Position=2)] [String] $Uri,
        [parameter(Mandatory=$True,Position=3)] [String] $Username,
        [parameter(Mandatory=$True,Position=4)] [String] $Password
    )
    $response = doGet -Server $Server -Api $Uri -Username $Username -Password $Password
    $status = $response.lcm_state
    $restartStates = @('RECEIVED', 'DOWNLOAD_ERROR', 'NORMAL_UPLOADING_ERROR', 'RESUMABLE_UPLOADING_ERROR', 'RESUMABLE_UPLOADING_PARTIAL')
    if($restartStates -contains $status){
        return $true
    } else {
        return $false
    }
}

function resetBuffesrSize{
    param($Stream, $Offset, $ReadBufferSize)
    if (($ReadBufferSize+$Offset) -ge ($Stream.Length-1)) {
        $ReadBufferSize = $Stream.length-$Offset;
    }
    return $ReadBufferSize

}


function infoMessage{
    param($Message)
    Write-Host $Message
}

function erroMessage{
    param($Message)
    Write-Host $Message -ErrorAction Stop
}

function generateItem{
    param($Item, $HasConfig)
    $default = 'repleace-this-message'
    $ATTRIBUTE_TYPE = @('TEXT', 'PASSWORD', 'IP', 'BOOLEAN')
    $ATTRIBUTE_SHOW_TYPE = @('REF')
    $result = @{}

    if($Item.attributes.Count -gt 0){
        $r = @{}
        foreach($i in $Item.attributes){
            $tmp = generateItem -Item $i -HasConfig $HasConfig
            if ($null -ne $tmp) {
                $r += $tmp
            }
        }
        if($r.Keys.Count -gt 0){
            $result += @{$Item.id=$r}
        }
    }elseif($ATTRIBUTE_TYPE -contains $item.type.ToUpper()){
        $key = $item.id;
        if($HasConfig){
            $value = $default
        }elseif ($Item.type.ToUpper() -eq 'PASSWORD'){
            $temp = Read-Host $Item.description -AsSecureString
            $value =  [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($temp))
        }elseif($Item.type.ToUpper() -eq 'BOOLEAN'){
            while($true){
                $temp = Read-Host $Item.description'[true/false]'
                if($temp.ToUpper() -eq 'true' -or $temp.ToUpper() -eq 'false'){
                    $value = $temp.toLower()
                    break
                }
            }
        }else{
            $value = Read-Host $Item.description
        }
        return @{$key = $value}
    }elseif($ATTRIBUTE_SHOW_TYPE -contains $item.type.ToUpper()){
        $message = -join($Item.description, ": ", $Item.value)
        Write-Host $message
        return $null
    }
    return $result
}

function configSetup{
    param($Config, $Table)
    $configFile = Get-Content $Config
    foreach($line in $configFile){
        $kv = $line -split '='
        if($kv.Count -lt 2){
            erroMessage -Message 'config file is not correct'
        }
        $value = $kv[1];
        $keys = $kv[0] -split '\.'
        $t = $table
        for($index=0; ;$index++){
            if($index -eq $keys.Count-1){
                $t[$keys[$index]] = $value
                break;
            }else{
                $t = $t[$keys[$index]]
            }   
        }
    }
    return $table
}
