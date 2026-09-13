#!/bin/bash
# Post-install script for RClone Manager GUI (DEB/RPM)
#
# Installs a launcher wrapper that detects the NVIDIA + Wayland combination and
# applies the environment flags known to be required for stable WebKitGTK rendering.
# This avoids forcing users to set GDK_BACKEND / WEBKIT_DISABLE_COMPOSITING_MODE manually.

set -e

BIN_DIR="/usr/bin"
WRAPPER_NAME="rclone-manager"
REAL_BINARY="${WRAPPER_NAME}-bin"

# Rename the real binary, keeping a launcher at the original path.
if [ -f "$BIN_DIR/$WRAPPER_NAME" ] && [ ! -L "$BIN_DIR/$WRAPPER_NAME" ]; then
    mv "$BIN_DIR/$WRAPPER_NAME" "$BIN_DIR/$REAL_BINARY"
fi

cat > "$BIN_DIR/$WRAPPER_NAME" << 'WRAPPER_EOF'
#!/bin/sh
# RClone Manager GUI launcher script.
# Detects the NVIDIA + Wayland combo and sets the WebKitGTK env flags it needs,
# so users don't have to configure them manually. Respects any pre-set values.

is_wayland() {
    [ -n "$WAYLAND_DISPLAY" ] || [ "$XDG_SESSION_TYPE" = "wayland" ]
}

has_nvidia() {
    command -v nvidia-smi >/dev/null 2>&1 && return 0
    [ -d /proc/driver/nvidia ] && return 0
    if command -v lspci >/dev/null 2>&1; then
        lspci 2>/dev/null | grep -qi "nvidia" && return 0
    fi
    return 1
}

# Only intervene for the known-bad combination (NVIDIA + Wayland).
if is_wayland && has_nvidia; then
    export GDK_BACKEND="${GDK_BACKEND:-x11}"
    export WEBKIT_DISABLE_COMPOSITING_MODE="${WEBKIT_DISABLE_COMPOSITING_MODE:-1}"
fi

exec /usr/bin/rclone-manager-bin "$@"
WRAPPER_EOF

chmod +x "$BIN_DIR/$WRAPPER_NAME"

echo "RClone Manager GUI installed successfully!"
exit 0
