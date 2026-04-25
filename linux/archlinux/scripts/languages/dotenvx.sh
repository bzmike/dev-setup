#!/usr/bin/env bash
set -euo pipefail

echo "[dotenvx] Installing dotenvx..."

if ! command -v npm >/dev/null 2>&1; then
  echo "[dotenvx] npm is missing. Install Node.js first."
  exit 1
fi

npm install -g @dotenvx/dotenvx

echo "[dotenvx] Installed:"
dotenvx --version