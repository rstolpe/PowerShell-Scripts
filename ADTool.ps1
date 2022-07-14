<#
    Copyright (C) 2022  Stolpe.io
    <https://stolpe.io>
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

Function Find-NeededModules {
    # Modules to check if it's installed and imported
    $NeededModules = @("ImportExcel", "ActiveDirectory", "NuGet", "PowerShellGet")
    $NeededPackages = @("NuGet", "PowerShellGet")
    # Collects all of the installed modules on the system
    $CurrentModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name
    # Collects all of the installed packages
    $AllPackageProviders = Get-PackageProvider -ListAvailable | Select-Object Name -ExpandProperty Name

    # Making sure that TLS 1.2 is used.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    if ("ActiveDirectory" -NotIn $CurrentModules.Name) {
        throw "Can't continue this script as ActiveDirectory Module are missing, please install RSAT"
    }

    # Installing needed packages if it's missing.
    Write-Host "Making sure that all of the PackageProviders that are needed are installed..."
    foreach ($Provider in $NeededPackages) {
        if ($Provider -NotIn $AllPackageProviders) {
            Try {
                Write-Host "Installing $($Provider) as it's missing..."
                Install-PackageProvider -Name $provider -Force -Scope AllUsers
                Write-Host "$($Provider) is now installed" -ForegroundColor Green
            }
            catch {
                Write-Error "Error installing $($Provider)"
                Write-Error "$($PSItem.Exception.Message)"
                continue
            }
        }
        else {
            Write-Host "$($provider) is already installed." -ForegroundColor Green
        }
    }

    # Setting PSGallery as trusted if it's not trusted
    Write-Host "Making sure that PSGallery is set to Trusted..."
    if ((Get-PSRepository -name PSGallery | Select-Object InstallationPolicy -ExpandProperty InstallationPolicy) -eq "Untrusted") {
        try {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            Write-Host "PSGallery is now set to trusted" -ForegroundColor Green
        }
        catch {
            Write-Error "Error could not set PSGallery to trusted"
            Write-Error "$($PSItem.Exception.Message)"
            continue
        }
    }
    else {
        Write-Host "PSGallery is already trusted" -ForegroundColor Green
    }

    # Checks if all modules in $NeededModules are installed and up to date.
    foreach ($m in $NeededModules) {
        if ($m -in $CurrentModules.Name) {
            # Collects the latest version of module
            $NewestVersion = Find-Module -Name $m | Sort-Object Version -Descending | Select-Object Version -First 1
            # Get all the installed modules and versions
            $AllVersions = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending
            $MostRecentVersion = $AllVersions[0].Version

            Write-Host "Checking if $($m) needs to be updated..."
            # Check if the module are up to date
            if ($NewestVersion.Version -gt $AllVersions.Version) {
                try {
                    Write-Host "Updating $($m) to version $($NewestVersion.Version)..."
                    Update-Module -Name $($m) -Scope AllUsers
                    Write-Host "$($m) has been updated!" -ForegroundColor Green
                }
                catch {
                    Write-Error "Error updating module $($m)"
                    Write-Error "$($PSItem.Exception.Message)"
                    continue
                }

                # Remove old versions of the modules
                if ($AllVersions.Count -gt 1 ) {
                    Foreach ($Version in $AllVersions) {
                        if ($Version.Version -ne $MostRecentVersion) {
                            try {
                                Write-Host "Uninstalling previous version $($Version.Version) of module $($m)..."
                                Uninstall-Module -Name $m -RequiredVersion $Version.Version -Force -ErrorAction SilentlyContinue
                                Write-Host "$($m) are not uninstalled!" -ForegroundColor Green
                            }
                            catch {
                                Write-Error "Error uninstalling previous version $($Version.Version) of module $($m)"
                                Write-Error "$($PSItem.Exception.Message)"
                                continue
                            }
                        }
                    }
                }
            }
            else {
                Write-Host "$($m) don't need to be updated as it's on the latest version" -ForegroundColor Green
            }
        }
        else {
            # Installing missing module
            Write-Host "Installing module $($m) as it's missing..."
            try {
                Install-Module -Name $m -Scope AllUsers -Force
                Write-Host "$($m) are now installed!" -ForegroundColor Green
            }
            catch {
                Write-Error "Could not install $($m)"
                Write-Error "$($PSItem.Exception)"
                continue
            }
        }
    }
    # Collect all of the imported modules.
    $ImportedModules = get-module | Select-Object Name, Version
    
    # Import module if it's not imported
    foreach ($module in $NeededModules) {
        if ($module -in $ImportedModules.Name) {
            Write-Host "$($Module) are already imported!" -ForegroundColor Green
        }
        else {
            try {
                Write-Host "Importing $($module) module..."
                Import-Module -Name $module -Force
                Write-Host "$($module) are now imported!" -ForegroundColor Green
            }
            catch {
                Write-Error "Could not import module $($module)"
                Write-Error "$($PSItem.Exception.Message)"
                continue
            }
        }
    }
}

