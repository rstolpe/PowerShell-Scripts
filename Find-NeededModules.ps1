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
    Write-Host "`n=== Making sure that all modules are installad and up to date ===`n"
    # Modules to check if it's installed and imported
    $NeededModules = @("PowerShellGet", "MSIPatches", "PSWindowsUpdate")
    # Collects all of the installed modules on the system
    $CurrentModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object Name

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
                    Update-Module -Name $($m) -AcceptLicense -Scope:AllUsers
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
                                Uninstall-Module -Name $m -RequiredVersion $Version.Version -Force:$True -ErrorAction SilentlyContinue
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
                Install-Module -Name $m -AcceptLicense -Scope:AllUsers -Force:$true
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