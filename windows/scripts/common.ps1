$script:LogFile = $null

function Initialize-Logging {
    param(
        [Parameter(Mandatory = $true)]
        [string] $RootPath
    )

    $logDirectory = Join-Path $RootPath "logs"

    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory | Out-Null
    }

    $script:LogFile = Join-Path $logDirectory ("install-{0}.log" -f (Get-Date -Format "yyyy-MM-dd-HH-mm-ss"))
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string] $Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    Write-Host $line

    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $line
    }
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if (-not (Test-Path $Path)) {
        throw "JSON file not found: $Path"
    }

    try {
        return Get-Content -Path $Path -Raw | ConvertFrom-Json
    }
    catch {
        throw "Could not parse JSON file '$Path'. Error: $($_.Exception.Message)"
    }
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command
    )

    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Invoke-ExternalCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Executable,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    Write-Log "Running: $Executable $($Arguments -join ' ')"

    & $Executable @Arguments

    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "Command failed with exit code $exitCode`: $Executable $($Arguments -join ' ')"
    }
}