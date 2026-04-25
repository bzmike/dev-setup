#!/usr/bin/env bash
set -euo pipefail

echo "[Python] Installing pyenv dependencies..."

sudo pacman -S --needed --noconfirm \
  pyenv \
  base-devel \
  openssl \
  zlib \
  xz \
  tk \
  sqlite \
  bzip2 \
  readline \
  libffi \
  ncurses

echo "[Python] pyenv installed."

if ! grep -q 'PYENV_ROOT' "$HOME/.bashrc" 2>/dev/null; then
  cat <<'EOF' >> "$HOME/.bashrc"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
EOF
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init - bash)"

echo "[Python] Detecting latest stable Python version..."

LATEST_PYTHON_VERSION="$(
  pyenv install --list \
    | sed 's/^[[:space:]]*//' \
    | grep -E '^3\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n 1
)"

if [[ -z "$LATEST_PYTHON_VERSION" ]]; then
  echo "[Python] Could not detect latest stable Python version."
  exit 1
fi

echo "[Python] Latest stable Python version: $LATEST_PYTHON_VERSION"

if ! pyenv versions --bare | grep -qx "$LATEST_PYTHON_VERSION"; then
  echo "[Python] Installing Python $LATEST_PYTHON_VERSION..."
  pyenv install "$LATEST_PYTHON_VERSION"
else
  echo "[Python] Python $LATEST_PYTHON_VERSION is already installed."
fi

pyenv global "$LATEST_PYTHON_VERSION"
pyenv rehash

echo "[Python] Installed:"
python --version
pip --version
pyenv --version