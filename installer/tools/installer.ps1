<#
.SYNOPSIS
Script for downloading and installing Sensing SDK-installer

.DESCRIPTION
Downloads and install zip or msi of given version or latest version

.PARAMETER version
Specifies the version. The default is 'latest'.

.PARAMETER user
Specifies the user name. Use this to install installer at users's LOCALAPPDATA

.PARAMETER Url
Installer URL to be used by the script or function.

.PARAMETER installPath
Specifies the installation path. The default is the sensing-dev-installer directory in the user's LOCALAPPDATA.

.EXAMPLE
PS C:\> .\installer.ps1 -version 'v24.09.03' -user 'Admin' -Url 'http://example.com'

This example demonstrates how to run the script with custom version, user, and Url values.

.NOTES
Any additional notes related to the script or function.

.LINK
http://example.com/documentation-link
#>

param(
    [string]$version,
    [string]$user,
    [string]$Url,
    [string]$installPath = "$env:LOCALAPPDATA\sensing-dev-installer"
)
# Check if the MSI URL and Install Path are provided
if ( -not $installPath) {

    if ($user) {
        # If a username is provided, get that user's LOCALAPPDATA path
        $UserProfilePath = "C:\Users\$user"
        $installPath = Join-Path -Path $UserProfilePath -ChildPath "AppData\Local"
    } else {
        # If no username is provided, use the LOCALAPPDATA of the currently logged in user
        $installPath = "$env:LOCALAPPDATA"
    }   
   
}
if ( -not $installPath) {
    Write-Error "Please provide installation path!"
    exit
}
Write-Verbose "installPath = $installPath"

$installerName = "sensing-dev-installer"

$installPath = "$installPath\$installerName"

if (-not $Url ) {
    if (-not $version ) {
        $repoUrl = "https://api.github.com/repos/Sensing-Dev/sensing-dev-installer/releases/latest"
        $response = Invoke-RestMethod -Uri $repoUrl
        $version = $response.tag_name
        $version
    }
   if ($version -match 'v(\d+\.\d+\.\d+)-\w+') {
        $versionNum = $matches[1]
        Write-Output $versionNum
   }
    $zipUrl = "https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/${version}/sensing-dev-installer-${versionNum}-win64.zip"
    $msiUrl = "https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/${version}/sensing-dev-installer-${versionNum}-win64.msi"

    if ($user) {
        # If a username is provided, get that user's LOCALAPPDATA path
        $Url = "$zipUrl"
    } else {
        # If no username is provided, use the LOCALAPPDATA of the currently logged in user
        $Url = "$msiUrl"
    }   
  
}

if ($Url.EndsWith("zip")) {
    # Download ZIP to a temp location
    $tempZipPath = "$env:TEMP\$installerName.zip"

    Invoke-WebRequest -Uri $Url -OutFile $tempZipPath -Verbose
    # Unzip the file
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZipPath, $installPath)

    # Optionally delete the ZIP file after extraction
    Remove-Item -Path $TargetFile -Force

    # Check if the process started and finished successfully
    if ($?) {
        Write-Host "The process ExtractToDirectory ran successfully."
    } else {
        Write-Host "The process encountered an error."
    }
}

if ($Url.EndsWith("msi")) {
    # Download MSI to a temp location
    $tempMsiPath = "$env:TEMP\$installerName.msi"
    Invoke-WebRequest -Uri $Url -OutFile $tempMsiPath -Verbose

    Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$tempMsiPath`" TARGETDIR=`"$installPath`" INSTALL_ROOT=`"$installerName`" /qb /l*v $tempMsiPath\${installerName}_install.log" -Verb RunAs
    # Check if the process started and finished successfully
    if ($?) {
        Write-Host "The process msiexec.exe ran successfully."
    } else {
        Write-Host "The process encountered an error."
    }
}


$relativeScriptPath = "tools\Env.ps1"
# Run the .ps1 file from the installed package
$ps1ScriptPath = Join-Path -Path $installPath -ChildPath $relativeScriptPath
Write-Verbose "ps1ScriptPath = $ps1ScriptPath"
if (Test-Path -Path $ps1ScriptPath -PathType Leaf) {
    & $ps1ScriptPath
} else {
    Write-Error "Script at $relativeScriptPath not found in the installation path!"
}

# Cleanup
if (Test-Path -Path $tempZipPath ){
    Remove-Item -Path $tempZipPath -Force
}

