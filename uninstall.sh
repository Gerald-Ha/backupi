#!/usr/bin/env bash
set -Eeuo pipefail

BIN_DST="/usr/local/bin/backupi"
UNINSTALL_DST="/usr/local/sbin/backupi-uninstall"
CONF_DIR="/etc/backupi"

PURGE=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Uninstall backupi.

Usage:
  uninstall.sh              Remove program files, ask before removing config
  uninstall.sh --purge      Also remove /etc/backupi
  uninstall.sh --yes        Answer yes to interactive questions
EOF
}

run_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

yes_no() {
  local prompt="$1"
  local answer

  (( ASSUME_YES )) && return 0
  [[ -t 0 ]] || return 1

  printf '%s [y/N] ' "$prompt"
  read -r answer
  answer="${answer,,}"
  [[ "$answer" == "y" || "$answer" == "yes" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge) PURGE=1; shift ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

run_root rm -f "$BIN_DST"
run_root rm -f "$UNINSTALL_DST"

if (( PURGE )) || yes_no "Remove config directory $CONF_DIR?"; then
  run_root rm -rf "$CONF_DIR"
else
  echo "Config kept: $CONF_DIR"
fi

echo "backupi uninstalled."
