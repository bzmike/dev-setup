#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="$SCRIPT_ROOT/scripts"

source "$SCRIPTS_ROOT/common.sh"
source "$SCRIPTS_ROOT/dependencies.sh"
source "$SCRIPTS_ROOT/pacman-packages.sh"
source "$SCRIPTS_ROOT/languages.sh"
source "$SCRIPTS_ROOT/secrets.sh"
source "$SCRIPTS_ROOT/configs.sh"

init_logging "$SCRIPT_ROOT"

log_info "Starting Arch Linux dev setup..."

install_dependencies "$SCRIPT_ROOT"
install_pacman_packages "$SCRIPT_ROOT"
install_language_setups "$SCRIPT_ROOT"
prepare_encrypted_env_files "$SCRIPT_ROOT"
copy_config_files "$SCRIPT_ROOT"

# shellcheck disable=SC1090
source ~/.bashrc

log_success "Arch Linux dev setup completed."
log_info "Log file: $LOG_FILE"

log_warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
log_warn "IMPORTANT: YOU MUST NOW EDIT ~/.gitconfig-work."
log_warn "YOU MUST ENTER YOUR WORK EMAIL ADDRESS IN THAT FILE."
log_warn "YOU MUST ENTER THE CORRECT GPG SIGNING KEY IN THAT FILE."
log_warn "IMPORTANT: YOU MUST NOW EDIT ~/.gitconfig-private."
log_warn "YOU MUST ENTER YOUR PRIVATE EMAIL ADDRESS IN THAT FILE."
log_warn "YOU MUST ENTER THE CORRECT GPG SIGNING KEY IN THAT FILE."
log_warn "YOU MUST CHANGE THE SSH CONFIG FILE."
log_warn "WITHOUT THIS CHANGES, YOUR GIT CONFIGURATION WILL BE WRONG."
log_warn "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"