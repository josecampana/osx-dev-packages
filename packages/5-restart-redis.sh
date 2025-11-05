#!/usr/bin/env bash
# name: restart redis
# description: Restart Redis Service via Homebrew
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

is_redis_installed() {
  if has_brew; then
    brew list --versions redis >/dev/null 2>&1 && return 0
  fi

  command -v redis-server >/dev/null 2>&1 && return 0
  command -v redis-cli >/dev/null 2>&1 && return 0
  return 1
}

main() {
  if ! is_redis_installed; then
    log_error "Redis is not installed. Please install Redis first."
    return 1
  fi

  if has_brew; then
    brew services restart redis
    log_info "Redis service restarted via Homebrew."
  else
    log_error "Homebrew is not installed. Cannot restart Redis service."
    return 1
  fi

  return 0
}
main "$@"; exit $?