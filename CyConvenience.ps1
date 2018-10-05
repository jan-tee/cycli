<#
.SYNOPSIS
	A collection of convenience verbs to work with the Cylance Console API v2.

.DESCRIPTION
    Contains methods that are helpful, but do not represent API primitives, or are wrappers around API methods.

.LINK
    Blog: http://tietze.io/
    Jan Tietze
#>

<#
.SYNOPSIS
    Gets a user by email

.PARAMETER Email
    The user's email address
#>
function Get-CyUserByEmail {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true)]
        [string]$Email
        )

    Get-CyUserList | Where-Object email -eq $Email
}
