# Confirm-NeededModules
This function are making sure that the needed modules are installed, up to date and imported.  
I have made it dynamic so you can use switches to activate some of the features, like: -ImportModule, -OnlyUpgrade, -DeleteOldVersion. You can read more in the [blog post](](https://stolpe.io/function-to-check-if-needed-modules-are-installed/)) or in the [script file](https://github.com/rstolpe/PowerShell-Scripts/blob/main/Windows/Confirm-NeededModules.ps1).

### This script will do the following
- Checks so TLS 1.2 are used by PowerShell
- Making sure that NuGet and PowerShellGet are installed as provider
- Making sure that PSGallery are set as trusted
- Checks if the module are installed, if it's not installed it will be installed.
- If the module are installed it will check if it's the latest version if not then it will update the module.
- If the module are updated the script will uninstall the old version of the module.
- Import the modules at the end

### Links
- [Readme](https://github.com/rstolpe/PowerShell-Scripts/blob/main/Windows/Confirm-NeededModules.md)  
- [Script file](https://github.com/rstolpe/PowerShell-Scripts/blob/main/Windows/Confirm-NeededModules.ps1)
- [Blog post](https://stolpe.io/function-to-check-if-needed-modules-are-installed/)
- [YouTube video of the script](https://youtu.be/__xMLPhmm4Y)
- [Report bug, issue, improvement request or request new script](https://github.com/rstolpe/PowerShell-Scripts/issues/new/choose)
- [Main repo](https://github.com/rstolpe/PowerShell-Scripts)