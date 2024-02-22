Write-Output "####################################################"
Write-Output "# THIS SCRIPT REMOVE SDK AND ENVIRONMENT VARIABLES #"
Write-Output "####################################################"


$currentPATH = [Environment]::GetEnvironmentVariable("Path", "User")
$deleteTarget= [Environment]::GetEnvironmentVariable("SENSING_DEV_ROOT", "User")


$deleteTargetBin =  $deleteTarget+"\bin"
$pathArray = $currentPATH -split ";"

# If $env:PATH has $env:SENSING_DEV_ROOT+"\bin", remove it
if ($pathArray -contains $deleteTargetBin) {
    Write-Output "PATH has SENSING_DEV_ROOT."
    $pathArray = $pathArray | Where-Object { $_ -ne $deleteTargetBin }
    $newPath = $pathArray -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Output "Removed $deleteTargetBin from PATH."
} else {
    Write-Output "PATH does not have SENSING_DEV_ROOT. --skip"
}

$variableName="SENSING_DEV_ROOT"
if ([Environment]::GetEnvironmentVariable($variableName, "User") -ne $null) {
    echo [Environment]::GetEnvironmentVariable($variableName, "User")
    Write-Output "SENSING_DEV_ROOT will be removed."
    [Environment]::SetEnvironmentVariable($variableName, $null, "User")

    if (Test-Path -Path $deleteTarget) {
        echo "Directory $deleteTarget will be removed."
        Remove-Item $deleteTarget -r -force
    } else {
        echo "Directory $deleteTarget does not exist. --skip"
    }
} else {
    Write-Output "SENSING_DEV_ROOT is not set. --skip"
}

$variableName="PYTHONPATH"
if ([Environment]::GetEnvironmentVariable($variableName, "User") -ne $null) {
    echo [Environment]::GetEnvironmentVariable($variableName, "User")
    Write-Output "PYTHONPATH will be removed."
    [Environment]::SetEnvironmentVariable($variableName, $null, "User")
} else {
    Write-Output "PYTHONPATH is not set. --skip"
}

$variableName="GST_PLUGIN_PATH"
if ([Environment]::GetEnvironmentVariable($variableName, "User") -ne $null) {
    echo [Environment]::GetEnvironmentVariable($variableName, "User")
    Write-Output "GST_PLUGIN_PATH will be removed."
    [Environment]::SetEnvironmentVariable($variableName, $null, "User")
} else {
    Write-Output "GST_PLUGIN_PATH is not set. --skip"
}

Write-Output "####################################################"
Write-Output "# THIS SCRIPT REMOVE SDK AND ENVIRONMENT VARIABLES #"
Write-Output "####################################################"



