#!/usr/bin/env bash

install_shell_setup() {
  local root_path="$1"
  local generated_configs_dir="$root_path/configs/generated"
  local generated_theme="$generated_configs_dir/tokyo.omp.json"

  log_info "Starting shell phase..."

  if [[ "$(id -u)" -eq 0 ]]; then
    log_error "Do not run the Arch setup as root. Run it as your normal WSL user."
    return 1
  fi

  log_info "Installing shell dependencies..."
  sudo pacman -S --needed --noconfirm fish curl unzip coreutils

  mkdir -p "$HOME/.local/bin"
  mkdir -p "$HOME/bin"
  mkdir -p "$generated_configs_dir"

  log_info "Installing or updating Oh My Posh..."
  curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"

  export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

  if ! command -v oh-my-posh >/dev/null 2>&1; then
    log_error "Oh My Posh was installed, but is not available in PATH."
    return 1
  fi

  log_success "Oh My Posh installed: $(command -v oh-my-posh)"
  log_info "Oh My Posh version: $(oh-my-posh --version)"

  if [[ ! -f "$generated_theme" ]]; then
    log_info "Generating Oh My Posh tokyo theme: $generated_theme"

    if oh-my-posh config export --config tokyo --output "$generated_theme"; then
      log_success "Generated Oh My Posh theme: $generated_theme"
    else
      log_error "Failed to generate Oh My Posh theme."
      return 1
    fi
  else
    log_info "Oh My Posh generated theme already exists: $generated_theme"
  fi

  if ! grep -qxF "/usr/bin/fish" /etc/shells; then
    log_info "Adding /usr/bin/fish to /etc/shells..."
    echo "/usr/bin/fish" | sudo tee -a /etc/shells >/dev/null
  fi

  local current_shell
  current_shell="$(getent passwd "$USER" | cut -d: -f7)"

  if [[ "$current_shell" != "/usr/bin/fish" ]]; then
    log_info "Setting fish as default shell for user: $USER"
    sudo usermod --shell /usr/bin/fish "$USER"
    log_warn "Fish is now configured as default shell. Restart WSL after setup."
  else
    log_info "Fish is already the default shell."
  fi

  log_success "Shell phase completed."
}