#!/usr/bin/env bash
set -euo pipefail

echo "[PHP] Installing PHP and Composer..."

sudo pacman -S --needed --noconfirm php composer

echo "[PHP] Installed:"
php --version
composer --version