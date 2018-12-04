<#
.SYNOPSIS
    Gets a list of all policies from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).
#>
function Get-CyPolicyList {
    Param (
        [parameter(Mandatory=$false)]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle
        )

    Read-CyData -API $API -Uri "$($API.BaseUrl)/policies/v2"
}

<#
.SYNOPSIS
    Sets the policy for a specific device

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Device
    The device(s) to set policy for

.PARAMETER Policy
    The policy to assign to device
#>
function Set-CyPolicyForDevice {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object]$Device,
        [Parameter(Mandatory=$true)]
        [object]$Policy
    )

    Begin
	{
		if (([string]::IsNullOrEmpty($Policy.policy_id)) -and ([string]::IsNullOrEmpty($Policy.id)))
		{
			throw "Policy object does not contain 'policy_id' or 'id' property."
		}
		if (([string]::IsNullOrEmpty($Policy.policy_id)) -and (![string]::IsNullOrEmpty($Policy.id)))
		{
			 $PolicyID = $policy.id
		}
		if (!([string]::IsNullOrEmpty($Policy.policy_id)) -and ([string]::IsNullOrEmpty($Policy.id)))
		{
			 $PolicyID = $Policy.policy_id
		}
		if (!([string]::IsNullOrEmpty($Policy.policy_id)) -and (!([string]::IsNullOrEmpty($Policy.id))))
		{
			if(($Policy.policy_id).tostring() -eq ($Policy.id).tostring())
			{
			$PolicyID = $policy.id
			}
			else
			{
			throw 'Different value found in policy_id and id, expected to be the same'	
			}
		}
	}

    Process {
        $updateMap = @{
            "name" = $($Device.name)
            "policy_id" = $PolicyID
        }

        $json = $updateMap | ConvertTo-Json
        # remain silent
        $null = Invoke-CyRestMethod -API $API -Method PUT -Uri "$($API.BaseUrl)/devices/v2/$($Device.id)" -ContentType "application/json; charset=utf-8" -Body $json
    }
}

<#
.SYNOPSIS
    Retrieves the given Policy from the console. Gets the full version, not a shallow object.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Policy
    The policy to retrieve.
#>
function Get-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object]$Policy
        )

    Process {
        Invoke-CyRestMethod -API $API -Method GET -Uri  "$($API.BaseUrl)/policies/v2/$($Policy.id)" | Convert-CyObject
    }
}

<#
.SYNOPSIS
    Removes the given Policy from the console.

.PARAMETER API
    Optional. API Handle (use only when not using session scope).

.PARAMETER Policy
    The policy to retrieve the Detail for.
#>
function Remove-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
            [object]$Policy
        )

    Process {
        Invoke-CyRestMethod -API $API -Method DELETE -Uri  "$($API.BaseUrl)/policies/v2/$($Policy.id)" | Convert-CyObject
    }
}

<#
.SYNOPSIS
    Returns an empty scaffold for a CylancePROTECT policy.
