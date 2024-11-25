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

Retrieves VxRail cluster information and basic information about the appliances in the cluster.

.NOTES

You can run this cmdlet to retrieve VxRail cluster information and basic information about the appliances in the cluster.

.EXAMPLE

PS>Get-Cluster -Server <VxM IP or FQDN> -Username <username> -Password <password>

Retrieves VxRail cluster information and basic information about the appliances in the cluster.

#>
function Get-Cluster {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster"
    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth 4
        }
        return $ret
    } catch {
        write-host $_
    }

}


<#
.Synopsis
Shuts down a cluster or performs a shutdown dry run.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Dryrun
Perform a dry run to check whether it's safe to shut down. The default value is false.

.Notes
You can run this cmdlet to shut down a cluster or performs a shutdown dry run.

.Example
C:\PS>Start-ClusterShutdown -Server <vxm ip or FQDN> -Username <username> -Password <password>

Shut down a cluster.

.Example
C:\PS>Start-ClusterShutdown -Server <vxm ip or FQDN> -Username <username> -Password <password> -Dryrun

Shut down a cluster with dryrun.
#>
function Start-ClusterShutdown {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format,

        # Performs VxRail Cluster Shutdown dry run
        # Default is false.
        [Parameter(Mandatory = $false)]
        [Switch] $Dryrun
    )

    $uri = "/rest/vxm/v1/cluster/shutdown"

    # Body content to post and update
    $body = @{
        "dryrun" = if($Dryrun){"true"} else{"false"}
    } | ConvertTo-Json

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
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
Removes a host from the cluster.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter VcAdminUserUsername
Username of the vCenter Admin user account

.Parameter VcAdminUserPassword
Password of the vCenter Admin user account

.Parameter VcsaRootUserUsername
Username of the VCSA Root user.

.Parameter VcsaRootUserPassword
Password of the VCSA Root user.

.Parameter SerialNumber
Serial number of the host to be removed

.Notes
You can run this cmdlet to remove a host from the cluster.

.Example
C:\PS>Remove-ClusterHost -Server <vxm ip or FQDN> -Username <username> -Password <password> -vcAdminUserUsername <vc admin user username> -VcAdminUserPassword <vc admin user password> -VcsaRootUserUsername <vcsa root user username> -VcsaRootUserPassword <vcsa root user password> -SerialNumber <serial number>

Remove a host from cluster.
#>
function Remove-ClusterHost {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format,

        # Username of vcAdminUser
        [Parameter(Mandatory = $true)]
        [String] $VcAdminUserUsername,

        # Password of vcAdminUser
        [Parameter(Mandatory = $true)]
        [String] $VcAdminUserPassword,

        # Username of vcsaRootUser
        [Parameter(Mandatory = $true)]
        [String] $VcsaRootUserUsername,

        # Password of vcsaRootUser
        [Parameter(Mandatory = $true)]
        [String] $VcsaRootUserPassword,

        #serial number
        [Parameter(Mandatory = $true)]
        [String] $SerialNumber
    )

    $uri = "/rest/vxm/v1/cluster/remove-host"

    # Body content to post
    $body = @{
        "serial_number" = $SerialNumber
        "vc_admin_user" = @{
            "username" = $VcAdminUserUsername
            "password" = $VcAdminUserPassword
        }
        "vcsa_root_user" = @{
            "username" = $VcsaRootUserUsername
            "password" = $VcsaRootUserPassword
        }
    } | ConvertTo-Json

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $body
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
L2/L3 Node Expansion.

.Description
Starts an L2/L3 node expansion job with the provided NodeExpansionConfigFile.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter NodeExpansionConfigFile
Host configure json file for Node Expansion

.Parameter Format
Print JSON style format.

.Notes
L2/L3 node expansion, starts an expansion job based on the provided expansion spec.

.Example
Add-Host -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -NodeExpansionConfigFile <Json file to the path>

