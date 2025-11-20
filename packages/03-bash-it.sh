#!/usr/bin/env bash
# name: Bash-it
# description: Bash-it, a collection of community Bash commands and scripts for Bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

main() {
  if [[ -d "$HOME/.bash_it" ]]; then
    log_info "Bash-it already installed."
    return 0
  fi

  git clone --depth=1 https://github.com/Bash-it/bash-it.git "$HOME/.bash_it"
  "$HOME/.bash_it/install.sh" --silent
  log_info "Bash-it installed."

  log_info "Remember to restart your terminal or run 'source ~/.bashrc' to apply the changes."

  return 0
}

main "$@"; exit $?