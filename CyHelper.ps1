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

.DESCRIPTION
    This powershell module stores credentials and settings in a JSON file (consoles.json) for convenient access of
    parameters such as URLs to use, API secrets, TDR token etc. The use of the JSON file is not mandatory
    but makes using the API via the powershell module much easier, since consoles can be referred to by name
    rather than a combination of credentials  (e.g. API application ID, API secret, API Auth URL, and API tenant ID
    would otherwise be needed everytime the API is used in program code or from a Powershell console).

    You can call New-CyConsoleConfig without any parameters and it will prompt for all details.

.PARAMETER Console
    Mandatory. The console ID you will use to refer to this console entry in your consoles.json file. See the README for CyCLI module.

.PARAMETER Id
    Mandatory. API ID

.PARAMETER Secret
    Mandatory. API Secret

.PARAMETER TenantId
    Mandatory. API Tenant ID

.PARAMETER Region
    Mandatory. The tenant region. Determines the URLs to use for API and TDR access.

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
        [parameter(Mandatory=$true)]
        [ValidateSet ("apne1", "au", "euc1", "sae1", "us-gov", "us")]
        [String]$Region
        )

        $Consoles = Get-CyConsoleConfig
        if ($null -eq $script:ConsolesJsonPath) {
            $script:ConsolesJsonPath = "$($HOME)\consoles.json"
        }
        try {
            # was: $APISecret = Read-Host -AsSecureString
            $DPAPISecret = ConvertFrom-SecureString -SecureString $APISecret

            $TDRUrl = "https://protect.cylance.com/Reports/ThreatDataReportV1/";
            $APIAuthUrl = "https://protectapi.cylance.com/auth/v2/token";

            switch -Regex ($Region)
            {
                "apne1|au|euc1|sae1" {
                    $TDRUrl = "https://protect-$($Region).cylance.com/Reports/ThreatDataReportV1/";
                    $APIAuthUrl = "https://protectapi-$($Region).cylance.com/auth/v2/token";
                }
                "us-gov" {
                    $TDRUrl = "https://protect.us.cylance.com/Reports/ThreatDataReportV1/";
                    $APIAuthUrl = "https://protectapi.us.cylance.com/auth/v2/token";
                }
            }

            $null = Get-CyAPI -APIId $APIId -APISecret $APISecret -APITenantId $APITenantId -APIAuthUrl $APIAuthUrl -Scope None
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
            if ($null -eq $Consoles) {
                $Consoles = @( $NewConsole )
            } else {
                $Consoles += $NewConsole
            }
            if (Test-Path -Path $script:ConsolesJsonPath -Type Leaf) {
                Copy-Item $script:ConsolesJsonPath "$($script:ConsolesJsonPath).bak" -Force
            }
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
        [String]$ParameterSetName,
        [Parameter(Mandatory=$False)]
        [Int]$Position
    )

    #$consoleIds = (Get-CyConsoleConfig).ConsoleId
    #Get-CyDynamicParam @args -Options $consoleIds

    $consoleIds = (Get-CyConsoleConfig).ConsoleId

    if ($consoleIds.Count -eq 0) {
        return $null
    }

    $consolesAttributes = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
    $consolesParam = new-object System.Management.Automation.ParameterAttribute
    $consolesParam.Mandatory = $Mandatory
    if ($Position -ne $null) {
        $consolesParam.Position = $Position
    }
    $consolesParam.HelpMessage = "Enter one or more console IDs, separated by commas"
    if ([String]::Empty -ne $ParameterSetName) { $consolesParam.ParameterSetName = $ParameterSetName }
    $consolesAttributes.Add($consolesParam)    

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

function Get-CyDynamicParam {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$False)]
        [Switch]$AllowMultiple = $False,
        [parameter(Mandatory=$False)]
        [Switch]$Mandatory,
        [parameter(Mandatory=$True)]
        [String]$ParameterName,
        [parameter(Mandatory=$False)]
        [String]$ParameterSetName,
        [Parameter(Mandatory=$False)]
        [Int]$Position,
        [Parameter(Mandatory=$False)]
        [String]$HelpMessage,
        [Parameter(Mandatory=$True)]
        [String[]]$Options
    )

    if ($Options.Count -eq 0) {
        return $null
    }

    $attributes = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]
    
    $parameterAttribute = new-object System.Management.Automation.ParameterAttribute
    $parameterAttribute.Mandatory = $Mandatory
    if ($null -ne $Position) { $parameterAttribute.Position = $Position }
    if (![String]::IsNullOrEmpty($HelpMessage)) { $parameterAttribute.HelpMessage = "Enter one or more console IDs, separated by commas" }
    if (![String]::IsNullOrEmpty($ParameterSetName)) { $parameterAttribute.ParameterSetName = $ParameterSetName }
    $attributes.Add($parameterAttribute)    

    $validateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($Options)
    $attributes.Add($validateSetAttribute)
    if ($AllowMultiple) { 
        $OptionsRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("$($ParameterName)", [String[]], $attributes)
    } else { 
        $OptionsRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("$($ParameterName)", [String], $attributes)
    }
    $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add("$($ParameterName)", $OptionsRuntimeDefinedParam)
    return $paramDictionary
}
