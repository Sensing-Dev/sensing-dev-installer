<#
.SYNOPSIS
A build script for projects using the Meson build system, with optional Conan integration.

.DESCRIPTION
The script performs the following steps:
1. Checks for the existence of the source directory.
2. Clones the project from a Git repository if the source directory doesn't exist.
3. Optionally runs Conan scripts for dependencies.
4. Sets up and builds the project using Meson and Ninja.

.PARAMETER repositoryURL
URL of the Git repository to clone the project from. Defaults to 'https://gitlab.gnome.org/GNOME/pygobject.git'.

.PARAMETER version
Version tag or branch to checkout after cloning the Git repository. Defaults to '3.42.2'.

.PARAMETER sourceDir
Path to the source directory.

.PARAMETER buildDir
Path to the build directory. Defaults to '<sourceDir>\build'.

.PARAMETER installDir
Path where the project will be installed after building. Defaults to '<sourceDir>\install'.

.PARAMETER pkgConfigDir
Path to the directory for pkg-config files. Defaults to '<sourceDir>\<buildDir>\generators'.

.PARAMETER dependenciesDir
Path to the directory containing project dependencies. Defaults to '<sourceDir>\<buildDir>\dependencies'.

.PARAMETER nativeINI
Path to the native.ini file.

.EXAMPLE
.\build-Pygobject.ps1 -sourceDir "C:\path\to\source"

Builds the project located in 'C:\path\to\source' using the default parameters for other options.

.NOTES
Make sure to have Git, Meson, and Ninja installed and available in the system PATH.
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$sourceDir,

    [Parameter(Mandatory=$false)]
    [string]$repositoryURL="https://gitlab.gnome.org/GNOME/pygobject.git",

    [Parameter(Mandatory=$false)]
    [string]$version="3.42.2",

    [Parameter(Mandatory=$false)]
    [string]$nativeINI,

    [Parameter(Mandatory=$false)]
    [string]$buildDir = "$sourceDir\build",

    [Parameter(Mandatory=$false)]
    [string]$installDir = "$sourceDir\install",

    [Parameter(Mandatory=$false)]
    [string]$pkgConfigDir="$buildDir\generators",

    [Parameter(Mandatory=$false)]
    [string]$dependenciesDir ="$buildDir\dependencies"
)

# Set the build directory
$currentDir = (Get-Location).Path
Write-Output "currentDir $currentDir"
Write-Output "sourceDir $sourceDir"
Write-Output "buildDir $buildDir"
Write-Output "installDir $installDir"
Write-Output "pkgConfigDir $pkgConfigDir"
Write-Output "dependenciesDir $dependenciesDir"

# Check for Git
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Error "Git is not found. Please ensure it's installed and available in PATH."
    exit 1
}

# Check if sourceDir exists. If not, clone the repository
if (-not (Test-Path $sourceDir)) {
    git clone $repositoryURL $sourceDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone repository from $repositoryURL."
        exit 1
    }
    Set-Location $sourceDir
    git checkout $version
}
# Configure environment variables for pkg-config and dependencies if provided
if ($pkgConfigDir) {
    . $pkgConfigDir\conanbuild.ps1
    . $pkgConfigDir\conanrun.ps1
    $env:PKG_CONFIG_PATH = "$pkgConfigDir;$env:PKG_CONFIG_PATH"
}

if ($dependenciesDir) {
    $env:LD_LIBRARY_PATH = $dependenciesDir
    $env:PATH = "$env:PATH;$dependenciesDir\bin"
}
# Check if Meson and Ninja are available
if (-not (Get-Command "meson" -ErrorAction SilentlyContinue)) {
    Write-Error "Meson is not found. Please ensure it's installed and available in PATH."
    exit 1
}

if (-not (Get-Command "ninja" -ErrorAction SilentlyContinue)) {
    Write-Error "Ninja is not found. Please ensure it's installed and available in PATH."
    exit 1
}
if (-not (Test-Path $buildDir)){
    mkdir $buildDir
}
if (Test-Path $nativeINI) {
    $content = Get-Content -Path $nativeINI -Raw
    $content = $content -replace '@BUILD_ROOT@', $buildDir
    $iniFilePath="$buildDir\newNative.ini"
    Set-Content -Path $iniFilePath -Value $content

    Write-Output "meson setup $buildDir $sourceDir `
                --prefix=$installDir `
                --native-file $iniFilePath" 
    meson setup $buildDir $sourceDir `
                --prefix=$installDir `
                --native-file "$iniFilePath" 
}
else {
    # Setup build directory with Meson
    Write-Output "meson setup $buildDir $sourceDir `
                    --prefix=$installDir `
                    --buildtype release `
                    -Dpycairo=disabled `
                    -Dtests=false `
                    --pkg-config-path  $pkgConfigDir "

    meson setup $buildDir $sourceDir `
                --prefix=$installDir `
                --buildtype release `
                -Dpycairo=disabled `
                -Dtests=false `
                --pkg-config-path  "$pkgConfigDir" 
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to setup build directory with Meson."
    exit 1
}

# Change to the build directory
Set-Location $buildDir

# Compile and install the project with Ninja

meson compile -C . -v
meson install -C .

Set-Location $currentDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build  failed with Ninja."
    exit 1
}

Write-Output "Build and install completed successfully!"

