#!/usr/bin/env bash
# name: node lts
# description: Node LTS (via nvm)
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

main() {
  if ! load_nvm; then
    log_error "nvm is not installed or not loadable. Install NVM and ensure your RC loads it."
    return 1
  fi

  nvm install --lts
  nvm alias default 'lts/*' >/dev/null 2>&1 || true

  if node -v >/dev/null 2>&1; then
    log_info "node lts installed: $(node -v)"
  else
    log_warn "node seems installed, but 'node -v' did not return a version."
  fi
  return 0
}

main "$@"; exit $?
