# Dev Setup

Personal developer environment setup for Windows, WSL and Linux systems.

This repository contains scripts, package definitions, configuration files and documentation to bootstrap a reproducible development environment across different machines and operating systems.

The goal is to keep the setup:

- reproducible
- modular
- system-specific
- version controlled
- easy to understand
- safe to run repeatedly

---

## Purpose

Setting up a new development machine usually involves many repeated manual steps:

- installing applications
- installing developer tools
- preparing WSL
- installing Linux distributions
- configuring Git and SSH
- copying config files
- setting up shells and terminals
- installing programming languages
- configuring productivity tools

This repository collects those steps in one place.

Instead of relying on memory, screenshots or manual notes, the setup is described through scripts, JSON files and documentation.

---

## Repository Structure

```text
dev-setup/
├── README.md
├── windows/
├── linux/
├── shared/
└── docs/
````

---

## Directories

### `windows/`

Windows-specific setup.

This includes:

* PowerShell setup scripts
* WSL setup prompt
* WSL distro installation
* Winget package installation
* Windows application setup
* Windows-specific config file copying
* config backup handling
* setup logging
* troubleshooting notes

Example use cases:

* install or skip WSL
* install Arch Linux, Ubuntu or Debian through WSL
* install Git, JetBrains Toolbox, Docker Desktop, GlazeWM and Flow Launcher
* copy GlazeWM config files
* copy PowerShell profile files
* log failed package installs without stopping the whole setup

See:

```text
windows/README.md
```

---

### `linux/`

Linux-specific setup.

This folder is intended for Linux distributions and WSL Linux environments.

Current planned structure:

```text
linux/
└── archlinux/
```

---

### `linux/archlinux/`

Arch Linux setup, especially for Arch Linux running inside WSL.

This area is intended for:

* base system packages
* development tools
* programming languages
* package manager setup
* shell setup
* Git and SSH setup
* Docker CLI setup
* Node.js, PHP, Python, Java, Go or other language tooling

Example future structure:

```text
linux/archlinux/
├── README.md
├── install.sh
├── packages/
│   ├── base.txt
│   ├── node.txt
│   ├── php.txt
│   ├── python.txt
│   └── docker.txt
└── scripts/
    ├── install-base.sh
    ├── install-node.sh
    ├── install-php.sh
    └── install-docker-cli.sh
```

---

### `shared/`

Shared configuration and documentation that may be useful across multiple operating systems.

This folder may contain:

* Git configuration examples
* SSH setup notes
* editor-independent conventions
* shared dotfiles
* general development defaults

Example:

```text
shared/
├── git/
│   └── .gitconfig.example
└── ssh/
    └── README.md
```

---

### `docs/`

General documentation.

This folder is intended for explanations, decisions and setup notes that are not tied to one specific script.

Possible documents:

```text
docs/
├── windows.md
├── archlinux.md
├── wsl.md
├── jetbrains-wsl.md
└── sparse-checkout.md
```

---

## Sparse Checkout

This repository is designed to work well with Git sparse checkout.

That means each system can clone only the files it actually needs.

For example:

* Windows only needs `windows/`, `shared/` and `docs/`
* Arch Linux only needs `linux/archlinux/`, `shared/` and `docs/`

This avoids having to create multiple repositories for each operating system while still keeping local checkouts clean.

---

## Clone for Windows

```powershell
cd $HOME\workspace\github.com\bzmike

git clone --filter=blob:none --sparse git@github.com:bzmike/dev-setup.git
cd dev-setup

git sparse-checkout set windows shared docs
```

This results in a local checkout like:

```text
dev-setup/
├── README.md
├── windows/
├── shared/
└── docs/
```

Then continue with:

```text
windows/README.md
```

---

## Clone for Arch Linux / WSL

```bash
cd ~/workspace/github.com/bzmike

git clone --filter=blob:none --sparse git@github.com:bzmike/dev-setup.git
cd dev-setup

git sparse-checkout set linux/archlinux shared docs
```

This results in a local checkout like:

```text
dev-setup/
├── README.md
├── linux/
│   └── archlinux/
├── shared/
└── docs/
```

---

## Recommended Workspace Layout

This repository assumes a host/owner/repository based workspace structure.

Example:

```text
~/workspace/
└── github.com/
    └── bzmike/
        └── dev-setup/
