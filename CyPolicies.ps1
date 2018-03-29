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
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }

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
        $null = Invoke-RestMethod -Method PUT -Uri "$($API.BaseUrl)/devices/v2/$($Device.id)" -ContentType "application/json; charset=utf-8" -Header $headers -UserAgent "" -Body $json
    }
}

<#
.SYNOPSIS
    Retrieves the given Policy from the console. Gets the full version, not a shallow object.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Policy
    The device to retrieve the Detail for.
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
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }
        Invoke-RestMethod -Method GET -Uri  "$($API.BaseUrl)/policies/v2/$($Policy.id)" -Header $headers -UserAgent "" | Convert-CyObject
    }
}
