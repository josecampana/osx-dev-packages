#!/usr/bin/env bash
# name: redis
# description: Redis as a Service (via Homebrew)
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

check_redis_ok() {
  local host="${1:-127.0.0.1}"
  local port="${2:-6379}"
  local expected="${3:-PONG}"
  local attempts="${4:-10}"
  local sleep_secs="${5:-1}"

  local reply=""
  local i=1
  while [ "$i" -le "$attempts" ]; do
    if [ "$expected" = "PONG" ]; then
      reply="$(redis-cli -h "$host" -p "$port" ping 2>/dev/null || true)"
    else
      reply="$(redis-cli -h "$host" -p "$port" ping "$expected" 2>/dev/null || true)"
    fi

    if [ "$reply" = "$expected" ]; then
      log_info "Redis OK: responded '$reply' at $host:$port"
      return 0
    fi

    sleep "$sleep_secs"
    i=$((i+1))
  done

  log_error "Redis did not respond '$expected' after $attempts attempts. Last response: '$reply'"
  return 1
}


main() {
  if is_redis_installed; then
    log_info "Redis already installed. Skipping installation."
    return 0
  fi

  if ! has_brew; then
    log_error "Homebrew is not installed."
    return 1
  fi

  brew update
  brew install redis
  log_info "Starting Redis as a service..."
  brew services start redis

  if check_redis_ok "127.0.0.1" "6379" "PONG" "10" "1"; then
    log_info "Installation OK: Redis is responding."
    return 0
  else
    log_error "Installation does not seem correct. Check 'brew services list' and logs."
    return 1
  fi

}

main "$@"; exit $?