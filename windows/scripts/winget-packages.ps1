function Install-WingetPackages {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Write-Log "Starting winget packages phase..."

    $wingetPackagesFile = Join-Path $RootPath "winget-packages.json"

    if (-not (Test-Path $wingetPackagesFile)) {
        Write-Log "No winget-packages.json found. Skipping winget packages phase." "WARN"
        return
    }

    $wingetPackages = Read-JsonFile -Path $wingetPackagesFile

    foreach ($package in $wingetPackages.packages) {
        if ($package.enabled -eq $false) {
            Write-Log "Skipping disabled package: $($package.name)"
            continue
        }

        try {
            Install-Or-UpgradeWingetPackage -PackageId $package.winget_id -Name $package.name
        }
        catch {
            Write-Log "Failed to install or upgrade package '$($package.name)': $($_.Exception.Message)" "ERROR"
            continue
        }
    }

    Write-Log "Winget packages phase completed." "SUCCESS"
}