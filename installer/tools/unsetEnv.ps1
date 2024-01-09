<#
.SYNOPSIS
Script to remove changes made to environment variables.

.DESCRIPTION
This script removes the changes made by the "Env.ps1" script from the environment variables.

.PARAMETER installPath
Path of the installation to remove from environment variables.

.EXAMPLE
.\unsetEnv.ps1 -installPath "C:\example"
Removes changes made to the environment variables for the specified installation path.

.NOTES
File Name      : unsetEnv.ps1
Prerequisite   : PowerShell V3
#>
param(
    [string]$installPath
)

# Remove the specified installation path from the PATH environment variable
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -and $currentPath.Contains($installPath)) {
    $currentPath = $currentPath -replace [regex]::Escape("${installPath}\bin"), ""
    [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
}

# Remove the specified installation path from the PYTHONPATH environment variable
$currentPythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "User")
if ($currentPythonPath -and $currentPythonPath.Contains($installPath)) {
    $currentPythonPath = $currentPythonPath -replace [regex]::Escape("${installPath}\lib\site-packages"), ""
    [Environment]::SetEnvironmentVariable("PYTHONPATH", $currentPythonPath, "User")
}

# Remove the SENSING_DEV_ROOT environment variable
[Environment]::SetEnvironmentVariable("SENSING_DEV_ROOT", $null, "User")

# Remove the GST_PLUGIN_PATH environment variable
[Environment]::SetEnvironmentVariable("GST_PLUGIN_PATH", $null, "User")

Write-Output "Changes to environment variables have been removed."
