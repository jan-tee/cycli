<#
.NAME
    Cylance-API

.SYNOPSIS
	A collection of verbs to work with the Cylance Console API v2

.DESCRIPTION
    Allows retrieval and manipulation of configuration objects in the Cylance console using API v2.

.LINK
    Blog: http://tietze.io/
    Jan Tietze
#>

<#
    Represents the API handle returned by API after authentication
#>
Class CylanceAPIHandle {
    [string]$AccessToken
    [string]$BaseUrl
    [securestring]$APISecret
    [string]$APIId
    [string]$APITenantId
    [datetime]$ExpirationTime
    [string]$Scope
}

Class CylanceGlobalSettings {
    [string]$Proxy
    [PSCredential]$ProxyCredential
    [bool]$ProxyUseDefaultCredentials
}

<#
.TODO
    At some point In the future, artifacts for the API will be classes... if I can figure out how to use dynamic properties in Powershell.
    Type-safe objects would eliminate some issues people run into (confusion about when to use IDs and when to use objects)
#>

Class CylanceDevice {
    [string]$Id
}
Class CylanceZone {
    [string]$Id
}
Class CylanceThreat {
    [string]$Id
}

<#
.SYNOPSIS
    Gets an API access token for the authenticated access to the Console API, valid for 30 minutes.

.PARAMETER APIId
    Optional. API ID

.PARAMETER APISecret
    Optional. API Secret

.PARAMETER APITenantId
    Optional. API Tenant ID

.PARAMETER APIAuthUrl
    Optional. URL to obtain token, e.g. "https://protectapi<-region>.cylance.com/auth/v2/token". Defaults to EUC1 region.
    Use the value obtained from the API documentation for your console shard.

.PARAMETER Scope
    Optional. If you need to access multiple tenants in parallel, use "None" as scope and collect the API object returned.

.PARAMETER Console
    Optional. The console ID in your consoles.json file. See the README for CyCLI module.
#>
function Get-CyAPI {
    Param (
        [parameter(Mandatory=$true, ParameterSetName="Direct")]
        [String]$APIId,
        [parameter(Mandatory=$true, ParameterSetName="Direct")]
        [SecureString]$APISecret,
        [parameter(Mandatory=$true, ParameterSetName="Direct")]
        [String]$APITenantId,
        [parameter(Mandatory=$false, ParameterSetName="Direct")]
        [String]$APIAuthUrl = "https://protectapi-euc1.cylance.com/auth/v2/token",
        [parameter(Mandatory=$false)]
        [ValidateSet ("Session", "None")]
        [String]$Scope = "Session"
        )
    DynamicParam {
        Get-CyConsoleArgumentAutoCompleter -Mandatory -ParameterName "Console" -ParameterSetName "ByReference" -Position 0
    }

    Begin {
        $expirationTimeout = 1800
        switch ($PSCmdlet.ParameterSetName)
        {
            "Direct"
            {
                # decrypt DPAPI protected string into SecureString
                # https://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($APISecret)
                $pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

                $claims = @{}

                $jwtBearerToken = Get-CyJWTToken `
                    -claims $claims `
                    -expirationSeconds $expirationTimeout `
                    -secret $pw `
                    -iss "http://cylance.com" `
                    -tid $APITenantId `
                    -APIid $APIId

                $payload = @{ "auth_token" = $jwtBearerToken } | ConvertTo-Json

                $baseUrl = ([System.Uri]$APIAuthUrl).Scheme + "://" + ([System.Uri]$APIAuthUrl).Host

                $rest = @{
                    Method = "POST"
                    ContentType = "application/json; charset=utf-8"
                    Uri = "$($baseUrl)/auth/v2/token"
                    Body = $payload
                }

                try {
                    Write-Verbose "Requesting auth for JWT token: $($jwtBearerToken)"
                    $result = Invoke-CyRestMethod @rest -DoNotRenewToken
                }
                catch {
                    Write-Error $_.Exception
                    $result = $_.Exception.Response.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($result)
                    $reader.BaseStream.Position = 0
                    $reader.DiscardBufferedData()
                    Write-Error "Could not obtain valid API token. This may mean that (a) your API credentials are incorrect or (b) your API auth URL is incorrect (use Get-Help Get-CyAPI to get a list of URLs), and your code is attempting to authenticate to the wrong global API instance, or (c) the time or time zone on your device is set incorrectly."
                    if ($Scope -eq "Session") {
                        $script:GlobalCyAPIHandle = $null
                    }
                    throw $_.Exception
                    return
                }

                [CylanceAPIHandle]$r = New-Object CylanceAPIHandle
                $r.AccessToken = $result.access_token
                $r.BaseUrl = $baseUrl
                $r.APISecret = $APISecret
                $r.APIId = $APIId
                $r.APITenantId = $APITenantId
                $r.ExpirationTime = (Get-Date).AddSeconds(180) # force token renewal after 3 minutes at all times.
                $r.Scope = $Scope

                if ($Scope -eq "Session") {
                    $script:GlobalCyAPIHandle = $r
                } else {
                    $r
                }
            }
        "ByReference" 
            {
                $ConsoleDetails = (Get-CyConsoleConfig) | Where-Object ConsoleId -eq $PSBoundParameters.Console

                # decrypt DPAPI protected string into SecureString
                # https://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx
                $SecureStringPw = $ConsoleDetails.APISecret | ConvertTo-SecureString

                if ($null -ne $ConsoleDetails.APIUrl) { 
                    $APIAuthUrl = $ConsoleDetails.APIUrl
                }
                $rest = @{
                    APIId = $ConsoleDetails.APIId
                    APISecret = $SecureStringPw
                    APITenantId = $ConsoleDetails.APITenantId
                    APIAuthUrl = $APIAuthUrl
                    Scope = $Scope
                }
                Get-CyAPI @rest
            }
        }
    }

    Process {
    }
}

