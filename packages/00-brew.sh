#!/usr/bin/env bash
# name: Homebrew
# description: Homebrew - Package Manager for macOS
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

brew_prefix() {
  brew --prefix 2>/dev/null || {
    # common fallback per arch
    if os_is_macos; then
      if [[ -d /opt/homebrew ]]; then echo /opt/homebrew
      elif [[ -d /usr/local ]]; then echo /usr/local
      else echo /usr/local; fi
    else
      echo "$(brew --prefix 2>/dev/null)"
    fi
  }
}

main() {
  if has_brew; then
      log_warn "Homebrew already installed: $(brew --version | head -n1)"
      brew update
      brew upgrade
      return 0
    fi

  if ! os_is_macos; then
    log_error "You are not in macOS, skipping Homebrew installation."
    return 0
  fi

  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add to current shell environment and persist in RC
  local prefix
  prefix="$(brew_prefix)"

  if [[ -n "$prefix" && -x "$prefix/bin/brew" ]]; then
    eval "$("$prefix/bin/brew" shellenv)"
    ensure_shellenv_brew "$prefix"
    log_info "Homebrew installed in: $prefix"
    return 0
  else
    log_warn "Could not detect brew prefix after installation."
    return 1
  fi
}

main "$@"; exit $?