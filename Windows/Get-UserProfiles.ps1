Function Get-UserProfiles {
    <#
        .SYNOPSIS
        Shows all user profiles that are stored on a computer
        .DESCRIPTION
        Shows all user profiles that are stored on a local or remote computer and you can also delete one or all of the user profiles, the special windows profiles are excluded
        .PARAMETER Computer
        The name of the remote computer you want to display all of the user profiles from. If you want to use it on a local computer you don't need to fill this one out.
        .PARAMETER ExcludedProfiles
        All of the usernames you write here will be excluded from the script and they will not show up, it's a array so you can add multiple users like @("User1", "User2")
        .EXAMPLE
        Get-UserProfiles
        This will show all of the user profiles stored on the local machine

        Get-UserProfiles -ExcludedProfiles @("Frank", "rstolpe")
        This will show all of the user profiles stored on the local machine except user profiles that are named Frank and rstolpe

        Get-UserProfiles -Computer "Win11-Test"
        This will show all of the user profiles stored on the remote computer "Win11-test"

        Get-UserProfiles -Computer "Win11-Test" -ExcludedProfiles @("Frank", "rstolpe")
        This will show all of the user profiles stored on the remote computer "Win11-Test" except user profiles that are named Frank and rstolpe
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)][string]$Computer,
        [Parameter(Mandatory = $False)][array]$ExcludedProfiles
    )
    if ([string]::IsNullOrEmpty($Computer)) {
        $Computer = "localhost"
    }

    try {
        Get-CimInstance -ComputerName $Computer -className Win32_UserProfile | Where-Object { (-Not ($_.Special)) } | Foreach-Object {
            if (-Not ($_.LocalPath.split('\')[-1] -in $ExcludedProfiles)) {
                [PSCustomObject]@{
                    ProfileUserName = $_.LocalPath.split('\')[-1]
                    ProfilePath     = $_.LocalPath
                    LastUsed        = ($_.LastUseTime -as [DateTime]).ToString("yyyy-MM-dd HH:mm")
                    IsProfileLoaded = $_.Loaded
                }
            }
        }
    }
    catch {
        Write-Error "Something went wrong when collecting the user profiles!"
        Write-Error "$($PSItem.Exception.Message)"
        break
    }
}

Function Remove-UserProfile {
    <#
        .SYNOPSIS
        Let you delete user profiles from a local or remote computer
        .DESCRIPTION
        Let you delete user profiles from a local computer or remote computer, you can also delete all of the user profiles. You can also exclude profiles.
        If the profile are loaded you can't delete it. The special Windows profiles are excluded
        .PARAMETER Computer
        The name of the remote computer you want to display all of the user profiles from. If you want to use it on a local computer you don't need to fill this one out.
        .PARAMETER ProfileToDelete
        If you want to delete just one user profile your specify the username here.
        .PARAMETER DeleteAll
        If you want to delete all of the user profiles on the local or remote computer you can set this to $True or $False
        .EXAMPLE
        Remove-UserProfile -DeleteAll
        This will remove all of the user profiles from the local computer your running the script from.

        Remove-UserProfile -ProfileToDelete @("User1", "User2")
        This will delete only user profile "User1" and "User2" from the local computer where you run the script from.

        Remove-UserProfile -Computer "Win11-test" -DeleteAll
        This will delete all of the user profiles on the remote computer named "Win11-Test"

        Remove-UserProfile -Computer "Win11-test" -ProfileToDelete @("User1", "User2")
        This will delete only user profile "User1" and "User2" from the remote computer named "Win11-Test"

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)][string]$Computer,
        [Parameter(Mandatory = $False)][array]$ProfileToDelete,
        [Parameter(Mandatory)][switch]$DeleteAll,
        [Parameter(Mandatory = $False)][array]$ExcludedProfiles
    )
    if ([string]::IsNullOrEmpty($Computer)) {
        $Computer = "localhost"
    }

    $AllUserProfiles = Get-CimInstance -ComputerName $Computer -className Win32_UserProfile | Where-Object { (-Not ($_.Special)) } | Select-Object LocalPath, Loaded

    if ($DeleteAll -eq $True) {
        foreach ($Profile in $AllUserProfiles) {
            if ($Profile.Loaded -eq $True) {
                Write-Warning "The user profile $($Profile.LocalPath.split('\')[-1]) is loaded, can't delete it so skipping it!"
            }
            else {
                try {
                    write-Host "Deleting user profile $($Profile.LocalPath.split('\')[-1])..."
                    Get-CimInstance -ComputerName $Computer Win32_UserProfile | Where-Object { $_.LocalPath -eq $Profile.LocalPath } | Remove-CimInstance
                    Write-Host "The user profile $($Profile.LocalPath.split('\')[-1]) are now deleted!" -ForegroundColor Green
                }
                catch {
                    Write-Error "Something went wrong when trying to delete the user profile $($Profile.LocalPath.split('\')[-1])"
                    Write-Error "$($PSItem.Exception.Message)"
                    continue
                }
            }
        }
    }
    elseif ($DeleteAll -eq $False) {
        foreach ($user in $ProfileToDelete) {
            if ("C:\Users\$($user)" -in $AllUserProfiles.LocalPath) {
                # check if the userprofile are loaded and if it is show warning
                try {
                    write-Host "Deleting user profile $($user)..."
                    Get-CimInstance -ComputerName $Computer Win32_UserProfile | Where-Object { $_.LocalPath -eq "C:\Users\$($user)" } | Remove-CimInstance
                    Write-Host "The user profile $($user) are now deleted!" -ForegroundColor Green
                }
                catch {
                    Write-Error "Something went wrong when trying to delete the user profile $($user)"
                    Write-Error "$($PSItem.Exception.Message)"
                    continue
                }
            }
            else {
                Write-Warning "$($user) did not have any user profile on the computer!"
            }
        }
    }
}