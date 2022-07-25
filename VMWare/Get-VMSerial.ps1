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

function Get-VMSerial {
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][string]$VIServer
    )
    try {
        Connect-VIServer -Server $VIServer
    }
    catch {
        throw "$($PSItem.Exception)"
    }

    # Insert loop
    foreach ($VM in $VMName.Split(",").Trim()) {
        $s = ((Get-VM -Name $VM).ExtensionData.Config.Uuid).Replace("-", "")
        $Uuid = "VMware-"
        for ($i = 0; $i -lt $s.Length; $i += 2) {
            $Uuid += ("{0:x2}" -f [byte]("0x" + $s.Substring($i, 2)))
            if ($Uuid.Length -eq 30) { $Uuid += "-" } else { $Uuid += " " }
        }

        $VM
        $Uuid.TrimEnd()
    }
    
    try {
        Disconnect-VIServer -Server $VIServer -Force -Confirm:$false
    }
    catch {
        Write-Error "$($PSItem.Exception)"
    }
}