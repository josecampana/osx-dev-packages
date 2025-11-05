#!/usr/bin/env bash
# name: vscode
# description: Visual Studio Code Editor (Universal OSX)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"

download() {
  local url="$1" out="$2"
  log_info "Downloading: $url"
  curl -fsSL "$url" -o "$out"
  log_info "Saved to: $out"
}

install_macos() {
  # Prefer universal build; fallback to arch-specific if needed
  local os_id="darwin-universal"
  case "$(arch_name)" in
    arm64) os_id="darwin-arm64" ;;
    x86_64) os_id="darwin" ;; # Intel
  esac

  # Official update feed (returns a ZIP)
  local url="https://update.code.visualstudio.com/latest/${os_id}/stable"
  local zip="/tmp/VSCode.zip"
  local tmp_dir="/tmp/vscode_unzip.$"

  log_info "Downloading VSCode ZIP (${os_id})..."
  rm -f "$zip"
  curl -fL --retry 3 --retry-delay 2 -o "$zip" "$url"

  # Sanity check download
  if [[ ! -s "$zip" ]]; then
    log_error "Download failed or empty file: $zip"
    return 1
  fi

  log_info "Extracting ZIP..."
  mkdir -p "$tmp_dir"
  if ! unzip -q "$zip" -d "$tmp_dir"; then
    log_error "Failed to unzip VS Code archive."
    rm -rf "$tmp_dir" "$zip"
    return 1
  fi

  # Find the app bundle inside the extracted content
  local app_path
  app_path="$(find "$tmp_dir" -maxdepth 2 -name 'Visual Studio Code.app' -print -quit)"
  if [[ -z "$app_path" || ! -d "$app_path" ]]; then
    log_error "Could not find 'Visual Studio Code.app' in the archive."
    rm -rf "$tmp_dir" "$zip"
    return 1
  fi

  log_info "Installing to /Applications..."
  # Remove existing app (optional; comment this if you prefer to keep existing)
  if [[ -d "/Applications/Visual Studio Code.app" ]]; then
    rm -rf "/Applications/Visual Studio Code.app"
  fi
  cp -R "$app_path" "/Applications/"

  # Clean up
  rm -rf "$tmp_dir" "$zip"

  log_info "Launching VS Code to complete setup..."
  open "/Applications/Visual Studio Code.app"

  # Install 'code' CLI symlink
  # local code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  # if [[ -x "$code_bin" ]]; then
  #   if [[ -w /usr/local/bin ]]; then
  #     ln -sf "$code_bin" /usr/local/bin/code
  #     log_info "Installed 'code' to /usr/local/bin/code"
  #   else
  #     log_info "Installing 'code' to /usr/local/bin with sudo..."
  #     run_maybe_sudo "ln -sf \"$code_bin\" /usr/local/bin/code"
  #   fi
  # else
  #   log_warn "VS Code installed, but 'code' CLI not found inside the app bundle."
  # fi

  # log_info "VS Code installed. Try: code --version"
  return 0
}


install_linux_deb() {
  local arch="x64"
  case "$(arch_name)" in
    arm64) arch="arm64" ;;
    x86_64) arch="x64" ;;
    *) log_warn "Unknown arch for Debian-based install; defaulting to x64." ;;
  esac
  local url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$arch"
  local deb="/tmp/code_latest.deb"
  download "$url" "$deb"

  log_info "Installing .deb (requires sudo)..."
  run_maybe_sudo "dpkg -i \"$deb\" || apt-get -f install -y"
  rm -f "$deb"
  log_info "VS Code installed. Try: code --version"
}

install_linux_rpm() {
  local arch="x64"
  case "$(arch_name)" in
    arm64) arch="arm64" ;;
    x86_64) arch="x64" ;;
    *) log_warn "Unknown arch for RPM install; defaulting to x64." ;;
  esac
  local url="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-$arch"
  local rpm="/tmp/code_latest.rpm"
  download "$url" "$rpm"

  log_info "Installing .rpm (requires sudo)..."
  # Prefer dnf, fallback to yum
  if has_cmd dnf; then
    run_maybe_sudo "dnf install -y \"$rpm\""
  elif has_cmd yum; then
    run_maybe_sudo "yum install -y \"$rpm\""
  else
    log_error "Neither dnf nor yum found. Install the RPM manually: $rpm"
    return 1
  fi
  rm -f "$rpm"
  log_info "VS Code installed. Try: code --version"
}

main() {
  if os_is_macos; then
    install_macos
    return $?
  fi

  if os_is_linux; then
    if has_cmd apt-get || has_cmd dpkg; then
      install_linux_deb
      return $?
    elif has_cmd dnf || has_cmd yum || has_cmd rpm; then
      install_linux_rpm
      return $?
    else
      log_error "Unsupported Linux package manager. Use the official tarball from https://code.visualstudio.com/ and install manually."
      return 1
    fi
  fi

  log_error "Unsupported OS. This script handles macOS and common Linux distros."
  return 1

}
main "$@"; exit $?