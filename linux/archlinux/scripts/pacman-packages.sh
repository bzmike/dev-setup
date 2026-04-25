#!/usr/bin/env bash

install_pacman_packages() {
  local root_path="$1"
  local packages_file="$root_path/pacman-packages.json"

  log_info "Starting pacman packages phase..."

  if [[ ! -f "$packages_file" ]]; then
    log_warn "No pacman-packages.json found. Skipping pacman packages phase."
    return 0
  fi

  ensure_jq

  local package_count
  package_count="$(jq '.packages // [] | length' "$packages_file")"

  for ((i = 0; i < package_count; i++)); do
    local enabled
    local name
    local pacman_name

    enabled="$(jq -r ".packages[$i].enabled // true" "$packages_file")"
    name="$(jq -r ".packages[$i].name" "$packages_file")"
    pacman_name="$(jq -r ".packages[$i].pacman_name" "$packages_file")"

    if [[ "$enabled" == "false" ]]; then
      log_info "Skipping disabled pacman package: $name"
      continue
    fi

    log_info "Installing or updating pacman package: $name ($pacman_name)"

    if sudo pacman -S --needed --noconfirm "$pacman_name"; then
      log_success "Pacman package installed or already present: $name"
    else
      log_error "Failed to install pacman package: $name ($pacman_name)"
      continue
    fi
  done

  log_success "Pacman packages phase completed."
}