# Copyright (c) 2022 Dell Inc. or its subsidiaries. All Rights Reserved.
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

Update VXM certificate

.NOTES

You can run this cmdlet to update VxM certificate.

.EXAMPLE

PS> Update-Certificate -Server <VxM IP or FQDN> -Username <username> -Password <password> -CertContent <cert content> -PrimaryKey <primary key> -RootCertChain <root cert content> -PfxPassword <.pfx password>

Update VxM certificate
#>
function Update-Certificate {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $true)]
        # .crt file content
        [String] $CertContent,

        [Parameter(Mandatory = $true)]
        # .key file content
        [String] $PrimaryKey,

        [Parameter(Mandatory = $true)]
        # Root certificate content
        [String] $RootCertChain,

        [Parameter(Mandatory = $true)]
        # The password for new .pfx fi:q!le
        [String] $PfxPassword,

        # The API version, default is v1
        [Parameter(Mandatory = $false)]
        [String] $Version = "v1"
    )

    $Body = @{
        "cert" = $CertContent.replace("\n","`n")
        "primary_key" = $PrimaryKey.replace("\n","`n")
        "root_cert_chain" = $RootCertChain.replace("\n","`n")
        "password" = $PfxPassword
    } | ConvertTo-Json

    $uri = "/rest/vxm/" + $Version.ToLower() + "/certificates/import-vxm"
    # check Version
    if(("v1","v2") -notcontains $Version.ToLower()) {
        write-host "The inputted Version $Version is invalid." -ForegroundColor Red
        return
    }

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth
        }
        return $ret
    } catch {
        write-host $_
    }

}

<#
.SYNOPSIS

Get Fingerprints From Trust Store

.NOTES

You can run this cmdlet to get a fingerprints list from VXM trust store.

.EXAMPLE

PS> Get-Fingerprints -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get Fingerprints From Trust Store
#>
function Get-Fingerprints {
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

    $uri = "/rest/vxm/v1/trust-store/certificates/fingerprints"

    try{
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }

}

<#
.SYNOPSIS

Get the information of all the certificates in the trust store.

.NOTES

You can run this cmdlet to get the information of all the certificates in the trust store.

.EXAMPLE

