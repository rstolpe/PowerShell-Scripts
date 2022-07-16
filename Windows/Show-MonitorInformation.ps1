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

Function Show-MonitorInformation {
    <#
        .SYNOPSIS
        Returns information about all the monitors that has been connected to the computer
        .DESCRIPTION
        With this script you can get information about all of the monitors that has been connected to a local or remote computer
        .PARAMETER Computer
        If you want to run this against a remote computer you specify which computer with this parameter.
        .EXAMPLE
        Show-MonitorInformation
        Returns the information about the monitors on the local computer

        Show-MonitorInformation -ComputerName "Win11"
        Return information about the monitor on a remote computer named "Win11"

        Show-MonitorInformation -ComputerName "Win10,Win11"
        Return information about the monitor from both remote computer named Win10 and Win11

    #>

    [CmdletBinding()]
    Param(
        [String]$ComputerName = "localhost"
    )

    foreach ($Computer in $ComputerName.Split(",").Trim()) {
        try {
            Write-Host "`n== Monitor information from $($Computer) ==`n"
            Get-CimInstance -ComputerName $Computer -ClassName WmiMonitorID -Namespace root\wmi | Foreach-Object {
                [PSCustomObject]@{
                    Active                = $_.Active
                    'Manufacturer Name'   = ($_.Manufacturername | ForEach-Object { [char]$_ }) -join ""
                    'Model'               = ($_.UserFriendlyName | ForEach-Object { [char]$_ }) -join ""
                    'Serial Number'       = ($_.SerialNumberID | ForEach-Object { [char]$_ }) -join ""
                    'Year Of Manufacture' = $_.YearOfManufacture
                    'Week Of Manufacture' = $_.WeekOfManufacture
                }
            }
        }
        catch {
            Write-Error "$($PSItem.Exception)"
            Break
        }
    }
}