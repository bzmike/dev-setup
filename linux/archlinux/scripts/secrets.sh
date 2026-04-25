#!/usr/bin/env bash

ensure_sops_age() {
  if ! command -v sops >/dev/null 2>&1; then
    log_error "sops is missing. Install it with: sudo pacman -S sops"
    return 1
  fi

  if ! command -v age >/dev/null 2>&1; then
    log_error "age is missing. Install it with: sudo pacman -S age"
    return 1
  fi

  if ! command -v envsubst >/dev/null 2>&1; then
    log_error "envsubst is missing. Install it with: sudo pacman -S gettext"
    return 1
  fi
}

parse_env_file() {
  local env_file="$1"

  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Trim whitespace around key
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"

    # Skip empty lines and comments
    [[ -z "$key" ]] && continue
    [[ "$key" =~ ^# ]] && continue

    # Skip SOPS/dotenv metadata if it ever appears
    [[ "$key" == sops_* ]] && continue
    [[ "$key" == DOTENV_PUBLIC_KEY* ]] && continue

    # Only allow valid shell variable names
    if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      log_warn "Skipping invalid env key from $env_file: $key"
      continue
    fi

    # Remove Windows CR and optional wrapping quotes
    value="${value%$'\r'}"
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"

    export "$key=$value"
  done < "$env_file"
}

render_template() {
  local template_file="$1"
  local output_file="$2"

  if [[ ! -f "$template_file" ]]; then
    log_error "Template file does not exist: $template_file"
    return 1
  fi

  mkdir -p "$(dirname "$output_file")"

  if envsubst < "$template_file" > "$output_file"; then
    log_success "Rendered template: $template_file -> $output_file"
  else
    log_error "Failed to render template: $template_file"
    return 1
  fi
}

decrypt_env_file() {
  local encrypted_file="$1"
  local decrypted_file="$2"
  local display_name="$3"

  log_info "Decrypting $display_name..."

  if ! sops --decrypt \
    --input-type dotenv \
    --output-type dotenv \
    "$encrypted_file" > "$decrypted_file"; then
    log_error "Failed to decrypt $display_name"
    return 1
  fi

  chmod 600 "$decrypted_file" 2>/dev/null || true
  log_success "Decrypted $display_name -> $decrypted_file"
}

prepare_encrypted_env_files() {
  local root_path="$1"
  local repo_root
  local env_root
  local generated_root
  local age_key_file
  local decrypted_git_env
  local decrypted_ssh_env

  repo_root="$(cd "$root_path/../.." && pwd)"
  env_root="$repo_root/shared/env"
  generated_root="$root_path/configs/generated"
  age_key_file="$HOME/.config/sops/age/keys.txt"

  decrypted_git_env="$generated_root/git.env.dec"
  decrypted_ssh_env="$generated_root/ssh.env.dec"

  log_info "Starting SOPS env preparation phase..."

  ensure_sops_age || return 1

  echo ""
  echo "SOPS + age secrets are required now."
  echo ""
  echo "Make sure your age private key exists here:"
  echo "$age_key_file"
  echo ""
  echo "If it does not exist, restore it from your password manager."
  echo ""
  echo "To create a new key instead, run:"
  echo "age-keygen -o $age_key_file"
  echo ""
  echo "The public key must be present in .sops.yaml."
  echo ""

  read -r -p "Press Enter to continue after the age key is ready..."

  if [[ ! -f "$age_key_file" ]]; then
    log_error "Missing age private key: $age_key_file"
    return 1
  fi

  chmod 600 "$age_key_file" 2>/dev/null || true

  if [[ ! -f "$env_root/git.env.enc" ]]; then
    log_error "Missing encrypted env file: $env_root/git.env.enc"
    return 1
  fi

  if [[ ! -f "$env_root/ssh.env.enc" ]]; then
    log_error "Missing encrypted env file: $env_root/ssh.env.enc"
    return 1
  fi

  mkdir -p "$generated_root"
  chmod 700 "$generated_root" 2>/dev/null || true

  decrypt_env_file "$env_root/git.env.enc" "$decrypted_git_env" "git.env.enc" || return 1
  decrypt_env_file "$env_root/ssh.env.enc" "$decrypted_ssh_env" "ssh.env.enc" || return 1

  parse_env_file "$decrypted_git_env"
  parse_env_file "$decrypted_ssh_env"

  render_template "$repo_root/shared/git/.gitconfig-private.template" "$generated_root/.gitconfig-private" || return 1
  render_template "$repo_root/shared/git/.gitconfig-work.template" "$generated_root/.gitconfig-work" || return 1
  render_template "$repo_root/shared/ssh/config.template" "$generated_root/ssh-config" || return 1

  chmod 600 \
    "$generated_root/.gitconfig-private" \
    "$generated_root/.gitconfig-work" \
    "$generated_root/ssh-config" \
    2>/dev/null || true

  log_success "SOPS env preparation phase completed."
}