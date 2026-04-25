# Encrypted Env Files with SOPS and age

This guide explains how to create, encrypt, commit, decrypt and restore encrypted environment files using **SOPS + age**.

The encrypted files are used to generate local Git and SSH configuration files without committing private names, emails, key IDs or host aliases in plain text.

---

## Goal

We want to store files like this in the repository:

```text
shared/env/
├── git.env.enc
└── ssh.env.enc
````

These files are encrypted and safe to commit.

They are later decrypted locally and used to generate files such as:

```text
~/.gitconfig-private
~/.gitconfig-work
~/.ssh/config
```

---

## Important Files

```text
dev-setup/
├── .sops.yaml
├── shared/
│   ├── env/
│   │   ├── git.env.enc
│   │   └── ssh.env.enc
│   ├── git/
│   │   ├── .gitconfig-private.template
│   │   └── .gitconfig-work.template
│   └── ssh/
│       └── config.template
```

---

## What Is Safe to Commit?

Safe to commit:

```text
.sops.yaml
shared/env/git.env.enc
shared/env/ssh.env.enc
shared/git/*.template
shared/ssh/config.template
```

Never commit:

```text
shared/env/git.env
shared/env/ssh.env
~/.config/sops/age/keys.txt
```

The private age key must be stored securely, for example, in a password manager.

---

## 1. Install SOPS and age

On Arch Linux:

```bash
sudo pacman -S --needed sops age gettext
```

Check installation:

```bash
sops --version
age --version
envsubst --version
```

---

## 2. Create an age Key

Create the age key file:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 700 ~/.config/sops
chmod 700 ~/.config/sops/age
chmod 600 ~/.config/sops/age/keys.txt
```

Show the public key:

```bash
grep "public key:" ~/.config/sops/age/keys.txt
```

Example output:

```text
# public key: age1examplepublickey000000000000000000000000000000000000
```

The `age1...` value is the public key.

---

## 3. Store the Private Key in a Password Manager

Show the private key file:

```bash
cat ~/.config/sops/age/keys.txt
```

Example:

```text
# created: 2026-04-26T00:00:00+00:00
# public key: age1examplepublickey000000000000000000000000000000000000
AGE-SECRET-KEY-1EXAMPLESECRETKEY000000000000000000000000000000000000
```

Store the complete content in a password manager.

Recommended entry:

```text
Name: dev-setup SOPS age key
Type: Secure Note
Content:
# created: ...
# public key: age1...
AGE-SECRET-KEY-1...
```

Do not commit this key.

---

## 4. Configure `.sops.yaml`

Create `.sops.yaml` in the repository root:

```yaml
creation_rules:
  - path_regex: shared/env/.*\.env\.enc$
    age: age1examplepublickey000000000000000000000000000000000000
```

Replace the example key with your real public age key.

The public key may be committed.

---

## 5. Create Test Git Env File

Create a temporary plain-text file:

```bash
mkdir -p shared/env

cat > shared/env/git.env <<'EOF'
PRIVATE_GIT_NAME="Test Private User"
PRIVATE_GIT_EMAIL=12345678+test-private@users.noreply.github.com
PRIVATE_GPG_KEY_ID=ABCDEF1234567890

WORK_GIT_NAME="Test Work User"
WORK_GIT_EMAIL=test.work@example.com
WORK_GPG_KEY_ID=1234567890ABCDEF
EOF
```

Encrypt it:

```bash
sops --encrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/git.env > shared/env/git.env.enc
```

Remove the plain-text file:

```bash
rm shared/env/git.env
```

Test decryption:

```bash
sops --decrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/git.env.enc
```

Expected output:

```
PRIVATE_GIT_NAME="Test Private User"
PRIVATE_GIT_EMAIL=12345678+test-private@users.noreply.github.com
PRIVATE_GPG_KEY_ID=ABCDEF1234567890

WORK_GIT_NAME="Test Work User"
WORK_GIT_EMAIL=test.work@example.com
WORK_GPG_KEY_ID=1234567890ABCDEF
```

---

## 6. Create Test SSH Env File

Create a temporary plain-text file:

```bash
cat > shared/env/ssh.env <<'EOF'
PRIVATE_SSH_KEY_FILE=id_ed25519_private
WORK_SSH_KEY_FILE=id_ed25519_work

PRIVATE_GIT_HOST_ALIAS=github.com-private
PRIVATE_GIT_HOST_NAME=github.com

WORK_GIT_HOST_ALIAS=bitbucket.org-work
WORK_GIT_HOST_NAME=bitbucket.org
EOF
```

Encrypt it:

```bash
sops --encrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/ssh.env > shared/env/ssh.env.enc
```

Remove the plain-text file:

```bash
rm shared/env/ssh.env
```

Test decryption:

```bash
sops --decrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/ssh.env.enc
```

Expected output:

```dotenv
PRIVATE_SSH_KEY_FILE=id_ed25519_private
WORK_SSH_KEY_FILE=id_ed25519_work

PRIVATE_GIT_HOST_ALIAS=github.com-private
PRIVATE_GIT_HOST_NAME=github.com

WORK_GIT_HOST_ALIAS=bitbucket.org-work
WORK_GIT_HOST_NAME=bitbucket.org
```

---

## 7. Create Git Config Templates

Create the private Git config template:

```bash
mkdir -p shared/git

cat > shared/git/.gitconfig-private.template <<'EOF'
[user]
    name = ${PRIVATE_GIT_NAME}
    email = ${PRIVATE_GIT_EMAIL}
    signingkey = ${PRIVATE_GPG_KEY_ID}
EOF
```

Create the work Git config template:

```bash
cat > shared/git/.gitconfig-work.template <<'EOF'
[user]
    name = ${WORK_GIT_NAME}
    email = ${WORK_GIT_EMAIL}
    signingkey = ${WORK_GPG_KEY_ID}
EOF
```

---

## 8. Create SSH Config Template

Create the SSH config template:

```bash
mkdir -p shared/ssh

cat > shared/ssh/config.template <<'EOF'
Host ${PRIVATE_GIT_HOST_ALIAS}
    HostName ${PRIVATE_GIT_HOST_NAME}
    User git
    IdentityFile ~/.ssh/${PRIVATE_SSH_KEY_FILE}
    IdentitiesOnly yes

Host ${WORK_GIT_HOST_ALIAS}
    HostName ${WORK_GIT_HOST_NAME}
    User git
    IdentityFile ~/.ssh/${WORK_SSH_KEY_FILE}
    IdentitiesOnly yes
EOF
```

---

## 9. Render Templates Manually for Testing

Create a temporary generated folder:

```bash
mkdir -p /tmp/dev-setup-generated
```

Decrypt both env files:

```bash
sops --decrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/git.env.enc > /tmp/dev-setup-generated/git.env.dec

sops --decrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/ssh.env.enc > /tmp/dev-setup-generated/ssh.env.dec
```

Load the env values:

```bash
set -a
source /tmp/dev-setup-generated/git.env.dec
source /tmp/dev-setup-generated/ssh.env.dec
set +a
```

Render the templates:

```bash
envsubst < shared/git/.gitconfig-private.template > /tmp/dev-setup-generated/.gitconfig-private
envsubst < shared/git/.gitconfig-work.template > /tmp/dev-setup-generated/.gitconfig-work
envsubst < shared/ssh/config.template > /tmp/dev-setup-generated/ssh-config
```

Show generated files:

```bash
cat /tmp/dev-setup-generated/.gitconfig-private
cat /tmp/dev-setup-generated/.gitconfig-work
cat /tmp/dev-setup-generated/ssh-config
```

Expected private Git config:

```
[user]
    name = Test Private User
    email = 12345678+test-private@users.noreply.github.com
    signingkey = ABCDEF1234567890
```

Expected work Git config:

```
[user]
    name = Test Work User
    email = test.work@example.com
    signingkey = 1234567890ABCDEF
```

Expected SSH config:

```sshconfig
Host github.com-private
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_private
    IdentitiesOnly yes

Host bitbucket.org-work
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

---

## 10. Commit Encrypted Files

Before committing, check that no plain-text env files are left:

```bash
find shared/env -type f
```

This should show only:

```text
shared/env/git.env.enc
shared/env/ssh.env.enc
```

Then commit:

```bash
git add .sops.yaml shared/env/git.env.enc shared/env/ssh.env.enc shared/git shared/ssh
git commit -m "Add encrypted env setup"
```

---

## 11. Use on a New Device

Install tools:

```bash
sudo pacman -S --needed sops age gettext
```

Restore the private age key from your password manager:

```bash
mkdir -p ~/.config/sops/age
nano ~/.config/sops/age/keys.txt
chmod 700 ~/.config/sops
chmod 700 ~/.config/sops/age
chmod 600 ~/.config/sops/age/keys.txt
```

Paste the saved key content into:

```text
~/.config/sops/age/keys.txt
```

Clone the repository:

```bash
git clone git@github.com-private:bzmike/dev-setup.git
cd dev-setup
```

Test decryption:

```bash
sops --decrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/git.env.enc
```

If the plain-text test values are printed, the key works.

---

## 12. Rotate or Add More Devices

There are two approaches.

### Option A: Same age key on all devices

Store the same private age key in your password manager and restore it on every device.

Pros:

```text
simple
easy to manage
```

Cons:

```text
one shared secret for all devices
harder to revoke only one device
```

### Option B: One age key per device

Create a new age key on each device:

```bash
age-keygen -o ~/.config/sops/age/keys.txt
grep "public key:" ~/.config/sops/age/keys.txt
```

Add all public keys to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: shared/env/.*\.env\.enc$
    age: >-
      age1device1publickey...,
      age1device2publickey...,
      age1device3publickey...
```

Then update encrypted files:

```bash
sops updatekeys shared/env/git.env.enc
sops updatekeys shared/env/ssh.env.enc
```

Commit the updated files:

```bash
git add .sops.yaml shared/env/git.env.enc shared/env/ssh.env.enc
git commit -m "Update SOPS age recipients"
```

---

## Troubleshooting

### `no matching creation rules found`

This means `.sops.yaml` does not match the file path you are encrypting.

If your rule is:

```yaml
path_regex: shared/env/.*\.env\.enc$
```

then encrypt files named like:

```text
shared/env/git.env.enc
shared/env/ssh.env.enc
```

Or use this more flexible rule:

```yaml
creation_rules:
  - path_regex: shared/env/.*\.env(\.enc)?$
    age: age1examplepublickey000000000000000000000000000000000000
```

---

### Decrypted output looks like YAML or contains SOPS metadata

Use explicit dotenv input and output types:

```bash
sops --decrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/git.env.enc
```

Also encrypt with explicit types:

```bash
sops --encrypt \
  --input-type dotenv \
  --output-type dotenv \
  shared/env/git.env > shared/env/git.env.enc
```

---

### `failed to decrypt`

Check that the private age key exists:

```bash
ls -l ~/.config/sops/age/keys.txt
```

Check that the public key in `.sops.yaml` belongs to your private key:

```bash
grep "public key:" ~/.config/sops/age/keys.txt
```

The public key shown there must be listed in `.sops.yaml`.

---

### `envsubst: command not found`

Install `gettext`:

```bash
sudo pacman -S --needed gettext
```

---

## Summary

Use this workflow:

```text
1. Create age key
2. Store private age key in password manager
3. Add public age key to .sops.yaml
4. Create temporary plain-text env file
5. Encrypt it into *.env.enc
6. Delete the plain-text file
7. Commit only encrypted files
8. Restore age key on new devices
9. Decrypt and render templates locally
```
