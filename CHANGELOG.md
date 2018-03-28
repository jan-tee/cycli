# Changelog

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