#!/usr/bin/env bash

install_language_setups() {
  local root_path="$1"
  local languages_file="$root_path/languages.json"
  local languages_root="$root_path/scripts/languages"

  log_info "Starting language setup phase..."

  if [[ ! -f "$languages_file" ]]; then
    log_warn "No languages.json found. Skipping language setup phase."
    return 0
  fi

  ensure_jq

  local language_count
  language_count="$(jq '.languages // [] | length' "$languages_file")"

  for ((i = 0; i < language_count; i++)); do
    local enabled
    local name
    local script
    local script_path

    enabled="$(jq -r ".languages[$i].enabled // true" "$languages_file")"
    name="$(jq -r ".languages[$i].name" "$languages_file")"
    script="$(jq -r ".languages[$i].script" "$languages_file")"
    script_path="$languages_root/$script"

    if [[ "$enabled" == "false" ]]; then
      log_info "Skipping disabled language setup: $name"
      continue
    fi

    if [[ ! -f "$script_path" ]]; then
      log_error "Language setup script not found for $name: $script_path"
      continue
    fi

    log_info "Running language setup: $name"

    if bash "$script_path"; then
      log_success "Language setup completed: $name"
    else
      log_error "Language setup failed: $name"
      continue
    fi
  done

  log_success "Language setup phase completed."
}