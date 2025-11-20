#!/usr/bin/env bash
# name: gcloud-cli
# description: Google Cloud SDK CLI
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"
URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm.tar.gz?hl=es"
FILENAME="google-cloud-cli-darwin-arm.tar.gz"

main() {
  log_info "Downloading Google Cloud SDK CLI for Darwin ARM..."
  curl -L "$URL" -o "$FILENAME"
  tar -xzf "$FILENAME"

  log_info "🚀 Launching installer..."
  cd google-cloud-sdk
  ./install.sh

  echo "➡️ Adding gcloud to PATH (only for current session)..."
  source "$HOME/.bashrc" 2>/dev/null || true
  source "$HOME/.zshrc" 2>/dev/null || true

  echo
  echo "🔧 Starting gcloud configuration..."
  gcloud init
}

main "$@"; exit $?