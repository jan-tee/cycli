<#
.SYNOPSIS
	A collection of convenience verbs to work with the Cylance Console API v2.

.DESCRIPTION
    Contains methods that are helpful, but do not represent API primitives, or are wrappers around API methods.

.LINK
    Blog: http://tietze.io/
    Jan Tietze
#>

<#
.SYNOPSIS
    Gets a user by email

.PARAMETER Email
    The user's email address
#>
function Get-CyUserByEmail {
    [CmdletBinding(DefaultParameterSetName="All")] 
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [parameter(Mandatory=$true)]
        [string]$Email
        )

    Get-CyUserList -API $API | Where-Object email -eq $Email
}

<#
.SYNOPSIS
    Adds exclusions for a certain application (from an application definition JSON file) to a policy.

.PARAMETER Definitions
    The JSON file with definitions.

.PARAMETER Application
    The application identifier from the JSON file

.PARAMETER Policy
    The policy object to change.
#>
function Add-CyPolicyExclusionsForApplication {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [pscustomobject]$Policy
    )
    DynamicParam {
        $Options = (Get-Content "$PSScriptRoot\CyDATA_ApplicationDefinitions.json" | ConvertFrom-Json).Name
        Get-CyDynamicParam -Mandatory -AllowMultiple -ParameterName Application -Options $Options
    }

    Begin {
        $Definitions = (Get-Content "$PSScriptRoot\CyDATA_ApplicationDefinitions.json" | ConvertFrom-Json)
        $ApplicationDefinition = $Definitions | Where-Object name -eq $PSBoundParameters.Application
    }

    Process {
        $ApplicationDefinition.memory_exclusion_list | ForEach-Object {
            Add-CyPolicyListSetting -Type MemDefExclusionPath -Value $_ -Policy $Policy
        }

        $ApplicationDefinition.scan_exception_list | ForEach-Object {
            Add-CyPolicyListSetting -Type ScanExclusion -Value $_ -Policy $Policy
        }

        $ApplicationDefinition.script_allowed_folders | ForEach-Object {
            Add-CyPolicyListSetting -Type ScriptControlExclusionPath -Value $_ -Policy $Policy
        }
    }
}