#>
function Add-Host {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # Valid vCenter username which has either Administrator or HCIA role
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $NodeExpansionConfigFile,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format

    )

    $uri = "/rest/vxm/v1/cluster/expansion"
    $url = "https://" + $Server + $uri
    $body = Get-Content $NodeExpansionConfigFile

    try {
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $body -ContentType "application/json"
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
       HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Do L2/L3 Node Expansion Validation.

.Description
Starts an L2/L3 node expansion validation job with the provided NodeExpansionConfigFile.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter NodeExpansionConfigFile
Host configure json file for Node Expansion

.Parameter Format
Print JSON style format.

.Notes
L2/L3 node expansion validation, starts an expansion validation job based on the provided expansion spec.

.Example
Add-HostValidate -Server <vxm ip or FQDN> -Username <username> -Password <password> -NodeExpansionConfigFile <Json file to the path>

#>
function Add-HostValidate {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,

        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $NodeExpansionConfigFile,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/cluster/expansion/validate"
    $url = "https://" + $Server + $uri
    $body = Get-Content $NodeExpansionConfigFile

    try {
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $body -ContentType "application/json"
        if ($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
       HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Cancel previous failed L2/L3 Node Expansion.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
You can run this cmdlet to cancel previous failed L2/L3 Host expansion.

.Example
C:\PS>Add-HostCancel -Server <vxm ip or FQDN> -Username <username> -Password <password>

Cancel previous failed L2/L3 Host expansion.
#>
function Add-HostCancel {
    param(
        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [String] $Server,

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

    $uri = "/rest/vxm/v1/cluster/expansion/cancel"

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password
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
Get the Layer3 segment info.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter Format
Print JSON style format.
.Example
C:\PS>Get-Layer3Segments -Server <vxm ip or FQDN> -Username <username> -Password <password>
Get the Layer3 segment info.
#>
function Get-Layer3Segments {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/cluster/layer3/segments"
    $url = Get-Url -Server $Server -Uri $uri

    try {
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.SYNOPSIS
Creates a new segment.
.PARAMETER Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.PARAMETER Conf
Required. Json configuration file as the body API
.Parameter Format
Print JSON style format.
.EXAMPLE
PS> Add-Layer3Segment -Server <VxM IP> -Username <username> -Password <password> -Conf <Json file to the path>
Creates a new segment.
#>
function Add-Layer3Segment {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $Conf,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()){
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/layer3/segment"
    $url = Get-Url -Server $Server -Uri $uri
    $body = Get-Content $Conf

    try {
         $response = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.Synopsis
Retrieves the segment configuration for a specific segment.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter SegmentLabel
Segment label of a specific segment.
.Parameter Format
Print JSON style format.
.Example
C:\PS>Get-Layer3SegmentByLabel -Server <vxm ip or FQDN> -Username <username> -Password <password> -SegmentLabel <segment label>
Retrieves the segment configuration for a specific segment.
#>
function Get-Layer3SegmentByLabel {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        # Segment label of a specific segment.
        [String] $SegmentLabel,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()){
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/layer3/segment/" + $SegmentLabel
    $url = Get-Url -Server $Server -Uri $uri

    try {
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.Synopsis
Retrieves the health status for a specific segment.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter SegmentLabel
Segment label of a specific segment.
.Parameter Format
Print JSON style format.
.Example
C:\PS>Get-Layer3SegmentHealth -Server <vxm ip or FQDN> -Username <username> -Password <password> -SegmentLabel <segment label>
Retrieves the health status for a specific segment.
#>
function Get-Layer3SegmentHealth {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        # Segment label of a specific segment.
        [String] $SegmentLabel,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    $uri = "/rest/vxm/v1/cluster/layer3/segment/" + $SegmentLabel + "/health"
    $url = Get-Url -Server $Server -Uri $uri

    try {
        $response = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    }
    catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.Synopsis
Changes the segment label for the current segment.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter SegmentLabel
Segment label of a specific segment.
.Parameter NewSegmentLabel
New segment label of the specific segment.
.Parameter Format
Print JSON style format.
.Example
C:\PS>Update-Layer3SegmentLabel -Server <vxm ip or FQDN> -Username <username> -Password <password> -SegmentLabel <segment label> -NewSegmentLabel <new segment label>
Changes the segment label for the current segment.
#>
function Update-Layer3SegmentLabel {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        # Segment label of a specific segment.
        [String] $SegmentLabel,

        [Parameter(Mandatory = $true)]
        # New segment label of the specific segment.
        [String] $NewSegmentLabel,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()){
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/layer3/segment/" + $SegmentLabel
    $url = Get-Url -Server $Server -Uri $uri

    # Body content to patch
    $body = @{
    }
    $vcenter = @{
    }
    $body.add("segment_label", $NewSegmentLabel)
    $body.add("vcenter", $vcenter)
    $body.vcenter.add("username",$Username)
    $body.vcenter.add("password",$Password)
    $body = $body | ConvertTo-Json

    try{
        $response = doPatch -Server $server -Api $uri -Username $username -Password $password -Body $body
        if($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.SYNOPSIS
Updates the segment configuration for a specific segment.
.PARAMETER Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter SegmentLabel
Segment label of a specific segment.
.PARAMETER Conf
Required. Json configuration file as the body of API
.Parameter Format
Print JSON style format.
.EXAMPLE
PS> Update-Layer3Segment -Server <VxM IP> -Username <username> -Password <password> -Conf <Json file to the path>
Updates the segment configuration for a specific segment.
#>
function Update-Layer3Segment {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        # Segment label of a specific segment.
        [String] $SegmentLabel,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        # Json configuration file
        [String] $Conf,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()){
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/layer3/segment/" + $SegmentLabel
    $url = Get-Url -Server $Server -Uri $uri
    $body = Get-Content $Conf

    try {
        $response = doPost -Server $server -Api $uri -Username $username -Password $password -Body $body
        if ($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.Synopsis
Deletes a segment.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter SegmentLabel
Segment label of a specific segment.
.Parameter Format
Print JSON style format.
.Example
C:\PS>Remove-Layer3Segment -Server <vxm ip or FQDN> -Username <username> -Password <password> -SegmentLabel <segment label>
Deletes a segment.
#>
function Remove-Layer3Segment {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [String] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        # Segment label of a specific segment.
        [String] $SegmentLabel,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format
    )

    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()){
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/layer3/segment/" + $SegmentLabel
    $url = Get-Url -Server $Server -Uri $uri

    try{
        $response = doDelete -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $response = $response | ConvertTo-Json
        }
        return $response
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}


function ValidateHosts {
    param(
        [object[]] $Hosts,
        [System.Collections.ArrayList] $FailedList
    )

    if ($Hosts) {
        foreach($node in $Hosts) {
            if (($node.customer_supplied -And $node.host_psnt -And !$FailedList.Contains("customer_supplied or host_psnt"))) {
                Write-Host "either customer_supplied or host_psnt is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("customer_supplied or host_psnt") > $null
            }
            if (!$node.customer_supplied -And !$node.host_psnt -And !$FailedList.Contains("customer_supplied and host_psnt")) {
                Write-Host "customer_supplied and host_psnt are not allowed both to have values." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("customer_supplied and host_psnt") > $null
            }
            if(! $node.hostname -And !$FailedList.Contains("hostname")) {
                Write-Host "hostname is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("hostname") > $null
            }
            if(!$node.accounts -And !$FailedList.Contains("accounts")) {
                Write-Host "accounts is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("accounts") > $null
            }
            if( $node.accounts -And !$node.accounts.root -And !$FailedList.Contains("accounts.root")) {
                Write-Host "accounts.root is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("accounts.root") > $null
            }
            if( $node.accounts -And $node.accounts.root -And !$node.accounts.root.username -And !$FailedList.Contains("accounts.root.username")) {
                Write-Host "accounts.root.username is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("accounts.root.username") > $null
            }
            if( $node.accounts -And $node.accounts.root -And !$node.accounts.root.password -And !$FailedList.Contains("accounts.root.password")) {
                Write-Host "accounts.root.password is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("accounts.root.password") > $null
            }
            if( $node.accounts -And !$node.accounts.management -And !$FailedList.Contains("accounts.management")) {
                Write-Host "accounts.management is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("accounts.management") > $null
            }
            if( $node.accounts -And $node.accounts.management -And !$node.accounts.management.username -And !$FailedList.Contains("accounts.management.username")) {
                Write-Host "accounts.management.username is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("accounts.management.username") > $null
            }
            if( $node.accounts -And $node.accounts.management -And !$node.accounts.management.password -And !$FailedList.Contains("accounts.management.password")) {
                Write-Host "accounts.management.password is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("accounts.management.password") > $null
            }
            if(! $node.network -And !$FailedList.Contains("network")) {
                Write-Host "network is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("network") > $null
            }

            if(! $node.nic_mappings -And !$FailedList.Contains("nic_mappings")) {
                Write-Host "nic_mappings is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                $FailedList.Add("nic_mappings") > $null
            }
            if($node.nic_mappings) {
                foreach($nic_mapping in $node.nic_mappings) {
                    if(! $nic_mapping.vds_name -And !$FailedList.Contains("nic_mapping.vds_name")) {
                        Write-Host "nic_mapping.vds_name is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                        $FailedList.Add("nic_mapping.vds_name") > $null
                    }
                    if(! $nic_mapping.name -And !$FailedList.Contains("nic_mapping.name")) {
                        Write-Host "nic_mapping.name is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                        $FailedList.Add("nic_mapping.name") > $null
                    }
                    if(! $nic_mapping.physical_nic -And !$FailedList.Contains("nic_mapping.physical_nic")) {
                        Write-Host "nic_mapping.physical_nic is not allowed empty." -ForegroundColor Red -BackgroundColor Black
                        $FailedList.Add("nic_mapping.physical_nic") > $null
                    }
                }
            }
        }
    }
}


function Get-Url{
        param(
        [String] $Server,

        [String] $Uri
    )
    if ($Server -match $IPV6_PATTERN) {
        return "https://" + "[" + $Server + "]" + $Uri
    }else{
        return "https://" + $Server + $Uri
    }
}
