#!/usr/bin/env bash
# GIFCopier Linux installer
# Usage:  ./install.sh          — install
#         ./install.sh --remove — uninstall

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$HOME/.local/share/gifcopier"
NATIVE_NAME="com.syanth.gifcopier"
EXE_NAME="ClipApp"

FF_MANIFEST_DIR="$HOME/.mozilla/native-messaging-hosts"
CR_MANIFEST_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
CB_MANIFEST_DIR="$HOME/.config/chromium/NativeMessagingHosts"

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "$1" == "--remove" ]]; then
    read -rp "Uninstall GIFCopier? (y/n) " ans
    [[ "$ans" != "y" ]] && echo "Cancelled." && exit 0

    rm -rf "$INSTALL_DIR"
    rm -f "$FF_MANIFEST_DIR/$NATIVE_NAME.json"
    rm -f "$CR_MANIFEST_DIR/$NATIVE_NAME.json"
    rm -f "$CB_MANIFEST_DIR/$NATIVE_NAME.json"
    echo "GIFCopier removed."
    exit 0
fi

# ── Install ───────────────────────────────────────────────────────────────────
SRC_EXE="$SCRIPT_DIR/$EXE_NAME"
if [[ ! -f "$SRC_EXE" ]]; then
    echo "Error: $EXE_NAME not found at $SRC_EXE"
    echo "Build it first:  cd app && cmake -B build && cmake --build build"
    echo "Then copy app/build/ClipApp next to this script."
    exit 1
fi

# Check for a clipboard tool
if ! command -v xclip &>/dev/null && \
   ! command -v xsel  &>/dev/null && \
   ! command -v wl-copy &>/dev/null; then
    echo "Warning: no clipboard tool found."
    echo "Install one:  sudo apt install xclip"
    echo "              sudo apt install xsel"
    echo "              sudo apt install wl-clipboard   # Wayland"
fi

read -rp "Install GIFCopier to $INSTALL_DIR? (y/n) " ans
[[ "$ans" != "y" ]] && echo "Cancelled." && exit 0

mkdir -p "$INSTALL_DIR"
cp "$SRC_EXE" "$INSTALL_DIR/$EXE_NAME"
chmod +x "$INSTALL_DIR/$EXE_NAME"

EXE_PATH="$INSTALL_DIR/$EXE_NAME"

# ── Write Native Messaging manifests ─────────────────────────────────────────
FF_JSON="$INSTALL_DIR/$NATIVE_NAME.firefox.json"
CR_JSON="$INSTALL_DIR/$NATIVE_NAME.chrome.json"
CB_JSON="$INSTALL_DIR/$NATIVE_NAME.chromium.json"

cat > "$FF_JSON" <<EOF
{
  "name": "$NATIVE_NAME",
  "description": "GIFCopier clipboard helper",
  "path": "$EXE_PATH",
  "type": "stdio",
  "allowed_extensions": ["gifcopier@syanth"]
}
EOF

cat > "$CR_JSON" <<EOF
{
  "name": "$NATIVE_NAME",
  "description": "GIFCopier clipboard helper",
  "path": "$EXE_PATH",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://ncddcifdiglpdkflenjfceajajjmglji/"]
}
EOF

cat > "$CB_JSON" <<EOF
{
  "name": "$NATIVE_NAME",
  "description": "GIFCopier clipboard helper",
  "path": "$EXE_PATH",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://ncddcifdiglpdkflenjfceajajjmglji/"]
}
EOF

# ── Symlink manifests into browser directories ────────────────────────────────
mkdir -p "$FF_MANIFEST_DIR" "$CR_MANIFEST_DIR" "$CB_MANIFEST_DIR"
ln -sf "$FF_JSON" "$FF_MANIFEST_DIR/$NATIVE_NAME.json"
ln -sf "$CR_JSON" "$CR_MANIFEST_DIR/$NATIVE_NAME.json"
ln -sf "$CB_JSON" "$CB_MANIFEST_DIR/$NATIVE_NAME.json"

echo ""
echo "GIFCopier installed to $INSTALL_DIR"
echo "Now install the browser extension:"
echo "  Firefox : https://addons.mozilla.org/en-US/firefox/addon/gifcopier/"
echo ""
echo "To uninstall later:  ./install.sh --remove"