```

On Windows PowerShell:

```powershell
cd $HOME\workspace\github.com\bzmike
```

On Linux / WSL:

```bash
cd ~/workspace/github.com/bzmike
```

This structure scales well across multiple Git hosting providers, organizations and projects.

Example:

```text
~/workspace/
├── github.com/
│   ├── bzmike/
│   │   ├── dev-setup/
│   │   └── some-project/
│   └── other-org/
│       └── another-project/
├── gitlab.com/
│   └── company/
│       └── internal-tool/
└── bitbucket.org/
    └── team/
        └── legacy-project/
```

---

## Design Goals

### One repository, multiple systems

The repository should contain setup logic for different systems without forcing every system to check out every file.

Sparse checkout makes this possible.

---

### System-specific setup

Each operating system gets its own setup area.

Windows setup should not be mixed with Arch Linux setup.

Arch Linux setup should not be mixed with Windows setup.

Shared files belong in `shared/`.

---

### Modular scripts

The setup should not become one large script that does everything.

Instead, each concern should live in its own script:

```text
windows/scripts/
├── common.ps1
├── wsl.ps1
├── dependencies.ps1
├── winget-packages.ps1
└── configs.ps1
```

The main `install.ps1` acts as the entry point and orchestrates the individual setup steps.

---

### Declarative package definitions

Where possible, tools and packages are defined in JSON or plain text files instead of being hardcoded directly inside scripts.

For example, Windows setup uses:

```text
windows/wsl.json
windows/dependencies.json
windows/winget-packages.json
windows/configs.json
```

This makes the setup easier to update without constantly changing script logic.

---

### Safe repeated execution

The scripts should be safe to run multiple times.

For example:

* already installed WSL distributions should be skipped
* already installed packages should be upgraded or skipped
* missing optional packages should be logged
* config files can be backed up before being overwritten
* disabled entries can be skipped without deleting them
* logs should be written for later inspection

---

### Clear error behavior

Not all errors are equal.

Critical dependencies should stop the setup.

Optional applications should log errors and continue.

Config copy errors should log errors and continue.

WSL installation errors should log errors and continue.

This keeps the setup strict where necessary and flexible where useful.

---

## Windows Setup Overview

The Windows setup currently uses these main files:

```text
windows/
├── install.ps1
├── wsl.json
├── dependencies.json
├── winget-packages.json
├── configs.json
└── scripts/
```

### `install.ps1`

Main entry point.

It loads the helper scripts and runs the setup phases in order.

Current order:

```text
1. WSL setup prompt
2. dependencies.json
3. winget-packages.json
4. configs.json
```

---

### `wsl.json`

Defines optional WSL distributions that can be installed by the setup.

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

### `dependencies.json`

Required commands or packages.

If something in this file fails, the setup stops.

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

### `winget-packages.json`

Normal Windows applications installed with Winget.

If an installation fails, the error is logged and the setup continues.

Example:

```json
{
  "packages": [
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

### `configs.json`

Config files to copy into their target locations.

Configs are independent from Winget packages.

Example:

```json
{
  "config_groups": [
    {
      "name": "GlazeWM",
      "enabled": true,
      "files": [
        {
          "source": "glazewm/config.yaml",
          "target": "~\\.glzr\\glazewm\\config.yaml",
          "overwrite": true,
          "backup": true
        }
      ]
    }
  ]
}
```

---

## Current Status

This repository is a personal setup project and is expected to evolve over time.

Current focus:

```text
Windows setup
├── WSL prompt
├── WSL distro installation
├── Winget packages
├── Config file copying
├── Backup before overwrite
├── Logging
└── Troubleshooting docs
```

Planned or possible future areas:

```text
Arch Linux setup
├── Base packages
├── Git and SSH
├── Shell setup
├── Node.js
├── PHP
├── Docker CLI
└── programming language tooling
```

---

## Running the Windows Setup

Open PowerShell or Windows Terminal as Administrator.

```powershell
cd $HOME\workspace\github.com\bzmike\dev-setup\windows

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\install.ps1
```

For details, see:

```text
windows/README.md
```

---

## Notes

This setup is mainly intended for personal use.

It may make assumptions about:

* preferred tools
* folder structure
* Windows user profile paths
* WSL usage
* Arch Linux as the preferred Linux environment
* JetBrains IDEs running on Windows while toolchains run inside WSL

Review scripts and JSON files before running them on a new machine.

---

## Philosophy

A development environment is part of the development workflow.

It should be treated like code:

* versioned
* reviewed
* improved over time
* reproducible
* documented
* easy to rebuild

This repository is the place where that setup lives.