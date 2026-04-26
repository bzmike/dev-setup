function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")

    $combinedPath = @(
        $env:Path
        $machinePath
        $userPath
        "C:\Tools\sops"
    ) -join ";"

    $env:Path = ($combinedPath -split ";" | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } | Select-Object -Unique) -join ";"
}

function Get-SopsCommand {
    $preferredSopsPath = "C:\Tools\sops\sops.exe"

    if (Test-Path $preferredSopsPath) {
        return $preferredSopsPath
    }

    $command = Get-Command sops -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }

    return $null
}

function Get-AgeCommand {
    $preferredAgePath = "C:\Tools\age\age.exe"

    if (Test-Path $preferredAgePath) {
        return $preferredAgePath
    }

    $command = Get-Command age -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }

    return $null
}

function Get-SopsVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string] $SopsPath
    )

    $versionOutput = & $SopsPath --version 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Could not determine SOPS version from: $SopsPath. Output: $($versionOutput -join ' ')"
    }

    $versionText = ($versionOutput | Out-String).Trim()

    $match = [regex]::Match($versionText, 'sops\s+([0-9]+\.[0-9]+\.[0-9]+)')

    if (-not $match.Success) {
        throw "Could not parse SOPS version output from '$SopsPath'. Output: $versionText"
    }

    return [version] $match.Groups[1].Value
}

function Ensure-SopsAge {
    Update-ProcessPath

    $script:SopsCommand = Get-SopsCommand
    $script:AgeCommand = Get-AgeCommand

    if (-not $script:SopsCommand) {
        throw "sops is missing. Install it manually to C:\Tools\sops\sops.exe."
    }

    if (-not $script:AgeCommand) {
        throw "age is missing. Install it with Winget or place it at C:\Tools\age\age.exe."
    }

    $sopsVersion = Get-SopsVersion -SopsPath $script:SopsCommand
    $minimumSopsVersion = [version]"3.12.0"

    if ($sopsVersion -lt $minimumSopsVersion) {
        throw "SOPS version $sopsVersion is too old. Required: $minimumSopsVersion or newer. Current path: $script:SopsCommand"
    }

    Write-Log "sops found: $script:SopsCommand" "SUCCESS"
    Write-Log "sops version: $sopsVersion" "SUCCESS"
    Write-Log "age found: $script:AgeCommand" "SUCCESS"
}

function Confirm-AgeKeyFileReady {
    param(
        [Parameter(Mandatory = $true)]
        [string] $AgeKeyFile
    )

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "SOPS + age key required"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "Before continuing, make sure your age private key exists here:"
    Write-Host ""
    Write-Host "  $AgeKeyFile"
    Write-Host ""
    Write-Host "If this file does not exist yet:"
    Write-Host ""
    Write-Host "  1. Open your password manager."
    Write-Host "  2. Copy the saved dev-setup SOPS age key."
    Write-Host "  3. Paste it into this file:"
    Write-Host ""
    Write-Host "     $AgeKeyFile"
    Write-Host ""
    Write-Host "You can create/open the file with:"
    Write-Host ""
    Write-Host "  New-Item -ItemType Directory -Force `"$env:APPDATA\sops\age`""
    Write-Host "  notepad `"$AgeKeyFile`""
    Write-Host ""
    Write-Host "The file should contain something like:"
    Write-Host ""
    Write-Host "  # public key: age1..."
    Write-Host "  AGE-SECRET-KEY-1..."
    Write-Host ""
    Write-Host "Do not commit this file."
    Write-Host ""

    Read-Host "Press Enter after the age key file is ready"

    if (-not (Test-Path $AgeKeyFile)) {
        throw "Missing age private key: $AgeKeyFile"
    }

    Write-Log "Age key file found: $AgeKeyFile" "SUCCESS"
}

function Read-EnvFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    $values = @{}

    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()

        if ([string]::IsNullOrWhiteSpace($line)) {
            return
        }

        if ($line.StartsWith("#")) {
            return
        }

        $parts = $line -split "=", 2

        if ($parts.Count -ne 2) {
            return
        }

        $key = $parts[0].Trim()
        $value = $parts[1].Trim()

        if ($key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
            Write-Log "Skipping invalid env key from ${Path}: $key" "WARN"
            return
        }

        # Remove optional wrapping quotes
        $value = $value.Trim('"').Trim("'")

        $values[$key] = $value
    }

    return $values
}