<#
.SYNOPSIS
    Sets global settings for the API module, e.g. proxy server settings

.PARAMETER Proxy
    Specifies that the module uses a proxy server for the request, rather than connecting directly to the Internet resource. Enter the URI of a network proxy server.

.PARAMETER ProxyCredential

    Specifies a user account that has permission to use the proxy server that is specified by the Proxy parameter. The default is the current user.

    Type a user name, such as "User01" or "Domain01\User01", or enter a PSCredential object, such as one generated by the Get-Credential cmdlet.

    This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.

.PARAMETER ProxyUseDefaultCredentials
    Indicates that the cmdlet uses the credentials of the current user to access the proxy server that is specified by the Proxy parameter.

    This parameter is valid only when the Proxy parameter is also used in the command. You cannot use the ProxyCredential and ProxyUseDefaultCredentials parameters in the same command.
#>
function Set-CyGlobalSettings {
    Param(
        [parameter(Mandatory=$false)]
        [String]$Proxy = $null,
        [parameter(Mandatory=$false)]
        [PSCredential]$ProxyCredential = $null,
        [parameter(Mandatory=$false)]
        [Switch]$ProxyUseDefaultCredentials
    )

    $s = $script:GlobalCyGlobalSettings

    if ($s -eq $null) {
        $s = New-Object CylanceGlobalSettings
    }

    if (![String]::IsNullOrEmpty($Proxy)) {
        $s.Proxy = $Proxy
        if ($ProxyCredential -ne $null) {
            $s.ProxyCredential = $ProxyCredential
        }
    }

    if ($ProxyUseDefaultCredentials -eq $true) {
        $s.ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials
    } else {
        $s.ProxyUseDefaultCredentials = $false
    }

    $script:GlobalCyGlobalSettings = $s
}

<#
.SYNOPSIS
    Retrieves the current global settings for the module session
#>
function Get-CyGlobalSettings {
    if ($script:GlobalCyGlobalSettings -eq $null) {
        $script:GlobalCyGlobalSettings = New-Object CylanceGlobalSettings
    }
    $script:GlobalCyGlobalSettings
}

<#
.SYNOPSIS
    Gets ALL pages for paged query results with maximum page size.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER QueryParams
    Optional. If you need to add any query parameters, supply them in a Hashtable.
