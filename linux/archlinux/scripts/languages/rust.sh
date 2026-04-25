#!/usr/bin/env bash
set -euo pipefail

echo "[Rust] Installing rustup..."

sudo pacman -S --needed --noconfirm rustup

if ! rustup toolchain list | grep -q "stable"; then
  rustup toolchain install stable
fi

rustup default stable

echo "[Rust] Installed:"
rustc --version
cargo --version