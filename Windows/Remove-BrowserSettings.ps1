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

        Remove-BrowserSettings -UserName "Robin" -Edge
        This will delete Edge settings for the user Robin on local computer, if you want to delete Chrome settings just
        replace -Edge with -Chrome

        Remove-BrowserSettings -UserName "Robin,Adam" -Edge
        This will delete Edge settings for the user Robin and Adam on the local, if you want to delete Chrome settings just
        replace -Edge with -Chrome

        Remove-BrowserSettings -ComputerName "Win11" -UserName "Robin" -Edge
        This will delete Edge settings for the user Robin on remote computer "Win11", if you want to delete Chrome settings just
        replace -Edge with -Chrome

        Remove-BrowserSettings -ComputerName "Win11" -UserName "Robin,Adam" -Edge
        This will delete Edge settings for the user Robin and Adam on the remote computer named "Win11", if you want to delete Chrome settings just
        replace -Edge with -Chrome

    #>

    [CmdletBinding()]
    Param(
        [string]$ComputerName = "localhost",
        [string]$UserName,
        [switch]$Edge,
        [switch]$Chrome,
        [switch]$ListUsers
    )
    if ($ListUsers -eq $False) {
        if ([string]::IsNullOrEmpty($UserName)) {
            Write-Output "You must enter a username!" -ForegroundColor Red
            Break
        }
        if ($Edge -eq $False -and $Chrome -eq $False) {
            throw "You must either delete Chrome or Edge"
        }
        if ($Edge -eq $True -and $Chrome -eq $True) {
            throw "You can't delete both Edge and Chrome at the same time!"
        }

        if ($Edge -eq $True) {
            $Browser = "Microsoft Edge"
            $BrowserAddPath = "Microsoft\Edge"
            $BrowserProcessName = "msedge.exe"
        }
        if ($Chrome -eq $True) {
            $Browser = "Google Chrome"
            $BrowserAddPath = "Google\Chrome"
            $BrowserProcessName = "chrome.exe"
        }
    }

    $GetAllUsers = (Get-CimInstance -ComputerName $ComputerName -className Win32_UserProfile | Where-Object { (-Not ($_.Special)) } | Select-Object LocalPath | foreach-object { $_.LocalPath.split('\')[-1] })

    if ($ListUsers -eq $true) {
        Write-Output "== The following user profiles exists on $($ComputerName) ==`n"
        $GetAllUsers
    }
    else {
        # Setting up CIMSession and killing the browser process
        try {
            Write-Output "Trying to stop all of the active $($BrowserProcessName) processes..."
            $BrowserProcess = Get-CimInstance -ComputerName $ComputerName -Class Win32_Process -Property Name | where-object { $_.name -eq "$($BrowserProcessName)" }
            if ($Null -ne $BrowserProcess) {
                [void]($BrowserProcess | Invoke-CimMethod -MethodName Terminate)
                Write-Output "All $($BrowserProcessName) processes has now been stopped!" -ForegroundColor Green
            }
            else {
                Write-Warning "Could not stop $($BrowserProcessName) processes because no process are running!"
            }
        }
        catch {
            Write-Error "$($PSItem.Exception)"
            Break
        }
        # Looping trough the UserNames to make sure it has a profile on the computer
        foreach ($User in $UserName.Split(",").Trim()) {
            if ($User -in $GetAllUsers) {
                Write-Output "`n== Starting to delete all $($Browser) settings for $($User) ==`n"
                # Deleting Chrome/Edge folder in the user profile but before that it copy the bookmarks to C:\Temp and then back to the correct folder so the bookmarks don't get lost.
                Invoke-Command -ComputerName $ComputerName -Scriptblock {
                    Param(
                        $User,
                        $Browser,
                        $BrowserAddPath
                    )
                    $BrowserPath = "$env:SystemDrive\Users\$($User)\AppData\Local\$($BrowserAddPath)\User Data\"
                    $BookmarkPath = "$env:SystemDrive\Users\$($User)\AppData\Local\$($BrowserAddPath)\User Data\Default\Bookmarks"
                    $BookmarkFolderPath = "$env:SystemDrive\Users\$($User)\AppData\Local\$($BrowserAddPath)\User Data\Default\"

                    if (-Not(Test-Path -Path $BrowserPath)) {
                        Write-Warning "Can't delete $($Browser) settings for $($user) because it's nothing there to delete!"
                        Break
                    }

                    Write-Output "Trying to backup the bookmarks for $($Browser)..."
                    try {
                        if (Test-Path -Path $BookmarkPath -PathType Leaf) {
                            if (Test-Path -Path "$env:SystemDrive\Temp") {
                                Copy-Item $BookmarkPath -Destination "$env:SystemDrive\Temp"
                            }
                            else {
                                New-Item -Path "$env:SystemDrive\" -Name "Temp" -ItemType "directory" > $Null
                                Copy-Item $BookmarkPath -Destination "$env:SystemDrive\Temp"
                            }
                            Write-Output "Bookmarks for $($Browser) has been backed up!" -ForegroundColor Green
                        }
                        else {
                            Write-Warning "Could not backup bookmarks as it did'nt exist!"
                        }
                    }
                    catch {
                        Write-Error "$($PSItem.Exception)"
                        Break
                    }
                        
                    Write-Output "Deleting all of the settings for $($Browser)..."
                    try {
                        if (Test-Path -Path $BrowserPath) {
                            Remove-Item $BrowserPath -Recurse -Force
                            Write-Output "All of the settings for $($Browser) has been deleted!" -ForegroundColor Green
                        }
                        else {
                            Write-Warning "Could not delete settings for $($Browser) as $($BrowserPath) did not exist"
                        }
                    }
                    catch {
                        Write-Error "$($PSItem.Exception)"
                        Break
                    }

                    Write-Output "Restoring the bookmark for $($Browser)..."
                    try {
                        if (Test-Path -Path "$env:SystemDrive\Temp\Bookmarks" -PathType Leaf) {
                            [void](New-Item -ItemType Directory -Force -Path $BookmarkFolderPath)
                            Copy-Item "$env:SystemDrive\Temp\Bookmarks" -Destination $BookmarkFolderPath
                            Remove-Item "$env:SystemDrive\Temp\Bookmarks" -Recurse -Force
                            Write-Output "Bookmarks for $($Browser) has been restored!" -ForegroundColor Green
                        }
                        else {
                            Write-Warning "Could not restore the bookmarks as $env:SystemDrive\Temp\Bookmarks did not exist!"
                        }
                    }
                    catch {
                        Write-Error "$($PSItem.Exception)"
                        Break
                    }
                } -ArgumentList $User, $Browser, $BrowserAddPath
                Write-Output "The script run for $($User) is complete!" -ForegroundColor Green
            }
            else {
                Write-Warning "$($User) don't have a user profile on $($ComputerName)!"
                Continue
            }
        }
    }
}