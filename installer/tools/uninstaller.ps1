function Write-Log{
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )

    $ret = ""
    foreach ($Argument in $Arguments) {
        $ret = $ret +  $Argument +" "
    }
    Write-Output $ret 
}

function Check-EnvironmentVariableExistence{
    param(
        [string]$EnvValName
    )
    return [Environment]::GetEnvironmentVariable($EnvValName, "User") -ne $null
}

function Remove-EnvironmentVariable{
    param(
        [string]$EnvValName,
        [bool]$IsDirectoryRemoved=$false
    )
    Write-Log "Removing from User Environment variable" $EnvValName
    if (Check-EnvironmentVariableExistence -EnvValName $EnvValName){
        $ItsPath = [Environment]::GetEnvironmentVariable($EnvValName, "User")
        Write-Log $EnvValName "exists:" $ItsPath 
        Write-Log "Removed" $EnvValName "from User Environment variables."
        [Environment]::SetEnvironmentVariable($EnvValName, $null, "User")

        if ($IsDirectoryRemoved){
            Remove-Directory -TargetPath $ItsPath
        }
    } else {
        Write-Log $EnvValName " does not exist. --skipped"
    }
}

function Remove-PathFromPath{
    param(
        [string]$TargetPath
    )
    if ($TargetPath -ne $null){
        Write-Log "Removing" $TargetPath "from User Environment variable PATH"

        $currentPATH = [Environment]::GetEnvironmentVariable("Path", "User")
        $pathArray = $currentPATH -split ";"
    
        if ($pathArray -contains $TargetPath) {
            $pathArray = $pathArray | Where-Object { $_ -ne $deleteTargetBin }
            $newPath = $pathArray -join ";"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Log "Removed" $TargetPath "from User Environment variable PATH"
        } else {
            Write-Log "PATH does not have" $TargetPath ". --skip"
        }
    }
}

function Remove-Directory{
    param(
        [string]$TargetPath
    )
    Write-Log "Uninstalling" $TargetPath "from this host machine."
    if (Test-Path -Path $TargetPath) {
        Remove-Item $TargetPath -r -force
        Write-Log "Uninstalled" $TargetPath "from this host machine."
    } else {
        Write-Log $TargetPath " does not exist. --skipped"
    } 
}

Write-Log "####################################################"
Write-Log "# THIS SCRIPT REMOVE SDK AND ENVIRONMENT VARIABLES #"
Write-Log "####################################################"

$deleteSensingDev = $true

try { 
    Get-Package -Name "sensing-dev" -ErrorAction Stop

    Write-Log "Sensing-Dev is installed with msi and you can uninstall it from Control Panel."
    Write-Log "Uninstall Sensing-Dev --skip"
    $deleteSensingDev = $false
} catch {
    $deleteSensingDev = $true
}

$SENSING_DEV_BIN = [Environment]::GetEnvironmentVariable("SENSING_DEV_ROOT", "User") + "\bin"

Remove-PathFromPath -TargetPath $SENSING_DEV_BIN
Remove-EnvironmentVariable -EnvValName "SENSING_DEV_ROOT" -IsDirectoryRemoved $deleteSensingDev
Remove-EnvironmentVariable -EnvValName "PYTHONPATH"
Remove-EnvironmentVariable -EnvValName "GST_PLUGIN_PATH"







