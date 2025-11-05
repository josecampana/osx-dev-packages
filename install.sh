#!/usr/bin/env bash
# Persistent menu that executes packages in child processes
# Compatible with macOS Bash 3.2; avoids 'set -e' to keep menu alive.

set -u
set -o pipefail

source "./lib/common.sh"

PACKAGES_DIR="./packages"

SCRIPT_FILES=()
NAMES=()
DESCS=()

load_scripts() {
  SCRIPT_FILES=()
  NAMES=()
  DESCS=()

  while IFS= read -r f; do
    SCRIPT_FILES+=("$f")
  done < <(find "$PACKAGES_DIR" -maxdepth 1 -type f -name "*.sh" | sort)

  if [[ ${#SCRIPT_FILES[@]} -eq 0 ]]; then
    log_warn "No scripts found in '$PACKAGES_DIR'."
    return 1
  fi

  for f in "${SCRIPT_FILES[@]}"; do
    if [[ ! -r "$f" ]]; then
      log_warn "'$f' not readable. Attempting to fix..."
      chmod u+r "$f" 2>/dev/null || { log_error "Cannot read '$f'. Skipping."; continue; }
    fi
    # name="$(sed -n '2s/^[[:space:]]*#[:[:space:]]*name:[[:space:]]*//p' "$f" | tr -d '\r')"
    name="$(awk 'NR<=10 && /^#[[:space:]]*name:/ {sub(/^#[[:space:]]*name:[[:space:]]*/, ""); print; exit}' "$f" | tr -d '\r')"
    desc="$(awk 'NR<=10 && /^#[[:space:]]*description:/ {sub(/^#[[:space:]]*description:[[:space:]]*/, ""); print; exit}' "$f" | tr -d '\r')"

    # [[ -z "$name" ]] && name="$(basename "$f")"
    # NAMES+=("$name")
    # Fallbacks
    if [[ -z "$name" ]]; then
      name="$(basename "$f")"
      log_warn "'$f' is missing '# name:' header. Using filename as name: $name"
    fi
    if [[ -z "$desc" ]]; then
      desc="$name"
    fi

    NAMES+=("$name")
    DESCS+=("$desc")
  done
  return 0
}

show_menu() {
  echo "Choose a package to install:"
  echo
  for i in "${!DESCS[@]}"; do
    printf "%2d) %s\n" $((i+1)) "${DESCS[$i]}"
  done
  echo 
  echo " a) Run all"
  echo " r) Reload packages"
  echo 
  echo " q) Quit"
  echo
}

run_one_script_exec() {
  local script="$1"
  local name="$2"

  log_info "Running: ${name}"

  [[ ! -x "$script" ]] && chmod +x "$script"

  # Ejecutar como proceso hijo para aislar entorno
  ( bash "$script" )
  local rc=$?

  if [[ ! $rc -eq 0 ]]; then
  #   log_info "${name} finished OK"
  # else
    log_error "${name} finished with errors (exit code: $rc)."
  fi
  
  return $rc
}

run_scripts() {
  local idxs=("$@")
  local any_rc=0
  for idx in "${idxs[@]}"; do
    local pos=$((idx - 1))
    local script="${SCRIPT_FILES[$pos]}"
    local name="${NAMES[$pos]}"
    if [[ -z "${script:-}" ]]; then
      log_error "Invalid index: $idx"
      any_rc=1
      continue
    fi
    run_one_script_exec "$script" "$name" || any_rc=1
  done
  return $any_rc
}

clear 
echo "*** Package Installer for devs ***"
echo
while true; do
  if ! load_scripts; then
    read -r -p "No packages. Press Enter to exit..." _
    exit 0
  fi

  show_menu
  read -r -p "Select option(s) (e.g., 1,3 or a or r or q): " selection

  case "$selection" in
    a|A)
      all_idxs=()
      for i in "${!SCRIPT_FILES[@]}"; do all_idxs+=("$((i+1))"); done
      run_scripts "${all_idxs[@]}"
      ;;
    r|R)
      log_info "Packages reloaded."
      continue
      ;;
    q|Q)
      log_info "Bye."
      exit 0
      ;;
    *)
      normalized="${selection//,/ }"
      parts=(); for p in $normalized; do parts+=("$p"); done
      valid_idxs=()
      for p in "${parts[@]}"; do
        if [[ "$p" =~ ^[0-9]+$ ]] && (( p >= 1 && p <= ${#SCRIPT_FILES[@]} )); then
          valid_idxs+=("$p")
        else
          log_warn "Invalid option: '$p'"
        fi
      done
      [[ ${#valid_idxs[@]} -gt 0 ]] && run_scripts "${valid_idxs[@]}"
      ;;
  esac

  echo
done
