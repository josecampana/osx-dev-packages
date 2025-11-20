#!/usr/bin/env bash
# name: Verify SSH connectivity to GitHub
# description: Verify SSH connectivity to GitHub using ~/.ssh/id_ed25519
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"

main() {
  if ! has_cmd ssh; then
    log_error "ssh command not found."
    return 1
  fi

  # Usamos la clave por defecto; comprobamos que exista
  local ssh_dir="$HOME/.ssh"
  local key_path="$ssh_dir/id_ed25519"
  local pub_path="$ssh_dir/id_ed25519.pub"

  if [[ ! -f "$key_path" || ! -f "$pub_path" ]]; then
    log_error "Missing SSH key at ~/.ssh/id_ed25519. Run the GitHub SSH key package first."
    return 1
  fi

  output="$(ssh -T git@github.com 2>&1 || true)"

  if echo "$output" | grep -qi "successfully authenticated"; then
    log_info "SSH authentication to GitHub: OK"
    return 0
  fi

  # Error cases
  if echo "$output" | grep -qi "permission denied"; then
    log_error "Permission denied by GitHub. Ensure your public key is added to your GitHub account."
    return 1
  fi
  if echo "$output" | grep -qi "could not resolve host"; then
    log_error "Network/DNS error: could not resolve github.com."
    return 1
  fi
  if echo "$output" | grep -qi "no matching host key type"; then
    log_error "Host key mismatch. Update your OpenSSH or known_hosts."
    return 1
  fi
  if echo "$output" | grep -qi "unknown host key"; then
    log_error "Unknown host key. Try connecting once interactively to trust GitHub's host key."
    return 1
  fi

  # general failure: show output failure
  log_error "SSH verification failed. Output:"
  echo "$output"
  return 1
}

main "$@"; exit $?
