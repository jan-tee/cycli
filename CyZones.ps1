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
            $Device = Get-CyDeviceList | Where-Object name -eq $DeviceName
            Get-CyZoneList -API $API -Device $Device
        }
        "ByDevice" {
            Read-CyData -API $API -Uri "$($API.BaseUrl)/zones/v2/$($Device.id)/zones"
        }
        "All" {
            Read-CyData -API $API -Uri "$($API.BaseUrl)/zones/v2"
        }
    }
}

<#
.SYNOPSIS
    Retrieves the given ZONE Detail from the console. Gets full data, not a shallow version.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAM Zone
    The zone object to fetch Detail for.

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
                Get-CyZoneList -API $API | Where-Object name -eq $Name
            }
            "ByZoneObject" {
                Write-Verbose "Get-CyZone: Getting zone via zone object for zone ID '$($Zone.id)'"
                Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/zones/v2/$($Zone.id)"
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
    }

    Process {
        $updateMap = @{
            "name" = $($Name)
            "policy_id" = $($Policy.id)
            "criticality" = $Criticality
        }

        $json = $updateMap | ConvertTo-Json
        Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/zones/v2" -ContentType "application/json; charset=utf-8" -Body $json
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
    }

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByZoneName" {
                $Zone = Get-CyZone -API $API -Name $Name
                Remove-CyZone -API $API -Zone $Zone
            }
            "ByZone" {
                Invoke-CyRestMethod -API $API -Method DELETE -Uri "$($API.BaseUrl)/zones/v2/$($Zone.id)" -ContentType "application/json; charset=utf-8"
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
    }

    Process {
        if (($null -eq $Device) -or ($null -eq $Device.id) -or ([String]::IsNullOrEmpty($Device.id))) {
            throw "Add-CyDeviceToZone: Device ID cannot be null or empty."
        }

        if (($null -eq $Device.policy) -or ($null -eq $Device.policy.id) -or ([String]::IsNullOrEmpty($Device.policy.id))) {
            throw "Add-CyDeviceToZone: Device policy ID cannot be null or empty."
        }

        $updateMap = @{
            "name" = $($Device.name)
            "policy_id" = $($Device.policy.id)
            "add_zone_ids" = $zoneIds
        }

        $json = $updateMap | ConvertTo-Json
        Write-Verbose "Update device JSON: $($json)"
        # remain silent
        $null = Invoke-CyRestMethod -API $API -Method PUT -Uri "$($API.BaseUrl)/devices/v2/$($Device.id)" -ContentType "application/json; charset=utf-8" -Body $json
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
    }

    Process {
        $updateMap = @{
            "name" = $($Device.name)
            "policy_id" = $($Device.policy.id)
            "remove_zone_ids" = $zoneIds
        }

        $json = $updateMap | ConvertTo-Json
        # remain silent
        $null = Invoke-CyRestMethod -API $API -Method PUT -Uri "$($API.BaseUrl)/devices/v2/$($Device.id)" -ContentType "application/json; charset=utf-8" -Body $json
    }
}

<#
.SYNOPSIS
    Updates a zone.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Zone
    The zone to modify.

.PARAMETER Name
    Optional. Thenew  name of the zone.

.PARAMETER Policy
    Optional. The new policy to set as the policy for the zone. NOTE, this does NOT affect the policy set on any device assigned to the zone! This is by principle and you'll have to look at the Cylance docs to better understand what this means.

.PARAMETER Criticality
    Optional. The new criticality to set for the zone.
#>
function Update-CyZone {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true)]
        [object]$Zone,
        [String]$Name = $null,
        [Parameter(Mandatory=$false)]
        [object]$Policy = @{ id = $null},
        [Parameter(Mandatory=$false)]
        [ValidateSet("Low", "Normal", "High")]
        [String]$Criticality
    )

    # default to existing
    $updateMap = @{
        name = $Zone.name
        policy_id = $Zone.policy_id
        criticality = $Zone.criticality
    }

    # update provided properties only
    if (![String]::IsNullOrEmpty($Name)) {
        $updateMap.name = $Name
    }
    if ($null -ne $Policy) {
        if (![String]::IsNullOrEmpty($Policy.id)) {
            $updateMap.policy_id = $Policy.id
        } else {
            $updateMap.policy_id = $Policy.policy_id
        }
    }
    if (![String]::IsNullOrEmpty($Criticality)) {
        $updateMap.criticality = $Criticality
    }

    $json = $updateMap | ConvertTo-Json
    Write-Verbose "Update zone JSON: $json"
    # remain silent
    $null = Invoke-CyRestMethod -API $API -Method PUT -Uri "$($API.BaseUrl)/zones/v2/$($Zone.id)" -ContentType "application/json; charset=utf-8" -Body $json
}