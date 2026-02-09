#!/bin/bash
set -euo pipefail

### ----------------------------
### Constants
### ----------------------------

SCRIPT_NAME="x3d-wrapper"
X3D_SYSFS="/sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode"
UDEV_RULE_PATH="/etc/udev/rules.d/99-x3dctl.rules"
X3D_GROUP="x3d"

### ----------------------------
### Logging helpers
### ----------------------------

log() {
  echo "[$SCRIPT_NAME] $*" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

### ----------------------------
### Installer
### ----------------------------

install_udev_rule() {
  [[ $EUID -eq 0 ]] || die "install must be run as root"

  log "Installing udev rule for AMD X3D v-cache control"

  if ! getent group "$X3D_GROUP" >/dev/null; then
    log "Creating group '$X3D_GROUP'"
    groupadd -r "$X3D_GROUP"
  else
    log "Group '$X3D_GROUP' already exists"
  fi

  log "Writing udev rule → $UDEV_RULE_PATH"
  cat > "$UDEV_RULE_PATH" <<EOF
SUBSYSTEM=="platform", KERNEL=="AMDI0101:00", MODE="0666"
EOF

  log "Reloading udev rules"
  udevadm control --reload-rules
  udevadm trigger --sysname-match="AMDI0101:00"

  if [[ -n "${SUDO_USER:-}" ]]; then
    log "Adding user '$SUDO_USER' to group '$X3D_GROUP'"
    usermod -aG "$X3D_GROUP" "$SUDO_USER"
    log ""
    log "⚠️  IMPORTANT: User '$SUDO_USER' must log out and back in for group changes to apply"
    log "   Or run: newgrp $X3D_GROUP"
    log ""
  else
    log "NOTE: no SUDO_USER detected — add users to '$X3D_GROUP' manually"
  fi

  log "Install complete"
  exit 0
}

uninstall_udev_rule() {
  [[ $EUID -eq 0 ]] || die "uninstall must be run as root"

  log "Uninstalling X3D udev rule"

  if [[ -f "$UDEV_RULE_PATH" ]]; then
    log "Removing $UDEV_RULE_PATH"
    rm -f "$UDEV_RULE_PATH"
  else
    log "No udev rule found at $UDEV_RULE_PATH"
  fi

  log "Reloading udev rules"
  udevadm control --reload-rules
  udevadm trigger --sysname-match="AMDI0101:00"

  log "Uninstall complete"

  log "NOTE:"
  log "  The '$X3D_GROUP' group was NOT removed."
  log "  To remove it manually (optional):"
  log "    sudo groupdel $X3D_GROUP"
  log "    sudo gpasswd -d <user> $X3D_GROUP"

  exit 0
}

### ----------------------------
### Runtime helpers
### ----------------------------

require_write_access() {
  [[ -w "$X3D_SYSFS" ]] || die "No write access to $X3D_SYSFS (did you run install?)"
}

set_x3d_mode() {
  local mode="$1"
  
  # Validate mode
  case "$mode" in
    cache|frequency)
      ;;
    *)
      die "Invalid X3D mode: $mode"
      ;;
  esac
  
  local current
  current="$(cat "$X3D_SYSFS")"

  if [[ "$current" == "$mode" ]]; then
    log "X3D mode already '$mode'"
    return
  fi

  log "Setting X3D mode → $mode"
  echo "$mode" > "$X3D_SYSFS"
}

detect_cyberpunk() {
  local cmd_str="${CMD[*]}"
  # Check for common patterns (case-insensitive)
  [[ "$cmd_str" =~ [Cc]yberpunk|2077 ]] && return 0
  
  # Check actual executable name
  local exe="${CMD[0]}"
  [[ "$(basename "$exe")" =~ [Cc]yberpunk ]] && return 0
  
  return 1
}

### ----------------------------
### Entry point
### ----------------------------

case "${1:-}" in
  install)
    install_udev_rule
    ;;
  uninstall)
    uninstall_udev_rule
    ;;
  *)
    # Runtime mode: profile-based launching
    PROFILE="${1:-gaming}"
    shift || true
    CMD=("$@")
    
    [[ ${#CMD[@]} -eq 0 ]] && die "No command specified"

    log "Profile: $PROFILE"
    log "Command: ${CMD[*]}"

    require_write_access

    if detect_cyberpunk; then
      log "Detected Cyberpunk → forcing cache mode"
      set_x3d_mode "cache"
    else
      case "$PROFILE" in
        gaming)
          set_x3d_mode "cache"
          ;;
        default)
          set_x3d_mode "frequency"
          ;;
        *)
          die "Unknown profile '$PROFILE'"
          ;;
      esac
    fi

    log "Final X3D mode: $(cat "$X3D_SYSFS")"
    log "Launching: ${CMD[*]}"

    exec "${CMD[@]}"
    ;;
esac
