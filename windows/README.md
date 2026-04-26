# Windows Dev Setup

This folder contains the Windows setup scripts and configuration files for the `dev-setup` repository.

The goal is to automate the basic Windows developer environment setup using:

- PowerShell
- WSL
- Winget
- JSON-based package definitions
- JSON-based config file definitions
- optional backups before overwriting config files
- logs for later troubleshooting

---

## What This Setup Does

The Windows setup can:

- optionally install or skip WSL
- install a selected WSL distribution
- skip WSL distributions that are already installed
- check required dependencies
- install or upgrade required packages
- install or upgrade normal Winget packages
- log failed optional package installs without stopping the setup
- copy configuration files
- overwrite existing configuration files
- optionally create backups before overwriting config files

---

## Repository Checkout

You can either clone the repository or manually download it from GitHub.

Recommended clone setup for Windows:

```powershell
cd $HOME\workspace\github.com\bzmike

git clone --filter=blob:none --sparse git@github.com:bzmike/dev-setup.git
cd dev-setup

git sparse-checkout set windows shared docs
````

This checks out only the parts of the repository that are needed on Windows:

```text
dev-setup/
├── README.md
├── windows/
├── shared/
└── docs/
```

---

## Folder Structure

```text
windows/
├── install.ps1
├── wsl.json
├── dependencies.json
├── winget-packages.json
├── configs.json
├── scripts/
│   ├── common.ps1
│   ├── wsl.ps1
│   ├── dependencies.ps1
│   ├── winget-packages.ps1
│   └── configs.ps1
├── configs/
│   ├── glazewm/
│   │   └── config.yaml
│   ├── zebar/
│   │   └── settings.json
│   └── powershell/
│       └── Microsoft.PowerShell_profile.ps1
└── logs/
```

The `logs/` folder is created automatically when the setup script runs.

---

## Script Structure

The setup is split into multiple scripts.

| Script                        | Purpose                                                         |
|-------------------------------|-----------------------------------------------------------------|
| `install.ps1`                 | Main entry point / orchestrator                                 |
| `scripts/common.ps1`          | Shared helpers like logging, JSON reading and command execution |
| `scripts/wsl.ps1`             | WSL prompt and distro installation                              |
| `scripts/dependencies.ps1`    | Required tools and packages                                     |
| `scripts/winget-packages.ps1` | Normal Winget application installation                          |
| `scripts/configs.ps1`         | Config file copying, overwrite handling and backups             |

`install.ps1` loads the other scripts and runs the setup phases in order.

---

## Running the Setup

Open PowerShell or Windows Terminal as Administrator.

Then go to the Windows setup folder:

```powershell
cd $HOME\workspace\github.com\bzmike\dev-setup\windows
```

PowerShell may block local scripts depending on your execution policy.

For this terminal session only, allow script execution with:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run the installer:

```powershell
.\install.ps1
```

The bypass only applies to the current PowerShell session. It does not permanently change your system-wide execution policy.

---

## SOPS on Windows

Winget may provide an outdated SOPS version. This setup expects SOPS to be installed manually at:

```text
C:\Tools\sops\sops.exe
````

Install manually:

```powershell
New-Item -ItemType Directory -Force C:\Tools\sops
Copy-Item "$env:USERPROFILE\Downloads\sops-v3.12.2.amd64.exe" "C:\Tools\sops\sops.exe" -Force

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($userPath -notlike "*C:\Tools\sops*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;C:\Tools\sops", "User")
}

$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
```

Check:

```powershell
sops --version
```


## Setup Phases

The setup script runs in this order:

```text
1. WSL setup prompt
2. dependencies.json
3. winget-packages.json
4. configs.json
```

Each phase has different error behavior.

| Phase                  | Error behavior         |
|------------------------|------------------------|
| WSL setup              | Log error and continue |
| `dependencies.json`    | Stop immediately       |
| `winget-packages.json` | Log error and continue |
| `configs.json`         | Log error and continue |

---

## 1. WSL Setup

The setup script can optionally install a WSL distribution before running the rest of the Windows setup.

