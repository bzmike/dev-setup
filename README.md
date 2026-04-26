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
- managing encrypted setup values with SOPS + age
- preparing Git identities for private and work projects
- preparing SSH and GPG keys for GitHub and Bitbucket
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

## Encrypted Configuration Values

This repository uses **SOPS + age** for encrypted setup values.

Encrypted environment files live in:

```text
shared/env/
├── git.env.enc
└── ssh.env.enc
```

These files may contain encrypted values such as:

* private Git name
* private Git email
* work Git name
* work Git email
* SSH host aliases
* SSH key file names
* GPG signing key IDs

The encrypted `*.env.enc` files are safe to commit.

Plain text environment files must never be committed.

Do not commit:

```text
shared/env/*.env
*.env.dec
age private keys
```

The age private key is required to decrypt the files on a new machine.

On Linux, SOPS usually expects the age key here:

```text
~/.config/sops/age/keys.txt
```

On Windows, SOPS usually expects the age key here:

```text
%APPDATA%\sops\age\keys.txt
```

The age private key should be stored securely, for example in a password manager.

---

## Important SOPS Version Note

Before decrypting or editing encrypted files, always check which SOPS version was used to create them.

SOPS stores metadata inside the encrypted `*.env.enc` files, including the SOPS version.

You can inspect an encrypted file directly:

```bash
cat shared/env/git.env.enc
```

Look for metadata similar to:

```text
sops_version=...
```

Use a compatible SOPS version when decrypting on another system.

This is especially important on Windows, because package managers may provide an older SOPS version than the one used to encrypt the files.

Check the installed SOPS version:

```powershell
sops --version
```

The Windows setup documentation explains how to manually install a newer SOPS binary if the Winget version is too old.

See:

```text
windows/README.md
```

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
* SOPS + age encrypted env preparation
* Windows-specific config file copying
* config backup handling
* setup logging
* troubleshooting notes

Example use cases:

* install or skip WSL
* install Arch Linux, Ubuntu or Debian through WSL
* install Git, JetBrains Toolbox, Docker Desktop, GlazeWM and Flow Launcher
* decrypt encrypted setup values
* render Git and SSH config templates
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
* SOPS + age encrypted env preparation
* Docker CLI setup
* Node.js, PHP, Python, Rust, Go, Zig or other language tooling

Example structure:

```text
linux/archlinux/
├── README.md
├── install.sh
├── dependencies.json
├── pacman-packages.json
├── languages.json
├── configs.json
├── configs/
└── scripts/
    ├── common.sh
    ├── dependencies.sh
    ├── pacman-packages.sh
    ├── languages.sh
    ├── secrets.sh
    ├── configs.sh
    └── languages/
        ├── node.sh
        ├── python.sh
        ├── rust.sh
        ├── go.sh
        ├── php.sh
        └── zig.sh
```

---

### `shared/`

Shared configuration and templates that may be useful across multiple operating systems.

This folder may contain:

* Git base configuration
* Git profile templates
* SSH config templates
* encrypted setup values
* shared dotfiles
* editor-independent conventions
* general development defaults

Example:

```text
shared/
├── env/
│   ├── git.env.enc
│   └── ssh.env.enc
├── git/
│   ├── .gitconfig
│   ├── .gitconfig-private.template
│   └── .gitconfig-work.template
└── ssh/
    └── config.template
```

The files in `shared/env/` are encrypted with SOPS + age.

The files in `shared/git/` and `shared/ssh/` are templates or shared base configs.

Generated files such as `.gitconfig-private`, `.gitconfig-work` and `ssh-config` are created locally during setup and should not be committed.

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
├── sparse-checkout.md
└── git/
    ├── keys-windows.md
    ├── keys-archlinux.md
    └── add-keys-to-git-hosts.md
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

Instead, each concern should live in its own script.

Windows example:

```text
windows/scripts/
├── common.ps1
├── wsl.ps1
├── dependencies.ps1
├── winget-packages.ps1
├── secrets.ps1
└── configs.ps1
```

Arch Linux example:

```text
linux/archlinux/scripts/
├── common.sh
├── dependencies.sh
├── pacman-packages.sh
├── languages.sh
├── secrets.sh
├── configs.sh
└── languages/
```

The main install script acts as the entry point and orchestrates the individual setup steps.

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

Arch Linux setup uses:

```text
linux/archlinux/dependencies.json
linux/archlinux/pacman-packages.json
linux/archlinux/languages.json
linux/archlinux/configs.json
```

This makes the setup easier to update without constantly changing script logic.

---

### Encrypted personal values

Personal values such as Git names, Git emails, SSH host aliases and GPG key IDs should not be committed in plain text.

Instead, encrypted env files are stored in:

```text
shared/env/
```

The setup decrypts these files locally with SOPS + age and renders system-specific generated config files.

This keeps personal setup values versioned but encrypted.

---

### Safe repeated execution

The scripts should be safe to run multiple times.

For example:

