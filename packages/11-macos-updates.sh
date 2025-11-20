#!/usr/bin/env bash
# name: macos-software-updates
# description: macOS Software Updates (no icloud account needed)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"

main() {
  log_info "Checking for available updates..."
  UPDATES=$(softwareupdate -l | grep "Label:" | sed 's/^[[:space:]]*\* *Label: //')
  
  if [ -z "$UPDATES" ]; then
    log_info "No updates available."
    exit 0
  fi

  UPDATE_ARRAY=()
  while IFS= read -r line; do
    UPDATE_ARRAY+=("$line")
  done <<< "$UPDATES"

  if [ ${#UPDATE_ARRAY[@]} -eq 0 ]; then
    log_error "No updates parsed. Raw value: $UPDATES"
    exit 1
  fi

  log_info "Updates found: ${#UPDATE_ARRAY[@]}"
  echo

  for i in "${!UPDATE_ARRAY[@]}"; do
    echo "$((i+1))) ${UPDATE_ARRAY[$i]}"
  done

  echo
  read -p "Select a package (1-${#UPDATE_ARRAY[@]}): " CHOICE

  # Convert selection to real index
  INDEX=$((CHOICE-1))

  if [ $INDEX -lt 0 ] || [ $INDEX -ge ${#UPDATE_ARRAY[@]} ]; then
      log_warn "invalid selection... Exiting."
      exit 0
  fi

  SELECTED="${UPDATE_ARRAY[$INDEX]}"
  log_info "➡️  $SELECTED"

  # Detectar si requiere reinicio
  DETAILS=$(softwareupdate -l | grep -A3 "$SELECTED")
  if echo "$DETAILS" | grep -qi "restart"; then
      log_info "This update requires a restart."
      sudo softwareupdate -i --verbose "$SELECTED" --restart
      log_info "System will restart to complete the update."
  else
      sudo softwareupdate -i --verbose "$SELECTED"
  fi

}

main "$@"; exit $?