When `install.ps1` starts, it asks whether WSL should be installed or configured.

Example prompt:

```text
Do you want to install or configure WSL?
[0] No
[1] Arch Linux (archlinux)
[2] Ubuntu (Ubuntu)
[3] Debian (Debian)
[4] Show online distro list
```

If `No` is selected, the WSL setup phase is skipped.

If a distribution is selected, the script checks whether the selected WSL distribution is already installed.

If the distribution is already installed, the installation is skipped.

If the distribution is not installed, the script runs:

```powershell
wsl --install --distribution <DistroName>
```

Example:

```powershell
wsl --install --distribution archlinux
```

If the installation fails, the error is logged and the setup continues with the next phases.

A Windows restart may be required before a newly installed distribution can be used.

---

## WSL Configuration File

WSL distributions are configured in:

```text
windows/wsl.json
```

Example:

```json
{
  "enabled": true,
  "default_distro": "archlinux",
  "distros": [
    {
      "name": "Arch Linux",
      "wsl_name": "archlinux",
      "enabled": true
    },
    {
      "name": "Ubuntu",
      "wsl_name": "Ubuntu",
      "enabled": true
    },
    {
      "name": "Debian",
      "wsl_name": "Debian",
      "enabled": true
    }
  ]
}
```

---

## Available WSL Options

### Root options

| Field            | Required | Description                                                |
|------------------|---------:|------------------------------------------------------------|
| `enabled`        |       no | If `false`, the WSL setup phase is skipped                 |
| `default_distro` |       no | Name of the preferred/default distro                       |
| `distros`        |      yes | List of available distro options shown in the setup prompt |

### Distro options

```json
{
  "name": "Arch Linux",
  "wsl_name": "archlinux",
  "enabled": true
}
```

| Field      | Required | Description                                              |
|------------|---------:|----------------------------------------------------------|
| `name`     |      yes | Human-readable distro name shown in the prompt           |
| `wsl_name` |      yes | Exact distro name used by `wsl --install --distribution` |
| `enabled`  |       no | If `false`, the distro is hidden from the prompt         |

---

## Finding Available WSL Distributions

To see all WSL distributions available from Microsoft, run:

```powershell
wsl --list --online
```

The setup prompt also includes an option to show this list.

Use the exact distro name from the output as `wsl_name`.

Example:

```json
{
  "name": "Ubuntu",
  "wsl_name": "Ubuntu",
  "enabled": true
}
```

---

## WSL Error Handling

WSL setup errors are logged, but they do not stop the rest of the Windows setup.

| Case                                 | Behavior                            |
|--------------------------------------|-------------------------------------|
| User selects `No`                    | WSL setup is skipped                |
| `wsl.json` does not exist            | WSL setup is skipped and logged     |
| `enabled` is `false`                 | WSL setup is skipped                |
| `wsl.exe` is missing                 | Error is logged                     |
| Selected distro is already installed | Installation is skipped             |
| Selected distro is not installed     | Script tries to install it          |
| Installation fails                   | Error is logged and setup continues |
| Restart is required                  | Warning is logged                   |

---

## 2. Dependencies

Dependencies are required tools or packages that the rest of the setup depends on.

If a dependency fails, the script stops immediately.

Dependencies are configured in:

```text
windows/dependencies.json
```

Example:

```json
{
  "commands": [
    {
      "name": "winget",
      "command": "winget",
      "required": true
    }
  ],
  "packages": [
    {
      "name": "Git",
      "winget_id": "Git.Git",
      "enabled": true
    }
  ]
}
```

---

## Available Dependency Options

### `commands`

Use this to check whether a command exists on the system.

```json
{
  "name": "winget",
  "command": "winget",
  "required": true
}
```

| Field      | Required | Description                                             |
|------------|---------:|---------------------------------------------------------|
| `name`     |      yes | Human-readable name used in logs                        |
| `command`  |      yes | Command that should be available in PowerShell          |
| `required` |       no | If `true`, the script fails when the command is missing |

Example:

