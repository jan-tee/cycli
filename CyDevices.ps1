<#
.SYNOPSIS
    Gets a list of all devices in console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER ZoneName
    Optional. The name of a zone to retrieve member devices for.

.PARAMETER Zone
    Optional. A zone object to retrieve member devices for.
#>
function Get-CyDeviceList {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true,ParameterSetName="ByZoneName")]
        [String]$ZoneName,
        [parameter(Mandatory=$true,ParameterSetName="ByZone")]
        [object]$Zone
        )

    switch ($PSCmdlet.ParameterSetName) {
        "ByZoneName" {
            $Zone = Get-CyZone -API $API -Name $ZoneName
            Get-CyDeviceList -API $API -Zone $Zone
        }
        "ByZone" {
            Read-CyData -API $API -Uri "$($API.BaseUrl)/devices/v2/$($Zone.id)/devices"
        }
        "All" {
            Read-CyData -API $API -Uri "$($API.BaseUrl)/devices/v2"
        }
    }
}


<#
.SYNOPSIS
    Deletes a device.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Device
    The device object to apply this threat action to.
#>
function Remove-CyDevice {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            ParameterSetName="ByDevice",
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Device,
        [Parameter(Mandatory=$true,ParameterSetName="ByDeviceId")]
        [object]$DeviceId,
        [Parameter(Mandatory=$false)]
        [object]$CallbackUrl


    )

    Begin {
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
        $devices = @()
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
        $output = Invoke-RestMethod -Method DELETE -Uri "$($API.BaseUrl)/devices/v2" -ContentType "application/json; charset=utf-8" -Header $headers -UserAgent "" -Body $json
    }
}

<#
.SYNOPSIS
    Retrieves the given DEVICE from the console. Gets full data, not a shallow version.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Device
    The device to retrieve the Detail for.
#>
function Get-CyDeviceDetail {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Device
        )

    Process {
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
        Invoke-RestMethod -Method GET -Uri  "$($API.BaseUrl)/devices/v2/$($Device.id)" -Header $headers -UserAgent "" | Convert-CyObject
    }
}

<#
.SYNOPSIS
    Retrieves the given DEVICE from the console. Gets full data, not a shallow version.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Device
    The device to retrieve the Detail for.
#>
function Get-CyDeviceDetailByMac {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [String]$MAC
        )

    Process {
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
        Invoke-RestMethod -Method GET -Uri  "$($API.BaseUrl)/devices/v2/macaddress/$($MAC)" -Header $headers -UserAgent ""
    }
}