#>
function Read-CyData {
    Param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API,
        [parameter(Mandatory=$true)]
        [string]$Uri,
        [parameter(Mandatory=$false)]
        [Hashtable]$QueryParams = @{}
        )

    $page = 1
    do {
        $params = @{
            "page" = $page
            "page_size" = 200
        }
        foreach ($key in $QueryParams.Keys) {
            $params.$key = $QueryParams.$key
        }

        foreach ($key in $params.Keys) {
            Write-Verbose "Read-CyData: GET ${Uri} | $($key) = $($params.$key)"
        }

        $rest = @{
            API = $API
            Method = "GET"
            Uri = $Uri
            Body = $params
        }

        $resp = Invoke-CyRestMethod @rest

        $resp.page_items | foreach-object {
            $_ | Convert-CyObject
        }
        Write-Verbose "Response was page $($resp.page_number) of $($resp.total_pages) pages"

        $page++
    } while ($resp.page_number -lt $resp.total_pages)
}

<#
.SYNOPSIS
    Returns the currently active global (session) CyAPIHandle, if one is set
#>
Function Get-CyAPIHandle {
    $GlobalCyAPIHandle
}

<#
.SYNOPSIS
    Clears the currently active global (session) CyAPIHandle, if one is set
#>
Function Clear-CyAPIHandle {
    $script:GlobalCyAPIHandle = $null
}

<#
.SYNOPSIS
    Converts a date string as returned from the API to a DateTime object

.PARAMETER Date
    The date string as returned by the API
#>
function ConvertFrom-CyDateString {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String]$Date
    )
    # convert e.g. 2018-03-07T13:21:07 to Date
    # convert e.g. 2018-03-07T13:21:07.123 to Date (date_offline uses fractional seconds)
    # convert e.g. 2018-09-01T14:15:47.164Z to Date (OccurenceTime uses Z suffix)
    Write-Verbose "Converting date $($Date) to [DateTime]"
    if ($Date -match ".*Z") 
    {
        # ends with "Z"; remove the last character
        $dt = [DateTime]::ParseExact($Date -replace ".$", "yyyy-MM-ddTHH:mm:ss.FFFFFFF", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal)
    } else {
        $dt = [DateTime]::ParseExact($Date, "yyyy-MM-ddTHH:mm:ss.FFFFFFF", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal)
    }
    Write-Verbose "Conversion result: $($dt)"
    return $dt
}

<#
.SYNOPSIS
    Converts a date to a date/time string as expected by the API

.PARAMETER Date
    The date to convert to string
#>
function ConvertTo-CyDateString {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [DateTime]$Date
    )
    Write-Verbose "Converting date $($Date) to string"

    $dt = ([DateTime]$Date).ToUniversalTime()
    $r = $dt.ToString("yyyy-MM-ddTHH:mm:ss.FFFZ", [Globalization.CultureInfo]::InvariantCulture)
    Write-Verbose "Conversion result: $($r)"
    return $r
}

<#
.SYNOPSIS
    Converts all "date" strings received through the JSON API and turns them into "date" objects.
#>
function Convert-CyObject {
    Param (
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [PSCustomObject]$CyObject
        )
    Begin {
        $fields = @("date_first_registered", "date_offline", "date_last_modified", "date_found", "cert_timestamp", "date_last_login", "date_email_confirmed", "date_created", "date_modified", "OccurrenceTime", "lockdown_expiration", "lockdown_initiated")
    }
    Process {
        foreach ($f in $fields) {
            try {
                if (($null -ne $CyObject.$f) -and ($CyObject.$f -isnot [DateTime]) -and (![String]::IsNullOrEmpty($CyObject.$f))) {
                    Write-Verbose "Converting field $($f) (value: $($CyObject.$f)) to date time value"
                    $newval = ConvertFrom-CyDateString $CyObject.$f
                    # I think we hit a bug in PowerShell. Previous code was $CyObject.$f = $newval.
                    # This would break on date conversion with a PropertyAssignmentException when called from Get-CyDeviceDetailByMac, but not when called by Get-CyDeviceDetail
                    $CyObject | Add-Member $f $newval -Force 
                    Write-Verbose "Conversion result for field $($f): $($CyObject.$f) $($newval)"
                }
            } catch [FormatException] {
                Write-Error "Problem converting field $($f) to date time (value: $($CyObject.$f))"
            }
        }

        $CyObject
    }
}

