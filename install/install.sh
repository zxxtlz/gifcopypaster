#!/usr/bin/env bash
# GifCopyPaster Linux installer / uninstaller
#
# Usage:
#   ./install.sh            Build (if needed) and install
#   ./install.sh --rebuild  Force a rebuild even if ClipApp already exists
#   ./install.sh --remove   Uninstall
#
# This script builds the native helper (ClipApp) if it isn't already sitting
# next to this script, installs it, and registers it as a Native Messaging
# host for every browser install it can find — including Flatpak and Snap
# Firefox — so you don't have to run separate build/copy/install steps.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTALL_DIR="$HOME/.local/share/gifcopypaster"
NATIVE_NAME="com.syanth.gifcopier"     # native messaging host id (unchanged from v1)
EXTENSION_ID="gifcopypaster@local"     # must match extension/manifest.json's gecko id
EXE_NAME="ClipApp"
AMO_URL="https://addons.mozilla.org/en-US/firefox/addon/gifcopypaster/"

# Standard + Flatpak + Snap native messaging host directories.
FF_MANIFEST_DIRS=(
    "$HOME/.mozilla/native-messaging-hosts"
    "$HOME/.var/app/org.mozilla.firefox/.mozilla/native-messaging-hosts"
    "$HOME/snap/firefox/common/.mozilla/native-messaging-hosts"
)
CR_MANIFEST_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
CB_MANIFEST_DIR="$HOME/.config/chromium/NativeMessagingHosts"

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--remove" ]]; then
    read -rp "Uninstall GifCopyPaster? (y/n) " ans
    [[ "$ans" != "y" ]] && echo "Cancelled." && exit 0

    rm -rf "$INSTALL_DIR"
    for d in "${FF_MANIFEST_DIRS[@]}"; do
        rm -f "$d/$NATIVE_NAME.json"
    done
    rm -f "$CR_MANIFEST_DIR/$NATIVE_NAME.json"
    rm -f "$CB_MANIFEST_DIR/$NATIVE_NAME.json"
    # Clean up a pre-2.0 install that used the old directory name, if present.
    rm -rf "$HOME/.local/share/gifcopier"
    echo "GifCopyPaster removed."
    exit 0
fi

FORCE_REBUILD=0
[[ "${1:-}" == "--rebuild" ]] && FORCE_REBUILD=1

# ── Dependency check ──────────────────────────────────────────────────────────
NEED_BUILD=0
[[ ! -f "$SCRIPT_DIR/$EXE_NAME" || "$FORCE_REBUILD" -eq 1 ]] && NEED_BUILD=1

missing_apt_pkgs=()

if [[ "$NEED_BUILD" -eq 1 ]]; then
    command -v cmake &>/dev/null || missing_apt_pkgs+=("cmake")
    command -v g++    &>/dev/null || command -v clang++ &>/dev/null || missing_apt_pkgs+=("g++")
fi

command -v curl &>/dev/null || missing_apt_pkgs+=("curl")

have_clip_tool=0
for tool in xclip xsel wl-copy; do
    command -v "$tool" &>/dev/null && have_clip_tool=1
done
[[ "$have_clip_tool" -eq 0 ]] && missing_apt_pkgs+=("xclip")

if [[ "${#missing_apt_pkgs[@]}" -gt 0 ]]; then
    echo "Missing required tools: ${missing_apt_pkgs[*]}"
    echo "Install them with:"
    echo "    sudo apt install ${missing_apt_pkgs[*]}"
    echo "Then re-run this script."
    exit 1
fi

# ── Build ClipApp if needed ──────────────────────────────────────────────────
if [[ "$NEED_BUILD" -eq 1 ]]; then
    echo "Building ClipApp..."
    BUILD_DIR="$REPO_ROOT/app/build"
    cmake -S "$REPO_ROOT" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "$BUILD_DIR" -j"$(nproc)" >/dev/null

    BUILT_EXE="$BUILD_DIR/app/$EXE_NAME"
    if [[ ! -f "$BUILT_EXE" ]]; then
        echo "Error: build finished but $EXE_NAME was not found at $BUILT_EXE"
        exit 1
    fi
    cp "$BUILT_EXE" "$SCRIPT_DIR/$EXE_NAME"
    echo "Built and copied $EXE_NAME to $SCRIPT_DIR"
fi

SRC_EXE="$SCRIPT_DIR/$EXE_NAME"

read -rp "Install GifCopyPaster to $INSTALL_DIR? (y/n) " ans
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
  "description": "GifCopyPaster clipboard helper",
  "path": "$EXE_PATH",
  "type": "stdio",
  "allowed_extensions": ["$EXTENSION_ID"]
}
EOF

cat > "$CR_JSON" <<EOF
{
  "name": "$NATIVE_NAME",
  "description": "GifCopyPaster clipboard helper",
  "path": "$EXE_PATH",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://ncddcifdiglpdkflenjfceajajjmglji/"]
}
EOF

cat > "$CB_JSON" <<EOF
{
  "name": "$NATIVE_NAME",
  "description": "GifCopyPaster clipboard helper",
  "path": "$EXE_PATH",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://ncddcifdiglpdkflenjfceajajjmglji/"]
}
EOF

# ── Symlink manifests into every Firefox variant found ───────────────────────
ff_installed_count=0
for d in "${FF_MANIFEST_DIRS[@]}"; do
    # Only install into a Flatpak/Snap dir if that Firefox variant's data
    # directory already exists — otherwise we'd create clutter for a browser
    # that isn't even installed.
    parent_exists=0
    case "$d" in
        "$HOME/.mozilla/native-messaging-hosts")
            parent_exists=1 ;;  # always try the standard location
        *)
            [[ -d "$(dirname "$(dirname "$d")")" ]] && parent_exists=1 ;;
    esac

    if [[ "$parent_exists" -eq 1 ]]; then
        mkdir -p "$d"
        ln -sf "$FF_JSON" "$d/$NATIVE_NAME.json"
        ff_installed_count=$((ff_installed_count + 1))
        echo "Registered native host for Firefox at: $d"
    fi
done

if [[ -d "$(dirname "$CR_MANIFEST_DIR")" || -d "$HOME/.config/google-chrome" ]]; then
    mkdir -p "$CR_MANIFEST_DIR"
    ln -sf "$CR_JSON" "$CR_MANIFEST_DIR/$NATIVE_NAME.json"
fi
if [[ -d "$HOME/.config/chromium" ]]; then
    mkdir -p "$CB_MANIFEST_DIR"
    ln -sf "$CB_JSON" "$CB_MANIFEST_DIR/$NATIVE_NAME.json"
fi

if [[ "$ff_installed_count" -eq 0 ]]; then
    echo "Warning: no Firefox profile directory found. The manifest was still"
    echo "written to $FF_JSON — if Firefox is installed somewhere non-standard,"
    echo "symlink it manually into that profile's native-messaging-hosts folder."
fi

echo ""
echo "GifCopyPaster installed to $INSTALL_DIR"
echo "Now install the browser extension:"
echo "  Firefox : $AMO_URL"
echo ""
echo "Note: if you use Firefox as a Flatpak or Snap, native messaging support"
echo "depends on that build's sandbox permissions — if the extension reports"
echo "\"Native app not reachable\" there, try the regular (deb/rpm/tarball)"
echo "build of Firefox instead."
echo ""
echo "To uninstall later:  ./install.sh --remove"
