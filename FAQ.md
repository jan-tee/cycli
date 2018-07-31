# FAQ

## How do I install the module?

Run `Install-Module CyCLI` from an administrative Powershell console. Once installed, close the console and create your first console entry.

If you get error messages, you are most likely behind a corporate proxy and need to add proxy arguments (use `Get-Help Install-Module` to find out how), or your Powershell policy settings disallow the installation of modules or execution of unsigned module code.

## How do I configure the module?

Run `Get-Help New-CyConsoleConfig` to understand the arguments, and then run `New-CyConsoleConfig` to add your first console entry. Use `us` for US consoles, `euc1` for Europe, and for any other console, use the appropriate suffix from your console login page URL.

## What should I know about the module?

1. This module is not a Cylance product. The Cylance product is the API itself, for which you can download documentation from the Cylance knowledgebase.
1. This module is an API client application. You can write your own applications, independent of this module, with the documentation available in the Cylance knowledgebase.
1. Most system administrators are not used to writing code against REST APIs.
1. If you are looking to automate system administration tasks in PowerShell, chances are it will be easier for you to use this existing module than custom coding your own client against the REST API.

## How does the module make my life easier?

* Instead of coding your own client application, you can focus on your business logic; you can achieve many tasks with a single line of code, more complex ones with a few lines, using this module.

## How does the module work?

* The modules writes a `consoles.json` file to your `$HOME` (profile) directory, or to `$HOME\TDRs` if that exists.
* The `consoles.json` file can serve as a directory holding the various credentials and URLs needed to access the API, Threat Data Reports, etc. and stores them for each console under a name of your choosing
* This allows you to configure once and later access the console by name, rather than by remembering the API ID, tenant ID, API secret, and base URL for a given console!
* The `consoles.json` file contains encrypted credentials, and is not portable across users or devices.

