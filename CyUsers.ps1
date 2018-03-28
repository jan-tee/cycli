function Get-CyUserList {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
        )

    Read-CyData -API $API -Uri "$($API.BaseUrl)/users/v2"
}

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
        $headers = @{
            "Accept" = "application/json"
            "Authorization" = "Bearer $($API.AccessToken)"
        }

        switch ($PSCmdlet.ParameterSetName) {
            "ByUserIdOrEmail" {
                $url = "$($API.BaseUrl)/users/v2/$($UserId)"
            }
            "ByUser" {
                $url = "$($API.BaseUrl)/users/v2/$($User.id)"
            }
        }

        # Read-CyData -API $API -Uri $url
        Invoke-RestMethod -Method GET -Uri $url -Header $headers -UserAgent "" | Convert-CyObject
    }
}
