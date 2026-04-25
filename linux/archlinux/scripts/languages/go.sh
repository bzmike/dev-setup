#!/usr/bin/env bash
set -euo pipefail

echo "[Go] Installing Go..."

sudo pacman -S --needed --noconfirm go

echo "[Go] Installed:"
go version