function Get-ADLastSeen {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)][string]$ObjectName,
        [Parameter(Mandatory)][string]$ObjectType
    )

    $DCs = Get-ADDomainController -Filter { Name -like "*" } | Select-Object hostname -ExpandProperty hostname

    if ($ObjectType -eq "Computer") {
        $LogonDates = foreach ($dc in $dcs) {
            [PSCustomObject]@{
                Server    = $dc.hostname
                LastLogon = [DateTime]::FromFileTime((Get-ADComputer -Identity $ObjectName -Properties LastLogon -Server $dc.hostname).LastLogon)
            }
        }
    }
    elseif ($ObjectType -eq "User") {
        $LogonDates = foreach ($dc in $dcs) {
            [PSCustomObject]@{
                Server    = $dc.hostname
                LastLogon = [DateTime]::FromFileTime((Get-ADUser -Identity $ObjectName -Properties LastLogon -Server $dc.hostname).LastLogon)
            }
        }
    }
    ($LogonDates | Sort-Object -Property LastLogon -Descending | Select-Object -First 1).LastLogon
}

Function Unlock-ADAccounts {
    Find-NeededModules
    Write-Host "`n================ Unlock AD account or accounts ================`n"
    #You must write the usernames like this user1,user2,user3 etc or you can just write one user name
    [string]$UserNames = Read-Host -Prompt "What user or users do you want to unlock? (separate the users with ,)"
    [array]$UserNames = $UserNames -split ","

    foreach ($User in $UserNames) {
        # Checks if the AD Account exists
        $CheckADAccount = $(try { Get-ADUser -Filter "SamAccountName -eq '$($User)'" -properties SamAccountName } catch { $null })
        if ($Null -ne $CheckADAccount) { 
            # Get locked status from the AD Account
            $ADuser = Get-ADUser -Filter "SamAccountName -eq '$($User)'" -Properties LockedOut, SamAccountName

            # IF the AD account are locked the following are happening
            if ($ADuser.LockedOut -eq $true) { 
                # Unlocks the account but it also catches if something goes wrong, but it still continues.
                try {
                    Unlock-ADAccount -Identity $ADuser.SamAccountName -Confirm:$false
                    write-host "$($ADuser.SamAccountName) has now been unlocked" -ForegroundColor Green
                }
                catch {
                    Write-Host "$($PSItem.Exception)" -ForegroundColor Red
                    return
                }
            }
            else {
                Write-Host "$($ADuser.SamAccountName) was not locked, did not do anything" -ForegroundColor Green
            }
        }
        else {
            Write-Host "$($ADuser.SamAccountName) don't exists in the AD, continuing to the next user" -ForegroundColor Red
        }
    }
    Select-ADFunction
}

Function Enable-ADAccounts {
    Find-NeededModules
    Write-Host "`n================ Enable AD account or accounts ================`n"
    #You must write the usernames like this user1,user2,user3 etc or you can just write one user name
    [string]$UserNames = Read-Host -Prompt "What user or users do you want to enable? (separate the users with , )"
    [array]$UserNames = $UserNames -split ","

    foreach ($User in $UserNames) {
        # Checks if the AD Account exists
        $CheckADAccount = $(try { Get-ADUser -Filter "SamAccountName -eq '$($User)'" -properties SamAccountName } catch { $null })
        if ($Null -ne $CheckADAccount) { 
            # Get enabled status from the AD Account
            $ADuser = Get-ADUser -Filter "SamAccountName -eq '$($User)'" -Properties Enabled, SamAccountName

            # IF the AD account are disabled the following are happening
            if ($ADuser.Enabled -eq $false) { 
                # Enable the account but it also catches if something goes wrong, but it still continues.
                try {
                    Enable-ADAccount -Identity $ADuser.SamAccountName -Confirm:$false
                    write-host "$($ADuser.SamAccountName) has now been enabled" -ForegroundColor Green
                }
                catch {
                    Write-Host "$($PSItem.Exception)" -ForegroundColor Red
                    return
                }
            }
            else {
                Write-Host "$($ADuser.SamAccountName) was already enabled did not do anything" -ForegroundColor Green
            }
        }
        else {
            Write-Host "$($ADuser.SamAccountName) don't exists in the AD, continuing to the next user" -ForegroundColor Red
        }
    }
    Select-ADFunction
}

