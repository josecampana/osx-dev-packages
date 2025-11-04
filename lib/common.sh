log_info()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
log_warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
log_error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

# OS/ARCH detection
os_name() {
  local u
  u="$(uname -s)"
  case "$u" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "$u" ;;
  esac
}

arch_name() {
  local a
  a="$(uname -m)"
  case "$a" in
    arm64|aarch64) echo "arm64" ;;
    x86_64|amd64)  echo "x86_64" ;;
    *)             echo "$a" ;;
  esac
}

os_is_macos() { [[ "$(os_name)" == "macos" ]]; }
os_is_linux() { [[ "$(os_name)" == "linux" ]]; }

# Command presence
has_cmd()  { command -v "$1" >/dev/null 2>&1; }
has_brew() { has_cmd brew; }

# Add a line to a file only once
append_once() {
  local file="$1" line="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# Detect RC files for the current user
detect_shell_rcs() {
  # Priorizes current one but supports bash and zsh RCs
  local rcs=()
  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  case "$shell_name" in
    zsh) rcs+=("$HOME/.zshrc") ;;
    bash) rcs+=("$HOME/.bashrc" "$HOME/.bash_profile") ;;
    *) rcs+=("$HOME/.bashrc" "$HOME/.zshrc") ;;
  esac
  printf "%s\n" "${rcs[@]}"
}

# Persist brew shellenv in RC files
ensure_shellenv_brew() {
  local prefix="$1"
  local line="eval \"($prefix/bin/brew shellenv)\""
  # We use simple quotes and scape to avoid expansion
  line='eval "$('"$prefix"'/bin/brew shellenv)"'
  while IFS= read -r rc; do
    append_once "$rc" "$line"
  done < <(detect_shell_rcs)
}

# Add a PATH entry to RCs if not present
ensure_path_in_rc() {
  local path="$1"
  while IFS= read -r rc; do
    if ! grep -q "$path" "$rc" 2>/dev/null; then
      append_once "$rc" "export PATH=\"$path:\$PATH\""
    fi
  done < <(detect_shell_rcs)
}

# Run with sudo if needed to write to system directories
run_maybe_sudo() {
  # Usage: run_maybe_sudo "command arg1 arg2"
  if [[ $EUID -ne 0 ]]; then
    # Check if sudo is available and needed
    if has_cmd sudo; then
      sudo bash -lc "$*"
      return
    fi
  fi
  bash -lc "$*"
}

# Interactive confirmation prompt
confirm() {
  local prompt="${1:-¿Continuar? [y/N]}"
  read -r -p "$prompt " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

reload_shell_rc() {
  local reloaded_any=0
  local rc

  # Desactiva temporalmente 'nounset' si estuviese activo para evitar errores al sourcear
  local restore_nounset=0
  case "$-" in
    *u*) restore_nounset=1; set +u ;;
  esac

  while IFS= read -r rc; do
    if [[ -f "$rc" ]]; then
      # shellcheck disable=SC1090
      . "$rc"
      reloaded_any=1
      log_info "Reloaded shell RC: $rc"
    fi
  done < <(detect_shell_rcs)

  # Restaura nounset si estaba activo
  if [[ "$restore_nounset" -eq 1 ]]; then
    set -u
  fi

  if [[ "$reloaded_any" -eq 0 ]]; then
    local checked
    checked="$(detect_shell_rcs | tr '\n' ' ')"
    log_warn "No RC files found to reload (checked: $checked)."
    return 1
  fi
  return 0
}

reset_nvm() {
  # Unload NVM function from current shell
  if [[ "$(type -t nvm || true)" == "function" ]]; then
    unset -f nvm
    unset NVM_DIR
    hash -r  # limpia el hash de comandos del shell
    log_info "Unloaded nvm from current session."
  fi
}

# Load NVM into the current shell if installed
load_nvm() {
  # Ya cargado
  if [[ "$(type -t nvm || true)" == "function" ]]; then
    return 0
  fi

  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  local nvm_sh="$NVM_DIR/nvm.sh"

  if [[ -s "$nvm_sh" ]]; then
    # shellcheck disable=SC1090
    . "$nvm_sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
    [[ "$(type -t nvm || true)" == "function" ]] && return 0
  fi

  # Fallback (si alguien instaló nvm por Homebrew)
  if has_brew; then
    local brew_prefix
    brew_prefix="$(brew --prefix 2>/dev/null || echo "")"
    if [[ -n "$brew_prefix" && -s "$brew_prefix/opt/nvm/nvm.sh" ]]; then
      # shellcheck disable=SC1090
      . "$brew_prefix/opt/nvm/nvm.sh"
      [[ "$(type -t nvm || true)" == "function" ]] && return 0
    fi
  fi

  log_warn "Could not load NVM. Ensure '~/.nvm/nvm.sh' exists and your RC sources it."
  return 1
}
