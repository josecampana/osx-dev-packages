#!/usr/bin/env bash
# name: GitHub SSH key (minimal)
# description: Generate ~/.ssh/id_ed25519 (GitHub SSH key)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"

get_git_global() { git config --global --get "$1" 2>/dev/null || true; }

main() {
  if ! has_cmd git; then
    log_error "Git is not installed or not in PATH."
    return 1
  fi

  # Get email from ~/.gitconfig
  local git_email
  git_email="$(get_git_global user.email)"
  if [[ -z "$git_email" ]]; then
    log_error "No global user.email found in ~/.gitconfig. Run the 'git global config' package first."
    return 1
  fi
  log_info "Using git global user.email: $git_email"

  # Paths
  local ssh_dir="$HOME/.ssh"
  local key_path="$ssh_dir/id_ed25519"
  local pub_path="$ssh_dir/id_ed25519.pub"
  local config_path="$ssh_dir/config"

  # Ensure ~/.ssh exists with secure perms
  if [[ -d "$ssh_dir" ]]; then
    chmod 700 "$ssh_dir" 2>/dev/null || true
  else
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
  fi

  # Generate key if not exists
  if [[ -f "$key_path" && -f "$pub_path" ]]; then
    log_info "SSH key already exists at $key_path"
  else
    log_info "Generating ed25519 SSH key at $key_path (comment: $git_email)..."
    # Passphrase opcional (si quieres permitirla, descomenta la línea de prompt)
    # read -r -p "Enter a passphrase (optional, press Enter for none): " passphrase
    local passphrase="${passphrase:-}"
    if [[ -n "$passphrase" ]]; then
      ssh-keygen -t ed25519 -C "$git_email" -f "$key_path" -N "$passphrase"
    else
      ssh-keygen -t ed25519 -C "$git_email" -f "$key_path" -N ""
    fi
    chmod 600 "$key_path"
    chmod 644 "$pub_path"
    log_info "SSH key generated."
  fi

  # Start ssh-agent if needed and add key
  if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    log_info "Starting ssh-agent..."
    eval "$(ssh-agent -s)" >/dev/null
  fi

  log_info "Adding SSH key to agent..."
  if os_is_macos && ssh-add -h 2>&1 | grep -q -- "--apple-use-keychain"; then
    ssh-add --apple-use-keychain "$key_path"
  else
    ssh-add "$key_path"
  fi

  # Show public key to paste into GitHub
  log_info "Copy this public key to GitHub → Settings → SSH and GPG keys → New SSH key:"
  echo "----- BEGIN PUBLIC KEY -----"
  cat "$pub_path"
  echo "----- END PUBLIC KEY -----"
  echo "In GitHub: Settings → SSH and GPG keys → New SSH key → paste the key, add a title (ex. 'MacBook Pro')"

  # Create/update ~/.ssh/config (without duplication), then secure perms
  append_once "$config_path" "Host github.com"
  append_once "$config_path" "  HostName github.com"
  append_once "$config_path" "  User git"
  append_once "$config_path" "  AddKeysToAgent yes"
  append_once "$config_path" "  IdentitiesOnly yes"
  append_once "$config_path" "  IdentityFile ~/.ssh/id_ed25519"
  if os_is_macos; then
    append_once "$config_path" "  UseKeychain yes"
  fi
  chmod 600 "$config_path" 2>/dev/null || true

  return 0
}

main "$@"; exit $?