Function Debug-ADUser {
    Find-NeededModules
    Write-Host "`n================ Debug user or users Active Directory account ================`n"
    #You must write the usernames like this user1,user2,user3 etc or you can just write one user name
    [string]$UserNames = Read-Host -Prompt "What user or users do you want to debug?"
    [array]$UserNames = $UserNames -split ","

    foreach ($User in $UserNames) {
        $CheckADAccount = $(try { Get-ADUser -Filter "SamAccountName -eq '$($User)'" -properties SamAccountName } catch { $null })

        if ($Null -ne $CheckADAccount) {
            $UserInfo = Get-ADUser -Filter "samaccountname -eq '$($User)'" -Properties UserPrincipalName, Enabled, lockedout, Passwordneverexpires, passwordexpired, AccountExpirationDate
            $Collectpwdexpdate = (Get-ADUser -Filter "samaccountname -eq '$($User)'" -Properties msDS-UserPasswordExpiryTimeComputed).'msDS-UserPasswordExpiryTimeComputed'
            $Today = Get-Date

            Write-Host "`n================ Status of $($User) ================`n"
            if ($UserInfo.Enabled -eq $true) {
                Write-Host "Enabled: Yes" -ForegroundColor Green
            }
            else {
                Write-Host "Enabled: No" -ForegroundColor Red
            }
            if ($UserInfo.lockedout -eq $true) {
                Write-Host "Locked: Yes" -ForegroundColor Red
            }
            else {
                Write-Host "Locked: No" -ForegroundColor Green
            }
            if (-Not($Collectpwdexpdate -eq "9223372036854775807")) {
                $pwdexpdate = [datetime]::FromFileTime($Collectpwdexpdate).ToString("yyyy-MM-dd HH:mm")
            }
            if ($pwdexpdate -like "1601-01-01*" -or $pwdexpdate -like "01/01/1601*") {
                Write-Host "Password expired: No, but it's set that the user need to change the password on the next login" -ForegroundColor Green
            }
            elseif ($UserInfo.Passwordneverexpires -eq $true) {
                Write-Host "Password expired: No, the password are set so it will never expire" -ForegroundColor Green
            }
            elseif ($UserInfo.passwordexpired -eq $true) {
                Write-Host "Password expired: Yes, the password did expire $($pwdexpdate)" -ForegroundColor Red
            }
            elseif ($UserInfo.passwordexpired -eq $false) {
                Write-Host "Password expired: No, password expires $($pwdexpdate)" -ForegroundColor Green
            }
            else {
                $Null
            }                   
                            
            if ($null -ne $UserInfo.AccountExpirationDate) {
                if ($UserInfo.AccountExpirationDate.ToString("yyyy-MM-dd HH:mm") -le $today.ToString("yyyy-MM-dd HH:mm")) {
                    Write-Host "Account Expired: Yes, it did expire $($UserInfo.AccountExpirationDate.ToString("yyyy-MM-dd HH:mm"))" -ForegroundColor Red
                }
                else {
                    Write-Host "Account Expired: No, it expires $($UserInfo.AccountExpirationDate.ToString("yyyy-MM-dd HH:mm"))" -ForegroundColor Green 
                }
            }
            else {
                Write-Host "Account Expired: No" -ForegroundColor Green 
            }

            $GetLastDate = Get-ADLastSeen -ObjectName $User -ObjectType "User"
            if (-Not([string]::IsNullOrEmpty($GetLastDate))) {
                $LastLoginDate = $GetLastDate.ToString("yyyy-MM-dd HH:mm")
            }
            if ([string]::IsNullOrEmpty($GetLastDate)) {
                $Null
            }
            elseif ($LastLoginDate -eq "1601-01-01 01:00") {
                Write-Host "Last connected to the domain: Has never connected" -ForegroundColor Red
            }
            else {
                Write-Host "Last connected to the domain: $($GetLastDate)" -ForegroundColor Green 
            }
        }
        else {
            Write-Host "$($User) did not exist in the Active Directory, continuing to the next user" -ForegroundColor Red
        }
    }
    Select-ADFunction
}

Function Select-ADFunction { 
    Write-Host "`n================ Stolpe.io Active Directory tool ================"
    Write-Host "1: Press '1' to debug user or users Active Directory account"
    Write-Host "2: Press '2' to unlock user or users"
    Write-Host "3: Press '3' to enable user or users"
    Write-Host "Q: Press 'Q' to quit."
    $WhatFunction = Read-Host "What function do you want to run?"

    Switch ($WhatFunction ) {
        1 {
            Debug-ADUser
        }
        2 {
            Unlock-ADAccounts
        }
        3 {
            Enable-ADAccounts
        }
        "Q" {
            return
        }
    }
}