* already installed WSL distributions should be skipped
* already installed packages should be upgraded or skipped
* missing optional packages should be logged
* config files can be backed up before being overwritten
* disabled entries can be skipped without deleting them
* generated files should be recreated locally
* logs should be written for later inspection

---

### Clear error behavior

Not all errors are equal.

Critical dependencies should stop the setup.

Optional applications should log errors and continue.

Config copy errors should log errors and continue.

WSL installation errors should log errors and continue.

SOPS decryption errors should stop the setup because generated Git and SSH configs depend on them.

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
    ├── common.ps1
    ├── wsl.ps1
    ├── dependencies.ps1
    ├── winget-packages.ps1
    ├── secrets.ps1
    └── configs.ps1
```

### `install.ps1`

Main entry point.

It loads the helper scripts and runs the setup phases in order.

Current order:

```text
1. WSL setup prompt
2. dependencies.json
3. winget-packages.json
4. SOPS env preparation
5. configs.json
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

### SOPS env preparation

Before config files are copied, the setup prepares encrypted configuration values.

This phase:

* checks that SOPS and age are available
* asks the user to restore the age private key if needed
* decrypts `shared/env/git.env.enc`
* decrypts `shared/env/ssh.env.enc`
* renders Git and SSH templates
* writes generated files into the local system config folder

The generated files are then copied by the config phase.

On Windows, SOPS may need to be installed manually if the Winget version is too old.

The expected manual SOPS path on Windows is:

```text
C:\Tools\sops\sops.exe
```

See:

```text
windows/README.md
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

Configs can use local or shared sources.

Example shared source:

```json
{
  "source": "git/.gitconfig",
  "source_base": "shared",
  "target": "~\\.gitconfig",
  "overwrite": true,
  "backup": true
}
```

Example generated local source:

```json
{
  "source": "generated/.gitconfig-private",
  "source_base": "local",
  "target": "~\\.gitconfig-private",
  "overwrite": true,
  "backup": true
}
```

---

## Arch Linux Setup Overview

The Arch Linux setup currently uses these main files:

```text
linux/archlinux/
├── install.sh
├── dependencies.json
├── pacman-packages.json
├── languages.json
├── configs.json
└── scripts/
    ├── common.sh
    ├── dependencies.sh
    ├── pacman-packages.sh
    ├── languages.sh
    ├── secrets.sh
    └── configs.sh
```

Current order:

```text
1. dependencies.json
2. pacman-packages.json
3. languages.json
4. SOPS env preparation
5. configs.json
```

The Arch Linux setup is intended for Arch Linux running inside WSL, but most parts can also be useful on a regular Arch Linux installation.

---

## Current Status

This repository is a personal setup project and is expected to evolve over time.

Current focus:

```text
Windows setup
├── WSL prompt
├── WSL distro installation
├── Winget packages
├── SOPS + age encrypted env preparation
├── Config template rendering
├── Config file copying
├── Backup before overwrite
├── Logging
└── Troubleshooting docs
```

Planned or current Arch Linux areas:

```text
Arch Linux setup
├── Base packages
├── Git and SSH
├── SOPS + age encrypted env preparation
├── Shell setup
├── Node.js via nvm
├── Python via pyenv
├── Rust
├── Go
├── PHP
├── Zig
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

## Running the Arch Linux Setup

Go to the Arch Linux setup folder:

```bash
cd ~/workspace/github.com/bzmike/dev-setup/linux/archlinux
```

Run:

```bash
chmod +x install.sh
./install.sh
```

For details, see:

```text
linux/archlinux/README.md
```

---

## Final Manual Steps: SSH and GPG Keys

After the base setup has run, SSH and GPG keys still need to be created manually per machine.

Recommended separation:

```text
Private:
- private SSH key
- private GPG signing key
- GitHub no-reply email

Work:
- work SSH key
- work GPG signing key
- work email or verified work alias
```

SSH keys are used for authentication with Git hosts such as GitHub and Bitbucket.

GPG keys are used for signing commits.

The generated Git profile files are:

```text
~/.gitconfig-private
~/.gitconfig-work
```

Each profile should contain its matching GPG signing key:

```
[user]
    name = Your Name
    email = your.email@example.com
    signingkey = YOUR_GPG_KEY_ID
```

If the GPG key ID is not known yet when the encrypted env files are created, update the encrypted env files later and regenerate the configs.

Helpful docs:

```text
docs/git/
├── keys-windows.md
├── keys-archlinux.md
└── add-keys-to-git-hosts.md
```

In short:

1. Create a private SSH key.
2. Create a work SSH key.
3. Add the public SSH keys to GitHub and Bitbucket.
4. Create a private GPG key.
5. Create a work GPG key.
6. Add the public GPG keys to GitHub and Bitbucket.
7. Store the matching GPG key IDs in the encrypted Git env values.
8. Regenerate `.gitconfig-private` and `.gitconfig-work`.

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
* SOPS + age as the encrypted configuration mechanism
* separate private and work Git identities

Review scripts, JSON files and encrypted setup values before running them on a new machine.

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
