#!/usr/bin/env bash
# name: xcode-cli
# description: XCode Command Line Tools
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"

main() {
  if xcode-select -p &>/dev/null; then
    log_info "XCode Command Line Tools already installed."
    return 0
  fi

  log_info "XCode Command Line Tools not found. Installing..."
  # This command will prompt a GUI dialog for installation
  sudo xcode-select --install

  log_info "Waiting for XCode Command Line Tools installation to complete..."
  # Wait until the tools are installed
  until xcode-select -p &>/dev/null; do
    sleep 5
  done

  log_info "XCode Command Line Tools installation completed."
}

main "$@"; exit $?