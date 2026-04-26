Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptRoot = $PSScriptRoot
$ScriptsRoot = Join-Path $ScriptRoot "scripts"

# Don't change the order of the scripts
. (Join-Path $ScriptsRoot "common.ps1")
. (Join-Path $ScriptsRoot "wsl.ps1")
. (Join-Path $ScriptsRoot "dependencies.ps1")
. (Join-Path $ScriptsRoot "winget-packages.ps1")
. (Join-Path $ScriptsRoot "secrets.ps1")
. (Join-Path $ScriptsRoot "configs.ps1")

Initialize-Logging -RootPath $ScriptRoot

$exitCode = 0

try {
    Write-Log "Starting Windows dev setup..."

    Invoke-WslSetupPrompt -RootPath $ScriptRoot

    Install-Dependencies -RootPath $ScriptRoot

    Install-WingetPackages -RootPath $ScriptRoot

    Prepare-EncryptedEnvFiles -RootPath $ScriptRoot

    Copy-ConfigFiles -RootPath $ScriptRoot

    Write-Log "Windows dev setup completed." "SUCCESS"
    Write-Log "Log file: $script:LogFile"

    Write-Log "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" "WARN"
    Write-Log "IMPORTANT: YOU MUST NOW EDIT $HOME\.gitconfig-work." "WARN"
    Write-Log "YOU MUST ENTER YOUR WORK EMAIL ADDRESS IN THAT FILE." "WARN"
    Write-Log "YOU MUST ENTER THE CORRECT GPG SIGNING KEY IN THAT FILE." "WARN"
    Write-Log "IMPORTANT: YOU MUST NOW EDIT $HOME\.gitconfig-private." "WARN"
    Write-Log "YOU MUST ENTER YOUR PRIVATE EMAIL ADDRESS IN THAT FILE." "WARN"
    Write-Log "YOU MUST ENTER THE CORRECT GPG SIGNING KEY IN THAT FILE." "WARN"
    Write-Log "YOU MUST CHANGE THE SSH CONFIG FILE.." "WARN"
    Write-Log "WITHOUT THIS CHANGES, YOUR GIT CONFIGURATION WILL BE WRONG." "WARN"
    Write-Log "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" "WARN"
}
catch {
    Write-Log "Setup failed: $($_.Exception.Message)" "ERROR"
    Write-Log "Log file: $script:LogFile"
    $exitCode = 1
}
finally {
    exit $exitCode
}