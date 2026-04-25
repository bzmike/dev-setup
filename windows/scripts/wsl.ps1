function Get-InstalledWslDistros {
    if (-not (Test-CommandExists -Command "wsl")) {
        return @()
    }

    $output = & wsl --list --quiet 2>$null

    if ($LASTEXITCODE -ne 0 -or $null -eq $output) {
        return @()
    }

    return @($output | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
}

function Test-WslDistroInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string] $DistroName
    )

    $installedDistros = Get-InstalledWslDistros

    return $installedDistros -contains $DistroName
}

function Show-WslOnlineDistros {
    try {
        Write-Log "Showing available online WSL distributions..."
        & wsl --list --online
    }
    catch {
        Write-Log "Could not show online WSL distributions: $($_.Exception.Message)" "ERROR"
    }
}

function Install-WslDistro {
    param(
        [Parameter(Mandatory = $true)]
        [string] $DistroName
    )

    if (-not (Test-CommandExists -Command "wsl")) {
        Write-Log "wsl.exe was not found. Cannot install WSL distribution." "ERROR"
        return
    }

    if (Test-WslDistroInstalled -DistroName $DistroName) {
        Write-Log "WSL distribution '$DistroName' is already installed. Skipping." "SUCCESS"
        return
    }

    try {
        Write-Log "Installing WSL distribution: $DistroName"

        & wsl --install --distribution $DistroName

        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            Write-Log "Failed to install WSL distribution '$DistroName'. Exit code: $exitCode" "ERROR"
            return
        }

        Write-Log "WSL distribution '$DistroName' installation started successfully." "SUCCESS"
        Write-Log "A Windows restart may be required before the distribution can be used." "WARN"
    }
    catch {
        Write-Log "Failed to install WSL distribution '$DistroName': $($_.Exception.Message)" "ERROR"
    }
}

function Invoke-WslSetupPrompt {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    $wslFile = Join-Path $RootPath "wsl.json"

    if (-not (Test-Path $wslFile)) {
        Write-Log "No wsl.json found. Skipping WSL setup." "WARN"
        return
    }

    $wslConfig = Read-JsonFile -Path $wslFile

    if ($wslConfig.enabled -eq $false) {
        Write-Log "WSL setup is disabled in wsl.json. Skipping." "WARN"
        return
    }

    Write-Host ""
    Write-Host "Do you want to install or configure WSL?"
    Write-Host "[0] No"

    $enabledDistros = @($wslConfig.distros | Where-Object { $_.enabled -ne $false })

    for ($i = 0; $i -lt $enabledDistros.Count; $i++) {
        $optionNumber = $i + 1
        Write-Host "[$optionNumber] $($enabledDistros[$i].name) ($($enabledDistros[$i].wsl_name))"
    }

    $showOnlineOption = $enabledDistros.Count + 1
    Write-Host "[$showOnlineOption] Show online distro list"
    Write-Host ""

    $selection = Read-Host "Select an option"

    if ($selection -eq "0" -or [string]::IsNullOrWhiteSpace($selection)) {
        Write-Log "WSL setup skipped by user."
        return
    }

    if ($selection -eq "$showOnlineOption") {
        Show-WslOnlineDistros
        return
    }

    $selectionNumber = 0

    if (-not [int]::TryParse($selection, [ref] $selectionNumber)) {
        Write-Log "Invalid WSL selection: $selection" "WARN"
        return
    }

    $selectedIndex = $selectionNumber - 1

    if ($selectedIndex -lt 0 -or $selectedIndex -ge $enabledDistros.Count) {
        Write-Log "Invalid WSL selection: $selection" "WARN"
        return
    }

    $selectedDistro = $enabledDistros[$selectedIndex]

    Install-WslDistro -DistroName $selectedDistro.wsl_name
}