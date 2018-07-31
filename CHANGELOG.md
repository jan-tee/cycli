# Changelog

## v 0.6.6
* Added "Create policy" API transaction
* Added auto-renewal of API token after 180s
* Added Clear-CyAPIHandle cmdlet to clear the session API handle

## v 0.6.5
* Updated function names
* Prepared auto-renewal for tokens

## v 0.6.4 (2018.07.17)
* Added support for first OPTICS APIs

## v 0.6.3 (2018.05.30)
* Get-CyAPI supports positional parameter for console selection, allowing for short-hand form "Get-CyAPI <Console>"
* Exposed some JWT primitives
* Added more -verbose support to Get-CyAPI

## v 0.6.2 (2018.05.29)
* Encapsulated the REST method call function to allow for proxy support
* Updated Get-CyAPI to support proxies with/without credential access

## v 0.6.1 (2018.05.20)
* Updated New-CyConsoleConfig code to automatically prompt for region - eliminates the most common issue
* Updated README.md to remove outdated/confusing content

## v 0.6.0 (2018.05.09)
* API seems to sometimes return dates as strings like this: "2018-05-09T12:54:27.7711212". Updated date conversion to support these cases.

## v 0.5.9 (2018.04.18)
* Bug fix in New-CyConsoleConfig when consoles.json was empty

## v 0.5.8 (2018.04.13)
* Bug fix in New-CyConsoleConfig and Get-CyAPI to (a) always check if credentials are valid before saving them, and (b) return error messages that point to the most common root cause (wrong shard URL)

## v 0.5.6 (2018.04.03)
* Bug fix in Get-CyDeviceDetailByMac to include date conversion
* Bug fix in Convert-CyObject to fix date conversion - seems like a weird property assignment bug in Powershell.

## v 0.5.4 (2018.03.28)
* Minor bug fix for creation of backup `consoles.json` file

## v 0.5.3 (2018.03.28)

* Creates a .bak backup of `consoles.json` before it writes it (useful in case of manual, syntax-breaking edits to the JSON file)

## v 0.5.2 (2018.03.28)

* _Breaking change_: Better credentials handling - only DPAPI/SecureString supported now; *this is a breaking change* and you will need to update your existing consoles.json with encrypted credentials. To migrate, use a command similar to this: ```(Get-CyConsoleConfig) | where APISecret -ne $null | foreach { $pw = ConvertTo-SecureString -Force -String $_.APISecret -AsPlainText ; New-CyConsoleConfig -Console "$($_.ConsoleId)_2" -APISecret $pw -APIId $_.APIId -Token $_.Token -APITenantId $_.APITenantId -APIAuthUrl $_.APIUrl -TDRUrl $_.TDRUrl }```. Check TDRUrl/APIUrl for correctness in consoles.json afterwards. This is only relevant for users of the pre-release version with a pre-existing consoles.json file.
* _Breaking change_: Renamed some verbs and nouns based on PS best practices
* Mild refactoring after running PS Script Analyzer

## v 0.5.1 (2018.03.28) 

* First candidate for public release, pending PSScriptAnalyzer fixes