<#
.NAME
    Cylance-TDR

.SYNOPSIS
    This module contains various functions to deal with the Cylance Console's Threat Data Reports (TDRs)

.NOTES

.LINK
    Blog: http://tietze.io/
    Jan Tietze
#>


<#
.SYNOPSIS
    Downloads Cylance console's TDR reports and converts them into Excel.

.DESCRIPTION
    The Cylance console makes certain reports available in CSV format about events and data that it collects.
    An even richer data set is available in real-time via Syslog, but if you want to periodically pull data
    from the console to keep e.g. historical snapshots or run additional processing steps on the data outside
    your SIEM, this script can be useful.

.PARAMETER TDRPath
    Mandatory, the base path to store the TDR data.

.PARAMETER ConsoleId
    Optional. Specify if you only want to retrieve a particular console's data. Is used as the key to load from the "consoles" map.
	
.PARAMETER AccessToken
    Optional. When specified with "RetrieveConsoleId", this token will be used instead of performing a lookup from the "consoles" map.

.PARAMETER DefaultTDRUrl
    Optional. When no TDR URL is specified in the console profile, use this default TDR URL (default = EUC1 shard)

.LINK
    Blog: http://tietze.io/
    Jan Tietze

#>

<#
.SYNOPSIS
    Downloads all TDRs for a console into given directory structure

.DESCRIPTION
    TDRUrl defaults to EUC1 shard.
#>
function Get-CyTDRs {
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ParameterSetName="Direct")]
        [String]$Id,
        [parameter(Mandatory=$True, ParameterSetName="Direct")]
        [String]$AccessToken,
        [parameter(Mandatory=$False)]
        [String]$TDRUrl = "https://protect-euc1.cylance.com/Reports/ThreatDataReportV1/",
        [parameter(Mandatory=$False)]
        [ValidateScript({Test-Path $_ -PathType Container })]
        [String]$TDRPath = "$($HOME)\TDRs"
    )
    DynamicParam {
        Get-CyConsoleArgumentAutoCompleter -Mandatory -ParameterName "Console" -ParameterSetName "ByReference"
    }

    Begin {
        $TDRPath = (Get-Item $TDRPath).FullName
        $Timestamp = $(Get-Date -UFormat "%Y%m%d-%H%M%S")

        switch ($PSCmdlet.ParameterSetName)
        {
            "Direct" {
            }
            "ByReference" {
                $ConsoleDetails = (Get-CyConsoleConfig) | Where-Object ConsoleId -eq $PSBoundParameters.Console
                $Id = $ConsoleDetails.ConsoleId
                $AccessToken = $ConsoleDetails.Token
                if (($null -ne $ConsoleDetails.TDRUrl) -and ([String]::Empty -ne $ConsoleDetails.TDRUrl)) {
                    $TDRUrl = $ConsoleDetails.TDRUrl
                }
            }
        }
        Write-Verbose "Retrieving data for console ${Id} from TDR URL ${TDRUrl} with token ${AccessToken} and storing to TDR path ${TDRPath}"

        ForEach ($TDRType in @("cleared", "devices", "events", "indicators", "policies", "threats", "externaldevices", "memoryprotection")) {
            $DirectoryName = $TDRPath + "\" + $Id+ "\" + $TDRType + "\"
            if (-Not (Test-Path $DirectoryName -PathType Container)) {
                New-Item -Path $DirectoryName -ItemType Directory -Force | Out-Null
                }
            $Filename = "${DirectoryName}\${Timestamp}_${Id}_${TDRType}.csv"

            # retrieve CSV
            $Url = "${TDRUrl}${TDRType}/${AccessToken}"
            # was: Invoke-WebRequest -Uri $Url -OutFile $Filename | Out-Null
            $null = Invoke-CyRestMethod -Method GET -Uri $Url -OutFile $Filename
        }

        # create XLSX summary - invoke with last retrieved component name
        Convert-CyTDRsToXLSX -CSVPath $Filename -Overwrite $False    }

    Process {
    }
}


<#
.SYNOPSIS
    Expands a command-delimited field (like "zone" fields in e.g. device TDR CSVs) into separate fields so that they can be used to sort effectively.
#>
function Convert-FromCSVField {
    Param (
        [parameter(Mandatory=$True)]
        [PSObject]$Data,
        [Parameter(Mandatory=$True)]
        [Array]$ExpandFields,
        [Parameter(Mandatory=$True)]
        [Array]$FieldPrefix
    )
    $Data | ForEach-Object {
        # each row
        foreach ($field in $ExpandFields) {
            if (![string]::IsNullOrWhiteSpace($_.$field)) {
                $fs = $_.$field.Split(",")
                foreach ($f in $fs) {
                    Add-Member -NotePropertyName "$($FieldPrefix)$($f)" -InputObject $_ -NotePropertyValue "x"
                }
            }
        }
        $_
    }
    
}

