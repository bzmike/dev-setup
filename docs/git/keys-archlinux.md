# Git Keys on Arch Linux

This guide explains how to create SSH and GPG keys on Arch Linux and print them so they can be copied.

This is especially useful for Arch Linux running inside WSL.

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

Install OpenSSH, Git and GnuPG:

```bash
sudo pacman -S --needed openssh git gnupg
```

Check that the required commands are available:

```bash
ssh -V
gpg --version
git --version
```

---

## 1. Create SSH Keys

Create the `.ssh` directory if it does not exist:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

### Private SSH Key

Use this for private GitHub projects:

```bash
ssh-keygen -t ed25519 -C "github-private" -f ~/.ssh/id_ed25519_private
```

When asked for a passphrase, use a secure passphrase.

### Work SSH Key

Use this for work repositories:

```bash
ssh-keygen -t ed25519 -C "work" -f ~/.ssh/id_ed25519_work
```

When asked for a passphrase, use a secure passphrase.

Fix permissions:

```bash
chmod 600 ~/.ssh/id_ed25519_private
chmod 600 ~/.ssh/id_ed25519_work
chmod 644 ~/.ssh/id_ed25519_private.pub
chmod 644 ~/.ssh/id_ed25519_work.pub
```

---

## 2. Start the SSH Agent

Start an SSH agent for the current shell:

```bash
eval "$(ssh-agent -s)"
```

Add your keys:

```bash
ssh-add ~/.ssh/id_ed25519_private
ssh-add ~/.ssh/id_ed25519_work
```

Check loaded keys:

```bash
ssh-add -l
```

---

## 3. Print SSH Public Keys

Only copy the `.pub` files.

Never copy the private key files.

### Print private GitHub SSH public key

```bash
cat ~/.ssh/id_ed25519_private.pub
```

### Print work SSH public key

```bash
cat ~/.ssh/id_ed25519_work.pub
```

### Copy directly to clipboard in WSL

If you are inside WSL, you can copy to the Windows clipboard with:

```bash
cat ~/.ssh/id_ed25519_private.pub | clip.exe
```

```bash
cat ~/.ssh/id_ed25519_work.pub | clip.exe
```

---

## 4. Configure SSH Hosts

Create or edit:

```bash
nano ~/.ssh/config.template
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

Fix permissions:

```bash
chmod 600 ~/.ssh/config.template
```

With this setup, use these clone URLs:

```bash
git clone git@github.com-private:bzmike/my-private-repo.git
git clone git@example.com-work:workspace-or-team/work-repo.git
```

The host alias decides which SSH key is used.

---

## 5. Test SSH Access

Test GitHub:

```bash
ssh -T git@github.com-private
```

Test example:

```bash
ssh -T git@example.com-work
```

---

## 6. Create GPG Keys

Create one GPG key for private commits and one for work commits.

Before creating a GPG key, make sure the email address you use is the same email address you want to use in Git commits.

---

### Private GPG Key

```bash
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

```bash
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

```bash
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

```bash
gpg --armor --export ABCDEF1234567890
```

Copy the full output, including:

```text
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----
```

Copy directly to the clipboard in WSL:

```bash
gpg --armor --export ABCDEF1234567890 | clip.exe
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

```bash
gpg --version
```

Configure Git explicitly if needed:

```bash
git config.template --global gpg.program "$(command -v gpg)"
```

### Test a signed commit

Inside a test repository:

```bash
git commit --allow-empty -m "test signed commit"
git log --show-signature -1
```

### GPG pinentry problems inside WSL

If GPG signing fails because no passphrase prompt appears, install pinentry:

```bash
sudo pacman -S --needed pinentry
```

Then add this to `~/.gnupg/gpg-agent.conf`:

```text
pinentry-program /usr/bin/pinentry-curses
```

Restart the GPG agent:

```bash
gpgconf --kill gpg-agent
```
