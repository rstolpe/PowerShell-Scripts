# Windows-Maintenance
This script will install all of the needed modules before it runs.  
This script does maintenance on Windows 10 and 11 machines and does the following:
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