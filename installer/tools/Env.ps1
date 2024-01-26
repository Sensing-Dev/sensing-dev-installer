<#
.SYNOPSIS
Script to update enviroment for sensing dev installer usage.

.DESCRIPTION
Script to update enviroment for sensing dev installer usage.

.PARAMETER installPath
Path of installation.

.EXAMPLE
.\Env.ps1
Runs the script with the default installPath set to the parent directory.

.EXAMPLE
.\YourScript.ps1 -InputPath "C:\example"
Runs the script with the installPath set to "C:\example".

.NOTES
File Name      : Env.ps1
Prerequisite   : PowerShell V3
#>
param(
    [string]$installPath = (Split-Path $PSScriptRoot -Parent)    
)

# Define the paths you want to add
$newPath = "${installPath}\bin"

Write-Output "installPath : $installPath"

# Get current PATH 
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

# Update PATH if the new path is not already in it
if (-not $currentPath.Contains($newPath)) {
    $currentPath += ";$newPath"
    [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
}
Write-Verbose "Updated PATH: $currentPath"

# Update SENSING_DEV_ROOT if the new path is not already in it
[Environment]::SetEnvironmentVariable("SENSING_DEV_ROOT", $installPath, "User")
Write-Verbose "Updated SENSING_DEV_ROOT: $installPath"

[Environment]::SetEnvironmentVariable("GST_PLUGIN_PATH", $installPath, "User")
Write-Verbose "Updated GST_PLUGIN_PATH: $installPath"
