# CyCLI
API &amp; CLI tools for Cylance

## FAQ

You can find the [FAQ here in this repository](FAQ.md).

## Examples

You can find the [CyCLI examples](https://github.com/jan-tee/cycli-examples) on Github, too.

## Prerequisites & Installation

All instructions assume PowerShell 5.0 or greater. Download the latest Microsoft Management Framework if you are on an earlier version.

### Install from PowerShell Gallery

1. From an administrative PowerShell prompt, enter `Install-Module CyCLI`
1. To use, `Import-Module CyCLI`

You can install from source too, but **only do this if you want to contribute new code to the module, and know what you are doing and why.**. [Instructions for manual install](MANUAL-INSTALL-FROM-SOURCE.md).

If you receive an error message like this:

```WARNING: The specified module 'CyCLI' with PowerShellGetFormatVersion '2.0' is not supported by the current version of PowerShellGet. Get the latest version of the PowerShellGet module to install this module, 'CyCLI'.```

Then you need to upgrade PowerShellGet to install. This is caused by a change in the minimum required PowerShellGet package version for PowerShellGallery.com. To fix it, from an administrative PowerShel prompt, enter `Update-Module PowerShellGet -force`, and after it completes successfully, restart the administrative PowerShell prompt and follow the instructions above again.

## See all verbs

```powershell
get-help *-cy*
```

## Getting started

### API credentials: Persistent Storage

The module uses a `consoles.json` file that can reside in your user profile path (`$HOME`) or a special subdirectory (`$HOME\TDRs\`). The module will *automatically* create the file in your user profile path if none exists when you add your first console entry, or use an existing file in either path (with precedence for `$HOME\TDRs`). 

It will also automatically create the `consoles.json` file for you when you run any ```New-CyConsoleConfig``` commands.

### Import the module

*All examples assume you have imported the module using `Import-Module CyCLI` first.*

### Proxy support

If you need to use a proxy, run ```Set-CyGlobalSettings``` as the first cmdlet in any API session to configure proxy settings.

### Create your first API connection

To get started, run ```New-CyConsoleConfig``` and answer all prompts. Run ```get-help New-CyConsoleConfig``` to look up the possible values for the `Region` argument.

**Note:** *If you choose to supply parameters rather than answering prompts, please note that the API secret cannot be given as a literal string command line argument because it is processed as a secure string (and stored using DPAPI).*

The `Console` argument throughout the module is a string that you can use to reference a set of credentials, so you do not have to remember/reference it yourself. An added advantage is that credentials are stored protected by DPAPI and you do not need to worry about accidentally sharing them when sharing your scripts.

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
 - Automatic substitution of illegal characters in e.g. zone names to prevent API errors
