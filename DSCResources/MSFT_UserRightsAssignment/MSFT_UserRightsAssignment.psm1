
Import-Module -Name (Join-Path -Path ( Split-Path $PSScriptRoot -Parent ) `
                               -ChildPath 'SecurityPolicyResourceHelper\SecurityPolicyResourceHelper.psm1') `
                               -Force

$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_UserRightsAssignment'

<#
    .SYNOPSIS
        Gets the current identities assigned to a user rights assignment.
    .PARAMETER Policy
        Specifies the policy to configure.
    .PARAMETER Identity
        Specifies the identity to add to a user rights assignment.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "Create_a_token_object",
            "Access_this_computer_from_the_network",
            "Change_the_system_time",
            "Deny_log_on_as_a_batch_job",
            "Deny_log_on_through_Remote_Desktop_Services",
            "Create_global_objects",
            "Remove_computer_from_docking_station",
            "Deny_access_to_this_computer_from_the_network",
            "Act_as_part_of_the_operating_system",
            "Modify_firmware_environment_values",
            "Deny_log_on_locally",
            "Access_Credential_Manager_as_a_trusted_caller",
            "Restore_files_and_directories",
            "Change_the_time_zone",
            "Replace_a_process_level_token",
            "Manage_auditing_and_security_log",
            "Create_symbolic_links",
            "Modify_an_object_label",
            "Enable_computer_and_user_accounts_to_be_trusted_for_delegation",
            "Generate_security_audits",
            "Increase_a_process_working_set",
            "Take_ownership_of_files_or_other_objects",
            "Bypass_traverse_checking",
            "Log_on_as_a_service",
            "Shut_down_the_system",
            "Lock_pages_in_memory",
            "Impersonate_a_client_after_authentication",
            "Profile_system_performance",
            "Debug_programs",
            "Profile_single_process",
            "Allow_log_on_through_Remote_Desktop_Services",
            "Allow_log_on_locally",
            "Increase_scheduling_priority",
            "Synchronize_directory_service_data",
            "Add_workstations_to_domain",
            "Adjust_memory_quotas_for_a_process",
            "Obtain_an_impersonation_token_for_another_user_in_the_same_session",
            "Perform_volume_maintenance_tasks",
            "Load_and_unload_device_drivers",
            "Force_shutdown_from_a_remote_system",
            "Back_up_files_and_directories",
            "Create_a_pagefile",
            "Deny_log_on_as_a_service",
            "Log_on_as_a_batch_job",
            "Create_permanent_shared_objects"
        )]
        [System.String]
        $Policy,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]      
        [System.String[]]
        $Identity,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $Force
    )
    
    $userRightPolicy = Get-UserRightPolicy -Name $Policy

    Write-Verbose -Message "Policy: $($userRightPolicy.FriendlyName). Identity: $($userRightPolicy.Identity)"
    
    return  @{
        Policy   = $userRightPolicy.FriendlyName
        Identity = $userRightPolicy.Identity
    }
}

