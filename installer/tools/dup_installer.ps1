<#
.SYNOPSIS
Installs the Sensing SDK.

.DESCRIPTION
This script downloads and installs the Sensing SDK components. You can specify a particular version or the latest version will be installed by default.

.PARAMETER Verbose
Display verbose

.PARAMETER version
Specifies the version of the Sensing SDK to be installed. Default is 'latest'.

.PARAMETER user
It used to be the flag to switch .zip version and .msi version of the package. Deprecated as of v24.05.05.

.PARAMETER installPath
The installation path for the Sensing SDK. Default is the sensing-dev-installer directory in the user's LOCALAPPDATA.

.PARAMETER InstallOpenCV
If set, the script will also install OpenCV. This is not done by default.

.EXAMPLE
PS C:\> .\installer.ps1 -version 'v24.05.06'

This example demonstrates how to run the script with custom version

.EXAMPLE
PS C:\> .\installer.ps1 -InstallOpenCV

This example demonstrates how to run the script with the default settings and includes the installation of OpenCV.

.NOTES
Ensure that you have the necessary permissions to install software and write to the specified directories.

.LINK
https://sensing-dev.github.io/doc/startup-guide/windows/index.html

#>

[cmdletbinding()]
param(
  [string]$version,
  [string]$user,
  [string]$installPath,
  [switch]$InstallOpenCV = $false,
  [switch]$debugScript = $false
)

$installerName = "sensing-dev"
$repositoryName = "Sensing-Dev/sensing-dev-installer"





function Get-LatestVersion {
  param (
  )

  $RepoApiUrl = "https://api.github.com/repos/$repositoryName/releases/latest"

  try {
    $response = Invoke-RestMethod -Uri $RepoApiUrl -Headers @{Accept = "application/vnd.github.v3+json" }
    $latestVersion = $response.tag_name

    if ($latestVersion) {
      return $latestVersion
    }
    else {
      Write-Error "Latest version not found."
      exit 1
    }
  }
  catch {
    Write-Error "Error fetching the latest version: $_"
    exit 1
  }
}





function CheckComponentHash(){
  param(
    [string]$compName,
    [string]$archivePath,
    [string]$expectedHash
  )
  if (Test-Path "$archivePath") {
    try {

        $fileStream = [System.IO.File]::OpenRead($archivePath)
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256")
        $computedHashBytes = $hashAlgorithm.ComputeHash($fileStream)
        $fileStream.Close()
        
        $computedHash = [BitConverter]::ToString($computedHashBytes) -replace "-", ""
        if ($computedHash -eq $expectedHash) {
            Write-Output "The component $compName has been downloaded successfully and the hash matches."
        } else {
            throw "The hash of the downloaded $compName does not match the expected hash."
        }
    } catch {
        throw "Failed to compute or compare the hash of the downloaded $compName."
    }
  } else {
    throw "The component $compName was not downloaded."
  }
}





# copy all <component>/bin to <tempInstallPath> bin, <component>/lib to <tempInstallPath> lib... 
function MergeComponents(){
  param(
    [string]$CompDirName,
    [string]$tempInstallPath
  )
  # copy directories such as bin, lib, include...
  Get-ChildItem $CompDirName -Directory |
  Foreach-Object {
    $dstDir = Join-Path -Path $tempInstallPath -ChildPath $_
    $srcDir = $_.FullName
    if (-not (Test-Path $dstDir)) {
      # create dst bubm lib, include...
      New-Item -ItemType Directory -Path "$dstDir" | Out-Null
    }
    try{
      Get-ChildItem $srcDir -Recurse| 
      Foreach-Object {
        Move-Item -Force -Path (Join-Path $srcDir $_) -Destination (Join-Path $dstDir $_)
      }
    } catch {
      throw "Failed to copy the content of $_"
    }
  }
  # copy other files such as VERSION
  Get-ChildItem $CompDirName -File |
  Foreach-Object{
    if (-not (Test-Path $tempInstallPath)) {
      New-Item -ItemType Directory -Path $tempInstallPath | Out-Null
    }
    try{
      Move-Item -Force -Path (Join-Path $CompDirName $_) -Destination $tempInstallPath
    } catch {
      throw "Failed to copy the content of $_"
    }
  }

  if (-not $debugScript){
    Remove-Item -Force $CompDirName -Recurse
  }
}





