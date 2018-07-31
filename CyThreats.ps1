<#
.SYNOPSIS
    Gets the threat list for the given device

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Device
    The device to retrieve the threats for.
#>
function Get-CyDeviceThreatList {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,ParameterSetName="ByDevice",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [object]$Device,
        [Parameter(Mandatory=$true,ParameterSetName="ByDeviceId")]
        [object]$DeviceId
        )

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByDevice" {
                $Uri = "$($API.BaseUrl)/devices/v2/$($Device.id)/threats"
            }
            "ByDeviceId" {
                $Uri = "$($API.BaseUrl)/devices/v2/$($DeviceId)/threats"
            }
        }
        
        Read-CyData -API $API -Uri $Uri    
    }
}

<#
.SYNOPSIS
    Update a device threat.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Action
    The action to take (quarantine or waive the threat)

.PARAMETER Device
    The device object to apply this threat action to.
#>
function Update-CyDeviceThreat {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$DeviceThreat,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Quarantine", "Waive")]
        [String]$Action,
        [Parameter(Mandatory=$true,ParameterSetName="ByDevice")]
        [object]$Device,
        [Parameter(Mandatory=$true,ParameterSetName="ByDeviceId")]
        [object]$DeviceId

    )

    Begin {
    }

    Process {
        $hash = $DeviceThreat.sha256
        if ($null -eq $hash) {
            $hash = $DeviceThreat
        }

        $updateMap = @{
            "threat_id" = $($hash)
            "event" = $Action
        }

        $json = $updateMap | ConvertTo-Json
        # remain silent
        switch ($PSCmdlet.ParameterSetName) {
            "ByDeviceId" {
                $output = Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/devices/v2/$($DeviceId)/threats" -ContentType "application/json; charset=utf-8" -Body $json
            }
            "ByDevice" {
                $output = Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/devices/v2/$($Device.id)/threats" -ContentType "application/json; charset=utf-8" -Body $json
            }
        }
        
    }
}

<#
.SYNOPSIS
    Retrieves the given threat's Detail from the console. Gets full data, not a shallow version.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER SHA256
    A collection of SHA256 values (as strings) to retrieve the data for.
#>
function Get-CyThreatDetail {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [String[]]$SHA256
        )

    Process {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/threats/v2/$($SHA256)" | Convert-CyObject
    }
}

<#
.SYNOPSIS
    Retrieves a download link for the given threat

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER SHA256
    The threat to retrieve the download link for.
#>
function Get-CyThreatDownloadLink {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [String[]]$SHA256
        )

    Process {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/threats/v2/download/$($SHA256)" 
    }
}


<#
.SYNOPSIS
    Gets the devices affected by a particular threat.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER SHA256
    The threat SHA256 hash
#>
function Get-CyThreatDeviceList {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,ParameterSetName="ByDevice",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [object]$SHA256
        )

    Process {
        Read-CyData -API $API -Uri "$($API.BaseUrl)/threats/v2/$($SHA256)/devices"
    }
}
