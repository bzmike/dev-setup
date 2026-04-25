#!/usr/bin/env bash

LOG_FILE=""

init_logging() {
  local root_path="$1"
  local log_dir="$root_path/logs"

  mkdir -p "$log_dir"

  LOG_FILE="$log_dir/install-$(date +"%Y-%m-%d-%H-%M-%S").log"
}

log() {
  local level="$1"
  local message="$2"
  local timestamp

  timestamp="$(date +"%Y-%m-%d %H:%M:%S")"

  echo "[$timestamp] [$level] $message"

  if [[ -n "$LOG_FILE" ]]; then
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  fi
}

log_info() {
  log "INFO" "$1"
}

log_warn() {
  log "WARN" "$1"
}

log_error() {
  log "ERROR" "$1"
}

log_success() {
  log "SUCCESS" "$1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_command() {
  local command_name="$1"

  if ! command_exists "$command_name"; then
    log_error "Required command is missing: $command_name"
    return 1
  fi

  log_success "Required command found: $command_name"
}

read_json() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    log_error "JSON file not found: $file"
    return 1
  fi

  cat "$file"
}

ensure_jq() {
  if command_exists jq; then
    return 0
  fi

  log_warn "jq is missing. Installing jq..."
  sudo pacman -S --needed --noconfirm jq
}