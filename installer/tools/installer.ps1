param(
    [string]$version="v23.08.02-test1",
    [string]$user,
    [string]$Url,
    [string]$installPath = "$env:LOCALAPPDATA\sensing-dev-installer",
    [string]$relativeScriptPath = "tools\Env.ps1"
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

   if ($version -match 'v(\d+\.\d+\.\d+)-\w+') {
        $versionNum = $matches[1]
        Write-Output $versionNum
   }
    #https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/v23.08.0-beta5/sensing-dev-installer-23.08.0-win64.zip
    $Url = "https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/${version}/sensing-dev-installer-${versionNum}-win64.zip"  
}

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