<#
.SYNOPSIS
    Invokes a REST method using the proxy configuration stored in the API object.

.PARAMETER API
    API Handle.

.PARAMETER Uri
    The URI for the REST method

.PARAMETER Body
    The request body

.PARAMETER Headers
    Any headers to transmit. 'Accept = "application/json"' is added if no headers are specified.
#>
function Invoke-CyRestMethod {
    Param(
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $null,
        [parameter(Mandatory=$true)]
        [string]$Uri,
        [parameter(Mandatory=$true)]
        [string]$Method,
        [parameter(Mandatory=$false)]
        [object]$Body = $null,
        [parameter(Mandatory=$false)]
        [Hashtable]$Headers = @{},
        [parameter(Mandatory=$false)]
        [string]$ContentType = $null,
        [parameter(Mandatory=$false)]
        [String]$Proxy = $null,
        [parameter(Mandatory=$false)]
        [PSCredential]$ProxyCredential = $null,
        [parameter(Mandatory=$false)]
        [string]$OutFile = $null,
        [parameter(Mandatory=$false)]
        [Switch]$ProxyUseDefaultCredentials,
        [Switch]$DoNotRenewToken
        )

        Write-Verbose "Entry into Invoke-CyRestMethod: DoNotRenewToken=$($DoNotRenewToken)"

        if ((!$DoNotRenewToken) -and ($API -ne $null) -and ((Get-Date) -gt $API.ExpirationTime)) {
            # renew token automatically
            Write-Verbose "Renewing token: $($API | out-string)"

            $APIrenewed = Get-CyAPI `
                -Scope None `
                -APIId $API.APIId `
                -APITenantId $API.APITenantId `
                -APISecret $API.APISecret `
                -APIAuthUrl $API.BaseUrl

            Write-Verbose "New token: $($APIrenewed | out-string)"

            # replace relevant token content in API handle object
            $API.ExpirationTime = $APIrenewed.ExpirationTime
            $API.AccessToken = $APIrenewed.AccessToken

            $API = $APIrenewed
        }

        if (!$Headers.ContainsKey("Accept"))
        {
            $Headers.Accept = "application/json";
        }
        
        if (!$Headers.ContainsKey("Authorization"))
        {
            if ($API -ne $null) 
            {
                $Headers.Authorization = "Bearer $($API.AccessToken)"
            }
        }

        $rest = @{
            Method = $Method
            Uri = $Uri
            Headers = $Headers
            UserAgent = "PowerShell/CyCLI"
        }

        if ($OutFile -ne $null) {
            $rest.OutFile = $OutFile
        }

        if ($Body -ne $null) {
            $rest.Body = $Body
        }
        
        if (![String]::IsNullOrEmpty($ContentType)) {
            $rest.ContentType = $ContentType
        }
        
        $settings = Get-CyGlobalSettings

        if (![String]::IsNullOrEmpty($settings.Proxy) -and [String]::IsNullOrEmpty($Proxy)) {
            # only use proxy from global settings if no proxy given explicitly, and a proxy is defined in global settings
            $Proxy = $settings.Proxy
            if ($settings.ProxyCredential -ne $null) {
                $ProxyCredential = $settings.ProxyCredential
            }
            if ($settings.ProxyUseDefaultCredentials -eq $true) {
                $ProxyUseDefaultCredentials = $settings.ProxyUseDefaultCredentials
            }
        }

        # use explicit proxy settings, or proxy settings retrieved from global settings
        if (![String]::IsNullOrEmpty($Proxy)) {
            $rest.Proxy = $Proxy
            if ($ProxyCredential -ne $null) {
                $rest.ProxyCredential = $ProxyCredential
            }
            if ($ProxyUseDefaultCredentials -eq $true) {
                $rest.ProxyUseDefaultCredentials = $ProxyUseDefaultCredentials
            }
        }

        Write-Verbose "Invoking CyREST method using params: $($rest | Out-String)"

        Invoke-RestMethod @rest
}