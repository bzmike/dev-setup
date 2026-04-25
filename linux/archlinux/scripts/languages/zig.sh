#!/usr/bin/env bash
set -euo pipefail

echo "[Zig] Installing Zig..."

sudo pacman -S --needed --noconfirm zig

echo "[Zig] Installed:"
zig version