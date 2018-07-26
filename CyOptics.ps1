<#
.SYNOPSIS
    Gets a list of all detections from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyDetectionList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
        )

    Read-CyData -API $API -Uri "$($API.BaseUrl)/detections/v2"
}