<#
    .SYNOPSIS
        Gets the current identities assigned to a user rights assignment.
    .PARAMETER Policy
        Specifies the policy to configure.
    .PARAMETER Identity
        Specifies the identity to add to a user rights assignment.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "Create_a_token_object",
            "Access_this_computer_from_the_network",
            "Change_the_system_time",
            "Deny_log_on_as_a_batch_job",
            "Deny_log_on_through_Remote_Desktop_Services",
            "Create_global_objects",
            "Remove_computer_from_docking_station",
            "Deny_access_to_this_computer_from_the_network",
            "Act_as_part_of_the_operating_system",
            "Modify_firmware_environment_values",
            "Deny_log_on_locally",
            "Access_Credential_Manager_as_a_trusted_caller",
            "Restore_files_and_directories",
            "Change_the_time_zone",
            "Replace_a_process_level_token",
            "Manage_auditing_and_security_log",
            "Create_symbolic_links",
            "Modify_an_object_label",
            "Enable_computer_and_user_accounts_to_be_trusted_for_delegation",
            "Generate_security_audits",
            "Increase_a_process_working_set",
            "Take_ownership_of_files_or_other_objects",
            "Bypass_traverse_checking",
            "Log_on_as_a_service",
            "Shut_down_the_system",
            "Lock_pages_in_memory",
            "Impersonate_a_client_after_authentication",
            "Profile_system_performance",
            "Debug_programs",
            "Profile_single_process",
            "Allow_log_on_through_Remote_Desktop_Services",
            "Allow_log_on_locally",
            "Increase_scheduling_priority",
            "Synchronize_directory_service_data",
            "Add_workstations_to_domain",
            "Adjust_memory_quotas_for_a_process",
            "Obtain_an_impersonation_token_for_another_user_in_the_same_session",
            "Perform_volume_maintenance_tasks",
            "Load_and_unload_device_drivers",
            "Force_shutdown_from_a_remote_system",
            "Back_up_files_and_directories",
            "Create_a_pagefile",
            "Deny_log_on_as_a_service",
            "Log_on_as_a_batch_job",
            "Create_permanent_shared_objects"
        )]
        [System.String]
        $Policy,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [System.String[]]
        $Identity,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $Force = $false
    )
    
    $userRightConstant = Get-UserRightConstant -Policy $Policy

    $script:seceditOutput = "$env:TEMP\Secedit-OutPut.txt"
    $userRightsToAddInf   = "$env:TEMP\userRightsToAdd.inf" 
    $idsToAdd = $Identity -join ","

    if ($null -eq $Identity)
    {
        Write-Verbose -Message ($script:localizedData.IdentityIsNullRemovingAll -f $Policy)
        $idsToAdd = $null
    }
    else
    {
        $currentRights = Get-TargetResource -Policy $Policy -Identity $Identity

        $accounts = @()
        switch ($Identity)
        {
            "[Local Account]" { $accounts += (Get-CimInstance win32_useraccount -Filter "LocalAccount='True'").SID }
            "[Local Account|Administrator]" 
            {
                $administratorsGroup = Get-CimInstance -class win32_group -filter "SID='S-1-5-32-544'"
                $groupUsers = Get-CimInstance -query "select * from win32_groupuser where GroupComponent = `"Win32_Group.Domain='$($env:COMPUTERNAME)'`,Name='$($administratorsGroup.name)'`""
                [array]$usersList = $groupUsers.partcomponent | ForEach-Object { (($_ -replace '.*Win32_UserAccount.Domain="', "") -replace '",Name="', "\") -replace '"', '' }
                $users += $usersList | Where-Object {$_ -match $env:COMPUTERNAME}
                $accounts += $users | ForEach-Object {(Get-CimInstance win32_useraccount -Filter "Caption='$($_.Replace("\", "\\"))'").SID}
            }
            Default { $accounts += $_} 
        }
        
        if ($Ensure -eq "Present")
        {
            if (!$Force)
            {   
                foreach ($id in $currentRights.Identity)
                {
                    if ($id -notin $accounts)
                    {
                        $accounts += $id
                    }
                }
            }
        }
        else
        {
            $accounts = $accounts | Where-Object {$_ -notin $currentRights.Identity}
        }
        
        $idsToAdd = $accounts -join ","
        
        Write-Verbose -Message ($script:localizedData.GrantingPolicyRightsToIds -f $Policy, $idsToAdd)
    }
       
    Out-UserRightsInf -InfPolicy $userRightConstant -UserList $idsToAdd -FilePath $userRightsToAddInf
    Write-Debug -Message ($script:localizedData.EchoDebugInf -f $userRightsToAddInf)

    Write-Verbose "Attempting to Set ($($idstoAdd -join ",")) for Policy $($Policy))"
    Invoke-Secedit -UserRightsToAddInf $userRightsToAddInf -SecEditOutput $seceditOutput
    
    # Verify secedit command was successful

    if ( Test-TargetResource -Identity $Identity -Policy $Policy -Ensure $Ensure )
    {
        Write-Verbose -Message ($script:localizedData.TaskSuccess)
        Write-Verbose "$(($idsToAdd -join ",")) successfully given Rights ($Policy)"
    }
    else
    {
        $seceditResult = Get-Content -Path $script:seceditOutput
        Write-Verbose -Message ($script:localizedData.TaskFail)
        throw "$($script:localizedData.TaskFail) $($seceditResult[-1])"
    }    
}

<#
    .SYNOPSIS
        Gets the current identities assigned to a user rights assignment.
    .PARAMETER Policy
        Specifies the policy to configure.
    .PARAMETER Identity
        Specifies the identity to add to a user rights assignment.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "Create_a_token_object",
            "Access_this_computer_from_the_network",
            "Change_the_system_time",
            "Deny_log_on_as_a_batch_job",
            "Deny_log_on_through_Remote_Desktop_Services",
            "Create_global_objects",
            "Remove_computer_from_docking_station",
            "Deny_access_to_this_computer_from_the_network",
            "Act_as_part_of_the_operating_system",
            "Modify_firmware_environment_values",
            "Deny_log_on_locally",
            "Access_Credential_Manager_as_a_trusted_caller",
            "Restore_files_and_directories",
            "Change_the_time_zone",
            "Replace_a_process_level_token",
            "Manage_auditing_and_security_log",
            "Create_symbolic_links",
            "Modify_an_object_label",
            "Enable_computer_and_user_accounts_to_be_trusted_for_delegation",
            "Generate_security_audits",
            "Increase_a_process_working_set",
            "Take_ownership_of_files_or_other_objects",
            "Bypass_traverse_checking",
            "Log_on_as_a_service",
            "Shut_down_the_system",
            "Lock_pages_in_memory",
            "Impersonate_a_client_after_authentication",
            "Profile_system_performance",
            "Debug_programs",
            "Profile_single_process",
            "Allow_log_on_through_Remote_Desktop_Services",
            "Allow_log_on_locally",
            "Increase_scheduling_priority",
            "Synchronize_directory_service_data",
            "Add_workstations_to_domain",
            "Adjust_memory_quotas_for_a_process",
            "Obtain_an_impersonation_token_for_another_user_in_the_same_session",
            "Perform_volume_maintenance_tasks",
            "Load_and_unload_device_drivers",
            "Force_shutdown_from_a_remote_system",
            "Back_up_files_and_directories",
            "Create_a_pagefile",
            "Deny_log_on_as_a_service",
            "Log_on_as_a_batch_job",
            "Create_permanent_shared_objects"
        )]
        [System.String]
        $Policy,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()] 
        [AllowEmptyString()]               
        [System.String[]]
        $Identity,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Boolean]
        $Force
    )

    $currentUserRights = Get-UserRightPolicy -Name $Policy

    if ( Test-IdentityIsNull -Identity $Identity )
    {
        Write-Verbose -Message ($script:localizedData.TestIdentityIsPresentOnPolicy -f "NULL", $Policy)

        if ( $null -eq $currentUserRights.Identity )
        {
            Write-Verbose -Message ($script:localizedData.NoIdentitiesFoundOnPolicy -f $Policy)
            return $true
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.IdentityFoundExpectedNull -f $Policy)
            return $false
        }
    }

    Write-Verbose -Message ($script:localizedData.TestIdentityIsPresentOnPolicy -f $($Identity -join ","), $Policy)

    $accounts = @()
    switch ($Identity)
    {
        "[Local Account]" { $accounts += (Get-CimInstance Win32_UserAccount -Filter "LocalAccount='True'").SID }
        "[Local Account|Administrator]" 
        {
            $administratorsGroup = Get-CimInstance -class Win32_Group -filter "SID='S-1-5-32-544'"
            $groupUsers = Get-CimInstance -Query "select * from win32_groupuser where GroupComponent = `"Win32_Group.Domain='$($env:COMPUTERNAME)'`,Name='$($administratorsGroup.name)'`""
            [array]$usersList = $groupUsers.partcomponent | ForEach-Object { (($_ -replace '.*Win32_UserAccount.Domain="', "") -replace '",Name="', "\") -replace '"', '' }
            $users += $usersList | Where-Object {$_ -match $env:COMPUTERNAME}
            $accounts += $users | ForEach-Object {(Get-CimInstance Win32_UserAccount -Filter "Caption='$($_.Replace("\", "\\"))'").SID}
        }
        Default
        {
            # To test for identities we have to do a dump of the security database the dump does not specify the 
            # computerName on local accounts. So we need to test for that scenario.
            if ( $_ -match '\\' -and $_ -notmatch 'Builtin')
            {
                if ( Test-IsLocalAccount -Identity $_ )
                {
                    $accounts += ( $_ -split '\\' )[-1]
                }
                else
                {
                    $accounts += ConvertTo-LocalFriendlyName $_
                }
            }
            else
            {
                $accounts += ConvertTo-LocalFriendlyName $(($_) -replace '\*')
            }    
        } 
    }
        
    if ($Ensure -eq "Present")
    {        
        $usersWithoutRight = $accounts | Where-Object { $_ -notin $currentUserRights.Identity }
        if ($usersWithoutRight)
        {
            Write-Verbose "$($usersWithoutRight -join ",") do not have Privilege ($Policy)"
            return $false
        }

        if ($Force)
        {
            $effectiveUsers = $currentUserRights.Identity | Where-Object {$_ -notin $accounts}
            if ($effectiveUsers.Count -gt 0)
            {
                Write-Verbose "$($effectiveUsers -join ",") are extraneous users with Privilege ($Policy)"
                return $false
            }
        }

        $returnValue = $true
    }
    else
    {
        $UsersWithRight = $accounts | Where-Object {$_ -in $userRights.Identity}
        if ($UsersWithRight.Count -gt 0)
        {
            Write-Verbose "$($UsersWithRight) should NOT have Privilege ($Policy)"
            return $false
        }

        $returnValue = $true
    }

    # If the code made it this far all identities have the desired user rights
    return $returnValue
}

<#
    .SYNOPSIS
        Returns an object of the identities assigned to a user rights assignment
    .PARAMETER Name
        Name of the policy to inspect
    .EXAMPLE
        Get-UserRightPolicy -Name Create_a_token_object
#>
function Get-UserRightPolicy
{
    [OutputType([PSObject])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "Create_a_token_object",
            "Access_this_computer_from_the_network",
            "Change_the_system_time",
            "Deny_log_on_as_a_batch_job",
            "Deny_log_on_through_Remote_Desktop_Services",
            "Create_global_objects",
            "Remove_computer_from_docking_station",
            "Deny_access_to_this_computer_from_the_network",
            "Act_as_part_of_the_operating_system",
            "Modify_firmware_environment_values",
            "Deny_log_on_locally",
            "Access_Credential_Manager_as_a_trusted_caller",
            "Restore_files_and_directories",
            "Change_the_time_zone",
            "Replace_a_process_level_token",
            "Manage_auditing_and_security_log",
            "Create_symbolic_links",
            "Modify_an_object_label",
            "Enable_computer_and_user_accounts_to_be_trusted_for_delegation",
            "Generate_security_audits",
            "Increase_a_process_working_set",
            "Take_ownership_of_files_or_other_objects",
            "Bypass_traverse_checking",
            "Log_on_as_a_service",
            "Shut_down_the_system",
            "Lock_pages_in_memory",
            "Impersonate_a_client_after_authentication",
            "Profile_system_performance",
            "Debug_programs",
            "Profile_single_process",
            "Allow_log_on_through_Remote_Desktop_Services",
            "Allow_log_on_locally",
            "Increase_scheduling_priority",
            "Synchronize_directory_service_data",
            "Add_workstations_to_domain",
            "Adjust_memory_quotas_for_a_process",
            "Obtain_an_impersonation_token_for_another_user_in_the_same_session",
            "Perform_volume_maintenance_tasks",
            "Load_and_unload_device_drivers",
            "Force_shutdown_from_a_remote_system",
            "Back_up_files_and_directories",
            "Create_a_pagefile",
            "Deny_log_on_as_a_service",
            "Log_on_as_a_batch_job",
            "Create_permanent_shared_objects"
        )]
        [System.String]
        $Name
    )

    $userRightConstant = Get-UserRightConstant -Policy $Name

    $userRights = Get-SecurityPolicy -Area 'USER_RIGHTS'  

    [PSObject]@{
        Constant     = $userRightConstant
        FriendlyName = $Name
        Identity     = $userRights[$userRightConstant]
    }
}

