# Find-NeededModules
This function are making sure that the needed modules are installed, up to date and imported.  
Add the modules that you want to include in the $NeededModules array.  
  
### This script will do the following
- Checks so TLS 1.2 are used by PowerShell
- Making sure that NuGet and PowerShellGet are installed as provider
- Making sure that PSGallery are set as trusted
- Checks if the module are installed, if it's not then it get installed
- If the module are installed it will check if it's the latest version if not then it will update the module.
- If the module are updated the script will uninstall the old version of the module
- Then it will import all of the modules.