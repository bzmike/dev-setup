#!/usr/bin/env bash
set -euo pipefail

echo "[Node.js] Installing nvm..."

sudo pacman -S --needed --noconfirm nvm

if ! grep -q '/usr/share/nvm/init-nvm.sh' "$HOME/.bashrc" 2>/dev/null; then
  cat <<'EOF' >> "$HOME/.bashrc"

# nvm
source /usr/share/nvm/init-nvm.sh
EOF
fi

if [[ -f "/usr/share/nvm/init-nvm.sh" ]]; then
  # shellcheck disable=SC1091
  source /usr/share/nvm/init-nvm.sh
else
  echo "[Node.js] nvm init script not found."
  exit 1
fi

echo "[Node.js] Installing latest LTS Node.js..."

nvm install --lts
nvm alias default 'lts/*'
nvm use default

echo "[Node.js] Installed:"
node --version
npm --version