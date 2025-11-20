#!/usr/bin/env bash
# name: git global config
# description: Git global configuration (interactive)
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Reutiliza tus helpers del common
# shellcheck disable=SC1090
source "$SCRIPT_DIR/../lib/common.sh"

# Helpers locales
get_current() { git config --global --get "$1" 2>/dev/null || true; }

prompt_def() {
  # Uso: prompt_def "Message" varname "default"
  local msg="$1" var="$2" def="${3:-}"
  local ans=""
  if [[ -n "$def" ]]; then
    read -r -p "$msg [$def]: " ans
    ans="${ans:-$def}"
  else
    read -r -p "$msg: " ans
  fi
  printf -v "$var" "%s" "$ans"
}

validate_email() {
  local email="${1:-}"
  [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

set_global() {
  local key="$1" val="$2"
  if [[ -n "$val" ]]; then
    git config --global "$key" "$val"
    log_info "Set $key=$val"
  fi
}

choose_editor_default() {
  # Usa tus helpers has_cmd para sugerir editor
  local guess=""
  if has_cmd code; then
    guess="code --wait"
  elif has_cmd nano; then
    guess="nano"
  elif has_cmd vim; then
    guess="vim"
  elif has_cmd nvim; then
    guess="nvim"
  fi
  echo "$guess"
}

configure_gitignore_global() {
  # Opcional: configurar un ~/.gitignore_global con entradas comunes
  local ans=""
  if confirm "Configure a global .gitignore? [y/N]"; then
    local path="$HOME/.gitignore_global"
    touch "$path"
    # Entradas comunes; se añaden solo si no existen
    append_once "$path" "# Global Git ignore"
    append_once "$path" ".DS_Store"
    append_once "$path" "Thumbs.db"
    append_once "$path" "node_modules/"
    append_once "$path" "dist/"
    append_once "$path" "build/"
    append_once "$path" "*.log"
    append_once "$path" "*.tmp"
    append_once "$path" "*.swp"
    append_once "$path" ".env"
    append_once "$path" ".env.*"
    set_global core.excludesfile "$path"
    log_info "Global .gitignore configured at $path"
  fi
}

# Fijar una clave si está sin valor
set_default_if_unset() {
  local key="$1" val="$2"
  local cur
  cur="$(get_current "$key")"
  if [[ -z "$cur" ]]; then
    git config --global "$key" "$val"
    log_info "Default applied: $key=$val"
  fi
}

# Aplicar baseline si no existe ~/.gitconfig, y rellenar claves vacías
ensure_git_baseline_defaults() {
  local gitconfig="$HOME/.gitconfig"
  if [[ ! -f "$gitconfig" ]]; then
    log_info "No ~/.gitconfig found. Applying baseline defaults..."
    git config --global init.defaultBranch "main"
    git config --global core.editor "code --wait"
    git config --global pull.rebase "false"
    git config --global merge.ff "false"
    git config --global core.autocrlf "input"
    git config --global credential.helper "store"
    return 0
  fi
  # Si existe, aún podemos rellenar claves que estén sin valor:
  set_default_if_unset init.defaultBranch "main"
  set_default_if_unset core.editor "code --wait"
  set_default_if_unset pull.rebase "false"
  set_default_if_unset merge.ff "false"
  set_default_if_unset core.autocrlf "input"
  set_default_if_unset credential.helper "store"
}

main() {
  if ! has_cmd git; then
    log_error "Git is not installed or not in PATH."
    return 1
  fi

  # Baseline por si es la primera vez
  ensure_git_baseline_defaults

  log_info "Configuring global Git settings..."

  # Defaults existentes
  local def_name def_email def_branch def_editor def_pull_rebase def_merge_ff def_autocrlf def_cred_helper
  def_name="$(get_current user.name)"
  def_email="$(get_current user.email)"
  def_branch="$(get_current init.defaultBranch)"
  def_editor="$(get_current core.editor)"
  def_pull_rebase="$(get_current pull.rebase)"
  def_merge_ff="$(get_current merge.ff)"
  def_autocrlf="$(get_current core.autocrlf)"
  def_cred_helper="$(get_current credential.helper)"

  # Nombre y email
  local name email
  prompt_def "Your name (user.name)" name "${def_name:-}"
  while true; do
    prompt_def "Your email (user.email)" email "${def_email:-}"
    if validate_email "$email"; then
      break
    else
      log_warn "Email format looks invalid. Try again."
    fi
  done

  # Default branch
  local branch
  prompt_def "Default branch name (init.defaultBranch)" branch "${def_branch:-main}"
  [[ -z "$branch" ]] && branch="main"

  # Editor
  local editor_default
  editor_default="$(choose_editor_default)"
  if [[ -z "${def_editor:-}" && -n "$editor_default" ]]; then
    def_editor="$editor_default"
  fi
  local editor
  prompt_def "Preferred editor (core.editor)" editor "${def_editor:-}"

  # pull.rebase
  local pull_rebase
  prompt_def "Use rebase on pull? (pull.rebase) [true/false]" pull_rebase "${def_pull_rebase:-false}"
  case "$pull_rebase" in
    true|false) ;;
    *) log_warn "Invalid value; defaulting to 'false'"; pull_rebase="false" ;;
  esac

  # merge.ff
  local merge_ff
  prompt_def "Allow fast-forward merges? (merge.ff) [true/false]" merge_ff "${def_merge_ff:-false}"
  case "$merge_ff" in
    true|false) ;;
    *) log_warn "Invalid value; defaulting to 'false'"; merge_ff="false" ;;
  esac

  # core.autocrlf
  local autocrlf_default=""
  if os_is_macos || os_is_linux; then autocrlf_default="input"; else autocrlf_default="false"; fi
  local autocrlf
  prompt_def "Line endings (core.autocrlf) [input/true/false]" autocrlf "${def_autocrlf:-$autocrlf_default}"
  case "$autocrlf" in
    input|true|false) ;;
    *) log_warn "Invalid value; defaulting to '$autocrlf_default'"; autocrlf="$autocrlf_default" ;;
  esac

  # credential.helper
  local cred_helper_default=""
  if os_is_macos; then
    cred_helper_default="osxkeychain"
  elif os_is_linux; then
    if has_cmd git-credential-manager; then
      cred_helper_default="manager"
    else
      cred_helper_default="store"
    fi
  fi
  local cred_helper
  prompt_def "Credential helper (credential.helper)" cred_helper "${def_cred_helper:-$cred_helper_default}"

  # GPG opcional
  local enable_signing=""
  if confirm "Enable GPG commit signing? [y/N]"; then
    enable_signing="yes"
  fi
  local signing_key=""
  if [[ "$enable_signing" == "yes" ]]; then
    if has_cmd gpg; then
      prompt_def "GPG signing key (user.signingkey) - leave blank to skip" signing_key "$(get_current user.signingkey)"
    else
      log_warn "gpg not found; skipping commit signing setup."
      enable_signing=""
    fi
  fi

  # Opcional: global .gitignore
  configure_gitignore_global

  # Resumen
  echo
  log_info "Summary:"
  echo "  user.name           = $name"
  echo "  user.email          = $email"
  echo "  init.defaultBranch  = $branch"
  echo "  core.editor         = ${editor:-<unset>}"
  echo "  pull.rebase         = $pull_rebase"
  echo "  merge.ff            = $merge_ff"
  echo "  core.autocrlf       = $autocrlf"
  echo "  credential.helper   = ${cred_helper:-<unset>}"
  if [[ "$enable_signing" == "yes" ]]; then
    echo "  commit.gpgsign      = true"
    echo "  user.signingkey     = ${signing_key:-<unset>}"
  fi
  echo

  if ! confirm "Apply these settings? [y/N]"; then
    log_warn "Aborted. No changes applied."
    return 0
  fi

  # Aplicar configuración global
  set_global user.name "$name"
  set_global user.email "$email"
  set_global init.defaultBranch "$branch"
  [[ -n "${editor:-}" ]] && set_global core.editor "$editor"
  set_global pull.rebase "$pull_rebase"
  set_global merge.ff "$merge_ff"
  set_global core.autocrlf "$autocrlf"
  [[ -n "${cred_helper:-}" ]] && set_global credential.helper "$cred_helper"

  if [[ "$enable_signing" == "yes" ]]; then
    git config --global commit.gpgsign true
    log_info "Set commit.gpgsign=true"
    [[ -n "${signing_key:-}" ]] && set_global user.signingkey "$signing_key"
  fi

  echo
  log_info "Global Git config now:"
  git config --global --list
  echo

  log_info "Tip: Global config file is at ~/.gitconfig"
  return 0
}

main "$@"; exit $?
