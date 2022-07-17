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

$PSVersion = $Host.Version.Major

Function Confirm-NeededModules {
    <#
        .SYNOPSIS
        Function that will let you in a easy way install or upgrade needed modules

        .DESCRIPTION
        This function will install specified modules if they are missing or upgrade them to the latest version if the modules already are installed.
        Option to delete all of the older versions of the modules and import the modules at the end does also exist.

        .PARAMETER NeededModules
        Here you can specify what modules you want to install and upgrade

        .PARAMETER ImportModules
        If this is used it will import all of the modules in the end of the script

        .PARAMETER DeleteOldVersion
        When this is used it will delete all of the older versions of the module after upgrading the module

        .PARAMETER OnlyUpgrade
        When this is used the script will not install any modules it will upgrade all of the already installed modules on the computer to the latest version.

        .EXAMPLE
        Confirm-NeededModules -NeededModules "PowerCLI,ImportExcel" -ImportModules -DeleteOldVersion
        This will check so PowerCLI and ImportExcel is installd and up to date, it not it will install them or upgrade them to the latest version and then delete
        all of the old versions and import the modules.

        Confirm-NeededModules -NeededModules "PowerCLI"
        This will only install PowerCli if it's not installed and upgrade it if needed. This example will not delete the old versions of PowerCli or import the module at the end.

        Confirm-NeededModules -NeededModules "PowerCLI" -OnlyUpgrade
        This will only upgrade PowerCLI module

        Confirm-NeededModules -OnlyUpgrade
        This will upgrade all of the already installed modules on the computer to the latest version

        Confirm-NeededModules -OnlyUpgrade -DeleteOldVersion
        This will upgrade all of the already installed modules on the computer to the latest version and delete all of the old versions after

    #>

    [CmdletBinding()]
    Param(
        [array]$NeededModules,
        [switch]$ImportModules,
        [switch]$DeleteOldVersion,
        [switch]$OnlyUpgrade
    )
    # Collects all of the installed modules on the system
    $CurrentModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

    if ($OnlyUpgrade -eq $True) {
        if ($Null -eq $NeededModules) {
            $NeededModules = $CurrentModules
        }
        $HeadLine = "`n=== Making sure that all modules up to date ===`n"
    }
    else {
        $HeadLine = "`n=== Making sure that all modules are installad and up to date ===`n"
        $NeededPackages = @("NuGet", "PowerShellGet")
        # Collects all of the installed packages
        $CurrentInstalledPackageProviders = Get-PackageProvider -ListAvailable | Select-Object Name -ExpandProperty Name
    }

    Write-Host $HeadLine
    Write-Host "Please wait, this can take time..."
    # This packages are needed for this script to work, you can add more if you want. Don't confuse this with modules
    if ($OnlyUpgrade -eq $false) {
        # Making sure that TLS 1.2 is used.
        Write-Host "Making sure that TLS 1.2 is used..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        # Installing needed packages if it's missing.
        Write-Host "Making sure that all of the PackageProviders that are needed are installed..."
        foreach ($Provider in $NeededPackages.Name) {
            if ($Provider -NotIn $CurrentInstalledPackageProviders) {
                Try {
                    Write-Host "Installing $($Provider) as it's missing..."
                    Install-PackageProvider -Name $provider -Force -Scope AllUsers
                    Write-Host "$($Provider) is now installed" -ForegroundColor Green
                }
                catch {
                    Write-Error "$($PSItem.Exception)"
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
                Write-Error "$($PSItem.Exception)"
                continue
            }
        }
        else {
            Write-Host "PSGallery is already trusted" -ForegroundColor Green
        }
    }

    # Checks if all modules in $NeededModules are installed and up to date.
    foreach ($m in $NeededModules.Split(",").Trim()) {
        if ($m -in $CurrentModules.Name -or $OnlyUpgrade -eq $true) {
            if ($m -in $CurrentModules.Name) {
                # Collects the latest version of module
                $NewestVersion = Find-Module -Name $m | Sort-Object Version -Descending | Select-Object Version -First 1
                # Get all the installed modules and versions
                $AllCurrentVersion = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending

                Write-Host "Checking if $($m) needs to be updated..."
                # Check if the module are up to date
                if ($AllCurrentVersion.Version -lt $NewestVersion.Version) {
                    try {
                        Write-Host "Updating $($m) to version $($NewestVersion.Version)..."
                        Update-Module -Name $($m) -Scope AllUsers -Force
                        Write-Host "$($m) has been updated!" -ForegroundColor Green
                    }
                    catch {
                        Write-Error "$($PSItem.Exception)"
                        continue
                    }
                    if ($DeleteOldVersion -eq $true) {
                        $AllCurrentVersion = Get-InstalledModule -Name $m -AllVersions | Sort-Object PublishedDate -Descending
                        # Remove old versions of the modules
                        if ($AllCurrentVersion.Count -gt 1) {
                            $MostRecentVersion = $AllCurrentVersion[0].Version
                            Foreach ($Version in $AllCurrentVersion.Version) {
                                if ($Version -ne $MostRecentVersion) {
                                    try {
                                        Write-Host "Uninstalling previous version $($Version) of module $($m)..."
                                        Uninstall-Module -Name $m -RequiredVersion $Version -Force -ErrorAction SilentlyContinue
                                        Write-Host "Version $($Version) of $($m) are now uninstalled!" -ForegroundColor Green
                                    }
                                    catch {
                                        Write-Error "$($PSItem.Exception)"
                                        continue
                                    }
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
                Write-Warning "Can't check if $($m) needs to be updated as $($m) are not installed!"
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
                Write-Error "$($PSItem.Exception)"
                continue
            }
        }
    }
    if ($ImportModules -eq $true) {
        # Collect all of the imported modules.
        $ImportedModules = get-module | Select-Object Name, Version
    
        # Import module if it's not imported
        foreach ($module in $NeededModules.Split(",").Trim()) {
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
                    Write-Error "$($PSItem.Exception)"
                    continue
                }
            }
        }
    }
    Write-Host "`n== Script Finished! ==" -ForegroundColor Green
}

Function Remove-MSPatches {
    if ($PSVersion -gt 5) {
        Write-Warning "Remove-MSPatches only works with PowerShell 5.1, skipping this function."
    }
    else {
        Write-Host "`n=== Delete all orphaned patches ===`n"
        $OrphanedPatch = Get-OrphanedPatch
        if ($Null -ne $OrphanedPatch) {
            $FreeUp = Get-MsiPatch | select-object OrphanedPatchSize -ExpandProperty OrphanedPatchSize
            Write-Host "This will free up: $($FreeUp)GB"
            try {
                Write-Host "Deleting all of the orphaned patches..."
                Get-OrphanedPatch | Remove-Item
                Write-Host "Success, all of the orphaned patches has been deleted!" -ForegroundColor Green
            }
            catch {
                Write-Error "$($PSItem.Exception)"
                continue
            }
        }
        else {
            Write-Host "No orphaned patches was found." -ForegroundColor Green
        }
    }
}

Function Update-MSUpdates {
    Write-Host "`n=== Windows Update and Windows Store ===`n"
    #Update Windows Store apps!
    if ($PSVersion -gt 5) {
        Write-Warning "Microsoft store updates only works with PowerShell 5.1, skipping this function."
    }
    else {
        try {
            Write-Host "Checking if Windows Store has any updates..."
            $namespaceName = "root\cimv2\mdm\dmmap"
            $className = "MDM_EnterpriseModernAppManagement_AppManagement01"
            $wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
            $result = $wmiObj.UpdateScanMethod()
            Write-Host "$($result)" -ForegroundColor Green
            Write-Host "Success, checking and if needed updated Windows Store apps!" -ForegroundColor Green
        }
        catch {
            Write-Error "$($PSItem.Exception)"
            continue
        }
    }

    # Checking after Windows Updates
    try {
        Write-Host "Starting to search after Windows Updates..."
        $WSUSUpdates = Get-WindowsUpdate
        if ($Null -ne $WSUSUpdates) {
            Install-WindowsUpdate -AcceptAll
            Write-Host "All of the Windows Updates has been installed!" -ForegroundColor Green
        }
        else {
            Write-Host "All of the latest updates has been installed already! Your up to date!" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "$($PSItem.Exception)"
        continue
    }
}

Function Update-MSDefender {
    Write-Host "`n=== Microsoft Defender ===`n"
    try {
        Write-Host "Update signatures from Microsoft Update Server..."
        Update-MpSignature -UpdateSource MicrosoftUpdateServer
        Write-Host "Updated signatures complete!" -ForegroundColor Green
    }
    catch {
        Write-Error "$($PSItem.Exception)"
        continue
    }


    try {
        Write-Host "Starting Defender Quick Scan, please wait..."
        Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
        Write-Host "Defender quick scan is completed!" -ForegroundColor Green
    }
    catch {
        Write-Error "$($PSItem.Exception)"
        continue
    }
}

function Remove-TempFolderFiles {
    Write-Host "`n=== Starting to delete temp files and folders ===`n"
    $WindowsOld = "C:\Windows.old"
    $Users = Get-ChildItem -Path C:\Users | select-object name -ExpandProperty Name
    $TempFolders = @("C:\Temp", "C:\Tmp", "C:\Windows\Temp", "C:\Windows\Prefetch", "C:\Windows\SoftwareDistribution\Download")
    $SpecialFolders = @("C:\`$Windows`.~BT", "C:\`$Windows`.~WS")

    try {
        Write-Host "Stopping wuauserv..."
        Stop-Service -Name 'wuauserv'
        do {
            Write-Host 'Waiting for wuauserv to stop...'
            Start-Sleep -s 1

        } while (Get-Process wuauserv -ErrorAction SilentlyContinue)
        Write-Host "Wuauserv is now stopped!" -ForegroundColor Green
    }
    catch {
        Write-Error "$($PSItem.Exception)"
        continue   
    }

    foreach ($TempFolder in $TempFolders) {
        if (Test-Path -Path $TempFolder) {
            try {
                Write-Host "Deleting all files in $($TempFolder)..."
                Remove-Item "$($TempFolder)\*" -Recurse -Force -Confirm:$false
                Write-Host "All files in $($TempFolder) has been deleted!" -ForegroundColor Green
            }
            catch {
                Write-Error "$($PSItem.Exception)"
                continue   
            }
        }  
    }

    Try {
        Write-Host "Starting wuauserv again..."
        Start-Service -Name 'wuauserv'
        Write-Host "Wuauserv has started again!" -ForegroundColor Green
    }
    catch {
        Write-Error "$($PSItem.Exception)"
        continue   
    }

    foreach ($usr in $Users) {
        $UsrTemp = "C:\Users\$($usr)\AppData\Local\Temp"
        if (Test-Path -Path $UsrTemp) {
            try {
                Write-Host "Deleting all files in $($UsrTemp)..."
                Remove-Item "$($UsrTemp)\*" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "All files in $($UsrTemp) has been deleted!" -ForegroundColor Green
            }
            catch {
                Write-Error "$($PSItem.Exception)"
                continue   
            }
        } 
    }

    if (Test-Path -Path $WindowsOld) {
        try {
            Write-Host "Deleting folder $($WindowsOld)..."
            Remove-Item "$($WindowsOld)\" -Recurse -Force -Confirm:$false
            Write-Host "The folder $($WindowsOld) has been deleted!" -ForegroundColor Green
        }
        catch {
            Write-Error "$($PSItem.Exception)"
            continue   
        }
    }

    foreach ($sFolder in $SpecialFolders) {
        if (Test-Path -Path $sFolder) {
            try {
                takeown /F "$($sFolder)\*" /R /A
                icacls "$($sFolder)\*.*" /T /grant administrators:F
                Write-Host "Deleting folder $($sFolder)\..."
                Remove-Item "$($sFolder)\" -Recurse -Force -Confirm:$False
                Write-Host "Folder $($sFolder)\* has been deleted!" -ForegroundColor Green
            }
            catch {
                Write-Error "$($PSItem.Exception)"
                continue   
            }
        }
    }

}

Function Start-CleanDisk {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Section
    )

    $sections = @(
        'Active Setup Temp Folders',
        'BranchCache',
        'Content Indexer Cleaner',
        'Device Driver Packages',
        'Downloaded Program Files',
        'GameNewsFiles',
        'GameStatisticsFiles',
        'GameUpdateFiles',
        'Internet Cache Files',
        'Memory Dump Files',
        'Offline Pages Files',
        'Old ChkDsk Files',
        'Previous Installations',
        'Recycle Bin',
        'Service Pack Cleanup',
        'Setup Log Files',
        'System error memory dump files',
        'System error minidump files',
        'Temporary Files',
        'Temporary Setup Files',
        'Temporary Sync Files',
        'Thumbnail Cache',
        'Update Cleanup',
        'Upgrade Discarded Files',
        'User file versions',
        'Windows Defender',
        'Windows Error Reporting Archive Files',
        'Windows Error Reporting Queue Files',
        'Windows Error Reporting System Archive Files',
        'Windows Error Reporting System Queue Files',
        'Windows ESD installation files',
        'Windows Upgrade Log Files'
    )

    if ($PSBoundParameters.ContainsKey('Section')) {
        if ($Section -notin $sections) {
            throw "The section [$($Section)] is not available. Available options are: [$($Section -join ',')]."
        }
    }
    else {
        $Section = $sections
    }

    Write-Verbose -Message 'Clearing CleanMgr.exe automation settings.'

    $getItemParams = @{
        Path        = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
        Name        = 'StateFlags0001'
        ErrorAction = 'SilentlyContinue'
    }
    Get-ItemProperty @getItemParams | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue

    Write-Verbose -Message 'Adding enabled disk cleanup sections...'
    foreach ($keyName in $Section) {
        $newItemParams = @{
            Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
            Name         = 'StateFlags0001'
            Value        = 1
            PropertyType = 'DWord'
            ErrorAction  = 'SilentlyContinue'
        }
        $null = New-ItemProperty @newItemParams
    }

    Write-Verbose -Message 'Starting CleanMgr.exe...'
    Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow

    Write-Verbose -Message 'Waiting for CleanMgr and DismHost processes...'
    Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process
}


Confirm-NeededModules -NeededModules "PowerShellGet,MSIPatches,PSWindowsUpdate,NuGet" -ImportModules -DeleteOldVersion
Remove-MSPatches
Remove-TempFolderFiles
Start-CleanDisk
Update-MSDefender
Update-MSUpdates

Write-Host "The script is finished!"
$RebootNeeded = Get-WURebootStatus | Select-Object RebootRequired -ExpandProperty RebootRequired
if ($RebootNeeded -eq "true") {
    Write-Warning "Windows Update want you to reboot your computer, so please do that!" -ForegroundColor Yellow
}