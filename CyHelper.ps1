<#
    Helper function.

    Converts a given string or byte array to Base64 "urlencoding" format (= replace certain special characters from the Base64 alphabet with URL safe chars)
#>
function ConvertTo-Base64UrlEncoding {
    Param(
        [parameter(Mandatory=$true)]
        [Object]$s
    )
    if ($s -is [String]) {
        $s = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($s)) # convert to base64
    } elseif ($s -is [byte[]]) {
        $s = [Convert]::ToBase64String($s)
    }
    $s.Split("=")[0].Replace("+", "-").Replace("/", "_") # alphabet replacement from regular base64 to base64urlencoded
}

<#
    Helper function.

    Converts a given string from Base64 "urlencoding" format (= replace certain special characters from the Base64 alphabet with URL safe chars) to a string
#>
function ConvertFrom-Base64UrlEncoding {
    Param(
        [parameter(Mandatory=$true)]
        [String]$s
    )
    $s = $s.Replace("-", "+").Replace("_", "/") # alphabet replacement from base64urlencoded to regular
    while ($s.Length % 4 -ne 0) { $s += "=" }   # padding
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($s))
}


<#
.SYNOPSIS
    Converts the named "date" fields from CSV data (in "M/d/yyyy h:mm:ss tt" format) into datetime objects so that they can be exported to Excel.

.DESCRIPTION
    All date/time data is treated as UTC.

    Format defaults to "M/d/yyyy h:mm:ss tt"

#>
function Convert-FromCSVDate {
    Param (
        [parameter(Mandatory=$True)]
        [PSObject]$Data,
        [Parameter(Mandatory=$True)]
        [Array]$Fields,
        [Parameter(Mandatory=$False)]
        [Array]$Format = "M/d/yyyy h:mm:ss tt"
    )
    $Data | ForEach-Object {
        # each row
        ForEach ($field in $Fields) {
            if (![string]::IsNullOrWhiteSpace($_.$field)) {
                try {
                    $t = $_.$field
                    $_.$field = [datetime]::ParseExact($_.$field, $Format, [cultureinfo]::InvariantCulture)
                } catch {
                    Write-Error "Could not convert date: $($t), exception: $($_.Exception.ItemName)"
                }
            }
        }
        $_
    }
}

<#
.SYNOPSIS
    Returns a hash map with the consoles configuration list for API and TDR modules

.DESCRIPTION
    Reads "consoles.json" from $HOME\ as a short-hand way to reference the credentials and settings
    to access one or more Cylance consoles.
