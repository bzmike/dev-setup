# Arch Linux Setup

This guide describes how to prepare Arch Linux for the `dev-setup` repository.

The main target is Arch Linux running inside WSL.

---

## 1. Update Arch Linux

After starting Arch Linux for the first time, update the keyring and the system.

Run as `root`:

```bash
pacman-key --init
pacman-key --populate archlinux
pacman -Syu
````

---

## 2. Install `sudo`

Run as `root`:

```bash
pacman -S sudo
```

---

## 3. Create a User

Create the default development user.

Replace `bzmike` if you want to use a different username.

```bash
useradd -m -G wheel -s /bin/bash bzmike
```

Set the password for the new user:

```bash
passwd bzmike
```

---

## 4. Enable `sudo` for the `wheel` Group

Install `nano`:

```bash
pacman -S nano
```

Open the sudoers file with `visudo`:

```bash
EDITOR=nano visudo
```

Find this line:

```text
# %wheel ALL=(ALL:ALL) ALL
```

Remove the `#` so it becomes:

```text
%wheel ALL=(ALL:ALL) ALL
```

Save and exit nano:

```text
Ctrl + O
Enter
Ctrl + X
```

Now users in the `wheel` group can use `sudo`.

Test the new user:

```bash
su - bzmike
sudo pacman -Syu
```

---

## 5. Set the Default WSL User

To make WSL start directly as the new user, create or edit `/etc/wsl.conf`.

Run as the new user:

```bash
sudo nano /etc/wsl.conf
```

Add:

```ini
[user]
default=bzmike
```

Save and exit nano:

```text
Ctrl + O
Enter
Ctrl + X
```

Then shut down WSL from Windows PowerShell:

```powershell
wsl --shutdown
```

Start Arch Linux again:

```powershell
wsl -d archlinux
```

Check the current user:

```bash
whoami
```

Expected output:

```text
bzmike
```

---

## 6. Install Git

After restarting Arch Linux and logging in as the default user, install Git:

```bash
sudo pacman -S git
```

---

## 7. Prepare the Workspace

Create the recommended workspace structure:

```bash
mkdir -p ~/workspace/private/github.com/bzmike
cd ~/workspace/private/github.com/bzmike
```

The recommended structure is:

```text
~/workspace/
└── github.com/
    └── private/
        └── bzmike/
            └── dev-setup/
```

---

## 8. Clone `dev-setup` with Sparse Checkout

Clone only the files needed for Arch Linux:

```bash
git clone https://github.com/bzmike/dev-setup.git
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

## 9. Continue with Arch Linux Setup

After cloning the repository, continue working from:

```bash
cd ~/workspace/private/github.com/bzmike/dev-setup/linux/archlinux
chmod +x install.sh
```

Future setup scripts for Arch Linux will live here.

Planned areas:

```text
linux/archlinux/
├── README.md
├── install.sh
└── scripts/
```

---

## Notes