<#
.SYNOPSIS
    Converts a Cylance TDR report to Excel.

.DESCRIPTION
    The Cylance console makes certain reports available in CSV format about events and data that it collects.
    An even richer data set is available in real-time via Syslog, but if you want to periodically pull data
    from the console to keep e.g. historical snapshots or run additional processing steps on the data outside
    your SIEM, this script can be useful.
#>
function Convert-CyTDRsToXLSX {
    Param (
        [parameter(Mandatory=$True)]
        [ValidateScript({Test-Path $_ -PathType Leaf })]
        [String]$CSVPath,
        [Parameter(Mandatory=$False)]
        [Boolean]$Overwrite = $False
    )

    function Get-ExcelSummaryReport-FromTDR ($TDRPath, $ConsoleId, $Timestamp, $OutputXLSX) {
        ForEach ($TDRType in @("cleared", "devices", "events", "indicators", "policies", "externaldevices", "memoryprotection", "threats")) {
            $InputCSV = $TDRPath + "\" + $ConsoleId + "\" + $TDRType + "\" + $Timestamp + "_" + $ConsoleId + "_" + $TDRType + ".csv"

            if ((Test-Path -Path $InputCSV -PathType Leaf) -ne $true) {
                # skip non-existent TDRs
                continue
            }

            $data = Import-CSV -Delimiter "," -Path $InputCSV
            Write-Verbose "Processing CSV into XLSX: ${InputCSV}"

            # time stamps are named:
            # "threats": Create Time, Modification Time, Access Time, First Found, Last Found => 7/20/2017 12:40:25 AM
            # "memoryprotection" ADDED => 11/23/2017 9:34:05 AM
            # "externaldevices": Date => 11/23/2017 9:34:05 AM
            # "events": Date => 11/29/2017 3:14:33 PM
            # "devices": created, "Online Date", "Offline Date" => 11/2/2017 10:54:32 AM
            # "cleared": "Date Removed" => 11/24/2017 10:02:49 AM

            if ($null -eq $data) { continue }

            switch ($TDRType) {
                "threats" {
                    $Data = Convert-FromCSVDate -Data $Data -Fields @("Create Time", "Modification Time", "Access Time", "First Found", "Last Found")
                }
                "memoryprotection" {
                    $Data = Convert-FromCSVDate -Data $Data -Fields @("ADDED")
                }
                "externaldevices" {
                    # the "externaldevices" TDR uses an inconsistent time format string and has no "seconds" field.
                    $Data = Convert-FromCSVDate -Data $Data -Fields @("Date") -Format "M/d/yy h:mm tt"
                }
                "events" {
                    $Data = Convert-FromCSVDate -Data $Data -Fields @("Date")
                }
                "devices" {
                    $Data = Convert-FromCSVDate -Data $Data -Fields @("Created", "Online Date", "Offline Date")
                }
                "cleared" {                
                    $Data = Convert-FromCSVDate -Data $Data -Fields @("Date Removed")

                }
            }

            $Data | Export-Excel $OutputXLSX -WorkSheetname $TDRType -AutoSize -TableName "${TDRType}Table"
        }

    }

    # got a CSV path - make absolute path
    $CSVPath = (Get-Item $CSVPath).FullName

    $s = [regex]::match($CSVPath,'(.+)\\([^\\]+)\\([^\\]+)\\([0-9]{8}-[0-9]{6})_([^\\_)]+)_([^\\]+)\.csv').Groups
    $TDRPath = $s[1].Value
    $ConsoleId = $s[2].Value
    $TDRType = $s[3].Value
    $Timestamp = $s[4].Value
    # $ConsoleId2 = $s[5].Value
    # $ReportType2 = $s[6].Value

    # Generate Excel summary file from TDRs
    $OutputXLSX = $TDRPath + "\" + $ConsoleId + "\" + $Timestamp + "_" + $ConsoleId + ".xlsx"

    # check if exists
    If (Test-Path $OutputXLSX -PathType Leaf) {
        Write-Verbose "Output file ${OutputXLSX} exists."
        if ($Overwrite) {
            Write-Verbose "Removing output file ${OutputXLSX}"
            Remove-Item $OutputXLSX
            Get-ExcelSummaryReport-FromTDR -ConsoleId $ConsoleId -Timestamp $Timestamp -OutputXLSX $OutputXLSX -TDRPath $TDRPath
        } else {
            Write-Verbose "Not set to overwrite, will not remove/re-create file ${OutputXLSX}"
        }
    } else {
        Get-ExcelSummaryReport-FromTDR -ConsoleId $ConsoleId -Timestamp $Timestamp -OutputXLSX $OutputXLSX -TDRPath $TDRPath
    }
}
