#!/usr/bin/env bash
# name: macos-software-updates
# description: macOS Software Updates
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"

main() {
  log_info "Checking for macOS software updates..."
  sudo softwareupdate -ia --verbose

  log_info "macOS software updates completed."
}

main "$@"; exit $?