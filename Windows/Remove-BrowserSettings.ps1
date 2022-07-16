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

function Remove-BrowserSettings {
    <#
        .SYNOPSIS
        Delete all settings for Chrome or Edge for a specified user

        .DESCRIPTION
        This function will delete all of the Chrome or Edge settings for a specified user, it will also save the bookmarks to C:\Temp before deleting and restoring them after.

        .PARAMETER Computer
        If you want to delete the settings on a remote computer you need to specify the computer name here, not needed if you going to use it on a local computer.

        .PARAMETER UserName
        Write the username of the user that you want to delete the Edge or Chrome settings for.

        .PARAMETER Edge
        Use this switch if you want to delete the settings for Edge

        .PARAMETER Chrome
        Use this switch if you want to delete the settings for Chrome

        .PARAMETER ListUsers
        When using this switch it will only return all of the user profiles on the computer

        .EXAMPLE
        Remove-BrowserSettings -ListUsers
        This will list all of the user profiles that are on the local computer

        Remove-BrowserSettings -ComputerName "Win11" -ListUsers
        This will list all fo the user profiles that are on the remote computer named "Win11"

        Remove-BrowserSettings -ComputerName "Win11" -UserName "Robin" -Edge
        This will delete Edge settings for the user Robin on remote computer "Win11", if you want to delete Chrome settings just
        replace -Edge with -Chrome

        Remove-BrowserSettings -UserName "Robin" -Edge
        This will delete Edge settings for the user Robin on local computer, if you want to delete Chrome settings just
        replace -Edge with -Chrome

    #>

    [CmdletBinding()]
    Param(
        [string]$ComputerName,
        [string]$UserName,
        [switch]$Edge,
        [switch]$Chrome,
        [switch]$ListUsers
    )
    if ($ListUsers -eq $False) {
        if ([string]::IsNullOrEmpty($UserName)) {
            Write-Host "You must enter a username!" -ForegroundColor Red
            Break
        }
        if ($Edge -eq $False -and $Chrome -eq $False) {
            throw "You must either delete Chrome or Edge"
        }
    }

    if ($Edge -eq $True -and $Chrome -eq $True) {
        throw "You can't delete both Edge and Chrome at the same time!"
    }

    if ([string]::IsNullOrEmpty($ComputerName)) {
        [string]$ComputerName = "localhost"
    }
    if ($Edge -eq $True) {
        $Browser = "Microsoft\Edge"
        $BrowserProcess = "edge.exe"
    }
    if ($Chrome -eq $True) {
        $Browser = "Google\Chrome"
        $BrowserProcess = "chrome.exe"
    }

    $GetAllUsers = (Get-CimInstance -ComputerName $ComputerName -className Win32_UserProfile | Where-Object { (-Not ($_.Special)) } | Select-Object LocalPath | foreach-object { $_.LocalPath.split('\')[-1] })

    if ($ListUsers -eq $true) {
        Write-Host "The following user profiles exists on $($ComputerName):`n"
        $GetAllUsers
    }
    else {
        if ($UserName -in $GetAllUsers) {
            try {
                # Setting up CIMSession to kill all the chrome.exe process.
                $CimSession = New-CimSession -ComputerName $ComputerName
                Write-Host "Stopping all of the active $($BrowserProcess)..."
                $ChromeProcess = Get-CimInstance -CimSession $CimSession -Class Win32_Process -Property Name | where-object { $_.name -eq "$($BrowserProcess)" }
                if ($Null -ne $ChromeProcess) {
                    [void]($ChromeProcess | Invoke-CimMethod -MethodName Terminate)
                }
                Remove-CimSession -InstanceId $CimSession.InstanceId
                Write-Host "All $($BrowserProcess) are now stopped" -ForegroundColor Green
            }
            catch {
                Write-Host "Something went wrong when trying to stopp $($BrowserProcess)" -ForegroundColor Red
                Write-Host "$($PSItem.Exception.Message)" -ForegroundColor Red
                Break
            }
            try {
                Write-Host "Starting to delete all browser settings..."

                # Deleting Chrome/Edge folder in the user profile but before that it copy the bookmarks to C:\Temp and then back to the correct folder so the bookmarks don't get lost.
                Invoke-Command -ComputerName $ComputerName -Scriptblock {
                    Param(
                        $UserName,
                        $Browser
                    )
                    $BrowserPath = "$env:SystemDrive\Users\$($UserName)\AppData\Local\$($Browser)\User Data\"
                    $BookmarkPath = "$env:SystemDrive\Users\$($UserName)\AppData\Local\$($Browser)\User Data\Default\Bookmarks"
                    $BookmarkFolderPath = "$env:SystemDrive\Users\$($UserName)\AppData\Local\$($Browser)\User Data\Default\"

                    if (Test-Path -Path $BookmarkPath -PathType Leaf) {
                        if (Test-Path -Path "$env:SystemDrive\Temp") {
                            Copy-Item $BookmarkPath -Destination "$env:SystemDrive\Temp"
                        }
                        else {
                            New-Item -Path "$env:SystemDrive\" -Name "Temp" -ItemType "directory" > $Null
                            Copy-Item $BookmarkPath -Destination "$env:SystemDrive\Temp"
                        }
                    }

                    if (Test-Path -Path $BrowserPath) {
                        Remove-Item $BrowserPath -Recurse -Force
                    }
                    if (Test-Path -Path "$env:SystemDrive\Temp\Bookmarks"-PathType Leaf) {
                        New-Item -ItemType Directory -Force -Path $BookmarkFolderPath
                        Copy-Item "$env:SystemDrive\Temp\Bookmarks" -Destination $BookmarkFolderPath
                        Remove-Item "$env:SystemDrive\Temp\Bookmarks" -Recurse -Force
                    }
                } -ArgumentList $UserName, $Browser
            }
            catch {
                Write-Host "Something went wrong when trying to delete the browser settings" -ForegroundColor Red
                Write-Host "$($PSItem.Exception.Message)" -ForegroundColor Red
                Break
            }
        }
        else {
            Write-Warning "$($UserName) don't have a user profile on $($ComputerName), see list below for all the user profiles that exists:`n"
            $GetAllUsers
        }
    }
}