<#
    .SYNOPSIS
        Converts policy names that match the GUI to the abbreviated names used by secedit.exe
    .PARAMETER Policy
        Name of the policy to get friendly name for. 
#>
function Get-UserRightConstant
{
    [OutputType([string])]
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Policy
    )
    
    $friendlyNames = Get-Content -Path $PSScriptRoot\UserRightsFriendlyNameConversions.psd1 -Raw | 
        ConvertFrom-StringData

    $friendlyNames[$Policy]
}

<#
    .SYNOPSIS 
        Creates Inf with desired configuration for a user rights assignment that is passed to secedit.exe
    .PARAMETER InfPolicy
        Name of user rights assignment policy
    .PARAMETER UserList
        List of users to be added to policy
    .PARAMETER FilePath
        Path to where the Inf will be created
    .EXAMPLE
        Out-UserRightsInf -InfPolicy SeTrustedCredManAccessPrivilege -UserList Contoso\User1 -FilePath C:\Scratch\Secedit.Inf
#>
function Out-UserRightsInf
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $InfPolicy,

        [Parameter(Mandatory = $true)]
        [System.String]
        $UserList,

        [Parameter(Mandatory = $true)]
        [System.String]
        $FilePath
    )

    $infTemplate =@"
[Unicode]
Unicode=yes
[Privilege Rights]
$InfPolicy = $UserList
[Version]
signature="`$CHICAGO`$"
Revision=1
"@

    $null = Out-File -InputObject $infTemplate -FilePath $FilePath -Encoding unicode
}
<#
    .SYNOPSIS
        Test if an account is a local account
    .PARAMETER Identity
        The identity of the user or group to be added or removed from the user rights assignment
#>
function Test-IsLocalAccount
{
    param
    (
        [string]$Identity
    )

    $localAccounts = Get-CimInstance Win32_UserAccount -Filter "LocalAccount='True'"

    if ( $localAccounts.Caption -contains $Identity )
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
