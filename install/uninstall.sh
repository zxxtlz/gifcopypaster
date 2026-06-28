#!/usr/bin/env bash
# GIFCopier Linux uninstaller

INSTALL_DIR="$HOME/.local/share/gifcopier"
NATIVE_NAME="com.syanth.gifcopier"

FF_MANIFEST="$HOME/.mozilla/native-messaging-hosts/$NATIVE_NAME.json"
CR_MANIFEST="$HOME/.config/google-chrome/NativeMessagingHosts/$NATIVE_NAME.json"
CB_MANIFEST="$HOME/.config/chromium/NativeMessagingHosts/$NATIVE_NAME.json"

read -rp "Uninstall GIFCopier? (y/n) " ans
[[ "$ans" != "y" ]] && echo "Cancelled." && exit 0

rm -rf "$INSTALL_DIR"
rm -f "$FF_MANIFEST" "$CR_MANIFEST" "$CB_MANIFEST"

echo "GIFCopier uninstalled."
