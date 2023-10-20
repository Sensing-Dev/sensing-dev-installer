<#
.SYNOPSIS
Script for downloading and installing Sensing SDK-installer

.DESCRIPTION
Downloads and install zip or msi of the given version or the latest version

.PARAMETER version
Specifies the version. The default is 'latest'.

.PARAMETER user
Specifies the user name. Use this to install the installer at users' LOCALAPPDATA

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
    [string]$installPath 
)
# Check if the MSI URL and Install Path are provided
if ( -not $installPath) {

    if ($user) {
        # If a username is provided, get that user's LOCALAPPDATA path
        $UserProfilePath = "C:\Users\$user"
        $installPath = Join-Path -Path $UserProfilePath -ChildPath "AppData\Local"
    } else {
        # If no username is provided, use the LOCALAPPDATA of the currently logged-in user
        $installPath = "$env:LOCALAPPDATA"
    }
}
Write-Verbose "installPath = $installPath"

$installerName = "sensing-dev-installer"

if (-not $Url ) {
    if (-not $version ) {
        $repoUrl = "https://api.github.com/repos/Sensing-Dev/${installerName}/releases/latest"
        $response = Invoke-RestMethod -Uri $repoUrl
        $version = $response.tag_name
        Write-Verbose "Latest version: $version" 
    }
   if ($version -match 'v(\d+\.\d+\.\d+)(-\w+)?') {
        $versionNum = $matches[1] 
        Write-Output "Installing version: $version" 
   }

    $zipUrl = "https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/${version}/${installerName}-${versionNum}-win64.zip"
    $msiUrl = "https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/${version}/${installerName}-${versionNum}-win64.msi"

    if ($user) {
        $Url = "$zipUrl"
    } else {
        $Url = "$msiUrl"
    }   
}

if ($Url.EndsWith("zip")) {
    # Download ZIP to a temp location

    $tempZipPath = "${env:TEMP}\${installerName}.zip"
    Invoke-WebRequest -Uri $Url -OutFile $tempZipPath -Verbose

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $tempExtractionPath = "$installPath\_tempExtraction"
    # Create the temporary extraction directory if it doesn't exist
    if (-not (Test-Path $tempExtractionPath)) {
        New-Item -Path $tempExtractionPath -ItemType Directory
    }
    # Attempt to extract to the temporary extraction directory
    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZipPath, $tempExtractionPath)
        Get-ChildItem -Path $tempExtractionPath
        # If extraction is successful, replace the old contents with the new
        $installPath = "$installPath\$installerName"
        if (Test-Path -Path ${installPath}){
            Get-ChildItem -Path $installPath -Recurse | Remove-Item -Force -Recurse
        }
        else{
            New-Item -Path $installPath -ItemType Directory
        }
        Move-Item -Path "$tempExtractionPath\${installerName}-${versionNum}-win64\*" -Destination $installPath -Force
        
        # Cleanup the temporary extraction directory
        Remove-Item -Path $tempExtractionPath -Force -Recurse
    }
    catch {
        Write-Error "Extraction failed. Original contents remain unchanged."
        # Optional: Cleanup the temporary extraction directory
        Remove-Item -Path $tempExtractionPath -Force -Recurse
    }    
     # Optionally delete the ZIP file after extraction
     Remove-Item -Path $tempZipPath -Force
}
elseif ($Url.EndsWith("msi")) {
    $installPath = "$installPath\$installerName"

    # Download MSI to a temp location
    $tempMsiPath = "${env:TEMP}\${installerName}.msi"
    Invoke-WebRequest -Uri $Url -OutFile $tempMsiPath -Verbose

    $log="${env:TEMP}\${installerName}__install.log"
    Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i ${tempMsiPath} INSTALL_ROOT=${installPath} /qb /l*v ${log}" -Verb RunAs

    # Check if the process started and finished successfully
    if ($?) {
        Write-Host "${installerName} installed at ${installPath}. See detailed log here ${log} "
    } else {
        Write-Error "The ${installerName} installation encountered an error. See detailed log here ${log}"        
    }
      # Optionally delete the MSI file after extraction
      Remove-Item -Path $tempMsiPath -Force
}
else {
    Write-Error "Invalid Url"
}

if (Test-Path -Path ${installPath})
{
    $relativeScriptPath = "tools\Env.ps1"
    # Run the .ps1 file from the installed package
    $ps1ScriptPath = Join-Path -Path $installPath -ChildPath $relativeScriptPath
    Write-Verbose "ps1ScriptPath = $ps1ScriptPath"
    if (Test-Path -Path $ps1ScriptPath -PathType Leaf) {
        & $ps1ScriptPath
    } else {
        Write-Error "Script at $relativeScriptPath not found in the installation path!"
    }
}


