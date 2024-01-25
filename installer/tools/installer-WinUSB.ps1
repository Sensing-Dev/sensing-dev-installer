
<#
.SYNOPSIS
    Install USB device driver using WinUSB and run a driver installer.

.DESCRIPTION
    This PowerShell script downloads and installs a USB device driver using WinUSB and then runs a driver installer. It also deletes temporary files after the installation.

.NOTES
    File Name      : installer-WinUSB.ps1 
    Prerequisite   : PowerShell 5.0 or later

.EXAMPLE
    .\installer-WinUSB.ps1 

    This example downloads and runs the script to install a USB device driver .

#>
$installPath = "$env:TEMP"
Write-Verbose "installPath = $installPath"
# Download win_usb installer

$installerName = "WinUSB-installer-generator"


$repoUrl = "https://api.github.com/repos/Sensing-Dev/$installerName/releases/latest"
# $repoUrl = "https://api.github.com/repos/Sensing-Dev/WinUSB-installer-generator/releases/latest"
$response = Invoke-RestMethod -Uri $repoUrl
$version = $response.tag_name
$version
Write-Verbose "Latest version: $version" 

if ($version -match 'v(\d+\.\d+\.\d+)(-\w+)?') {
    $versionNum = $matches[1] 
    Write-Output "Installing version: $version" 
}

$Url = "https://github.com/Sensing-Dev/$installerName/releases/download/${version}/${installerName}-${versionNum}.zip"

$Url

if ($Url.EndsWith("zip")) {
    # Download ZIP to a temp location

    $tempZipPath = "${env:TEMP}\${installerName}.zip"
    Invoke-WebRequest -Uri $Url -OutFile $tempZipPath -Verbose

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $tempExtractionPath = "$installPath\_tempWinUSBExtraction"
    # Create the temporary extraction directory if it doesn't exist
    if (Test-Path $tempExtractionPath) {
       Remove-Item -Path $tempExtractionPath -Force -Recurse -Confirm:$false
    }
    New-Item -Path $tempExtractionPath -ItemType Directory

    # Attempt to extract to the temporary extraction directory
    try {
        Expand-Archive -Path $tempZipPath -DestinationPath $tempExtractionPath 
        Get-ChildItem $tempExtractionPath
    }
    catch {
        Write-Error "Extraction failed...."
    }    
     Remove-Item -Path $tempZipPath -Force
}

if (Test-Path $tempExtractionPath) {    

    # Run Winusb installer
    Write-Host "This may take a few minutes. Starting the installation..."

    Write-Verbose "Start winUsb installer"
    $TempDir = "$tempExtractionPath/temp"
        
    New-item -Path "$TempDir" -ItemType Directory
    $winUSBOptions = @{
        FilePath               = "${tempExtractionPath}/${installerName}-${versionNum}/winusb_installer.exe"
        ArgumentList           = "054c"
        WorkingDirectory       = "$TempDir"
        Wait                   = $true
        Verb                   = "RunAs"  # This attempts to run the process as an administrator
    }
    # Start winusb_installer.exe process 
    Start-Process @winUSBOptions 

    Write-Verbose "End winUsb installer"
}

# Run Driver installer
Write-Verbose "Start Driver installer"

$infPath = "$TempDir/target_device.inf"
if (-not (Test-Path -Path $infPath -PathType Leaf) ){
    Write-Error "$infPath does not exist."
}
else{
    $pnputilOptions = @{
        FilePath = "PNPUtil"
        ArgumentList           = "-i -a ./target_device.inf"
        WorkingDirectory       = "$TempDir"
        Wait                   = $true
        Verb                   = "RunAs"  # This attempts to run the process as an administrator
    }
    try {
        # Start Pnputil process 
        Start-Process @pnputilOptions 
        Write-Host "Sucessfully installed winUSB driver"
    }
    catch {
        Write-Error "An error occurred while running pnputil: $_"
    }
}

# delete temp files

Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Remove-Item -Path '$tempExtractionPath' -Recurse -Force -Confirm:`$false`""

Write-Verbose "End Driver installer"
