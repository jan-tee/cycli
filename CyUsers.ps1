function Get-CyUserList {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
        )

    Get-CyDataPages -API $API -Uri "$($API.BaseUri)/users/v2"
}

function Get-CyUserDetails {
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
                $url = "$($API.BaseUri)/users/v2/$($UserId)"
            }
            "ByUser" {
                $url = "$($API.BaseUri)/users/v2/$($User.id)"
            }
        }

        # Get-CyDataPages -API $API -Uri $url
        Invoke-RestMethod -Method GET -Uri $url -Header $headers -UserAgent "" | Convert-CyTypes
    }
}
