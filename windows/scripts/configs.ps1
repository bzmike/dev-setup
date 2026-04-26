function Resolve-UserPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ($Path.StartsWith("~")) {
        return $Path.Replace("~", $HOME)
    }

    return $Path
}

function Get-BooleanSetting {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Object,

        [Parameter(Mandatory = $true)]
        [string] $PropertyName,

        [Parameter(Mandatory = $true)]
        [bool] $DefaultValue
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName) {
        return [bool] $Object.$PropertyName
    }

    return $DefaultValue
}

function New-ConfigBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string] $TargetPath
    )

    if (-not (Test-Path $TargetPath)) {
        return $null
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $targetDirectory = Split-Path -Parent $TargetPath
    $targetFileName = Split-Path -Leaf $TargetPath

    $backupDirectory = Join-Path $targetDirectory ".backup"

    if (-not (Test-Path $backupDirectory)) {
        New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
    }

    $backupPath = Join-Path $backupDirectory "$targetFileName.$timestamp.bak"

    Copy-Item -Path $TargetPath -Destination $backupPath -Force

    return $backupPath
}

function Resolve-ConfigSourcePath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath,

        [Parameter(Mandatory = $true)]
        [string] $ConfigsRoot,

        [Parameter(Mandatory = $true)]
        [object] $File
    )

    $sourceBase = "local"

    if ($File.PSObject.Properties.Name -contains "source_base") {
        $sourceBase = $File.source_base
    }

    switch ($sourceBase) {
        "local" {
            return Join-Path $ConfigsRoot $File.source
        }

        "shared" {
            $repoRoot = Resolve-Path (Join-Path $RootPath "..")
            $sharedRoot = Join-Path $repoRoot "shared"
            return Join-Path $sharedRoot $File.source
        }

        default {
            throw "Invalid source_base '$sourceBase' for config source '$($File.source)'. Allowed values: local, shared."
        }
    }
}

function Copy-ConfigFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    Write-Log "Starting configs phase..."

    $configsFile = Join-Path $RootPath "configs.json"
    $configsRoot = Join-Path $RootPath "configs"

    if (-not (Test-Path $configsFile)) {
        Write-Log "No configs.json found. Skipping configs phase." "WARN"
        return
    }

    $configData = Read-JsonFile -Path $configsFile

    foreach ($group in $configData.config_groups) {
        if ($group.enabled -eq $false) {
            Write-Log "Skipping disabled config group: $($group.name)"
            continue
        }

        Write-Log "Processing config group: $($group.name)"

        foreach ($file in $group.files) {
            try {
                $sourcePath = Resolve-ConfigSourcePath `
                    -RootPath $RootPath `
                    -ConfigsRoot $configsRoot `
                    -File $file

                $targetPath = Resolve-UserPath -Path $file.target
                $targetDirectory = Split-Path -Parent $targetPath

                $overwrite = Get-BooleanSetting -Object $file -PropertyName "overwrite" -DefaultValue $true
                $backup = Get-BooleanSetting -Object $file -PropertyName "backup" -DefaultValue $false

                if (-not (Test-Path $sourcePath)) {
                    throw "Source config does not exist: $sourcePath"
                }

                if (-not (Test-Path $targetDirectory)) {
                    Write-Log "Creating target directory: $targetDirectory"
                    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
                }

                $targetExists = Test-Path $targetPath

                if ($targetExists -and -not $overwrite) {
                    Write-Log "Target exists and overwrite is disabled. Skipping: $targetPath" "WARN"
                    continue
                }

                if ($targetExists -and $overwrite -and $backup) {
                    $backupPath = New-ConfigBackup -TargetPath $targetPath
                    Write-Log "Created backup: $backupPath" "SUCCESS"
                }

                Copy-Item -Path $sourcePath -Destination $targetPath -Force

                if ($targetExists) {
                    Write-Log "Overwritten config: $sourcePath -> $targetPath" "SUCCESS"
                }
                else {
                    Write-Log "Copied config: $sourcePath -> $targetPath" "SUCCESS"
                }
            }
            catch {
                Write-Log "Failed to copy config '$($file.source)' to '$($file.target)': $($_.Exception.Message)" "ERROR"
                continue
            }
        }
    }

    Write-Log "Configs phase completed." "SUCCESS"
}