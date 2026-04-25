# Add SSH and GPG Keys to Git hosts

This guide explains how to add SSH and GPG public keys to git hosts.

Use separate keys for private and work usage.

Recommended setup:

```text
Private:
- GitHub private SSH key
- GitHub private GPG key
- GitHub no-reply email

Work:
- Work SSH key
- Work GPG key
- Work email or verified work alias
````

Do not reuse the same SSH or GPG key for private and work identities.

## Copy private SSH Key

Windows:

```powershell
Get-Content "$HOME\.ssh\id_ed25519_private.pub" | Set-Clipboard
```

Arch Linux / WSL:

```bash
cat ~/.ssh/id_ed25519_private.pub | clip.exe
```


## Copy private GPG public key.

Windows:

```powershell
gpg --armor --export YOUR_PRIVATE_GPG_KEY_ID | Set-Clipboard
```

Arch Linux / WSL:

```bash
gpg --armor --export YOUR_PRIVATE_GPG_KEY_ID | clip.exe
```

## Copy SSH Key for work

Windows:

```powershell
Get-Content "$HOME\.ssh\id_ed25519_work.pub" | Set-Clipboard
```

Arch Linux / WSL:

```bash
cat ~/.ssh/id_ed25519_work.pub | clip.exe
```


## Copy work GPG public key.

Windows:

```powershell
gpg --armor --export YOUR_WORK_GPG_KEY_ID | Set-Clipboard
```

Arch Linux / WSL:

```bash
gpg --armor --export YOUR_WORK_GPG_KEY_ID | clip.exe
```

## Important: Use Separate Private and Work Keys

You should use two separate identities:

```text
Private identity:
- private SSH key
- private GPG key
- private Git email

Work identity:
- work SSH key
- work GPG key
- work Git email
```

This prevents accidental commits with the wrong email or wrong signing key.

---

## Check Active Git Identity

Inside a repository:

```bash
git config.template --show-origin --get user.name
git config.template --show-origin --get user.email
git config.template --show-origin --get user.signingkey
```

Check all active Git config values:

```bash
git config.template --show-origin --list
```
