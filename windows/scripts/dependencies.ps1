function Test-WingetPackageInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PackageId
    )

    & winget list --id $PackageId --exact --accept-source-agreements | Out-Null
    return $LASTEXITCODE -eq 0
}

function Install-Or-UpgradeWingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PackageId,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if (Test-WingetPackageInstalled -PackageId $PackageId) {
        Write-Log "$Name is already installed. Trying to upgrade..."

        & winget upgrade `
            --id $PackageId `
            --exact `
            --silent `
            --accept-package-agreements `
            --accept-source-agreements

        $upgradeExitCode = $LASTEXITCODE

        if ($upgradeExitCode -eq 0) {
            Write-Log "$Name upgraded or already up to date." "SUCCESS"
            return
        }

        if (Test-WingetPackageInstalled -PackageId $PackageId) {
            Write-Log "$Name is installed, but upgrade returned exit code $upgradeExitCode. Continuing." "WARN"
            return
        }

        throw "Upgrade failed for $Name."
    }

    Write-Log "$Name is not installed. Installing..."

    Invoke-ExternalCommand -Executable "winget" -Arguments @(
        "install",
        "--id", $PackageId,
        "--exact",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    Write-Log "$Name installed successfully." "SUCCESS"
}

function Install-Dependencies {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Write-Log "Starting dependencies phase..."

    $dependenciesFile = Join-Path $RootPath "dependencies.json"

    if (-not (Test-Path $dependenciesFile)) {
        Write-Log "No dependencies.json found. Skipping dependencies phase." "WARN"
        return
    }

    $dependencies = Read-JsonFile -Path $dependenciesFile

    if ($dependencies.PSObject.Properties.Name -contains "commands") {
        foreach ($commandDefinition in $dependencies.commands) {
            if ($commandDefinition.required -eq $false) {
                continue
            }

            $name = $commandDefinition.name
            $command = $commandDefinition.command

            Write-Log "Checking required command: $name"

            if (-not (Test-CommandExists -Command $command)) {
                throw "Required command '$command' is missing. Please install '$name' first."
            }

            Write-Log "Required command found: $name" "SUCCESS"
        }
    }

    if ($dependencies.PSObject.Properties.Name -contains "packages") {
        foreach ($package in $dependencies.packages) {
            if ($package.enabled -eq $false) {
                Write-Log "Skipping disabled dependency package: $($package.name)"
                continue
            }

            Install-Or-UpgradeWingetPackage -PackageId $package.winget_id -Name $package.name
        }
    }

    Write-Log "Dependencies phase completed." "SUCCESS"
}