PS> Get-AllCertificateContent -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get the Information of All the Certificates in the Trust Store
#>
function Get-AllCertificateContent {
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

    $uri = "/rest/vxm/v1/trust-store/certificates"

    try{
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS

Get Certificate Content From Trust Store

.NOTES

You can run this cmdlet to get a certificate content from VXM trust store according to fingerprint.

.EXAMPLE

PS> Get-CertificateContent -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get Certificate Content From Trust Store
#>
function Get-CertificateContent {
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

        # Certificate fingerprint
        [Parameter(Mandatory = $true)]
        [String] $Fingerprint,

        # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = -join("/rest/vxm/v1/trust-store/certificates/", $Fingerprint)

    try{
        $ret = doGet -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS

Import Certificates Into VXM Trust Store

.NOTES

You can run this cmdlet to import certificates content into VXM trust store.

.EXAMPLE

PS> Import-CertificatesIntoTrustStore -Server <VxM IP or FQDN> -Username <username> -Password <password> -certs <certs content list>

Import Certificates Into VXM Trust Store
#>
function Import-CertificatesIntoTrustStore {
    param (
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $true)]
        # Certficates content array
        [String[]] $CertContent
    )

    for ($i = 0; $i -lt $CertContent.Count; $i++) {
        $CertContent[$i] = $CertContent[$i].replace("\n","`n")
    }

    $Body = @{
        "certs" = $CertContent
    } | ConvertTo-Json

    $uri = "/rest/vxm/v1/trust-store/certificates"

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json -Depth
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS

Delete Certificates From VXM Trust Store

.NOTES

You can run this cmdlet to delete certificates frome VXM trust store.

.EXAMPLE

PS> Remove-CertificateFromTrustStore -Server <VxM IP or FQDN> -Username <username> -Password <password>

Delete Certificates Into VXM Trust Store
#>
function Remove-CertificateFromTrustStore {
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

    # Certificate fingerprint
        [Parameter(Mandatory = $true)]
        [String] $Fingerprint,

    # Formatting the output
        [Parameter(Mandatory = $false)]
        [Switch] $Format
    )

    $uri = -join("/rest/vxm/v1/trust-store/certificates/", $Fingerprint)

    try{
        $ret = doDelete -Server $Server -Api $uri -Username $Username -Password $Password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS

Generate a CSR with the given information.

.NOTES

You can run this cmdlet to generate a CSR with the given information.

.EXAMPLE

PS> New-CSR -Server <VxM IP or FQDN> -Username <username> -Password <password> -Country <US> -State <State name> -Locality <Locality name> -Organization <name> -OrganizationUnit <name> -CommonName <name> -EmailAddress <email> -SubjectAltName <IP or DNS>

Generate a CSR with the given information.
#>
function New-CSR {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $true)]
        # The two-letter country code
        [String] $Country,

        [Parameter(Mandatory = $false)]
        # The state or province name
        [String] $State,

        [Parameter(Mandatory = $false)]
        # The locality name
        [String] $Locality,

        [Parameter(Mandatory = $true)]
        # The organization name
        [String] $Organization,

        [Parameter(Mandatory = $true)]
        # The organization unit name
        [String] $OrganizationUnit,

        [Parameter(Mandatory = $true)]
        # The common name
        [String] $CommonName,

        [Parameter(Mandatory = $false)]
        # The email address
        [String] $EmailAddress,

        [Parameter(Mandatory = $false)]
        # Specify the IP addresses or domains as the alternative names
        [String[]] $SubjectAltName
    )

    $Body = @{
        "country" = $Country
        "state" = $State
        "locality" =  $Locality
        "organization" = $Organization
        "organization_unit" = $OrganizationUnit
        "common_name" = $CommonName
        "email_address" = $EmailAddress
        "subject_alt_name" = $SubjectAltName
    } | ConvertTo-Json

    $uri = -join("/rest/vxm/v1/certificates/csr")

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}


<#
.SYNOPSIS

Verify the VxRail Manager certificate.

.NOTES

You can run this cmdlet to verify the VxRail Manager certificate.

.EXAMPLE

PS> Test-Certificate -Server <VxM IP or FQDN> -Username <username> -Password <password> -CertContent <cert content> -RootCertChain <root cert content> -PrivateKey <private key> -PfxPassword <.pfx password>

Verify the VxRail Manager certificate.
#>
function Confirm-Certificate {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $true)]
        # .crt file content
        [String] $CertContent,

        [Parameter(Mandatory = $true)]
        # Root certificate content
        [String[]] $RootCertChain,

        [Parameter(Mandatory = $true)]
        # .key file content
        [String] $PrivateKey,

        [Parameter(Mandatory = $false)]
        # The password for new .pfx file
        [String] $PfxPassword
    )

    $Body = @{
        "cert" = $CertContent.replace("\n","`n")
        "root_cert_chain" = $RootCertChain.replace("\n","`n")
        "private_key" = $PrivateKey.replace("\n","`n")
        "password" = $PfxPassword
    } | ConvertTo-Json

    $uri = -join("/rest/vxm/v1/certificates/validate")

    try{
        $ret = doPost -Server $Server -Api $uri -Username $Username -Password $Password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS

Update VXM certificate

.DESCRIPTION
Optional parameter -Version only support v3, default value is v3.

.NOTES

You can run this cmdlet to update VxM certificate.

.EXAMPLE

PS> Start-CertificateImport -Server <VxM IP or FQDN> -Username <username> -Password <password> -CertContent <cert content> -RootCertChain <root cert content>  -PrivateKey <private key> -PfxPassword <.pfx password> -VcAdminAccount <account> -VcAdminPassword <password>

Update VxM certificate
#>
function Start-CertificateImport {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $true)]
        # .crt file content
        [String] $CertContent,

        [Parameter(Mandatory = $true)]
        # Root certificate content
        [String[]] $RootCertChain,

        [Parameter(Mandatory = $false)]
        # .key file content
        [String] $PrivateKey,

        [Parameter(Mandatory = $false)]
        # The password for new .pfx fi:q!le
        [String] $PfxPassword,

        [Parameter(Mandatory = $true)]
        # VC admin account for invoke VC API to send the new root cert to VC trust store.
        [String] $VcAdminAccount,

        [Parameter(Mandatory = $true)]
        # VC admin password for invoke VC API to send the new root cert to VC trust store.
        [String] $VcAdminPassword,

        # Optional, API version. Only support v3, default value is v3.
        [Parameter(Mandatory = $false)]
        [String] $Version = "v3"
    )

    $Body = @{
        "cert" = $CertContent.replace("\n","`n")
        "root_cert_chain" = $RootCertChain.replace("\n","`n")
        "private_key" = $PrivateKey.replace("\n","`n")
        "password" = $PfxPassword
        "vc_admin_account" = $VcAdminAccount
        "vc_admin_password" = $VcAdminPassword

    } | ConvertTo-Json

    $uri = "/rest/vxm/" + $Version.ToLower() + "/certificates/import-vxm"

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS
Update automated renewal configurations of the certificate through SCEP

