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
