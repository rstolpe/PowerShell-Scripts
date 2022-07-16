# Windows-Maintenance
With this script it automate maintenance for Windows 10 and 11 for example running Windows Update, deleting tempfiles and folders and much more.  
### This script will do the following
- Deleting the following folders if they exists
    - C:\Windows.old
    - C:\$Windows.~BT
    - C:\$Windows.~WS
- Deleting all of the files in the following folders
    - C:\Temp
    - C:\Tmp
    - C:\Windows\Temp
    - C:\Windows\Prefetch
    - C:\Windows\SoftwareDistribution\Download
    - C:\Users\USERNAME\AppData\Local\Temp"
- Delete Orphaned MS Patches (from C:\Windows\Installer with MSIPatches modules) (Only works with PS 5.1)
- Check and updates the program that are installed with Microsoft Store (Only works with PS 5.1)
- Check and update if needed updates from Windows Update
- Update Microsoft Defender signatures from Microsoft Update Server
- Runs Microsoft Defender Quick Scan
- Runs Microsoft Windows Disk-Clean

### Links
- [Readme](https://github.com/rstolpe/PowerShell-Scripts/blob/main/Windows/Windows-Maintenance.md)  
- [Script file](https://github.com/rstolpe/PowerShell-Scripts/blob/main/Windows/Windows-Maintenance.ps1)
- [YouTube video (PS 5.1)](https://youtu.be/DtXwHhKrOnY)
- [YouTube video (PS 7.x)](https://youtu.be/Qm57XmfhTkg)
- [Blog post](https://stolpe.io/windows-maintenance-script/)
- [Report bug, issue, improvement request or request new script](https://github.com/rstolpe/PowerShell-Scripts/issues/new/choose)
- [Main repo](https://github.com/rstolpe/PowerShell-Scripts)