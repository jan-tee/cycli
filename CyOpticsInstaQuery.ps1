<#
.SYNOPSIS
    Creates a new InstaQuery.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function New-CyInstaQuery {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true)]
        [String]$Name,
        [parameter(Mandatory=$false)]
        [String]$Description,
        [parameter(Mandatory=$true)]
        [ValidateSet ("File_Path", 
                        "File_MD5", 
                        "File_SHA256", 
                        "File_Owner", 
                        "File_CreationDateTime", 
                        "Process_Name", 
                        "Process_CommandLine", 
                        "Process_PrimaryImagePath", 
                        "Process_PrimaryImageMd5", 
                        "Process_StartDateTime", 
                        "NetworkConnection_DestAddr", 
                        "NetworkConnection_DestPort", 
                        "RegistryKey_ProcessName", 
                        "RegistryKey_ProcessPrimaryImagePath", 
                        "RegistryKey_ValueName", 
                        "RegistryKey_FilePath", 
                        "RegistryKey_FileMd5", 
                        "RegistryKey_IsPersistencePoint")]
        [String]$QueryType,
        [parameter(Mandatory=$false)]
        [bool]$CaseSensitive = $false,
        [parameter(Mandatory=$false)]
        [ValidateSet ("Fuzzy", "Exact")]
        [String]$MatchType = "Fuzzy",
        [parameter(Mandatory=$true)]
        [String[]]$Value,
        [parameter(Mandatory=$true)]
        [object[]]$Zones
    )

    Begin {
    }

    Process {
        $qt = $QueryType.Split("_")
        $params = @{
            name = $Name;
            case_sensitive = $CaseSensitive;
            match_type = $MatchType;
            match_values = @( $Value );
            artifact = $qt[0];
            match_value_type = $qt[1];
            zones = @( $Zones.id | ForEach-Object { $_.ToUpper() -replace "-" } )
#            filters = @{
                #aspect = "OS";
                #value = "Windows"
            #}
        }

        if (![String]::IsNullOrEmpty($Description)) {
            $params.description = $Description
        }


        $json = '{"name":"powershe- Proc Name","description":"","artifact":"Process","match_value_type":"Name","match_values":["powershell.exe"],"case_sensitive":false,"match_type":"Fuzzy","zones":["979951FC8E724A51B31105AC19BC1C8B","2D567BB4B1144F77BD4EB4D2D111AB70"]}' | ConvertFrom-Json
        $json = ConvertTo-Json $json

        $json = ConvertTo-Json $params
        $json

        Invoke-CyRestMethod -Method POST -API $API -Uri "$($API.BaseUrl)/instaqueries/v2" -Body $json
    }
}

<#
.SYNOPSIS
    Gets an InstaQuery status

    .PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyInstaQueryResults {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$false)]
        [Object]$InstaQuery
    )

    $queryId = $InstaQuery.id

    Invoke-CyRestMethod -API $API -Method GET -Uri "$($API.BaseUrl)/instaqueries/v2/$($queryId)/results"
}

<#
.SYNOPSIS
    Gets all InstaQuery queries in the tenant

    .PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyInstaQueries {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$false)]
        [bool]$IncludeArchived = $false,
        [parameter(Mandatory=$false)]
        [String]$Query = "",
        [parameter(Mandatory=$false)]
        [ValidateSet ("name", "description", "artifact", "match_value_type")]
        [string]$Sort
    )

    $params = @{
        archived = $IncludeArchived;
        q = $Query
    }

    if (![String]::IsNullOrEmpty($Sort)) {
        $params.sort = $Sort
    }

    Read-CyData -API $API -Uri "$($API.BaseUrl)/instaqueries/v2" -QueryParams $params
}
