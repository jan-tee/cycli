<#
.SYNOPSIS
    Gets a list of all detection rules from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyDetectionRuleList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
    )

    Read-CyData -API $API -Uri "$($API.BaseUrl)/rules/v2"
}

<#
.SYNOPSIS
    Retrieves the given detection rule native JSON structure

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Exception
    The detection rule to retrieve.
#>
function Get-CyDetectionRuleDetail {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Rule
        )

    Process {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/rules/v2/$($Rule.id)" | Convert-CyObject
    }
}


<#
.SYNOPSIS
    Gets a list of all detection rules from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyDetectionExceptionList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
    )

    Read-CyData -API $API -Uri "$($API.BaseUrl)/exceptions/v2"
}

<#
.SYNOPSIS
    Retrieves the given detection exception native JSON structure

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Exception
    The exception to retrieve.
#>
function Get-CyDetectionExceptionDetail {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Exception
        )

    Process {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/exceptions/v2/$($Exception.id)" | Convert-CyObject
    }
}