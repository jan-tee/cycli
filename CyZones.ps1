<#
.SYNOPSIS
    Gets a list of all zones from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER DeviceName
    Optional. Get zone list for a particular device name.

.PARAMETER Device
    Optional. Get zone list for a particular device.
#>
function Get-CyZoneList {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true,ParameterSetName="ByDeviceName")]
        [String]$DeviceName,
        [parameter(Mandatory=$true,ParameterSetName="ByDevice")]
        [object]$Device
        )


    switch ($PSCmdlet.ParameterSetName) {
        "ByDeviceName" {
            $Device = Get-CyDeviceList | where name -eq $DeviceName
            Get-CyZoneList -API $API -Device $Device
        }
        "ByDevice" {
            Get-CyDataPages -API $API -Uri "$($API.BaseUri)/zones/v2/$($Device.id)/zones"
        }
        "All" {
            Get-CyDataPages -API $API -Uri "$($API.BaseUri)/zones/v2"
        }
    }
}

<#
.SYNOPSIS
    Retrieves the given ZONE details from the console. Gets full data, not a shallow version.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAM Zone
    The zone object to fetch details for.

.PARAM ZoneName
    The zone name to fetch the zone object for.
#>
function Get-CyZone {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="ByZoneObject")
            ]
            [object[]]$Zone,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName="ByZoneName")
            ]
            [String[]]$Name
        )

    Process {
        switch ($PSCmdlet.ParameterSetName)
        {
            "ByZoneName" {
                Write-Verbose "Get-CyZone: Getting zone by name '$($Name)'"
                Get-CyZoneList | Where name -eq $Name
            }
            "ByZoneObject" {
                Write-Verbose "Get-CyZone: Getting zone via zone object for zone ID '$($Zone.id)'"
                $headers = @{
                    "Accept" = "application/json"
                    "Authorization" = "Bearer $($API.AccessToken)"
                }
                Invoke-RestMethod -Method GET -Uri  "$($API.BaseUri)/zones/v2/$($Zone.id)" -Header $headers -UserAgent ""
            }
        }
    }
}

<#
.SYNOPSIS
    Creates a new zone.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Name
    The name of the new zone

.PARAMETER Policy
    Optional. The policy for the new zone

.PARAMETER Criticality
    Optional. The criticality for the new zone
#>
function New-CyZone{
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
        [Parameter(Mandatory=$false)]
        [object]$Policy = @{ id = $null},
        [Parameter(Mandatory=$false)]
        [ValidateSet("Low", "Normal", "High")]
        [String]$Criticality = "Normal"

    )
    Begin {
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
    }

    Process {
        $updateMap = @{
            "name" = $($Name)
            "policy_id" = $($Policy.id)
            "criticality" = $Criticality
        }

        $json = $updateMap | ConvertTo-Json
        Invoke-RestMethod -Method POST -Uri "$($API.BaseUri)/zones/v2" -ContentType "application/json; charset=utf-8" -Header $headers -UserAgent "" -Body $json
    }
}

<#
.SYNOPSIS
    Removes a zone.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Name
    The name of a zone to remove

.PARAMETER Zone
    The zone object to remove.
#>
function Remove-CyZone {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,ParameterSetName="ByZoneName",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String]$Name,
        [Parameter(Mandatory=$false,ParameterSetName="ByZone",ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [object]$Zone

    )

    Begin {
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
    }

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByZoneName" {
                $Zone = Get-CyZone -API $API -Name $Name
                Remove-CyZone -API $API -Zone $Zone
            }
            "ByZone" {
                Invoke-RestMethod -Method DELETE -Uri "$($API.BaseUri)/zones/v2/$($Zone.id)" -ContentType "application/json; charset=utf-8" -Header $headers -UserAgent ""
            }
        }
    }
}

<#
.SYNOPSIS
    Adds device(s) to zone(s).

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Zone
    The zone to add the device to.

.PARAMETER Device
    The device(s) to add to the zone.
#>
function Add-CyDeviceToZone {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Device,
        [Parameter(Mandatory=$true)]
        [object]$Zone
    )

    Begin {
        $zoneIds = $Zone.id

        # zone IDs must be an array
        if ($zoneIds -isnot [array]) {
            $zoneIds = @($zoneIds)
        }

        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
    }

    Process {
        $updateMap = @{
            "name" = $($Device.name)
            "policy_id" = $($Device.policy.id)
            "add_zone_ids" = $zoneIds
        }

        $json = $updateMap | ConvertTo-Json
        # remain silent
        $output = Invoke-RestMethod -Method PUT -Uri "$($API.BaseUri)/devices/v2/$($Device.id)" -ContentType "application/json; charset=utf-8" -Header $headers -UserAgent "" -Body $json
    }
}
<#
.SYNOPSIS
    Removes device(s) from zone(s).

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Zone
    The zone to add the device to.

.PARAMETER Device
    The device(s) to add to the zone.
#>
function Remove-CyDeviceFromZone {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Device,
        [Parameter(Mandatory=$true)]
        [object]$Zone
    )

    Begin {
        $zoneIds = $Zone.id

        # zone IDs must be an array
        if ($zoneIds -isnot [array]) {
            $zoneIds = @($zoneIds)
        }

        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
    }

    Process {
        $updateMap = @{
            "name" = $($Device.name)
            "policy_id" = $($Device.policy.id)
            "remove_zone_ids" = $zoneIds
        }

        $json = $updateMap | ConvertTo-Json
        # remain silent
        $output = Invoke-RestMethod -Method PUT -Uri "$($API.BaseUri)/devices/v2/$($Device.id)" -ContentType "application/json; charset=utf-8" -Header $headers -UserAgent "" -Body $json
    }
}