#>
function Get-CyConsoleConfig {
    @("$($HOME)\TDRs\", "$($HOME)" ) | 
        ForEach-Object {
            if (Test-Path -Path "$($_)\consoles.json" -PathType Leaf) {
                # PowerShell parser chokes on JS comments... pffft
                $script:ConsolesJsonPath = "$($_)\consoles.json"
                Write-Verbose "consoles.json path used: $($script:ConsolesJsonPath)"
                Get-Content "$($_)\consoles.json" | Select-String -NotMatch -Pattern "^[\s]*//.*$" | ConvertFrom-Json
                return
            }
        }
    @()
}

<#
.SYNOPSIS
    Adds a console entry to the consoles.json file.

.PARAMETER Console
    Mandatory. The console ID you will use to refer to this console entry in your consoles.json file. See the README for CyCLI module.

.PARAMETER Id
    Mandatory. API ID

.PARAMETER Secret
    Mandatory. API Secret

.PARAMETER TenantId
    Mandatory. API Tenant ID

.PARAMETER Uri
    Optional. URI to obtain API token, e.g. "https://protectapi<-region>.cylance.com/auth/v2/token". Defaults to EUC1 region.

.PARAMETER Token
    Optional. If you would like to use TDR access as well, specify TDR token for console.

#>
function New-CyConsoleConfig {
    Param (
        [parameter(Mandatory=$true)]
        [String]$Console,
        [parameter(Mandatory=$true)]
        [String]$APIId,
        [parameter(Mandatory=$true)]
        [SecureString]$APISecret,
        [parameter(Mandatory=$true)]
        [String]$APITenantId,
        [parameter(Mandatory=$false)]
        [String]$Token,
        [parameter(Mandatory=$false)]
        [String]$TDRUrl = "https://protect-euc1.cylance.com/Reports/ThreatDataReportV1/",
        [parameter(Mandatory=$false)]
        [String]$APIAuthUrl = "https://protectapi-euc1.cylance.com/auth/v2/token"
        )
        $Consoles = Get-CyConsoleConfig
        if ($script:ConsolesJsonPath -eq $null) {
            $script:ConsolesJsonPath = "$($HOME)\consoles.json"
        }
        try {
            # was: $APISecret = Read-Host -AsSecureString
            $DPAPISecret = ConvertFrom-SecureString -SecureString $APISecret
            $handle = CyAPIHandle -APIId $id -APISecret $Secret -APITenantId $APITenantId -APIAuthUrl $APIAuthUrl -Scope None
            # https://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx
            $NewConsole = @{
                    ConsoleId = $Console
                    AutoRetrieve = $true
                    APIId = $APIId
                    APISecret = $DPAPISecret
                    APITenantId = $APITenantId
                    APIUrl = $APIAuthUrl
                    Token = $Token
                    TDRUrl = $TDRUrl
                }
            if ($Consoles -eq $null) {
                $Consoles = @( $NewConsole )
            } else {
                $Consoles += $NewConsole
            }
            Copy-Item $script:ConsolesJsonPath "$($script:ConsolesJsonPath).bak" -Force
            ConvertTo-Json $Consoles | Out-File -FilePath $script:ConsolesJsonPath -Force
        } catch {
            $_.Exception
            return
        }
}

<#
.SYNOPSIS
    Removes a console configuration entry from consoles.json

#>
function Remove-CyConsoleConfig {
    [CmdletBinding()]
    Param()
    DynamicParam {
        Get-CyConsoleArgumentAutoCompleter -Mandatory -ParameterName "Console"
    }

    Begin {
    }

    Process {
        $Consoles = (Get-CyConsoleConfig) | Where-Object ConsoleId -ne $PSBoundParameters.Console
        ConvertTo-Json $Consoles | Out-File -FilePath $script:ConsolesJsonPath -Force
    }
}

<#
.SYNOPSIS
    Gets a DynamicParam definition that enables auto-completion to specify a single or multiple
    console IDs as an argument.

.PARAMETER Mandatory
    Makes the dynamic parameter mandatory.

.PARAMETER AllowMultiple
    Allows specification of multiple comma-separated consoles arguments

.PARAMETER ParameterName
    The name of the dynamic parameter (typically "Console" or "Consoles")

#>
function Get-CyConsoleArgumentAutoCompleter {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$False)]
        [Switch]$AllowMultiple = $False,
        [parameter(Mandatory=$False)]
        [Switch]$Mandatory,
        [parameter(Mandatory=$True)]
        [String]$ParameterName,
        [parameter(Mandatory=$False)]
        [String]$ParameterSetName
    )
    
    $consolesAttributes = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
    $consolesParam = new-object System.Management.Automation.ParameterAttribute
    $consolesParam.Mandatory = $Mandatory
    $consolesParam.HelpMessage = "Enter one or more console IDs, separated by commas"
    if ([String]::Empty -ne $ParameterSetName) { $consolesParam.ParameterSetName = $ParameterSetName }
    $consolesAttributes.Add($consolesParam)    
    $consoleIds = (Get-CyConsoleConfig).ConsoleId
    $consoleIdsValidateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($consoleIds)
    $consolesAttributes.Add($consoleIdsValidateSetAttribute)
    if ($AllowMultiple) { 
        $consoleIdsRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("$($ParameterName)", [String[]], $consolesAttributes)
    } else { 
        $consoleIdsRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("$($ParameterName)", [String], $consolesAttributes)
    }
    $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add("$($ParameterName)", $consoleIdsRuntimeDefinedParam)
    return $paramDictionary
}
