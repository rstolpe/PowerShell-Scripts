I’m writing some useful PowerShell Scripts from time to time and I’m collecting them in my [repo](https://github.com/rstolpe/PowerShell-Scripts) and also posting them at my [blog](https://stolpe.io).  
I also use to post videos of the script running at my [YouTube Channel](https://www.youtube.com/channel/UClrIQN9SysVTEMPmxxn-p1w) and I have a dedicated [playlist](https://www.youtube.com/playlist?list=PLOdABThmxohswmbXjPadlpqdNiQxj9ZoP) for this [repo](https://github.com/rstolpe/PowerShell-Scripts).

## Windows-Maintenance
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

## Find-NeededModules
Add the modules that you want to include in the $NeededModules array.  
This function are then doing the following.  
- Checks so TLS 1.2 are used by PowerShell
- Making sure that NuGet and PowerShellGet are installed as provider
- Making sure that PSGallery are set as trusted
- Checks if the module are installed, if it's not then it get installed
- If the module are installed it will check if it's the latest version if not then it will update the module.
- If the module are updated the script will uninstall the old version of the module
- Then it will import all of the modules.

## AD-Tool
This script contains the following functions:
### Check status of users account
This function are checking the following things on a user and showing the results
- Is the account enabled?
- Is the account locked?
- Has the account expired?
- Has the password expired?
- When did the user last connect to the domain?

### Unlock user
Checking it the user/users are locked and it the user/users are locked the script will unlock the user/users

### Enable user or users
Checking if the user/users are disabled if the user/users are disabled the script will enable the user/users