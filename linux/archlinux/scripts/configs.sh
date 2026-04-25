#!/usr/bin/env bash

resolve_user_path() {
  local path="$1"

  if [[ "$path" == "~/"* ]]; then
    echo "$HOME/${path#"~/"}"
  elif [[ "$path" == "~" ]]; then
    echo "$HOME"
  else
    echo "$path"
  fi
}

create_backup() {
  local target_path="$1"

  if [[ ! -f "$target_path" ]]; then
    return 0
  fi

  local target_dir
  local target_file
  local backup_dir
  local backup_path
  local timestamp

  target_dir="$(dirname "$target_path")"
  target_file="$(basename "$target_path")"
  backup_dir="$target_dir/.backup"
  timestamp="$(date +"%Y%m%d-%H%M%S")"
  backup_path="$backup_dir/$target_file.$timestamp.bak"

  mkdir -p "$backup_dir"
  cp "$target_path" "$backup_path"

  log_success "Created backup: $backup_path"
}

apply_permissions() {
  local target_path="$1"
  local mode="$2"
  local directory_mode="$3"

  local target_dir
  target_dir="$(dirname "$target_path")"

  if [[ -n "$directory_mode" && "$directory_mode" != "null" ]]; then
    if chmod "$directory_mode" "$target_dir"; then
      log_success "Applied directory mode $directory_mode to: $target_dir"
    else
      log_error "Failed to apply directory mode $directory_mode to: $target_dir"
      return 1
    fi
  fi

  if [[ -n "$mode" && "$mode" != "null" ]]; then
    if chmod "$mode" "$target_path"; then
      log_success "Applied file mode $mode to: $target_path"
    else
      log_error "Failed to apply file mode $mode to: $target_path"
      return 1
    fi
  fi
}

copy_config_files() {
  local root_path="$1"
  local configs_file="$root_path/configs.json"
  local configs_root="$root_path/configs"

  log_info "Starting configs phase..."

  if [[ ! -f "$configs_file" ]]; then
    log_warn "No configs.json found. Skipping configs phase."
    return 0
  fi

  ensure_jq

  local group_count
  group_count="$(jq '.config_groups // [] | length' "$configs_file")"

  for ((g = 0; g < group_count; g++)); do
    local group_enabled
    local group_name

    group_enabled="$(jq -r ".config_groups[$g].enabled // true" "$configs_file")"
    group_name="$(jq -r ".config_groups[$g].name" "$configs_file")"

    if [[ "$group_enabled" == "false" ]]; then
      log_info "Skipping disabled config group: $group_name"
      continue
    fi

    log_info "Processing config group: $group_name"

    local file_count
    file_count="$(jq ".config_groups[$g].files // [] | length" "$configs_file")"

    for ((f = 0; f < file_count; f++)); do
      local source
      local source_base
      local target
      local overwrite
      local backup
      local mode
      local directory_mode
      local source_path
      local target_path
      local target_dir
      local repo_root

      source="$(jq -r ".config_groups[$g].files[$f].source" "$configs_file")"
      source_base="$(jq -r ".config_groups[$g].files[$f].source_base // \"local\"" "$configs_file")"
      target="$(jq -r ".config_groups[$g].files[$f].target" "$configs_file")"
      overwrite="$(jq -r ".config_groups[$g].files[$f].overwrite // true" "$configs_file")"
      backup="$(jq -r ".config_groups[$g].files[$f].backup // false" "$configs_file")"
      mode="$(jq -r ".config_groups[$g].files[$f].mode // empty" "$configs_file")"
      directory_mode="$(jq -r ".config_groups[$g].files[$f].directory_mode // empty" "$configs_file")"

      case "$source_base" in
        "local")
          source_path="$configs_root/$source"
          ;;
        "shared")
          repo_root="$(cd "$root_path/../.." && pwd)"
          source_path="$repo_root/shared/$source"
          ;;
        *)
          log_error "Invalid source_base '$source_base' for config source: $source"
          continue
          ;;
      esac

      target_path="$(resolve_user_path "$target")"
      target_dir="$(dirname "$target_path")"

      if [[ ! -f "$source_path" ]]; then
        log_error "Source config does not exist: $source_path"
        continue
      fi

      mkdir -p "$target_dir"

      if [[ -f "$target_path" && "$overwrite" == "false" ]]; then
        log_warn "Target exists and overwrite is disabled. Skipping: $target_path"
        continue
      fi

      if [[ -f "$target_path" && "$overwrite" == "true" && "$backup" == "true" ]]; then
        create_backup "$target_path"
      fi

      if cp "$source_path" "$target_path"; then
        log_success "Copied config: $source_path -> $target_path"
      else
        log_error "Failed to copy config: $source_path -> $target_path"
        continue
      fi

      if ! apply_permissions "$target_path" "$mode" "$directory_mode"; then
        log_error "Failed to apply permissions for: $target_path"
        continue
      fi
    done
  done

  log_success "Configs phase completed."
}