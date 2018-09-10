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
        # remain silent
        switch ($PSCmdlet.ParameterSetName) {
            "ByDeviceId" {
                $devices += $DeviceId
            }
            "ByDevice" {
                $devices += $Device.id
            }
        }
    }

    End {
        $updateMap = @{
            "device_ids" = $devices
        }

        if (![String]::IsNullOrEmpty($CallbackUrl)) {
            $updateMap += @{ "url" = $CallbackUrl }
        }

        $json = $updateMap | ConvertTo-Json
        Write-verbose "Update Map: $($json)"
        # remain silent
        $null = Invoke-CyRestMethod -API $API -Method DELETE -Uri "$($API.BaseUrl)/devices/v2" -ContentType "application/json; charset=utf-8" -Body $json
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
                "detection_id" = $DetectionId;
                "field_to_update" = $updateFields;
            }
        )
        $json = $transaction | ConvertTo-Json
        Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/detections/v2" -Body $json
    }
}