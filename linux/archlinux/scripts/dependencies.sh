#!/usr/bin/env bash

install_dependencies() {
  local root_path="$1"
  local dependencies_file="$root_path/dependencies.json"

  log_info "Starting dependencies phase..."

  if [[ ! -f "$dependencies_file" ]]; then
    log_warn "No dependencies.json found. Skipping dependencies phase."
    return 0
  fi

  ensure_jq

  local package_count
  package_count="$(jq '.packages // [] | length' "$dependencies_file")"

  for ((i = 0; i < package_count; i++)); do
    local enabled
    local name
    local pacman_name

    enabled="$(jq -r ".packages[$i].enabled // true" "$dependencies_file")"
    name="$(jq -r ".packages[$i].name" "$dependencies_file")"
    pacman_name="$(jq -r ".packages[$i].pacman_name" "$dependencies_file")"

    if [[ "$enabled" == "false" ]]; then
      log_info "Skipping disabled dependency package: $name"
      continue
    fi

    log_info "Installing dependency package: $name ($pacman_name)"
    sudo pacman -S --needed --noconfirm "$pacman_name"
    log_success "Dependency package installed: $name"
  done

  local command_count
  command_count="$(jq '.commands // [] | length' "$dependencies_file")"

  for ((i = 0; i < command_count; i++)); do
    local required
    local name
    local command_name

    required="$(jq -r ".commands[$i].required // false" "$dependencies_file")"
    name="$(jq -r ".commands[$i].name" "$dependencies_file")"
    command_name="$(jq -r ".commands[$i].command" "$dependencies_file")"

    if [[ "$required" == "true" ]]; then
      log_info "Checking required command: $name ($command_name)"
      require_command "$command_name"
    else
      if command_exists "$command_name"; then
        log_success "Optional command found: $name ($command_name)"
      else
        log_warn "Optional command missing: $name ($command_name)"
      fi
    fi
  done

  log_success "Dependencies phase completed."
}