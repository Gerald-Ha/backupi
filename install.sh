#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$SCRIPT_DIR/backupi"
CONF_SRC="$SCRIPT_DIR/backupi.conf"
UPDATE_CONF_EXAMPLE_SRC="$SCRIPT_DIR/backupi-update.conf.example"
UNINSTALL_SRC="$SCRIPT_DIR/uninstall.sh"

BIN_DST="/usr/local/bin/backupi"
CONF_DIR="/etc/backupi"
CONF_DST="$CONF_DIR/backupi.conf"
CONF_EXAMPLE="$CONF_DIR/backupi.conf.example"
UPDATE_CONF_DST="$CONF_DIR/update.conf"
UPDATE_CONF_EXAMPLE="$CONF_DIR/update.conf.example"
UNINSTALL_DST="/usr/local/sbin/backupi-uninstall"
REPLACE_CONFIG=0

usage() {
  cat <<'EOF'
Install backupi.

Usage:
  ./install.sh                  Install program, keep existing config
  ./install.sh --replace-config Replace /etc/backupi/backupi.conf after backup
  ./install.sh --uninstall      Remove installed backupi files
EOF
}

run_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--replace-config" ]]; then
  REPLACE_CONFIG=1
  shift
fi

if [[ "${1:-}" == "--uninstall" ]]; then
  if [[ -x "$UNINSTALL_DST" ]]; then
    "$UNINSTALL_DST" "${@:2}"
  else
    "$UNINSTALL_SRC" "${@:2}"
  fi
  exit 0
fi

[[ -f "$BIN_SRC" ]] || { echo "Missing $BIN_SRC" >&2; exit 1; }
[[ -f "$CONF_SRC" ]] || { echo "Missing $CONF_SRC" >&2; exit 1; }
[[ -f "$UPDATE_CONF_EXAMPLE_SRC" ]] || { echo "Missing $UPDATE_CONF_EXAMPLE_SRC" >&2; exit 1; }
[[ -f "$UNINSTALL_SRC" ]] || { echo "Missing $UNINSTALL_SRC" >&2; exit 1; }

run_root install -Dm755 "$BIN_SRC" "$BIN_DST"
run_root install -Dm755 "$UNINSTALL_SRC" "$UNINSTALL_DST"
run_root mkdir -p "$CONF_DIR"
run_root install -Dm644 "$UPDATE_CONF_EXAMPLE_SRC" "$UPDATE_CONF_EXAMPLE"

if [[ -e "$CONF_DST" && "$REPLACE_CONFIG" == "1" ]]; then
  backup_path="$CONF_DST.backup.$(date +%Y%m%d-%H%M%S)"
  run_root cp -a "$CONF_DST" "$backup_path"
  run_root install -Dm644 "$CONF_SRC" "$CONF_DST"
  echo "Existing config backed up: $backup_path"
  echo "Config replaced: $CONF_DST"
elif [[ -e "$CONF_DST" ]]; then
  run_root install -Dm644 "$CONF_SRC" "$CONF_EXAMPLE"
  echo "Existing config kept: $CONF_DST"
  echo "New default config written as: $CONF_EXAMPLE"
else
  run_root install -Dm644 "$CONF_SRC" "$CONF_DST"
  echo "Config installed: $CONF_DST"
fi

if [[ ! -e "$UPDATE_CONF_DST" ]]; then
  echo "Update config example written as: $UPDATE_CONF_EXAMPLE"
  echo "Update checks work with the built-in public project key."
  echo "Create $UPDATE_CONF_DST only if you want to override update settings."
fi

echo "Installed: $BIN_DST"
echo "Uninstaller: $UNINSTALL_DST"
echo
echo "Run: backupi"