function Render-Template {
    param(
        [Parameter(Mandatory = $true)]
        [string] $TemplatePath,

        [Parameter(Mandatory = $true)]
        [string] $OutputPath,

        [Parameter(Mandatory = $true)]
        [hashtable] $Values
    )

    if (-not (Test-Path $TemplatePath)) {
        throw "Template file does not exist: $TemplatePath"
    }

    $content = Get-Content $TemplatePath -Raw

    foreach ($key in $Values.Keys) {
        $placeholder = '${' + $key + '}'
        $content = $content.Replace($placeholder, $Values[$key])
    }

    $outputDirectory = Split-Path -Parent $OutputPath

    if (-not (Test-Path $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    Set-Content -Path $OutputPath -Value $content -NoNewline

    Write-Log "Rendered template: $TemplatePath -> $OutputPath" "SUCCESS"
}

function Get-RelativePathFromRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [string] $FullPath
    )

    $root = (Resolve-Path $RootPath).Path.TrimEnd('\', '/')
    $full = (Resolve-Path $FullPath).Path

    if (-not $full.StartsWith($root)) {
        throw "Path '$full' is not inside root '$root'."
    }

    $relative = $full.Substring($root.Length).TrimStart('\', '/')

    return $relative.Replace('\', '/')
}

function Decrypt-EnvFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $EncryptedFile,

        [Parameter(Mandatory = $true)]
        [string] $DecryptedFile,

        [Parameter(Mandatory = $true)]
        [string] $DisplayName,

        [Parameter(Mandatory = $true)]
        [string] $RepoRoot
    )

    Write-Log "Decrypting $DisplayName..."

    $outputDirectory = Split-Path -Parent $DecryptedFile

    if (-not (Test-Path $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    $sopsConfig = Join-Path $RepoRoot ".sops.yaml"

    if (-not (Test-Path $sopsConfig)) {
        throw "Missing SOPS config file: $sopsConfig"
    }

    $relativeEncryptedFile = Get-RelativePathFromRoot `
        -RootPath $RepoRoot `
        -FullPath $EncryptedFile

    Write-Log "Using relative SOPS path: $relativeEncryptedFile"

    Push-Location $RepoRoot

    try {
        & $script:SopsCommand --decrypt `
        --config ".sops.yaml" `
        --input-type dotenv `
        --output-type dotenv `
        $relativeEncryptedFile | Set-Content -Path $DecryptedFile

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to decrypt $DisplayName"
        }
    }
    finally {
        Pop-Location
    }

    Write-Log "Decrypted $DisplayName -> $DecryptedFile" "SUCCESS"
}

function Prepare-EncryptedEnvFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Write-Log "Starting SOPS env preparation phase..."

    Ensure-SopsAge

    $repoRoot = Resolve-Path (Join-Path $RootPath "..")
    $envRoot = Join-Path $repoRoot "shared\env"
    $generatedRoot = Join-Path $RootPath "configs\generated"
    $ageKeyFile = Join-Path $env:APPDATA "sops\age\keys.txt"

    $gitEnv = Join-Path $envRoot "git.env.enc"
    $sshEnv = Join-Path $envRoot "ssh.env.enc"

    $decryptedGitEnv = Join-Path $generatedRoot "git.env.dec"
    $decryptedSshEnv = Join-Path $generatedRoot "ssh.env.dec"

    Confirm-AgeKeyFileReady -AgeKeyFile $ageKeyFile

    if (-not (Test-Path $gitEnv)) {
        throw "Missing encrypted env file: $gitEnv"
    }

    if (-not (Test-Path $sshEnv)) {
        throw "Missing encrypted env file: $sshEnv"
    }

    if (-not (Test-Path $generatedRoot)) {
        New-Item -ItemType Directory -Path $generatedRoot -Force | Out-Null
    }


    Decrypt-EnvFile `
       -EncryptedFile $gitEnv `
       -DecryptedFile $decryptedGitEnv `
       -DisplayName "git.env.enc" `
       -RepoRoot $repoRoot

    Decrypt-EnvFile `
       -EncryptedFile $sshEnv `
       -DecryptedFile $decryptedSshEnv `
       -DisplayName "ssh.env.enc" `
       -RepoRoot $repoRoot

    $values = @{}

    foreach ($item in (Read-EnvFile -Path $decryptedGitEnv).GetEnumerator()) {
        $values[$item.Key] = $item.Value
    }

    foreach ($item in (Read-EnvFile -Path $decryptedSshEnv).GetEnumerator()) {
        $values[$item.Key] = $item.Value
    }

    Render-Template `
        -TemplatePath (Join-Path $repoRoot "shared\git\.gitconfig-private.template") `
        -OutputPath (Join-Path $generatedRoot ".gitconfig-private") `
        -Values $values

    Render-Template `
        -TemplatePath (Join-Path $repoRoot "shared\git\.gitconfig-work.template") `
        -OutputPath (Join-Path $generatedRoot ".gitconfig-work") `
        -Values $values

    Render-Template `
        -TemplatePath (Join-Path $repoRoot "shared\ssh\config.template") `
        -OutputPath (Join-Path $generatedRoot "ssh-config") `
        -Values $values

    Write-Log "SOPS env preparation phase completed." "SUCCESS"
}