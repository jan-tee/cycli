# CyCLI
API &amp; CLI tools for Cylance

## Prerequisites & Installation

All instructions assume PowerShell 5.0 or greater. Download the latest Microsoft Management Framework if you are on an earlier version.

### Option 1: Install from PowerShell Gallery

1. From an administrative PowerShell prompt, enter `Install-Module CyCLI`
1. To use, `Import-Module CyCLI`

### Option 2: Install from source 

**Only do this if you want to contribute new code, and know what you are doing and why.** 

1. Clone the repository.
1. Install the ImportExcel module: `Install-Module ImportExcel`
1. Install the module: `.\InstallModule`
1. Import the CyCLI: `Import-Module CyCLI`

## See all verbs

```powershell
get-help *-cy*
```

## Getting started

The module uses a `consoles.json` file that can reside in your user profile path (`$HOME`) or a special subdirectory (`$HOME\TDRs\`).

The module will automatically create the file in your user profile path if none exists when you add your first console entry, or use an existing file in either path (with precedence for `$HOME\TDRs`). 

It will also automatically create the `consoles.json` file for you when you run any ```New-CyConsoleConfig``` commands.

To get started:

1. Run ```New-CyConsoleConfig``` and answer all prompts.

**Note:** *If you choose to supply parameters rather than answering prompts, please note that the API secret cannot be given as a literal string command line argument because it is processed as a secure string (and stored using DPAPI).*

*All examples assume you have imported the module using `Import-Module CyCLI` first.*

## Example use of Powershell cmdlets for the console API

To obtain API authorization valid for 30 minutes if you have configured your `Consoles.json` file:

```powershell
Get-CyAPI -Console <myconsoleID>
```

If you did not configure `Consoles.json`, you can provide the secrets directly:

```powershell
Get-CyAPI -APIId $APIId -APISecret $APIsecret -APITenantId $TenantId
```

To obtain collections of all devices, zones, and policies:

```powershell
Get-CyDeviceList
Get-CyDeviceList | Get-CyDeviceDetail
Get-CyZoneList
```

To obtain the *detailed information* for one particular device:

```powershell
$devices = Get-CyDeviceList
Get-CyDeviceDetail -Device $devices[0]
```

To add all devices that have names like `JTIETZE-*` to a new zone `TESTOMAT` with policy `Default`:

```powershell
Create-CyZone -Name "TESTOMAT" -Policy 
$d = Get-CyDeviceList | Where name -like "*JTIETZE-*"
$z = Create-CyZone -Name "TESTOMAT" -Criticality Low
$d | Add-CyDeviceToZone -Zone $z
```

To obtain the details of all threats in the environment:
```powershell
$threats = Get-CyDeviceList | Get-CyDeviceThreats
$threatDetails = $threats.sha256 | Get-CyThreatDetails
```

# TODO
 - Web proxy detection & support
 - Automatic substitution of illegal characters in e.g. zone names to prevent API errors
