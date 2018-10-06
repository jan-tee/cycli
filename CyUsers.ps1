<#
.SYNOPSIS
    Gets a list of users in the console
#>
function Get-CyUserList {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
        )

    Read-CyData -API $API -Uri "$($API.BaseUrl)/users/v2"
}

<#
.SYNOPSIS
    Retrieves the details of a user object.

.PARAMETER User
    A user object (retrieved e.g. via Get-CyUserList)

.PARAMETER UserId
    A user ID or email to retrieve the user detail for
#>
function Get-CyUserDetail {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(ParameterSetName="ByUser", Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [object[]]$User,
        [Parameter(Mandatory=$true,ParameterSetName="ByUserIdOrEmail")]
        [object]$UserId
        )

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByUserIdOrEmail" {
                $url = "$($API.BaseUrl)/users/v2/$($UserId)"
            }
            "ByUser" {
                $url = "$($API.BaseUrl)/users/v2/$($User.id)"
            }
        }

        # Read-CyData -API $API -Uri $url
        Invoke-CyRestMethod -API $API -Method GET -Uri $url | Convert-CyObject
    }
}

<#
.SYNOPSIS
    Resolves a human-readable role identifier to the fixed 'guid' assigned to the role.
#>
function RoleToGuid() {
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Role,
        [Parameter(Mandatory=$false)]
        [ValidateSet("User", "Zone")]
        [string]$Type = "User"

    )
    switch ($Type) {
        "User" {
            switch ($Role) {
                "User" {
                    "00000000-0000-0000-0000-000000000001"
                }
                "Administrator" {
                    "00000000-0000-0000-0000-000000000002"
                }
                "ZoneManager" {
                    "00000000-0000-0000-0000-000000000003"
                }
        
            }
        }
        "Zone" {
            switch ($Role) {
                "ZoneManager" {
                    "00000000-0000-0000-0000-000000000001"
                }
                "User" {
                    "00000000-0000-0000-0000-000000000002"
                }        
           }
        }
    }
}

<#
.SYNOPSIS
    Creates a new user account

.PARAMETER UserId
    The user's email address

.PARAMETER FirstName
    The user's first name

.PARAMETER LastName
    The user's first name

.PARAMETER Role
    The user's role

.PARAMETER ZoneRights
    If the user's role is "zone manager", an array of hashtables with pairs of "zone_id" (zone's ID) and "role" ("ZoneManager", "User").
#>
function New-CyUser {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [string]$UserId,
        [Parameter(Mandatory=$true)]
        [string]$FirstName,
        [Parameter(Mandatory=$true)]
        [string]$LastName,
        [Parameter(Mandatory=$true)]
        [ValidateSet ("Administrator","ZoneManager","User")]
        [string]$Role,
        [Parameter(Mandatory=$false)]
        [Hashtable[]]$ZoneRights
        )

    Process {
        $EffectiveRole = RoleToGuid -Role $Role

        $updateMap = @{
            email = $UserId
            user_role = $EffectiveRole
            first_name = $FirstName
            last_name = $LastName
        }


        if ($EffectiveRole -eq "00000000-0000-0000-0000-000000000003")  {
            $EffectiveZoneRights = @()
            foreach ($ZoneRight in $ZoneRights) {
                Write-Host "Zone: $($ZoneRight.zone_id) = $($ZoneRight.role)"

                $EffectiveZoneRights += @{
                    id = $ZoneRight.zone_id
                    role_type = RoleToGuid -Role $ZoneRight.role -Type Zone
                }
            }
            $updateMap.zones = $EffectiveZoneRights

        }

        $json = ConvertTo-Json $updateMap
        Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/users/v2" -Body $json  -ContentType "application/json; charset=utf-8" | Convert-CyObject
    }
}


<#
.SYNOPSIS
    Sends an invite to a user

.PARAMETER UserId
    The user's email address
#>
function Invoke-CySendUserInvite {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$UserId
        )

    Process {
        if ($null -ne $UserId.email) {
            $id = $UserId.email
        } 
        else 
        {
            $id = $UserId
        }

        Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/users/v2/$($id)/invite" -Body "" -ContentType "application/json; charset=utf-8" | Convert-CyObject
    }
}