.DESCRIPTION
Update automated renewal configurations of the VxRail Manager TLS certificate through SCEP.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter CaServerURL
Certificate Authority server URL.

.Parameter ChallengePassword
Challenge password.

.Parameter ScepOn
Enable or disable the automated renewal. Valid value is $True or $False.

.Parameter ScepRenewalInterval
Certificate validation frequency in minutes. Valid range is 60 - 1440.

.Parameter ScepDaysBeforeExpire
Days to renew the certificate before expiration. Valid range is 14 - 60.

.Parameter Format
Print JSON style format.

.Parameter Version
Optional. API version. Only input v1. Default value is v1.

.NOTES
You can run this cmdlet to update automated renewal configurations of the VxRail Manager TLS certificate through SCEP.

.EXAMPLE
PS> Update-SCEPConfig -Server <VxM IP or FQDN> -Username <username> -Password <password> -CaServerURL <CA server URL> -ChallengePassword <challenge password> -ScepOn $True -ScepRenewalInterval 180 -ScepDaysBeforeExpire 30

Update automated renewal configurations of certificate through SCEP

#>
function Update-SCEPConfig {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $true)]
        # Certificate Authority server URL
        [String] $CaServerURL,

        [Parameter(Mandatory = $true)]
        # Challenge password
        [String] $ChallengePassword,

        [Parameter(Mandatory = $true)]
        # Enable or disable the automated renewal
        [Bool] $ScepOn,

        [Parameter(Mandatory = $true)]
        # Certificate validation frequency in minutes
        [int] $ScepRenewalInterval,

        [Parameter(Mandatory = $true)]
        # Days to renew the certificate before expiration
        [int] $ScepDaysBeforeExpire,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $false)]
        # API version
        [String] $Version = "v1"
    )

    $Body = @{
        "caserver_url" = $CaServerURL
        "challenge_password" = $ChallengePassword
        "scep_on" = $ScepOn
        "scep_renewal_interval_in_minutes" = $ScepRenewalInterval
        "scep_days_before_expire" = $ScepDaysBeforeExpire

    } | ConvertTo-Json

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/certificates/scep/config"

    try{
        $ret = doPost -Server $server -Api $uri -Username $username -Password $password -Body $Body
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS
Get automated renewal configurations of the certificate

.DESCRIPTION
Get automated renewal configurations of the VxRail Manager TLS certificate.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Version
Optional. API version. Only input v1. Default value is v1.

.NOTES
You can run this cmdlet to get automated renewal configurations of the VxRail Manager TLS certificate.

.EXAMPLE
PS> Get-SCEPConfig -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get automated renewal configurations of the certificate

#>
function Get-SCEPConfig {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $false)]
        # API version
        [String] $Version = "v1"
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/certificates/scep/config"

    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}

<#
.SYNOPSIS
Get automated renewal status of the certificate

.DESCRIPTION
Get automated renewal status of the VxRail Manager TLS certificate.

.Parameter Server
VxM IP or FQDN.

.Parameter Username
Valid vCenter username which has either Administrator or HCIA role.

.Parameter Password
Use corresponding password for username.

.Parameter Format
Print JSON style format.

.Parameter Version
Optional. API version. Only input v1. Default value is v1.

.NOTES
You can run this cmdlet to get automated renewal status of the VxRail Manager TLS certificate.

.EXAMPLE
PS> Get-SCEPStatus -Server <VxM IP or FQDN> -Username <username> -Password <password>

Get automated renewal status of the certificate

#>
function Get-SCEPStatus {
    param(
        [Parameter(Mandatory = $true)]
        # VxM IP or FQDN
        [string] $Server,

        [Parameter(Mandatory = $true)]
        # Valid vCenter username which has either Administrator or HCIA role
        [String] $Username,

        [Parameter(Mandatory = $true)]
        # Use corresponding password for username
        [String] $Password,

        [Parameter(Mandatory = $false)]
        # Print JSON style format
        [switch] $Format,

        [Parameter(Mandatory = $false)]
        # API version
        [String] $Version = "v1"
    )

    $uri = "/rest/vxm/" + $Version.ToLower() + "/cluster/certificates/scep/status"

    try{
        $ret = doGet -Server $server -Api $uri -Username $username -Password $password
        if($Format) {
            $ret = $ret | ConvertTo-Json
        }
        return $ret
    } catch {
        write-host $_
    }
}
