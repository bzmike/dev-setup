# Git Keys on Windows

This guide explains how to create SSH and GPG keys on Windows and print them so they can be copied.

Use separate keys for private and work usage.

Recommended setup:

```text
Private:
- SSH key: ~/.ssh/id_ed25519_private
- GPG key: private Git identity

Work:
- SSH key: ~/.ssh/id_ed25519_work
- GPG key: work Git identity
````

---

## Requirements

Install Git for Windows and Gpg4win.

If you use Winget:

```powershell
winget install --id Git.Git --exact
winget install --id GnuPG.Gpg4win --exact
```

After installation, open a new PowerShell or Git Bash window.

Check that the required commands are available:

```powershell
ssh -V
gpg --version
git --version
```

---

## 1. Create SSH Keys

### Private SSH Key

Use this for private projects:

```powershell
ssh-keygen -t ed25519 -C "private" -f "$HOME\.ssh\id_ed25519_private"
```

When asked for a passphrase, use a secure passphrase.

### Work SSH Key

Use this for work repositories:

```powershell
ssh-keygen -t ed25519 -C "work" -f "$HOME\.ssh\id_ed25519_work"
```

When asked for a passphrase, use a secure passphrase.

---

## 2. Start the SSH Agent

Start the SSH agent service:

```powershell
Get-Service ssh-agent
```

If it is disabled, enable it:

```powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
```

Add your keys:

```powershell
ssh-add "$HOME\.ssh\id_ed25519_private"
ssh-add "$HOME\.ssh\id_ed25519_work"
```

Check loaded keys:

```powershell
ssh-add -l
```

---

## 3. Print SSH Public Keys

Only copy the `.pub` files.

Never copy the private key files.

### Print private SSH public key

```powershell
Get-Content "$HOME\.ssh\id_ed25519_private.pub"
```

Copy the output.

### Print work SSH public key

```powershell
Get-Content "$HOME\.ssh\id_ed25519_work.pub"
```

Copy the output.

### Copy directly to clipboard

Private key:

```powershell
Get-Content "$HOME\.ssh\id_ed25519_private.pub" | Set-Clipboard
```

Work key:

```powershell
Get-Content "$HOME\.ssh\id_ed25519_work.pub" | Set-Clipboard
```

---

## 4. Configure SSH Hosts

Create or edit:

```powershell
notepad "$HOME\.ssh\config"
```

Example:

```sshconfig
Host github.com-private
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_private
    IdentitiesOnly yes

Host example.com-work
    HostName example.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

With this setup, use these clone URLs:

```powershell
git clone git@github.com-private:bzmike/my-private-repo.git
git clone git@example.com-work:workspace-or-team/work-repo.git
```

The host alias decides which SSH key is used.

---

## 5. Test SSH Access

Test GitHub:

```powershell
ssh -T git@github.com-private
```

Test example:

```powershell
ssh -T git@example.com-work
```

---

## 6. Create GPG Keys

Create one GPG key for private commits and one for work commits.

Before creating a GPG key, make sure the email address you use is the same email address you want to use in Git commits.

---

### Private GPG Key

```powershell
gpg --full-generate-key
```

Recommended options:

```text
Key type: RSA and RSA
Key size: 4096
Expiration: 1y or 2y
Name: bzmike
Email: your-github-noreply-email@users.noreply.github.com
Comment: private
```

---

### Work GPG Key

```powershell
gpg --full-generate-key
```

Recommended options:

```text
Key type: RSA and RSA
Key size: 4096
Expiration: 1y or 2y
Name: Your Name
Email: your.work.email@company.com
Comment: work
```

---

## 7. List GPG Keys

List secret keys with long key IDs:

```powershell
gpg --list-secret-keys --keyid-format=long
```

Example output:

```text
sec   rsa4096/ABCDEF1234567890 2026-04-25 [SC]
      1234567890ABCDEF1234567890ABCDEF12345678
uid                 [ultimate] bzmike <12345678+bzmike@users.noreply.github.com>
ssb   rsa4096/1234567890ABCDEF 2026-04-25 [E]
```

The signing key ID is usually the part after `rsa4096/`.

Example:

```text
ABCDEF1234567890
```

---

## 8. Print GPG Public Keys

Use the key ID from the previous step.

Private GPG public key:

```powershell
gpg --armor --export ABCDEF1234567890
```

Copy the full output, including:

```text
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----
```

Copy directly to the clipboard:

```powershell
gpg --armor --export ABCDEF1234567890 | Set-Clipboard
```

Repeat the same for the work GPG key.

---

## 9. Configure Git to Use GPG

The recommended setup is to configure GPG signing per Git profile.

Private projects should use the private GPG key.

Work projects should use the work GPG key.

Example private Git config:

```
[user]
    name = bzmike
    email = 12345678+bzmike@users.noreply.github.com
    signingkey = ABCDEF1234567890

[commit]
    gpgsign = true
```

Example work Git config:

```
[user]
    name = Your Name
    email = your.work.email@company.com
    signingkey = 1234567890ABCDEF

[commit]
    gpgsign = true
```

---

## 10. Troubleshooting

### Git cannot find GPG

Check:

```powershell
gpg --version
```

If Git cannot find GPG, configure the GPG program path.

Find GPG:

```powershell
where.exe gpg
```

Then configure Git:

```powershell
git config --global gpg.program "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
```

The path may be different on your system.

### Test a signed commit

Inside a test repository:

```powershell
git commit --allow-empty -m "test signed commit"
git log --show-signature -1
```