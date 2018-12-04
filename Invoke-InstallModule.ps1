<#
    .SYNOPSIS
        Install the module in the PowerShell module folder.
    .DESCRIPTION
        Install the module in the PowerShell module folder by copying all the files.
#>

[CmdLetBinding()]
Param (
    [ValidateNotNullOrEmpty()]
    [String]$ModuleName = 'CyCLI',
    [ValidateScript({Test-Path -Path $_ -Type Container})]
    [String]$ModulePath = 'C:\Program Files\WindowsPowerShell\Modules'
)

Begin {
    Try {
        Write-Verbose "$ModuleName module installation started"

        $Files = @(
            'CyCLI.psd1',
            'CyCLI.psm1',
            'CyHelper.ps1',
            'CyTDR.ps1',
            'CyAPI.ps1',
            'CyCrypto.ps1',
            'CyDevices.ps1',
            'CyThreats.ps1',
            'CyZones.ps1',
            'CyPolicies.ps1',
            'CyInstallers.ps1',
            'CyGlobalLists.ps1',
            'CyUsers.ps1',
            'CyOpticsDetections.ps1',
            'CyOpticsPackages.ps1',
            'CyOpticsInstaQuery.ps1',
            'CyConvenience.ps1',
            'CyDATA_ApplicationDefinitions.json'
            'license.txt'
        )
    }
    Catch {
        throw "Failed installing the module '$ModuleName': $_"
    }
}

Process {
    Try {
        $TargetPath = Join-Path -Path $ModulePath -ChildPath $ModuleName
        $SourcePath = $PSScriptRoot

        if (-not (Test-Path $TargetPath)) {
            New-Item -Path $TargetPath -ItemType Directory -EA Stop | Out-Null
            Write-Verbose "$ModuleName created module folder '$TargetPath'"
        }

        $Files | 
            ForEach-Object { Get-ChildItem (Join-Path -Path $SourcePath -ChildPath $_) } |
            ForEach-Object {
                $Destination = Join-Path $TargetPath -ChildPath $_.Name
                Copy-Item -Path $_.FullName -Destination $Destination
                Write-Verbose "$ModuleName installed module file '$($_.Name)' to '$($Destination)'"
            }

        Write-Verbose "$ModuleName module installation successful"
    }
    Catch {
        throw "Failed installing the module '$ModuleName': $_"
    }
}