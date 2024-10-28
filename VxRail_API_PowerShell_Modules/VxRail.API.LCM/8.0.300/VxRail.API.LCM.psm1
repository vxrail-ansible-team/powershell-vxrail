# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

$currentPath = $PSScriptRoot.Substring(0,$PSScriptRoot.LastIndexOf("\"))
$currentVersion = $PSScriptRoot.Substring($PSScriptRoot.LastIndexOf("\") + 1, $PSScriptRoot.Length - ($PSScriptRoot.LastIndexOf("\") + 1))
$commonPath = $currentPath.Substring(0,$currentPath.LastIndexOf("\")) + "\VxRail.API.Common\" + $currentVersion + "\VxRail.API.Common.ps1"

. "$commonPath"

# Add-Type -AssemblyName System.IO.Compression.FileSystem
# Add-Type -AssemblyName System.Text.Encoding
# class FixedEncoder : System.Text.UTF8Encoding {
#     FixedEncoder() : base($true) { }

#     [byte[]] GetBytes([string] $s)
#     {
#         $s = $s.Replace('\', '/');
#         return ([System.Text.UTF8Encoding]$this).GetBytes($s);
#     }
# }

<#
.Synopsis
Upgrades all VxRail software and hardware.

.Parameter Version
Optional. API version. Only input v1 or v2 or v3. Default value is v1.

.Parameter Server
Required. VxM IP or FQDN.

.Parameter Username
Required. Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Required. Use corresponding password for username. 

.Parameter BundleFilePath
Required. Full path of the upgrade bundle

.Parameter VxmRootUsername
Optional. Username of VxRail Manager root user. Default is root.

.Parameter VxmRootPassword
Required. Password of VxRail Manager root user

.Parameter VcAdminUsername
Required. Username for vCenter Admin user

.Parameter VcAdminPassword
Required. Password for vCenter Admin user

.Parameter VcsaRootUsername
Username for VCSA Root user. Required if the upgrade bundle contains vcenter component

.Parameter VcsaRootPassword
Password for VCSA Root user. Required if the upgrade bundle contains vcenter component

.Parameter PscRootUsername
Username for PSC Root user. Required if the upgrade bundle contains vcenter component

.Parameter PscRootPassword
Password for PSC Root user. Required if the upgrade bundle contains vcenter component

.Parameter SourceVcsaHostname
Optional. Hostname of the VxRail host on which VCSA VM is currently on

.Parameter SourceVcsaHostUsername
Optional. Username of the VxRail host on which VCSA VM is currently on

.Parameter SourceVcsaHostPassword
Optional. Password of the VxRail host on which VCSA VM is currently on

.Parameter SourcePscHostname
Optional. Hostname of the VxRail host on which PSC VM is currently on

.Parameter SourcePscHostUsername
Optional. Username of the VxRail host on which PSC VM is currently on

.Parameter SourcePscHostPassword
Optional. Password of the VxRail host on which PSC VM is currently on

.Parameter TargetVcsaHostname
Optional. Hostname of the VxRail host on which VCSA/PSC VM is to be deployed on

.Parameter TargetVcsaHostUsername
Optional. Username of the VxRail host on which VCSA/PSC VM is to be deployed on

.Parameter TargetVcsaHostPassword
Optional. Password of the VxRail host on which VCSA/PSC VM is to be deployed on

.Parameter TemporaryIP
Optional. Temporary IP address for the upgrade

.Parameter TemporaryGateway
Optional. Temporary gateway for the upgrade

.Parameter TemporaryNetmask
Optional. Temporary netmask for the upgrade

.Parameter AutoWitnessUpgrade
Support since Version v2. Used for Stretched Cluster or vSAN 2-Node Cluster. Whether VxRail will automatically upgrade the witness node

.Parameter WitnessUsername
Support since Version v2. Used for Stretched Cluster or vSAN 2-Node Cluster. Username for witness node user. Required if witness node is upgraded.

.Parameter WitnessUserPassword
Support since Version v2. Used for Stretched Cluster or vSAN 2-Node Cluster. Password for witness node user. Required if witness node is upgraded.

.Parameter PreferredFaultDomainFirst
Support since Version v2. Stretched cluster upgrade sequence selection. For standard cluster and vSAN 2-Node cluster, this option should not be specified. For stretched cluster, this option is optional. 

.Parameter UpgradeConfig
Required after Version v4. Path for json file which contains related public API requested info.

.Parameter Format
Print JSON style format.


.Notes
You can run this cmdlet to start LCM.

.Example
For standard cluster,
C:\PS>Start-LcmUpgrade -Version <v1 or v2 or v3> -Server <vxm ip or FQDN> -Username <username> -Password <password> -BundleFilePath <bundle file path> -VxmRootUsername <vxm root user> -VxmRootPassword <vxm root password> -VcAdminUsername <vc admin user> -VcAdminPassword <vc admin password> -VcsaRootUsername <vcsa root username> -VcsaRootPassword <vcsa root password> -PscRootUsername <psc root user> -PscRootPassword <psc root password> -SourceVcsaHostname <source vcsa hostname> -SourceVcsaHostUsername <source vcsa host username> -SourceVcsaHostPassword <source vcsa host password> -SourcePscHostname <source psc hostname> -SourcePscHostUsername <source psc host username> -SourcePscHostPassword <source psc host password> -TargetVcsaHostname <target vcsa  hostname> -TargetVcsaHostUsername <target vcsa host username> -TargetVcsaHostPassword <target vcsa host password> -TemporaryIP <temporary ip> -TemporaryGateway <temporary gateway> -TemporaryNetMask <temporary netmask>

.Example
For stretched cluster and vSAN 2-Node cluster,
C:\PS>Start-LcmUpgrade -Version <v1 or v2 or v3> -Server <vxm ip or FQDN> -Username <username> -Password <password> -BundleFilePath <bundle file path> -VxmRootUsername <vxm root user> -VxmRootPassword <vxm root password> -VcAdminUsername <vc admin user> -VcAdminPassword <vc admin password> -VcsaRootUsername <vcsa root username> -VcsaRootPassword <vcsa root password> -PscRootUsername <psc root user> -PscRootPassword <psc root password> -SourceVcsaHostname <source vcsa hostname> -SourceVcsaHostUsername <source vcsa host username> -SourceVcsaHostPassword <source vcsa host password> -SourcePscHostname <source psc hostname> -SourcePscHostUsername <source psc host username> -SourcePscHostPassword <source psc host password> -TargetVcsaHostname <target vcsa  hostname> -TargetVcsaHostUsername <target vcsa host username> -TargetVcsaHostPassword <target vcsa host password> -TemporaryIP <temporary ip> -TemporaryGateway <temporary gateway> -TemporaryNetMask <temporary netmask> -AutoWitnessUpgrade <$true or $false> -WitnessUsername <witness node username> -WitnessUserPassword <witness node user password> -PreferredFaultDomainFirst <$true or $false>

Start LCM upgrade. Need to provide all the necessary information. 
#>
function Start-LcmUpgrade  {
    param(
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,
        
        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,
        
        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,       

        # The absolute path of bundle file
        [Parameter(Mandatory = $true)]
        [String] $BundleFilePath, 

        # The Vxm_Root account settings, default username is root
        [Parameter(Mandatory = $false)]
        [String] $VxmRootUsername = "root",

        [Parameter(Mandatory = $true)]
        [String] $VxmRootPassword,

        # The Vc_Admin account settings
        [Parameter(Mandatory = $true)]
        [String] $VcAdminUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminPassword,

        # The Vcsa_Root account settings, Only required if the upgrade bundle contains vcenter component
        [Parameter(Mandatory = $false)]
        [String] $VcsaRootUsername,

        [Parameter(Mandatory = $false)]
        [String] $VcsaRootPassword,
        
         # The Psc_Root account settings, Only required if the upgrade bundle contains vcenter component
        [Parameter(Mandatory = $false)]
        [String] $PscRootUsername,

        [Parameter(Mandatory = $false)]
        [String] $PscRootPassword,

        # The Source Vcsa ESXi host settings, Only required for migration based vcenter upgrade
        [Parameter(Mandatory = $false)]
        [String] $SourceVcsaHostname,  
         
        [Parameter(Mandatory = $false)]
        [String] $SourceVcsaHostUsername, 
           
        [Parameter(Mandatory = $false)]
        [String] $SourceVcsaHostPassword,  

        # The Source Psc ESXi host settings, Only required for migration based vcenter upgrade
        [Parameter(Mandatory = $false)]
        [String] $SourcePscHostname,  

        [Parameter(Mandatory = $false)]
        [String] $SourcePscHostUsername,  

        [Parameter(Mandatory = $false)]
        [String] $SourcePscHostPassword, 

        # The Target vcsa ESXi host settings, Only required for migration based vcenter upgrade
        [Parameter(Mandatory = $false)]
        [String] $TargetVcsaHostname,   

        [Parameter(Mandatory = $false)]
        [String] $TargetVcsaHostUsername,    
 
        [Parameter(Mandatory = $false)]
        [String] $TargetVcsaHostPassword,  

        # Temporary IP settings, Only required for migration based vcenter upgrade
        [Parameter(Mandatory = $false)]
        [String] $TemporaryIP,  

        [Parameter(Mandatory = $false)]
        [String] $TemporaryGateway,  

        [Parameter(Mandatory = $false)]
        [String] $TemporaryNetmask,

        [Parameter(Mandatory = $false)]
        [bool] $AutoWitnessUpgrade,

        [Parameter(Mandatory = $false)]
        [String] $WitnessUsername,

        [Parameter(Mandatory = $false)]
        [String] $WitnessUserPassword,

        [Parameter(Mandatory = $false)]
        [bool] $PreferredFaultDomainFirst,

        [Parameter(Mandatory = $false)]
        # Json configuration file
        [String] $UpgradeConfig,

        # need good format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/lcm/upgrade"

    # new logic for public API v4 and later
    if ($Version.ToLower() -ge "v4") {
        if ($UpgradeConfig) {
            # New logic after v4, using json file path method to trigger LCM
            if (Test-Path $UpgradeConfig) {
                $url = "https://" + $Server + $uri
                $body = Get-Content $UpgradeConfig

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
            } else {
                Write-Host "Haven't found file in the given UpgradeConfig path, please check." -ForegroundColor Red
                return
            }
        } else {
            Write-Host "From v4 version, UpgradeConfig parameter is mandatory. Please input this value." -ForegroundColor Red
            return
        }
    }

    # check Version
    # $pattern = "^v{1}[1|2]{1}$"
    if(($Version.ToLower() -ne "v1") -and ($Version.ToLower() -ne "v2") -and ($Version.ToLower() -ne "v3")) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }
        
    # check parameters support since version v2 api
    $message = ""
    if(!$Version -or ($Version.ToLower() -eq "v1")) {
        if($PSBoundParameters.ContainsKey("AutoWitnessUpgrade")) {
            $message = $message + "The parameter 'AutoWitnessUpgrade' is supported since Version v2.`n"
        }
        if($PSBoundParameters.ContainsKey("WitnessUsername")) {
            $message = $message + "The parameter 'WitnessUsername' is supported since Version v2.`n"
        }
        if($PSBoundParameters.ContainsKey("WitnessUserPassword")) {
            $message = $message + "The parameter 'WitnessUserPassword' is supported since Version v2.`n"
        }
        if($PSBoundParameters.ContainsKey("PreferredFaultDomainFirst")) {
            $message = $message + "The parameter 'PreferredFaultDomainFirst' is supported since Version v2."
        }
    }

    if($message.Length -gt 0) {
        write-host $message -ForegroundColor Red
        return
    }
    
    # Add mandatory information to body
    $Body = @{
    	"bundle_file_locator" = $BundleFilePath 
    	"vxrail" = @{
    		"vxm_root_user" = @{
    			"username" = $VxmRootUsername
    			"password" = $VxmRootPassword
    		}	
    	}
    	"vcenter" = @{
    		"vc_admin_user" = @{
    			"username" = $VcAdminUsername
    			"password" = $VcAdminPassword
    		}
        }
    }

    # if user entered vcsa root user account, add it to body
    if($VcsaRootUsername -and $VcsaRootPassword){
            $VcsaRootObj = @{
                "username" = $VcsaRootUsername
                "password" = $VcsaRootPassword
            }
            $Body.vcenter.add("vcsa_root_user",$VcsaRootObj)
    }

    # if version is v3, not add psc credential to body
    # if user entered psc root user account, add it to body
    if(($Version.ToLower() -ne "v3") -and $PscRootUsername -and $PscRootPassword){
            $PscRootObj = @{
                "username" = $PscRootUsername
                "password" = $PscRootPassword
            }
            $Body.vcenter.add("psc_root_user",$PscRootObj)
    }

    # if user entered  Source Vcsa ESXi host info, add it to body
    if($SourceVcsaHostname -and $SourceVcsaHostUsername -and $SourceVcsaHostPassword){
        # if Body object don't have 'migration_spec' object yet, add below info
        $toBeAdd_to_vcenter = @{
            "source_vcsa_host" = @{
                "name"= $SourceVcsaHostname    
			    "user"= @{
                    "username" = $SourceVcsaHostUsername
			    	"password" = $SourceVcsaHostPassword
			    }
		    }
        }
        # if Body object already have 'migration_spec', add below info
        $toBeAdd_to_vcenter_upgrade_spec = @{
            "name"= $SourceVcsaHostname    
			"user"= @{
                "username" = $SourceVcsaHostUsername
                "password" = $SourceVcsaHostPassword
            }
		}
        if($Body.vcenter.vcenter_major_version_upgrade_spec){
             $Body.vcenter.migration_spec.add("source_vcsa_host",$toBeAdd_to_vcenter_upgrade_spec)
        }
        else {
             $Body.vcenter.add("migration_spec",$toBeAdd_to_vcenter)
        }
    }

    # if version is v3, not add source psc to body
    # if user entered Source psc ESXi host info, add it to body
    if($Version.ToLower() -ne "v3" -and $SourcePscHostname -and $SourcePscHostUsername -and $SourcePscHostPassword){
        # if Body object don't have 'migration_spec' object yet, add below info
        $toBeAdd_to_vcenter = @{
            "source_psc_host" = @{
                "name"= $SourcePscHostname    
			    "user"= @{
                    "username" = $SourcePscHostUsername
			    	"password" = $SourcePscHostPassword
			    }
		    }
        }
        # if Body object already have 'migration_spec', add below info
        $toBeAdd_to_vcenter_upgrade_spec = @{
            "name"= $SourcePscHostname    
			"user"= @{
                "username" = $SourcePscHostUsername
                "password" = $SourcePscHostPassword
            }
		}
        if($Body.vcenter.migration_spec){
             $Body.vcenter.migration_spec.add("source_psc_host",$toBeAdd_to_vcenter_upgrade_spec)
        }
        else {
             $Body.vcenter.add("migration_spec",$toBeAdd_to_vcenter)
        }
    }

    # if user entered target Vcsa Esxi host info, add it to body
    if($TargetVcsaHostname -and $TargetVcsaHostUsername -and $TargetVcsaHostPassword){
        # if Body object don't have 'migration_spec' object yet, add below info
        $toBeAdd_to_vcenter = @{
            "target_vcsa_host" = @{
                "name"= $TargetVcsaHostname    
			    "user"= @{
                    "username" = $TargetVcsaHostUsername
			    	"password" = $TargetVcsaHostPassword
			    }
		    }
        }
        # if Body object already have 'migration_spec', add below info
        $toBeAdd_to_vcenter_upgrade_spec = @{
            "name"= $TargetVcsaHostname    
		    "user"= @{
                "username" = $TargetVcsaHostUsername
			    "password" = $TargetVcsaHostPassword
            }
		}
        if($Body.vcenter.migration_spec){
             $Body.vcenter.migration_spec.add("target_vcsa_host",$toBeAdd_to_vcenter_upgrade_spec)
        }
        else {
             $Body.vcenter.add("migration_spec",$toBeAdd_to_vcenter)
        }
    }

    # if user entered Temporary IP info, add it to body
    if($TemporaryIP -and $TemporaryGateway -and $TemporaryNetmask){
        # if Body object don't have 'migration_spec' object yet, add below info
        $toBeAdd_to_vcenter = @{
            "temporary_ip_setting" = @{
		    	"temporary_ip" = $TemporaryIP
		    	"gateway" = $TemporaryGateway
		    	"netmask" = $TemporaryNetmask
		    }
        }
        # if Body object already have 'migration_spec', add below info
        $toBeAdd_to_vcenter_upgrade_spec = @{
            "temporary_ip" = $TemporaryIP
		    "gateway" = $TemporaryGateway
		  	"netmask" = $TemporaryNetmask
		}
        if($Body.vcenter.migration_spec){
             $Body.vcenter.migration_spec.add("temporary_ip_setting",$toBeAdd_to_vcenter_upgrade_spec)
        }
        else {
             $Body.vcenter.add("migration_spec",$toBeAdd_to_vcenter)
        }
    }

    # Add parameters for v2/v3 API
    if($Version.ToLower() -ne "v1") {
        # witness node upgrade spec
        if($AutoWitnessUpgrade) {
            if(! $WitnessUsername -or ! $WitnessUserPassword) {
                write-host "Please input WitnessUsername and WitnessUserPassword if AutoWitnessUpgrade is true." -ForegroundColor Red
                return
            }
        }
        $WitnessObj = @{
            "auto_witness_upgrade" = $AutoWitnessUpgrade
        }
        $Body.add("witness",$WitnessObj)
        if($WitnessUserPassword -or $WitnessUserPassword) {
            $WitnessUserObj = @{
                "username" = $WitnessUsername
                "password" = $WitnessUserPassword
            }
            $Body.witness.add("witness_user",$WitnessUserObj)
        }
        
        # upgrade_sequence
        if($PSBoundParameters.ContainsKey("PreferredFaultDomainFirst")) {
            $UpgradeSeqObj = @{
                "preferred_fault_domain_first" = $PreferredFaultDomainFirst
            }
            $Body.add("upgrade_sequence",$UpgradeSeqObj)
        }
    }
    
    # Convert Body to Json format
    $Body = $Body | ConvertTo-Json -Depth 10

    $url = "https://" + $Server + $uri

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body -ContentType "application/json"
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}

<#
.Synopsis
Do pre-check before upgrading all VxRail software and hardware.

.Parameter Version
Optional. API version. Only input v1. Default value is v1.

.Parameter Server
Required. VxM IP or FQDN.

.Parameter Username
Required. Valid vCenter username which has either Administrator or HCIA role. 

.Parameter Password
Required. Use corresponding password for username. 

.Parameter BundleFilePath
Required. Full path of the upgrade bundle

.Parameter PrecheckType
Required. Pre-check type. Only input LCM_PRECHECK.

.Parameter VxmRootUsername
Optional. Username of VxRail Manager root user. Default is root.

.Parameter VxmRootPassword
Required. Password of VxRail Manager root user

.Parameter VcAdminUsername
Required. Username for vCenter Admin user

.Parameter VcAdminPassword
Required. Password for vCenter Admin user

.Parameter VcsaRootUsername
Username for VCSA Root user. Required if the upgrade bundle contains vcenter component

.Parameter VcsaRootPassword
Password for VCSA Root user. Required if the upgrade bundle contains vcenter component

.Parameter SourceVcsaHostname
Optional. Hostname of the VxRail host on which VCSA VM is currently on

.Parameter SourceVcsaHostUsername
Optional. Username of the VxRail host on which VCSA VM is currently on

.Parameter SourceVcsaHostPassword
Optional. Password of the VxRail host on which VCSA VM is currently on

.Parameter TargetVcsaHostname
Optional. Hostname of the VxRail host on which VCSA/PSC VM is to be deployed on

.Parameter TargetVcsaHostUsername
Optional. Username of the VxRail host on which VCSA/PSC VM is to be deployed on

.Parameter TargetVcsaHostPassword
Optional. Password of the VxRail host on which VCSA/PSC VM is to be deployed on

.Parameter TemporaryIP
Optional. Temporary IP address for the upgrade

.Parameter TemporaryGateway
Optional. Temporary gateway for the upgrade

.Parameter TemporaryNetmask
Optional. Temporary netmask for the upgrade

.Parameter AutoWitnessUpgrade
Used for Stretched Cluster or vSAN 2-Node Cluster. Whether VxRail will automatically upgrade the witness node

.Parameter WitnessUsername
Used for Stretched Cluster or vSAN 2-Node Cluster. Username for witness node user. Required if witness node is upgraded.

.Parameter WitnessUserPassword
Used for Stretched Cluster or vSAN 2-Node Cluster. Password for witness node user. Required if witness node is upgraded.

.Parameter PreferredFaultDomainFirst
Stretched cluster upgrade sequence selection. For standard cluster and vSAN 2-Node cluster, this option should not be specified. For stretched cluster, this option is optional. 

.Parameter Format
Print JSON style format.


.Notes
You can run this cmdlet to start LCM upgrade pre-check.

.Example
For standard cluster,
C:\PS>Start-LcmPrecheck -Version <v1> -Server <vxm ip or FQDN> -Username <username> -Password <password> -BundleFilePath <bundle file path> -PrecheckType <pre-check type> -VxmRootUsername <vxm root user> -VxmRootPassword <vxm root password> -VcAdminUsername <vc admin user> -VcAdminPassword <vc admin password> -VcsaRootUsername <vcsa root username> -VcsaRootPassword <vcsa root password> -SourceVcsaHostname <source vcsa hostname> -SourceVcsaHostUsername <source vcsa host username> -SourceVcsaHostPassword <source vcsa host password> -TargetVcsaHostname <target vcsa  hostname> -TargetVcsaHostUsername <target vcsa host username> -TargetVcsaHostPassword <target vcsa host password> -TemporaryIP <temporary ip> -TemporaryGateway <temporary gateway> -TemporaryNetMask <temporary netmask>

Start LCM upgrade pre-check. Need to provide all the necessary information. 
#>
function Start-LcmPrecheck  {
    param(
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1",

        # VxRail Manager IP address or FQDN
        [Parameter(Mandatory = $true)]
        [string] $Server,
        
        # User name in vCenter
        [Parameter(Mandatory = $true)]
        [String] $Username,
        
        # password for the vCenter
        [Parameter(Mandatory = $true)]
        [String] $Password,       

        # The absolute path of bundle file
        [Parameter(Mandatory = $true)]
        [String] $BundleFilePath, 

        # The pre-check type
        [Parameter(Mandatory = $true)]
        [String] $PrecheckType, 

        # The Vxm_Root account settings, default username is root
        [Parameter(Mandatory = $false)]
        [String] $VxmRootUsername = "root",

        [Parameter(Mandatory = $true)]
        [String] $VxmRootPassword,

        # The Vc_Admin account settings
        [Parameter(Mandatory = $true)]
        [String] $VcAdminUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminPassword,

        # The Vcsa_Root account settings, Only required if the upgrade bundle contains vcenter component
        [Parameter(Mandatory = $false)]
        [String] $VcsaRootUsername,

        [Parameter(Mandatory = $false)]
        [String] $VcsaRootPassword,
        
        # The Source Vcsa ESXi host settings, Only required for migration based vcenter upgrade
        [Parameter(Mandatory = $false)]
        [String] $SourceVcsaHostname,  
         
        [Parameter(Mandatory = $false)]
        [String] $SourceVcsaHostUsername, 
           
        [Parameter(Mandatory = $false)]
        [String] $SourceVcsaHostPassword,  

        # The Target vcsa ESXi host settings, Only required for migration based vcenter upgrade
        [Parameter(Mandatory = $false)]
        [String] $TargetVcsaHostname,   

        [Parameter(Mandatory = $false)]
        [String] $TargetVcsaHostUsername,    
 
        [Parameter(Mandatory = $false)]
        [String] $TargetVcsaHostPassword,  

        # Temporary IP settings, Only required for migration based vcenter upgrade
        [Parameter(Mandatory = $false)]
        [String] $TemporaryIP,  

        [Parameter(Mandatory = $false)]
        [String] $TemporaryGateway,  

        [Parameter(Mandatory = $false)]
        [String] $TemporaryNetmask,

        [Parameter(Mandatory = $false)]
        [bool] $AutoWitnessUpgrade,

        [Parameter(Mandatory = $false)]
        [String] $WitnessUsername,

        [Parameter(Mandatory = $false)]
        [String] $WitnessUserPassword,

        [Parameter(Mandatory = $false)]
        [bool] $PreferredFaultDomainFirst,

        [Parameter(Mandatory = $false)]
        # Json configuration file
        [String] $UpgradeConfig,

        # need good format
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/lcm/precheck"

    # new logic for public API v2 and later
    if ($Version.ToLower() -ge "v2") {
        if ($UpgradeConfig) {
            # New logic after v2, using json file path method to trigger LCM precheck
            if (Test-Path $UpgradeConfig) {
                $url = "https://" + $Server + $uri
                $body = Get-Content $UpgradeConfig

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
            } else {
                Write-Host "Haven't found file in the given UpgradeConfig path, please check." -ForegroundColor Red
                return
            }
        } else {
            Write-Host "From v2 version, UpgradeConfig parameter is mandatory. Please input this value." -ForegroundColor Red
            return
        }
    }

    # check Version
    # $pattern = "^v{1}[1|2]{1}$"
    if($Version -ne "v1") {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }
        
    if($message.Length -gt 0) {
        write-host $message -ForegroundColor Red
        return
    }
    
    # Add mandatory information to body
    $Body = @{
    	"bundle_file_locator" = $BundleFilePath 
    	"vxrail" = @{
    		"vxm_root_user" = @{
    			"username" = $VxmRootUsername
    			"password" = $VxmRootPassword
    		}	
    	}
    	"vcenter" = @{
    		"vc_admin_user" = @{
    			"username" = $VcAdminUsername
    			"password" = $VcAdminPassword
    		}
        }
    }

    # if user entered pre-check type, add it to body
    if($PrecheckType){
        $Body.add("health_precheck_type",$PrecheckType)
    }

    # if user entered vcsa root user account, add it to body
    if($VcsaRootUsername -and $VcsaRootPassword){
            $VcsaRootObj = @{
                "username" = $VcsaRootUsername
                "password" = $VcsaRootPassword
            }
            $Body.vcenter.add("vcsa_root_user",$VcsaRootObj)
    }

    # if user entered psc root user account, add it to body
    if($PscRootUsername -and $PscRootPassword){
            $PscRootObj = @{
                "username" = $PscRootUsername
                "password" = $PscRootPassword
            }
            $Body.vcenter.add("psc_root_user",$PscRootObj)
    }

    # if user entered  Source Vcsa ESXi host info, add it to body
    if($SourceVcsaHostname -and $SourceVcsaHostUsername -and $SourceVcsaHostPassword){
        # if Body object don't have 'migration_spec' object yet, add below info
        $toBeAdd_to_vcenter = @{
            "source_vcsa_host" = @{
                "name"= $SourceVcsaHostname    
			    "user"= @{
                    "username" = $SourceVcsaHostUsername
			    	"password" = $SourceVcsaHostPassword
			    }
		    }
        }
        # if Body object already have 'migration_spec', add below info
        $toBeAdd_to_vcenter_upgrade_spec = @{
            "name"= $SourceVcsaHostname    
			"user"= @{
                "username" = $SourceVcsaHostUsername
                "password" = $SourceVcsaHostPassword
            }
		}
        if($Body.vcenter.vcenter_major_version_upgrade_spec){
             $Body.vcenter.migration_spec.add("source_vcsa_host",$toBeAdd_to_vcenter_upgrade_spec)
        }
        else {
             $Body.vcenter.add("migration_spec",$toBeAdd_to_vcenter)
        }
    }

    # if user entered target Vcsa Esxi host info, add it to body
    if($TargetVcsaHostname -and $TargetVcsaHostUsername -and $TargetVcsaHostPassword){
        # if Body object don't have 'migration_spec' object yet, add below info
        $toBeAdd_to_vcenter = @{
            "target_vcsa_host" = @{
                "name"= $TargetVcsaHostname    
			    "user"= @{
                    "username" = $TargetVcsaHostUsername
			    	"password" = $TargetVcsaHostPassword
			    }
		    }
        }
        # if Body object already have 'migration_spec', add below info
        $toBeAdd_to_vcenter_upgrade_spec = @{
            "name"= $TargetVcsaHostname    
		    "user"= @{
                "username" = $TargetVcsaHostUsername
			    "password" = $TargetVcsaHostPassword
            }
		}
        if($Body.vcenter.migration_spec){
             $Body.vcenter.migration_spec.add("target_vcsa_host",$toBeAdd_to_vcenter_upgrade_spec)
        }
        else {
             $Body.vcenter.add("migration_spec",$toBeAdd_to_vcenter)
        }
    }

    # if user entered Temporary IP info, add it to body
    if($TemporaryIP -and $TemporaryGateway -and $TemporaryNetmask){
        # if Body object don't have 'migration_spec' object yet, add below info
        $toBeAdd_to_vcenter = @{
            "temporary_ip_setting" = @{
		    	"temporary_ip" = $TemporaryIP
		    	"gateway" = $TemporaryGateway
		    	"netmask" = $TemporaryNetmask
		    }
        }
        # if Body object already have 'migration_spec', add below info
        $toBeAdd_to_vcenter_upgrade_spec = @{
            "temporary_ip" = $TemporaryIP
		    "gateway" = $TemporaryGateway
		  	"netmask" = $TemporaryNetmask
		}
        if($Body.vcenter.migration_spec){
             $Body.vcenter.migration_spec.add("temporary_ip_setting",$toBeAdd_to_vcenter_upgrade_spec)
        }
        else {
             $Body.vcenter.add("migration_spec",$toBeAdd_to_vcenter)
        }
    }

    # witness node upgrade spec
    if($AutoWitnessUpgrade) {
        if(! $WitnessUsername -or ! $WitnessUserPassword) {
            write-host "Please input WitnessUsername and WitnessUserPassword if AutoWitnessUpgrade is true." -ForegroundColor Red
            return
        }
    }
    $WitnessObj = @{
        "auto_witness_upgrade" = $AutoWitnessUpgrade
    }
    $Body.add("witness",$WitnessObj)
    if($WitnessUserPassword -or $WitnessUserPassword) {
        $WitnessUserObj = @{
            "username" = $WitnessUsername
            "password" = $WitnessUserPassword
        }
        $Body.witness.add("witness_user",$WitnessUserObj)
    }
    
    # upgrade_sequence
    if($PSBoundParameters.ContainsKey("PreferredFaultDomainFirst")) {
        $UpgradeSeqObj = @{
            "preferred_fault_domain_first" = $PreferredFaultDomainFirst
        }
        $Body.add("upgrade_sequence",$UpgradeSeqObj)
    }
    
    # Convert Body to Json format
    $Body = $Body | ConvertTo-Json -Depth 10

    $url = "https://" + $Server + $uri

    #write-host $Body

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body -ContentType "application/json"
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        HandleInvokeRestMethodException -URL $url
    }
}


<#
.Synopsis
Perform a partial upgrade of vLCM-enabled VxRail system (v4).

.Description
Perform a partial upgrade of all VxRail software and hardware. Version 4 of this API includes the optional property "target_hosts",
which indicates the nodes to be upgraded. If "target_hosts" is empty or not provided, this API upgrades all nodes in the cluster.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter UpgradeConfig
Input parameters needed for the upgrade

.Parameter Format
Print JSON style format.

.Notes
Perform a partial upgrade of vLCM-enabled VxRail system (v4).

.Example
Start-LcmPartialUpgrade -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -UpgradeConfig <Json file to the path>

#>
function Start-LcmPartialUpgrade {
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
        [String] $UpgradeConfig,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v4/lcm/upgrade"
    $url = "https://" + $Server + $uri
    $body = Get-Content $UpgradeConfig

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
Upload an advisory metadata bundle

.Description
Upload a metadata bundle for local advisory analysis.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter meta_bundle
The binary string of the metadata bundle

.Parameter Format
Print JSON style format.

.Notes
Upload a metadata bundle for local advisory analysis.

.Example
Invoke-UploadAdvisoryMetaBundle -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -meta_bundle <file to the path>

#>

function Invoke-UploadAdvisoryMetaBundle {

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
        # meta_bundle zip file
        [String] $FilePath,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        $uri = '/rest/vxm/v1/lcm/advisory-meta-bundle'
        $url = "https://" + $Server + $uri

        try{
            $fileBytes = [System.IO.File]::ReadAllBytes($FilePath);
            $fileEnc = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes);
            $boundary = [System.Guid]::NewGuid().ToString();
            $LF = "`r`n";
            $bodyLines = (
                "--$boundary",
                "Content-Disposition: form-data; name=`"meta_bundle`"; filename=`"$(Split-Path -Leaf -Path $FilePath)`"",
                "Content-Type: application/octet-stream$LF",
                $fileEnc,
                "--$boundary--$LF"
            ) -join $LF

            try {
                $response = doPost -Server $server -Api $uri -Username $username -Password $password -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
                if ($Format) {
                    $response = $response | ConvertTo-Json
                 }
            }
            catch{
                HandleInvokeRestMethodException -URL $url
            }

        } catch {
            write-host $_
        }
}

<#
.Synopsis
Upload an customized component

.Description
Upload a customized component via LCM upload api

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter customized_component
Specifies if the uploading file is a customized component. If specifies as false, system will treat this file as a common file, such as lcm bundle.

.Parameter checksum
Specifies the checksum of uploading file encoded in SHA512.

.Parameter type
Only support driver/firmware/bundle customized type.

.Parameter component_bundle
The path of the file to be uploaded on the local machine.

.Parameter Format
Print JSON style format.

.Notes
Upload a customized component via LCM upload api for legacy LCM mode

.Example
How to manually generate SHA512 checksum value:
1. Linux system: sha512sum <component file> 
   ex: sha512sum  NVD-VGPU_460.32.04-1OEM.700.0.0.15525992_17478485.zip
2. Windows 10 system: certutil -hashfile <component file> sha512
   ex: certutil -hashfile NVD-VGPU_460.32.04-1OEM.700.0.0.15525992_17478485.zip sha512

Invoke-UploadCustomizedComponent -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -customized_component <component or bundle> -checksum <SHA512> -type <component type> -component_bundle <file path>

#>

function Invoke-UploadCustomizedComponent {

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

         # Specifies if the uploading file is a customized component
         # "true" is driver/firmware, "false" is bundle
         [Parameter(Mandatory = $true)]
         [String] $customized_component,
 
         # Specifies the checksum of uploading file encoded in SHA512
         [Parameter(Mandatory = $true)]
         [String] $checksum,
 
         # Only support driver/firmware/bundle customized type
         [Parameter(Mandatory = $true)]
         [String] $type,

         [Parameter(Mandatory = $true)]
         [ValidateScript({Test-Path $_})]
         # component_bundle zip file
         [String] $component_bundle,
 
         # Formatting the output
         [Parameter(Mandatory = $false)]
         [Switch] $Format
         )
 
         $uri = '/rest/vxm/v1/lcm/upgrade/upload-bundle'
         $url = "https://" + $Server + $uri
         $apiurl = $uri + "?" + "customized_component=" + $customized_component + "&" + "checksum=" + $checksum + "&" + "type=" + $type
 
         try{
             $fileBytes = [System.IO.File]::ReadAllBytes($component_bundle);
             $fileEnc = [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString($fileBytes);
             $boundary = [System.Guid]::NewGuid().ToString();
             $LF = "`r`n";
             $bodyLines = (
                 "--$boundary",
                 "Content-Disposition: form-data; name=`"component_bundle`"; filename=`"$(Split-Path -Leaf -Path $component_bundle)`"",
                 "Content-Type: application/octet-stream$LF",
                 $fileEnc,
                 "--$boundary--$LF"
             ) -join $LF
 
             try {
                 $response = doPost -Server $Server -Api $apiurl -Username $Username -Password $Password -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines
                 if ($Format) {
                     $response = $response | ConvertTo-Json
                  }
                  return $response
             }
             catch{
                 HandleInvokeRestMethodException -URL $url
             }
 
         } catch {
             write-host $_
         }
 }

<#
.Synopsis
Generate an advisory report of all online and local updates

.Description
Generate an advisory report that contains information about all online and local lifecycle management updates.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
Generate an advisory report that contains information about all online and local lifecycle management updates.

.Example
 New-LcmAdvisoryReport -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password>

#>

function New-LcmAdvisoryReport {

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

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        $uri = '/rest/vxm/v1/lcm/advisory-report'
        $url = "https://" + $Server + $uri

        try {
           $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password
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
Export CVS compliance report

.Description
Export the CVS compliance report that is generated using the provided parameters.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter GroupBy
Group by parameter.

.Parameter ReportFormat
The report's format.

.Parameter Ids
ID list for the report. 

.Notes
Export the CVS compliance report that is generated using the provided parameters.

.Example
Export-CvsComplianceReport -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -OutputFile <Output File Path>

#>

function Export-CvsComplianceReport {

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

        # Group by parameter.
        [Parameter(Mandatory = $false, HelpMessage="Supported GroupBy: 'COMPONENT'")]
        [ValidateSet('COMPONENT')]
        [string]$GroupBy,

        # The report's format
        [Parameter(Mandatory = $false, HelpMessage="Supported ReportFormat: 'HTML'")]
        [ValidateSet('HTML')]
        [string]$ReportFormat,

        # ID list for the report. 
        [Parameter(Mandatory = $false)]
        [string]$Ids,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile        
        )

        # Add System.Web
        Add-Type -AssemblyName System.Web
        
        $collection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
        if ($GroupBy) { $collection.Add('group_by', $GroupBy) }
        if ($Format) { $collection.Add('format', $Format) }
        if ($Ids) { $collection.Add('ids', $Ids) }
 
        $param = $collection.ToString()
        $uri = '/rest/vxm/v1/cvs-compliance/report'
        
        if ($param -ne "") {
            $uri += "?" + $param
        }        

        try {             
            doGet -Server $Server -Api $uri -Username $Username -Password $Password -OutFile $OutputFile             
        }
        catch {
           HandleInvokeRestMethodException -URL $uri
        }
}

<#
.Synopsis
Generate a compliance drift report

.Description
Generate a compliance report containing component drift information against the current system baseline.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
Generate a compliance report containing component drift information against the current system baseline.

.Example
 New-CvsComplianceReport -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password>

#>

function New-CvsComplianceReport {

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

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        $uri = '/rest/vxm/v1/cvs/compliance-report'
        $url = "https://" + $Server + $uri

        try {
           $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password
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
Perform Public APIs to support upgrade retry.

.Description
Perform a retry option after failure of upgrade(available as a public API).

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
Perform a upgrade retry.

.Example
Start-UpgradeRetry -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password>

#>
function Start-UpgradeRetry {
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

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format

    )

    $uri = "/rest/vxm/v1/lcm/upgrade/retry"
    $url = "https://" + $Server + $uri

    try {
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password      
        if($Format){
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
Fetch vlcm image content for LCM bundle

.Description
Fetch vlcm image content for LCM bundle

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter VxmRootUsername
Optional. Username of VxRail Manager root user. Default is root.

.Parameter VxmRootPassword
Required. Password of VxRail Manager root user

.Parameter BundleFilePath
Required. Full path of the upgrade bundle

.Notes
Fetch vlcm image content for LCM bundle

.Example
Start-UpgradeRetry -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -BundleFilePath <bundle file path> -VxmRootUsername <vxm root username> -VxmRootPassword <vxm root password>

#>
function Get-VlcmImage {
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

        # The absolute path of bundle file
        [Parameter(Mandatory = $true)]
        [String] $BundleFilePath, 

        # The Vxm_Root account settings, default username is root
        [Parameter(Mandatory = $false)]
        [String] $VxmRootUsername = "root",

        [Parameter(Mandatory = $true)]
        [String] $VxmRootPassword,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = "/rest/vxm/v1/lcm/upgrade/vlcm/image"
    $url = "https://" + $Server + $uri
    $Body = @{
        "bundle_file_locator" = $BundleFilePath
        "vxrail" = @{
          "vxm_root_user" = @{
            "username" = $VxmRootUsername
            "password" = $VxmRootPassword
          }
        }
      } | ConvertTo-Json

    try {
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body     
        if($Format){
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
Check vlcm is enable

.Description
Checks whether vLCM is enabled on the cluster.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Notes
Checks whether vLCM is enabled on the cluster.

.Example
Check-vLCMEnabled -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password>

#>

function Check-vLCMEnabled {

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

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        # Add System.Web
        Add-Type -AssemblyName System.Web

        $uri = '/rest/vxm/v1/lcm/vlcm'

        try {
            $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
            if($Format) {
                $ret = $ret | ConvertTo-Json
            }
            return $ret
        }
        catch {
           HandleInvokeRestMethodException -URL $uri
        }
}

<#
.Synopsis
Enable vLCM on the cluster.

.Description
Starts a task to enable vLCM and returns the task ID to track the progress of vLCM enablement.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter VcAdminUsername
vCenter admin username for vLCM enablement.

.Parameter VcAdminPassword
vCenter admin password for vLCM enablement.

.Parameter VcsaRootUsername
vCenter root username for vLCM enablement.

.Parameter VcsaRootPassword
vCenter root password for vLCM enablement.

.Parameter CustomizedComponents
JSON string containing name and version mapping of the ESXi component. This is a mandatory field.

.Parameter Format
Print JSON style format.

.Notes
Enables vLCM on the cluster.

.Example
Enable-vLCM -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -VcAdminUsername "admin" -VcAdminPassword "pass" -VcsaRootUsername "root" -VcsaRootPassword "pass" -CustomizedComponents '{"Component1": "Version1", "Component2": "Version2"}'

#>

function Enable-vLCM {

     param(
        [Parameter(Mandatory = $true)]
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [String] $Username,

        [Parameter(Mandatory = $true)]
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminPassword,

        [Parameter(Mandatory = $true)]
        [String] $VcsaRootUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcsaRootPassword,

        [Parameter(Mandatory = $true)]
        [String] $CustomizedComponents,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        # Prepare the EnablementSpec JSON payload
        $EnablementSpec = @{
            "vc_admin_user" = @{
                "username" = $VcAdminUsername
                "password" = $VcAdminPassword
            }
            "vcsa_root_user" = @{
                "username" = $VcsaRootUsername
                "password" = $VcsaRootPassword
            }
            "customized_components" = $CustomizedComponents | ConvertFrom-Json
        } | ConvertTo-Json

        # Add System.Web
        Add-Type -AssemblyName System.Web

        $uri = '/rest/vxm/v1/lcm/vlcm/enablement'

        try {
            $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $EnablementSpec
            if($Format) {
                $ret = $ret | ConvertTo-Json
            }
            return $ret
        }
        catch {
            HandleInvokeRestMethodException -URL $uri
        }
}

<#
.Synopsis
Get the progress of vLCM enablement task.

.Description
Returns the progress of the vLCM enablement task.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter TaskId
The vLCM enablement task ID.

.Parameter Format
Print JSON style format.

.Notes
Returns the progress of the vLCM enablement task.

.Example
Get-vLCMEnablementStatus -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -TaskId <Task ID>

#>

function Get-vLCMEnablementStatus {

    param(
        [Parameter(Mandatory = $true)]
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [String] $Username,

        [Parameter(Mandatory = $true)]
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [String] $TaskId,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    # Add System.Web
    Add-Type -AssemblyName System.Web

    # Prepare the URI
    $uri = "/rest/vxm/v1/lcm/vlcm/enablement/status/$TaskId"

    try {
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    }
    catch {
        HandleInvokeRestMethodException -URL $uri
    }
}

<#
.Synopsis
Generate vLCM draft on the cluster.
.Description
Starts a task to generate vLCM draft and returns the task ID to track the progress of generating vLCM draft.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter VcAdminUsername
vCenter admin username for vLCM enablement.
.Parameter VcAdminPassword
vCenter admin password for vLCM enablement.
.Parameter VcsaRootUsername
vCenter root username for vLCM enablement.
.Parameter VcsaRootPassword
vCenter root password for vLCM enablement.
.Parameter CustomizedComponents
JSON string containing name and version mapping of the ESXi component. This is a mandatory field.
.Parameter Format
Print JSON style format.
.Notes
Generate vLCM draft on the cluster.
.Example
Generate-vLCMDraft -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -VcAdminUsername "admin" -VcAdminPassword "pass" -VcsaRootUsername "root" -VcsaRootPassword "pass" -CustomizedComponents '{"Component1": "Version1", "Component2": "Version2"}'
#>

function Generate-vLCMDraft {

     param(
        [Parameter(Mandatory = $true)]
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [String] $Username,

        [Parameter(Mandatory = $true)]
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminPassword,

        [Parameter(Mandatory = $true)]
        [String] $VcsaRootUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcsaRootPassword,

        [Parameter(Mandatory = $true)]
        [String] $CustomizedComponents,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        # Prepare the EnablementSpec JSON payload
        $EnablementSpec = @{
            "vc_admin_user" = @{
                "username" = $VcAdminUsername
                "password" = $VcAdminPassword
            }
            "vcsa_root_user" = @{
                "username" = $VcsaRootUsername
                "password" = $VcsaRootPassword
            }
            "customized_components" = $CustomizedComponents | ConvertFrom-Json
        } | ConvertTo-Json

        # Add System.Web
        Add-Type -AssemblyName System.Web

        $uri = '/rest/vxm/v1/lcm/vlcm/enablement/draft/generate'

        try {
            $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $EnablementSpec
            if($Format) {
                $ret = $ret | ConvertTo-Json
            }
            return $ret
        }
        catch {
            HandleInvokeRestMethodException -URL $uri
        }
}

<#
.Synopsis
Commit vLCM draft on the cluster.
.Description
Starts a task to commit vLCM draft and returns the task ID to track the progress of committing vLCM draft.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Notes
Commit vLCM draft on the cluster.
.Example
Commit-vLCMDraft -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -Format
#>

function Commit-vLCMDraft {

     param(
        [Parameter(Mandatory = $true)]
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [String] $Username,

        [Parameter(Mandatory = $true)]
        [String] $Password,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        # Add System.Web
        Add-Type -AssemblyName System.Web

        $uri = '/rest/vxm/v1/lcm/vlcm/enablement/draft/commit'

        try {
            $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password
            if($Format) {
                $ret = $ret | ConvertTo-Json
            }
            return $ret
        }
        catch {
            HandleInvokeRestMethodException -URL $uri
        }
}

<#
.Synopsis
Delete vLCM draft on the cluster.
.Description
Starts a task to delete vLCM draft and returns the task ID to track the progress of deleting vLCM draft.
.Parameter Server
VxM IP or FQDN.
.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.
.Parameter Password
Use corresponding password for username.
.Parameter VcAdminUsername
vCenter admin username for vLCM enablement.
.Parameter VcAdminPassword
vCenter admin password for vLCM enablement.
.Parameter VcsaRootUsername
vCenter root username for vLCM enablement.
.Parameter VcsaRootPassword
vCenter root password for vLCM enablement.
.Notes
Delete vLCM draft on the cluster.
.Example
Delete-vLCMDraft -Server <vxm ip or FQDN> -Username <VC username> -Password <VC password> -VcAdminUsername "admin" -VcAdminPassword "pass" -VcsaRootUsername "root" -VcsaRootPassword "pass"
#>

function Delete-vLCMDraft {

     param(
        [Parameter(Mandatory = $true)]
        [String] $Server,

        [Parameter(Mandatory = $true)]
        [String] $Username,

        [Parameter(Mandatory = $true)]
        [String] $Password,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcAdminPassword,

        [Parameter(Mandatory = $true)]
        [String] $VcsaRootUsername,

        [Parameter(Mandatory = $true)]
        [String] $VcsaRootPassword,

        [Parameter(Mandatory = $false)]
        [Switch] $Format
        )

        # Prepare the EnablementSpec JSON payload
        $EnablementSpec = @{
            "vc_admin_user" = @{
                "username" = $VcAdminUsername
                "password" = $VcAdminPassword
            }
            "vcsa_root_user" = @{
                "username" = $VcsaRootUsername
                "password" = $VcsaRootPassword
            }
        } | ConvertTo-Json

        # Add System.Web
        Add-Type -AssemblyName System.Web

        $uri = '/rest/vxm/v1/lcm/vlcm/enablement/draft'

        try {
            $ret = doDelete -Server $Server -Api $uri -Username $Username -Password $Password -Body $EnablementSpec
            if($Format) {
                $ret = $ret | ConvertTo-Json
            }
            return $ret
        }
        catch {
            HandleInvokeRestMethodException -URL $uri
        }
}