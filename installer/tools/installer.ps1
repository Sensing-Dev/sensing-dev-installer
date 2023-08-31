param(
    [string]$version="v23.08.02-test1",
    [string]$msiUrl,
    [string]$installPath = "$env:LOCALAPPDATA\sensing-dev-installer",
    [string]$relativeScriptPath = "tools\Env.ps1"
)
# Check if the MSI URL and Install Path are provided
if ( -not $installPath) {
    Write-Error "Please provide installation path!"
    exit
}
Write-Output "installPath = $installPath"

# Check if the MSI URL and Install Path are provided
if (-not $version -and -not $msiUrl) {
    Write-Error "Please provide both MSI URL or version!"
    exit
}
$installerName = "sensing-dev-installer"

if (-not $msiUrl ) {

   if ($version -match 'v(\d+\.\d+\.\d+)-\w+') {
        $versionNum = $matches[1]
        Write-Output $versionNum
   }
    #https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/v23.08.0-beta2/sensing-dev-installer-23.08.0-win64.msi
    $msiUrl = "https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/${version}/sensing-dev-installer-${versionNum}-win64.msi"
}
# Download MSI to a temp location
$tempMsiPath = "$env:TEMP\$installerName.msi"
# Invoke-WebRequest -Uri $msiUrl -OutFile $tempMsiPath -Verbose

# Install MSI to the specified path
# Note: This assumes the MSI accepts TARGETDIR as an argument for the installation directory. Some MSIs might not.
Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$tempMsiPath`" TARGETDIR=`"$installPath`" INSTALL_ROOT=`"$installerName`" /qb /l*v $tempMsiPath\${installerName}_install.log" -Verb RunAs
# Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i `"$tempMsiPath`" TARGETDIR=`"$installPath`" /qb /l*v install.log" -Verb RunAs

# Check if the process started and finished successfully
if ($?) {
    Write-Host "The process msiexec.exe ran successfully."
} else {
    Write-Host "The process encountered an error."
}

# Run the .ps1 file from the installed package
$ps1ScriptPath = Join-Path -Path $installPath -ChildPath $relativeScriptPath
Write-Output "ps1ScriptPath = $ps1ScriptPath"
if (Test-Path -Path $ps1ScriptPath -PathType Leaf) {
    & $ps1ScriptPath
} else {
    Write-Error "Script at $relativeScriptPath not found in the installation path!"
}

# Cleanup
# Remove-Item -Path $tempMsiPath -Force
