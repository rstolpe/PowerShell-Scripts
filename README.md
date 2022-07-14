I’m writing some useful PowerShell Scripts from time to time and I’m collecting them in my [repo](https://github.com/rstolpe/PowerShell-Scripts) and also posting them at my [blog](https://stolpe.io).  
I also use to post videos of the script running at my [YouTube Channel](https://www.youtube.com/channel/UClrIQN9SysVTEMPmxxn-p1w) and I have a dedicated [playlist](https://www.youtube.com/playlist?list=PLOdABThmxohswmbXjPadlpqdNiQxj9ZoP) for this [repo](https://github.com/rstolpe/PowerShell-Scripts).  
  
This repo will get kind of big during time so I have made a link for all of the scripts below to it's own readme file.  
### Windows scripts
- [AD-Tool](https://github.com/rstolpe/PowerShell-Scripts/blob/main/Windows/AD-Tool.md)  
With this script you can troubleshoot ADUser accounts.
- [Windows-Maintenance](https://github.com/rstolpe/PowerShell-Scripts/blob/main/Windows/Windows-Maintenance.md)  
With this script it automate maintenance for Windows 10 and 11 for example running Windows Update, deleting tempfiles and folders and much more.

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