function Set-EnvironmentVariables {
  param(
    [string]$SensingDevRoot,
    [bool]$InstallOpenCV
  )
  begin {
    # Clear-Host
    $script:Date = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
    Write-Host "--------------------------------------" -ForegroundColor Green
    Write-Host "Set Environment variables  $script:Date" -ForegroundColor Green
  }
  process {
    # Define the paths you want to add
    $newPath = "${SensingDevRoot}\bin"
    $newPythonPath = "${SensingDevRoot}\lib\site-packages"

    Write-Verbose "SensingDevRoot : $SensingDevRoot"

    # Get current PATH and PYTHONPATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $currentPythonPath = [Environment]::GetEnvironmentVariable("PYTHONPATH", "User")

    # Update PATH if the new path is not already in it
    if (-not $currentPath.Contains($newPath)) {
        $currentPath += ";$newPath" 
        [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
        Write-Output "$newPath is added to PATH"
    }
    Write-Verbose "Updated PATH: $currentPath"

    # If OpenCV is installed under sensing-dev, add <sensing-dev>/opencv/build/x64/vc*/bin to PATH
    if ($InstallOpenCV){
        $opencvBinPath = (Get-ChildItem -Path "$SensingDevRoot/opencv/build/x64/vc*/bin" -Directory)[-1]
        if ($null -eq $opencvBinPath) {
            Write-Output "No $SensingDevRoot/opencv/build/x64/vc*/bin found under Sensing-Dev; skip adding to PATH"
        } else {
            if (-not $currentPath.Contains($opencvBinPath)) {
                $currentPath += ";$opencvBinPath"
                [Environment]::SetEnvironmentVariable("Path", $currentPath, "User")
                Write-Output "$opencvBinPath is added to PATH"
            }
            Write-Verbose "Updated PATH: $currentPath"
        }
    }

    # Update PYTHONPATH if the new path is not already in it
    if (-not $currentPythonPath -or (-not $currentPythonPath.Contains($newPythonPath))) {
        if ($currentPythonPath) {
            $currentPythonPath += ";$newPythonPath"
        } else {
            $currentPythonPath = $newPythonPath
        }
        [Environment]::SetEnvironmentVariable("PYTHONPATH", $currentPythonPath, "User")
        Write-Verbose "$newPythonPath is added to PYTHONPATH"
    }
    Write-Host "Updated PYTHONPATH: $currentPythonPath"

    # Update SENSING_DEV_ROOT if the new path is not already in it
    [Environment]::SetEnvironmentVariable("SENSING_DEV_ROOT", $SensingDevRoot, "User")
    Write-Host "Updated SENSING_DEV_ROOT: $SensingDevRoot"

    $gstLibPath = "$SensingDevRoot\lib\girepository-1.0"
    [Environment]::SetEnvironmentVariable("GST_PLUGIN_PATH", $gstLibPath, "User")
    Write-Host "Updated GST_PLUGIN_PATH: $gstLibPath"
  }
}





function Generate-VersionInfo {
  param(
    [string]$SensingDevRoot,
    [bool]$InstallOpenCV,
    $compInfo
  )
  begin {
    # Clear-Host
    $script:Date = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
    Write-Host "--------------------------------------" -ForegroundColor Green
    Write-Host " version_info.json is generated under $SensingDevRoot  $script:Date" -ForegroundColor Green
  }
  process {
    $compVersionInfo = @{}
    $keys = @("aravis", "aravis_dep", "ion_kit", "gendc_separator")
    foreach ($key in $keys) {

      $compVersionInfo.Add($compInfo.$key.name, $compInfo.$key.version)
    }

    if ($InstallOpenCV){
      $compVersionInfo.Add($compInfo.opencv.name, $compInfo.opencv.version)
    }

    $jsonContent = @{
      'Sensing-Dev' = $compInfo.sensing_dev.version
    }
    $jsonContent.Add("SDK components", $compVersionInfo)

    $jsonfile = Join-Path -Path $SensingDevRoot -ChildPath 'version_info.json'
    $jsonContent | ConvertTo-Json -Depth 5 | Set-Content $jsonfile
  }
}





function Invoke-Script {
  param(
        # exit code
        [Parameter(Mandatory = $false)]
        [int32] $ProcessExit = 0
  )

  begin {
      # Clear-Host
      $script:Date = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
      Write-Host "--------------------------------------" -ForegroundColor Green
      Write-Host " Start Installation  $script:Date" -ForegroundColor Green
  }
  process {
    ################################################################################
    # Set default installPath if not provide
    ################################################################################
    if (-not $installPath) {
      $installPath = "$env:LOCALAPPDATA"
    }
    Write-Verbose "installPath = $installPath"

    ################################################################################
    # Get Version
    ################################################################################
    if (-not $version) {
      $version = Get-LatestVersion
    }
    Write-Host "Sensing-Dev $version will be installed." 

    $baseUrl = "https://github.com/$repositoryName/releases/download/"

    ################################################################################
    # Get Working Directory
    ################################################################################
    $tempWorkDir = Join-Path -Path $env:TEMP -ChildPath $installerName
    if (-not (Test-Path $tempWorkDir)) {
        New-Item -ItemType Directory -Path $tempWorkDir | Out-Null
    }
    Write-Verbose "Working Directory = $tempWorkDir"

    $tempExtractionPath = "$tempWorkDir\_tempExtraction"
    if (Test-Path $tempExtractionPath) {
      Remove-Item -Path $tempExtractionPath -Force -Recurse
    }
    New-Item -ItemType Directory -Path $tempExtractionPath | Out-Null

    $tempInstallPath = "$tempWorkDir\sensing-dev"
    if (Test-Path $tempInstallPath) {
      Remove-Item -Path $tempInstallPath -Force -Recurse
    }
    New-Item -ItemType Directory -Path $tempInstallPath | Out-Null

    ################################################################################
    # Get Uninstaller
    ################################################################################
    $uninstallerFileName = "uninstaller.ps1"
    $uninstallerURL = "${baseUrl}${version}/$uninstallerFileName"
    $uninstallerPath = "$tempWorkDir/$uninstallerFileName"
    Invoke-WebRequest -Uri $uninstallerURL -OutFile $uninstallerPath
    
    ################################################################################
    # Get Config & Check content
    ################################################################################
    $configFileName = "config_Windows.json"
    $configURL = "${baseUrl}${version}/$configFileName"
    $configPath = "$tempWorkDir/$configFileName"
    Invoke-WebRequest -Uri $configURL -OutFile $configPath

    if (Test-Path $configPath) {
      try {
        $content = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        Write-Verbose "The config file $configFileName has been downloaded and is a valid JSON."
      } catch {
        throw  "The confg file $configFileName is not a valid JSON."
      }
    } else {
      throw  "The config file $configFileName was not downloaded."
    }

    ################################################################################
    # Dlownload each component to $tempWorkDir & extract to $tempExtractionPath
    ################################################################################ 
    $keys = @("aravis", "aravis_dep", "ion_kit", "gendc_separator")

    foreach ($key in $keys) {
      if ($content.PSObject.Properties.Name -contains $key) {

        $compVersion = $content.$key.version
        $compName = $content.$key.name
        $archiveName = "$tempWorkDir/$compName.zip"
        $compHash = $content.$key.pkg_sha
        $compoURL = $content.$key.pkg_url

        Write-Host "$compName $compVersion will be installed"
        Invoke-WebRequest -Uri $compoURL -OutFile $archiveName
    
        CheckComponentHash -compName $compName -archivePath $archiveName -expectedHash $compHash
        Expand-Archive -Path $archiveName -DestinationPath $tempExtractionPath 

      } else {
        throw "Component $key does not exist in $configFileName"
      }

      if (-not $debugScript){
        Remove-Item -Force $archiveName
      }
    }


    Get-ChildItem $tempExtractionPath -Directory |
    Foreach-Object {
      $CompDirName = $_.FullName

      if ($_.Name -eq "gendc_separator"){
        # GenDC Separator is a header library.
        # Move all contents under gendc_separator to under $tempInstallPath/include/gendc_separator 
        MergeComponents -CompDirName $CompDirName -tempInstallPath "$tempInstallPath/include/gendc_separator"
      }else{
        # Move all contents under $CompDirName to under $tempInstallPath
        MergeComponents -CompDirName $CompDirName -tempInstallPath $tempInstallPath
      }  
      
    }

    ################################################################################
    # Dlownload OpenCV to $tempWorkDir & extract to $tempExtractionPath
    ################################################################################
    if ($InstallOpenCV){
      $key = "opencv"
      $compVersion = $content.$key.version
      $compName = $content.$key.name
      $archiveName = "$tempWorkDir/$compName.exe"
      $compHash = $content.$key.pkg_sha
      $compoURL = $content.$key.pkg_url

      Write-Host "$compName $compVersion will be installed"
      Invoke-WebRequest -Uri $compoURL -OutFile $archiveName
  
      CheckComponentHash -compName $compName -archivePath $archiveName -expectedHash $compHash
      Start-Process -FilePath $archiveName -ArgumentList "-o`"$tempExtractionPath`" -y" -Wait
      if (-not $debugScript){
        Remove-Item -Force $archiveName
      }

      Move-Item -Force -Path "$tempExtractionPath/opencv" -Destination $tempInstallPath
    } 
    
    ################################################################################
    # Uninstall old Sensing-Dev Move $tempInstallPath to $installPath
    ################################################################################
    $SeinsingDevRoot = Join-Path -Path $installPath -ChildPath $installerName

    Write-Host "--------------------------------------" -ForegroundColor Green
    Write-Host "Uninstall old sensing-dev if any" -ForegroundColor Green
    & $uninstallerPath
    Move-Item -Force -Path $tempInstallPath -Destination $installPath
    Move-Item -Force -Path $uninstallerPath -Destination $SeinsingDevRoot
    Write-Host "--------------------------------------" -ForegroundColor Green

    ################################################################################
    # Set Environment variables
    ################################################################################
    Set-EnvironmentVariables -SensingDevRoot $SeinsingDevRoot -InstallOpenCV $InstallOpenCV

    ################################################################################
    # Generate version info json
    ################################################################################
    Generate-VersionInfo -SensingDevRoot $SeinsingDevRoot -InstallOpenCV $InstallOpenCV -compInfo $content
  }
}

#--------------------------------------------------------------

Invoke-Script



