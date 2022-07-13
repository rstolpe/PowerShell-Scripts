# PowerShell-Scripts
In this repo I'll publish some random PowerShell Scripts, function, modules that I have done.

## Find-NeededModules
Add the modules that you want to include in the $NeededModules array.  
This function are then doing the following.  
- Checks if the module are installed, if it's not then it get installed
- If the module are installed it will check if it's the latest version if not then it will update the module.
- If the module are updated the script will uninstall the old version of the module
- Then it will import all of the modules.