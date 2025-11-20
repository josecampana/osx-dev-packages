#!/usr/bin/env bash
# name: nvm
# description: NVM (Node Version Manager)
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

main() {
  if [[ -d "$HOME/.nvm" ]]; then
    log_info "NVM already installed at ~/.nvm"
  else
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    log_info "NVM installed."
  fi

  # Ensure RC has the NVM lines
  while IFS= read -r rc; do
    append_once "$rc" 'export NVM_DIR="$HOME/.nvm"'
    append_once "$rc" '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    append_once "$rc" '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
  done < <(detect_shell_rcs)

  log_info "You may need to reload your shell: 'source ~/.bashrc' or 'exec $SHELL -l'"
  return 0
}

main "$@"; exit $?
