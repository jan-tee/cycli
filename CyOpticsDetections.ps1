<#
.SYNOPSIS
    Gets a list of all detections from the console.

    Note that this does 

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyDetectionList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$false)]
        [DateTime]$Start,
        [parameter(Mandatory=$false)]
        [DateTime]$End,
        [parameter(Mandatory=$false)]
        [ValidateSet ("Informational", "Low", "Medium", "High")]
        [String]$Severity,
        [parameter(Mandatory=$false)]
        [String]$DetectionType,
        [parameter(Mandatory=$false)]
        [String]$DetectedOn,
        [parameter(Mandatory=$false)]
        [String]$EventNumber,
        [parameter(Mandatory=$false)]
        [String]$Device,
        [parameter(Mandatory=$false)]
        [ValidateSet ("New", "False Positive", "Follow Up", "In Progress", "Reviewed", "Done")]
        [string]$Status,
        [parameter(Mandatory=$false)]
        [ValidateSet ("Severity", "OccurrenceTime", "Status", "Device", "PhoneticId", "Description")]
        [string]$Sort
    )

    $params = @{}

    if ($null -ne $Start) {
        $params.start = ConvertTo-CyDateString -Date $Start

    }
    if ($null -ne $End) {
        $params.end = ConvertTo-CyDateString -Date $End
    }
    if (![String]::IsNullOrEmpty($Severity)) {
        $params.severity = $Severity
    }

    if (![String]::IsNullOrEmpty($Status)) {
        $params.status = $Status
    }

    if (![String]::IsNullOrEmpty($Device)) {
        $params.device = $Device
    }

    if (![String]::IsNullOrEmpty($DetectionType)) {
        $params.detection_type = $DetectionType
    }

    if (![String]::IsNullOrEmpty($DetectedOn)) {
        $params.detected_on = $DetectedOn
    }

    if (![String]::IsNullOrEmpty($EventNumber)) {
        $params.event_number = $EventNumber
    }

    if (![String]::IsNullOrEmpty($Sort)) {
        $params.sort = $Sort
    }

    Read-CyData -API $API -Uri "$($API.BaseUrl)/detections/v2" -QueryParams $params
}

<#
.SYNOPSIS
    Gets a list of all detections from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyDetectionRecentList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true)]
        [DateTime]$Since
    )

    $params = @{
        Since = ConvertTo-CyDateString -Date $Since
    }   

    Read-CyData -API $API -Uri "$($API.BaseUrl)/detections/v2/recent" -QueryParams $params
}


<#
.SYNOPSIS
    Gets a list of all detections from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyDetectionDetail {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [object]$Detection
        )

    Begin
    {

    }

    Process
    {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/detections/v2/$($Detection.id)/details" | Convert-CyObject
    }
}

<#
.SYNOPSIS
    Deletes a detection.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Detection
    The detection object to delete.
#>
function Remove-CyDetection {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [object]$Detection
    )

    Begin {
    }

    Process {
        if (($null -eq $Detection) -or ($null -eq $Detection.id) -or ([String]::IsNullOrEmpty($Detection.id))) {
            throw "Remove-CyDetection: Detection ID cannot be null or empty."
        }
        $null = Invoke-CyRestMethod -API $API -Method DELETE -Uri "$($API.BaseUrl)/detections/v2/$($Detection.id)" -ContentType "application/json; charset=utf-8"
    }
}


<#
.SYNOPSIS
    Updates a detection's fields.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Update-CyDetection {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$false)]
        [ValidateSet ("New", "False Positive", "Follow Up", "In Progress", "Reviewed", "Done")]
        [string]$Status,
        [parameter(Mandatory=$false)]
        [string]$Comment,
        [parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [object]$Detection
        )

    Begin {
        $updateFields = @{}
        if (![String]::IsNullOrEmpty($Status)) {
            $updateFields.status = $Status
        }
        if (![String]::IsNullOrEmpty($Comment)) {
            $updateFields.comment = $Comment
        }
    }

    Process {
        $transaction = @(
            @{
                "detection_id" = $Detection.Id;
                "field_to_update" = $updateFields;
            }
        )
        $json = ConvertTo-Json $transaction
        Write-Verbose "$($json)"
        Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/detections/v2/update/" -Body $json
    }
}

<#
.SYNOPSIS
    Gets a list of all detection exceptions from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>

function Get-CyDetectionExceptionList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
    )
    Read-CyData -API $API -Uri "$($API.BaseUrl)/exceptions/v2" -QueryParams $params
}


<#
.SYNOPSIS
    Gets a definition for a detection exception

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Exception
    The exception to retrieve (use object obtained with "Get-CyDetectionExceptionList")
#>
function Get-CyDetectionExceptionDetail {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [object[]]$Exception
    )

    Begin {

    }

    Process {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/exceptions/v2/$($Exception.id)" | Convert-CyObject
    }
}
