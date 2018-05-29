<#
.SYNOPSIS
    Gets a link for the agent installer.

.PARAMETER Product
    Protect or Optics

.PARAMETER OS
    Operating System

.PARAMETER Architecture
    Architecture. Contains some unexpected choices like CentOS6 base/UI etc. 

.PARAMETER Package
    Format. Does not apply to Linux. Required for all other OSes.
#>
function Get-CyAgentInstallerLink {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true)]
        [ValidateSet("Protect", "Optics")]
        [String]$Product,
        [parameter(Mandatory=$true)]
        [ValidateSet("CentOS7", "Linux", "Mac", "Ubuntu1404", "Ubuntu1604", "Windows")]
        [String]$OS,
        [parameter(Mandatory=$true)]
        [ValidateSet("X86", "X64", "CentOS6", "CentOS6UI", "CentOS7", "CentOS7UI", "Ubuntu1404", "Ubuntu1404UI", "Ubuntu1604", "Ubuntu1604UI")]
        [String]$Architecture,
        [parameter(Mandatory=$false)]
        [ValidateSet("Exe", "Msi", "Dmg", "Pkg")]
        [String]$Package
        )

        if (($OS -notmatch "CentOS.*|Linux|Ubuntu.*") -and ([String]::IsNullOrEmpty($Package))) {
            Throw "For non-Linux OS, parameter 'Package' must be set."
        }
 
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
        Invoke-CyRestMethod -Method GET -Uri  "$($API.BaseUrl)/devices/v2/installer?product=$($Product)&os=$($OS)&package=$($Package)&architecture=$($Architecture)" -Headers $headers
}