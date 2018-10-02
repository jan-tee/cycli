<#
.SYNOPSIS
    Gets a list of all policies from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyPolicyList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
        )

    Read-CyData -API $API -Uri "$($API.BaseUrl)/policies/v2"
}

<#
.SYNOPSIS
    Sets the policy for a specific device

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Device
    The device(s) to set policy for

.PARAMETER Policy
    The policy to assign to device
#>
function Set-CyPolicyForDevice {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object]$Device,
        [Parameter(Mandatory=$true)]
        [object]$Policy
    )

    Begin {
        if ($null -eq $Policy.id) {
            throw "Policy object does not contain 'id' property."
        }
    }

    Process {
        $updateMap = @{
            "name" = $($Device.name)
            "policy_id" = $($Policy.id)
        }

        $json = $updateMap | ConvertTo-Json
        # remain silent
        $null = Invoke-CyRestMethod -API $API -Method PUT -Uri "$($API.BaseUrl)/devices/v2/$($Device.id)" -ContentType "application/json; charset=utf-8" -Body $json
    }
}

<#
.SYNOPSIS
    Retrieves the given Policy from the console. Gets the full version, not a shallow object.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Policy
    The policy to retrieve.
#>
function Get-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Policy
        )

    Process {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/policies/v2/$($Policy.id)" | Convert-CyObject
    }
}

<#
.SYNOPSIS
    Creates a new policy.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Name
    The name of the new policy

.PARAMETER Policy
    The policy object.

#>
function New-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$Name,
        [Parameter(Mandatory=$true)]
        [object]$Policy = $null
    )
    Begin {
    }

    Process {
        $Policy.id = $null
        $Policy.utc_timestamp = $null
        $Policy.checksum = $null

        $updateMap = @{
            "policy" = $($Policy)
            "user_id" =$($API.APIId)
        }

        $json = $updateMap | ConvertTo-Json
        Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/policies/v2" -ContentType "application/json; charset=utf-8" -Body $json
    }
}

<#
.SYNOPSIS
    Removes the given Policy from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Policy
    The policy to retrieve the Detail for.
#>
function Remove-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object[]]$Policy
        )

    Process {
        Invoke-CyRestMethod -API $API -Method DELETE -Uri  "$($API.BaseUrl)/policies/v2/$($Policy.id)" | Convert-CyObject
    }
}
