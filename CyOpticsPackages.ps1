<#
.SYNOPSIS
    Gets a list of all packages from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyPackagesList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$false)]
        [String]$UpdatedByLogin,
        [parameter(Mandatory=$false)]
        [int]$Timeout,
        [parameter(Mandatory=$false)]
        [ValidateSet ("custom", "cylance")]
        [String]$Category,
        [parameter(Mandatory=$false)]
        [ValidateSet ("started", "success", "failed", "timeout")]
        [string]$Status,
        [parameter(Mandatory=$false)]
        [ValidateSet ("packageId", "uploadedOn", "uploadedBy.id", "uploadedBy.login", "size", "status", "timeout", "packageDescriptor.name")]
        [string]$Sort
    )

    $params = @{}

    if (![String]::IsNullOrEmpty($Status)) {
        $params.status = $Status
    }

    if (![String]::IsNullOrEmpty($UpdatedByLogin)) {
        $params.'updatedBy.Login' = $UpdatedByLogin
    }

    if (![String]::IsNullOrEmpty($Category)) {
        $params.category = $Category
    }

    if (![String]::IsNullOrEmpty($DetectedOn)) {
        $params.detected_on = $DetectedOn
    }

    if (0 -ne $Timeout) {
        $params.timeout = $Timeout
    }

    if (![String]::IsNullOrEmpty($Sort)) {
        $params.sort = $Sort
    }

    Read-CyData -API $API -Uri "$($API.BaseUrl)/packages/v2" -QueryParams $params
}
