# FAQ

## How does the module make my life easier?

*Instead of coding your own client application, you can focus on your business logic. You can achieve many tasks with a single line of code, more complex ones with a few lines, using this module.*

Examples include:

* Managing global lists (importing/exporting safe lists and manipulating quarantine lists)
* Looking at threats, downloading, and manipulating threats - individually or for 1000s of entries at once
* Manage devices and zones - creation, assignment of membership, removal...
* Completely automating common administrative tasks, such as safelisting trusted files

## Where can I find examples?

You can find the [CyCLI examples](https://github.com/jan-tee/cycli-examples) on Github.

## How do I install the module?

Run `Install-Module CyCLI` from an administrative Powershell console. Once installed, close the console and create your first console entry.

If you get error messages, you are most likely behind a corporate proxy and need to add proxy arguments (use `Get-Help Install-Module` to find out how), or your Powershell policy settings disallow the installation of modules or execution of unsigned module code. See below for help on the proxy issue.

## How do I use this behind a proxy server?

To use behind a proxy, configure the proxy server in the session you are using the module. Use `Set-CyGlobalSettings` as the first cmdlet in any API session to configure proxy settings. If you need to specify credentials for the proxy server, set them first by running `$proxyCreds = Get-Credential` and then use them as a parameter to `Set-CyGlobalSettings`. As a reminder, to find out what the available parameters are to a cmdlet, use tab-autocompletion or `Get-Help <cmdlet name>`, in this case `Get-Help Set-CyGlobalSettings`.

## How do I configure the module?

Run `Get-Help New-CyConsoleConfig` to understand the arguments, and then run `New-CyConsoleConfig` to add your first console entry. Use `us` for US consoles, `euc1` for Europe, and for any other console, use the appropriate suffix from your console login page URL. You only need to do this once per console you connect to.

## What should I know about the module?

1. This module is not a Cylance product. The Cylance product is the API itself, for which you can download documentation from the Cylance knowledgebase.
1. This module is an API client application.
1. You can write your own API client applications, independent of this module, with the documentation available in the Cylance knowledgebase.

This module exists because:

1. Most system administrators are not used to writing code against REST APIs.
1. If you are looking to automate system administration tasks in PowerShell, chances are it will be _much_ easier for you to use this existing module than custom coding your own client against the REST API.

## How does the module work?

* The modules writes a `consoles.json` file to your `$HOME` (profile) directory, or to `$HOME\TDRs` if that exists.
* The `consoles.json` file can serve as a directory holding the various credentials and URLs needed to access the API, Threat Data Reports, etc. and stores them for each console under a name of your choosing
* This allows you to configure once and later access the console by name, rather than by remembering the API ID, tenant ID, API secret, and base URL for a given console!
* The `consoles.json` file contains encrypted credentials, and is not portable across users or devices.