```json
{
  "commands": [
    {
      "name": "winget",
      "command": "winget",
      "required": true
    },
    {
      "name": "git",
      "command": "git",
      "required": true
    }
  ]
}
```

### `packages`

Use this for Winget packages that are required before the normal setup continues.

```json
{
  "name": "Git",
  "winget_id": "Git.Git",
  "enabled": true
}
```

| Field       | Required | Description                        |
|-------------|---------:|------------------------------------|
| `name`      |      yes | Human-readable package name        |
| `winget_id` |      yes | Exact Winget package ID            |
| `enabled`   |       no | If `false`, the package is skipped |

The script will:

* check if the package is already installed
* upgrade it if it is installed
* install it if it is missing
* stop the whole setup if the installation or upgrade fails

---

## 3. Winget Packages

Normal applications are defined in:

```text
windows/winget-packages.json
```

If a package fails, the error is logged and the script continues with the next package.

Example:

```json
{
  "packages": [
    {
      "name": "GlazeWM",
      "winget_id": "glzr-io.glazewm",
      "enabled": true
    },
    {
      "name": "Flow Launcher",
      "winget_id": "Flow-Launcher.Flow-Launcher",
      "enabled": true
    },
    {
      "name": "JetBrains Toolbox",
      "winget_id": "JetBrains.Toolbox",
      "enabled": true
    },
    {
      "name": "Docker Desktop",
      "winget_id": "Docker.DockerDesktop",
      "enabled": true
    }
  ]
}
```

---

## Available Winget Package Options

```json
{
  "name": "JetBrains Toolbox",
  "winget_id": "JetBrains.Toolbox",
  "enabled": true
}
```

| Field       | Required | Description                              |
|-------------|---------:|------------------------------------------|
| `name`      |      yes | Human-readable package name used in logs |
| `winget_id` |      yes | Exact Winget package ID                  |
| `enabled`   |       no | If `false`, the package is skipped       |

The script uses the Winget ID with `--exact`.

That means the ID must be correct.

To search for the correct Winget ID:

```powershell
winget search "Package Name"
```

Example:

```powershell
winget search "Flow Launcher"
```

Then use the exact ID from the result table.

---

## 4. Config Files

Config files are defined in:

```text
windows/configs.json
```

Configs are independent of Winget packages. This is useful because not every config belongs to an application installed through Winget.

Example:

```json
{
  "config_groups": [
    {
      "name": "GlazeWM",
      "enabled": true,
      "files": [
        {
          "source": "glazewm/config.template.yaml",
          "target": "~\\.glzr\\glazewm\\config.template.yaml",
          "overwrite": true,
          "backup": true
        }
      ]
    },
    {
      "name": "PowerShell",
      "enabled": true,
      "files": [
        {
          "source": "powershell/Microsoft.PowerShell_profile.ps1",
          "target": "~\\Documents\\PowerShell\\Microsoft.PowerShell_profile.ps1",
          "overwrite": true,
          "backup": true
        }
      ]
    }
  ]
}
```

Source paths are relative to:

```text
windows/configs/
```

For example:

```json
{
  "source": "glazewm/config.template.yaml",
  "target": "~\\.glzr\\glazewm\\config.template.yaml"
}
```

maps to:

```text
windows/configs/glazewm/config.yaml
```

and copies it to:

```text
C:\Users\<user>\.glzr\glazewm\config.yaml
```

---

## Available Config Options

### Config group

```json
{
  "name": "GlazeWM",
  "enabled": true,
  "files": []
}
```

| Field     | Required | Description                                   |
|-----------|---------:|-----------------------------------------------|
| `name`    |      yes | Human-readable group name used in logs        |
| `enabled` |       no | If `false`, the whole config group is skipped |
| `files`   |      yes | List of config files to copy                  |

### Config file

```json
{
  "source": "glazewm/config.template.yaml",
  "target": "~\\.glzr\\glazewm\\config.template.yaml",
  "overwrite": true,
  "backup": true
}
```