#>
function Get-CyPolicyScaffold {
    Param (
    )
    @{
        logpolicy = @{
            log_upload = @{
                compress = $true
                delete = $false
            }
            maxlogsize = "100"
            retentiondays = "30"
        }
        policy_name = ""
        policy = @(
            @{
                name = "auto_blocking"
                value = "0"
            }
            @{
                name = "auto_delete"
                value = "0"
            }
            @{
                name = "auto_uploading"
                value = "0"
            }
            @{
                name = "autoit_auto_uploading"
                value = "0"
            }
            @{
                name = "custom_thumbprint"
                value = $null
            }
            @{
                name = "data_privacy"
                value = "0"
            }
            @{
                name = "days_until_deleted"
                value = "14"
            }
            @{
                name = "device_control"
                value = "0"
            }
            @{
                name = "docx_auto_uploading"
                value = "0"
            }
            @{
                name = "full_disc_scan"
                value = "0"
            }
            @{
                name = "kill_running_threats"
                value = "0"
            }
            @{
                name = "logpolicy"
                value = "1"
            }
            @{
                name = "low_confidence_threshold"
                value = "-600"
            }
            @{
                name = "memory_exploit_detection"
                value = "0"
            }
            @{
                name = "ole_auto_uploading"
                value = "0"
            }
            @{
                name = "optics"
                value = "0"
            }
            @{
                name = "optics_application_control_auto_upload"
                value = "0"
            }
            @{
                name = "optics_malware_auto_upload"
                value = "0"
            }
            @{
                name = "optics_memory_defense_auto_upload"
                value = "0"
            }
            @{
                name = "optics_script_control_auto_upload"
                value = "0"
            }
            @{
                name = "optics_set_disk_usage_maximum_fixed"
                value = "1000"
            }
            @{
                name = "pdf_auto_uploading"
                value = "0"
            }
            @{
                name = "powershell_auto_uploading"
                value = "0"
            }
            @{
                name = "prevent_service_shutdown"
                value = "0"
            }
            @{
                name = "python_auto_uploading"
                value = "0"
            }
            @{
                name = "sample_copy_path"
                value = $null
            }
            @{
                name = "scan_max_archive_size"
                value = "150"
            }
            @{
                name = "script_control"
                value = "0"
            }
            @{
                name = "show_notifications"
                value = "0"
            }
            @{
                name = "threat_report_limit"
                value = "500"
            }
            @{
                name = "trust_files_in_scan_exception_list"
                value = "0"
            }
            @{
                name = "watch_for_new_files"
                value = "0"
            }
            @{
                name = "scan_exception_list"
                value = @()
            }
        )
        memoryviolation_actions = @{
            memory_violations = @(
                @{
                    violation_type = "lsassread"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocessunmapmemory"
                    action = "Alert"
                },
                @{
                    violation_type = "stackpivot"
                    action = "Alert"
                },
                @{
                    violation_type = "stackprotect"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocessoverwritecode"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocesscreatethread"
                    action = "Alert"
                },
                @{
                    violation_type = "overwritecode"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocesswritepe"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocessallocation"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocessmap"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocesswrite"
                    action = "Alert"
                },
                @{
                    violation_type = "outofprocessapc"
                    action = "Alert"
                }
            )
            memory_violations_ext = @(
                @{
                    violation_type = "dyldinjection"
                    action = "Alert"
                },
                @{
                    violation_type = "trackdataread"
                    action = "Alert"
                },
                @{
                    violation_type = "zeroallocate"
                    action = "Alert"
                },
                @{
                    violation_type = "maliciouspayload"
                    action = "Alert"
                }
            )
            memory_exclusion_list = @()
        }
        file_exclusions = @()
        checksum = ""
        script_control = @{
            global_settings = @{
                allowed_folders = @()
                control_mode = "Alert"
            }
            powershell_settings = @{
                console_mode = "Allow"
                control_mode = "Alert"
            }
            macro_settings = @{
                control_mode = "Alert"
            }
            activescript_settings = @{
                control_mode = "Alert"
            }
        }
        filetype_actions = @{
            suspicious_files = @(
                @{
                    actions = "0"
                    file_type = "executable"
                }
            )
            threat_files = @(
                @{
                    actions = "0"
                    file_type = "executable"
                }
            )
        }
    }
}

<#
.SYNOPSIS
    Creates a new policy in the console.

.DESCRIPTION
    The new policy is either created with default settings, or with the settings from the policy object passed.
    
    If the policy object is an existing policy, its ID, policy_name and other (checksum, last modified timestamp) properties
    will be overwritten before the policy is created.

.PARAMETER Name
    The name of the new policy

.PARAMETER Policy
    Policy object with settings to use. Optional.

.PARAMETER User
    User object (as returned by Get-CyUserDetail or Get-CyUserList) to use as creator, OR auser's email address.
#>
function New-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String]$Name,
        [Parameter(Mandatory=$false)]
        [object]$Policy = $null,
        [Parameter(Mandatory=$true)]
        [object]$User
    )
    Begin {
        # support passing the email address instead of a user object
        if ($User -match ".+@.+") {
            $User = Get-CyUserByEmail -API $API -Email $User
        }
    }

    Process {
        if ($Policy -eq $null) {
            $Policy = Get-CyPolicyScaffold
        }

        # remove fields that don't sit well with policy puts
        $Policy.checksum = ""
        $Policy.policy_name = $Name
        $Policy.psobject.properties.Remove("policy_utctimestamp")
        $Policy.psobject.properties.Remove("policy_id")

        $json = @{
            policy = $Policy
            user_id = $($User.id)
        } | ConvertTo-Json -Depth 100

        Invoke-CyRestMethod -API $API -Method POST -Uri "$($API.BaseUrl)/policies/v2" -ContentType "application/json; charset=utf-8" -Body $json
    }
}

function Update-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [object]$Policy = $null,
        [Parameter(Mandatory=$true)]
        [object]$User
    )
    Begin {
        # support passing the email address instead of a user object
        if ($User -match ".+@.+") {
            $User = Get-CyUserByEmail -API $API -Email $User
        }
    }

    Process {
        # remove fields that need to be removed for policy puts
        $Policy.checksum = ""
        $Policy.psobject.properties.Remove("policy_utctimestamp")

        $json = @{
            policy = $Policy
            user_id = $($User.id)
        } | ConvertTo-Json -Depth 100

        Invoke-CyRestMethod -API $API -Method PUT -Uri "$($API.BaseUrl)/policies/v2" -ContentType "application/json; charset=utf-8" -Body $json
    }
}

<#
.SYNOPSIS
    Creates a copy of an existing policy under a new name with identical settings.

.PARAMETER SourcePolicyName
    Original policy

.PARAMETER TargetPolicyName
    Target policy name

.PARAMETER User
    User object (as returned by Get-CyUserDetail or Get-CyUserList) to use as creator.
#>
function Copy-CyPolicy {
    Param (
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [CylanceAPIHandle]$API = $GlobalCyAPIHandle,
        [Parameter(Mandatory=$true)]
        [String]$SourcePolicyName,
        [Parameter(Mandatory=$true)]
        [object]$TargetPolicyName,
        [Parameter(Mandatory=$true)]
        [object]$User
    )

    # support passing the email address instead of a user object
    if ($User -match ".+@.+") {
        $User = Get-CyUserByEmail -API $API -Email $User
    }

    $shallowPolicy = Get-CyPolicyList | where name -eq $SourcePolicyName
    $policy = Get-CyPolicy -API $API -Policy $shallowPolicy

    New-CyPolicy -Policy $policy -User $User -Name $TargetPolicyName -Verbose

}

<#
.SYNOPSIS
    Adds a value to a list setting in a policy

.PARAMETER Type
    The type of setting to add a value to

.PARAMETER Value
    The value to add

.PARAMETER Policy
    The policy to add the setting to
#>
function Add-CyPolicyListSetting {
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateSet ("MemDefExclusionPath", "ScriptControlExclusionPath", "ScanExclusion" )]
        [String[]]$Type,
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [pscustomobject]$Policy,
        [Parameter(Mandatory=$false)]
        [String]$Value
    )
    Begin {
    }

    Process {
        if (! ([String]::IsNullOrEmpty($Value))) {
            switch ($Type) {
                "MemDefExclusionPath" {
                    if (! (($Policy.memoryviolation_actions.memory_exclusion_list -contains $Value)))
                    {
                        Write-Verbose "Adding policy memory exclusion: $($Value)"
                        $Policy.memoryviolation_actions.memory_exclusion_list += $Value
                    }
                }
                "ScriptControlExclusionPath" {
                    if (! ($Policy.script_control.global_settings.allowed_folders -contains $Value))
                    {
                        Write-Verbose "Adding script control exclusion: $($Value)"
                        $Policy.script_control.global_settings.allowed_folders += $Value
                    }
                }
                "ScanExclusion" {
                    $scan_exception_list = $Policy.policy | Where-Object name -eq scan_exception_list
                    if (! ($scan_exception_list.value -contains $Value)) 
                    {
                        Write-Verbose "Adding scan folder exclusion: $($Value)"
                        $scan_exception_list.value += $Value
                    }
                }
            }
        }
    }
}