| Field       | Required | Default | Description                                              |
|-------------|---------:|--------:|----------------------------------------------------------|
| `source`    |      yes |       - | Path relative to `windows/configs/`                      |
| `target`    |      yes |       - | Destination path on the local machine                    |
| `overwrite` |       no |  `true` | If `true`, existing files are overwritten                |
| `backup`    |       no | `false` | If `true`, existing files are backed up before overwrite |

---

## Backup Behavior

If this config is used:

```json
{
  "source": "glazewm/config.template.yaml",
  "target": "~\\.glzr\\glazewm\\config.template.yaml",
  "overwrite": true,
  "backup": true
}
```

and this target file already exists:

```text
C:\Users\<user>\.glzr\glazewm\config.yaml
```

the script creates a backup before overwriting:

```text
C:\Users\<user>\.glzr\glazewm\.backup\config.yaml.20260425-162219.bak
```

Then the new config file is copied to the target path.

---

## Overwrite Behavior

If `overwrite` is `false` and the target file already exists, the file is skipped:

```json
{
  "source": "glazewm/config.template.yaml",
  "target": "~\\.glzr\\glazewm\\config.template.yaml",
  "overwrite": false,
  "backup": true
}
```

In this case no backup is created because the file is not overwritten.

---

## Error Handling

The script handles errors differently depending on the phase.

| Phase                  | Error behavior         |
|------------------------|------------------------|
| WSL setup              | Log error and continue |
| `dependencies.json`    | Stop immediately       |
| `winget-packages.json` | Log error and continue |
| `configs.json`         | Log error and continue |

This makes dependencies strict, while allowing optional applications, WSL installation or config files to fail without breaking the whole setup.

---

## Logs

Every run creates a log file in:

```text
windows/logs/
```

Example:

```text
windows/logs/install-2026-04-25-16-21-37.log
```

The log contains:

* selected WSL setup option
* skipped WSL distributions
* WSL installation errors
* installed packages
* upgraded packages
* skipped packages
* failed packages
* copied configs
* created backups
* missing config files
* final setup result

---

## Docker Desktop Troubleshooting

Docker Desktop may fail with an error similar to:

```text
For security reasons C:\ProgramData\DockerDesktop must be owned by an elevated account
Installer failed with exit code: 4294967291
```

`C:\ProgramData` is a hidden Windows system folder.

To check whether it exists:

```powershell
Test-Path C:\ProgramData
```

To show hidden folders:

```powershell
Get-ChildItem C:\ -Force
```

If `C:\ProgramData\DockerDesktop` exists and Docker installation fails, open PowerShell as Administrator and remove the folder:

```powershell
Remove-Item C:\ProgramData\DockerDesktop -Recurse -Force
```

Then run the setup again or install Docker Desktop manually:

```powershell
winget install --id Docker.DockerDesktop --exact --accept-package-agreements --accept-source-agreements
```

---

## PowerShell Execution Policy

If PowerShell blocks the script with an error like:

```text
The file install.ps1 is not digitally signed.
You cannot run this script on the current system.
```

use:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run:

```powershell
.\install.ps1
```

This only changes the execution policy for the current terminal session.

To inspect the current policies:

```powershell
Get-ExecutionPolicy -List
```

---

## Useful Commands

Check current PowerShell execution policies:

```powershell
Get-ExecutionPolicy -List
```

Temporarily allow script execution for the current terminal:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Search for a Winget package:

```powershell
winget search "Package Name"
```

List installed Winget packages:

```powershell
winget list
```

Upgrade all Winget packages manually:

```powershell
winget upgrade --all
```

List installed WSL distributions:

```powershell
wsl --list --verbose
```

List available online WSL distributions:

```powershell
wsl --list --online
```

Install a specific WSL distribution manually:

```powershell
wsl --install --distribution archlinux
```

---

## Notes

Run this setup from PowerShell or Windows Terminal.

During development, it is recommended to run the script manually from an already opened terminal instead of using right-click → "Run with PowerShell", because the window may close immediately after execution.

Review all JSON files before running the setup on a new machine.
