#include "clipapp.h"
#include <cstdlib>
#include <cstring>

// ---------------------------------------------------------------------------
// CopyToClipboard — Linux
//
// Linux doesn't have a single universal "file on clipboard" API like
// Windows CF_HDROP.  The most compatible approach for desktop apps (Discord,
// Telegram, etc.) is to use xdotool + xclip to put the file URI onto the
// clipboard as text/uri-list, which most GTK/Qt apps treat as a file drop.
//
// Requirements: xclip  (sudo apt install xclip)
//               OR xsel (sudo apt install xsel)   ← fallback
//
// Wayland note: if running under a pure Wayland session (no XWayland),
// replace xclip with wl-copy:  wl-copy --type text/uri-list < <(echo "$URI")
// ---------------------------------------------------------------------------
int CopyToClipboard(const std::string& pathStr)
{
    if (pathStr.empty()) return ERR_PATH;

    // Build a file URI: file:///absolute/path/to/clip.gif
    std::string uri = "file://" + pathStr;

    // Try xclip first (most common), then xsel, then wl-copy (Wayland)
    // We pipe the URI into xclip as a text/uri-list selection on the CLIPBOARD.
    std::string cmd;

    // Check what's available
    if (std::system("which xclip > /dev/null 2>&1") == 0) {
        // xclip: echo URI | xclip -selection clipboard -t text/uri-list
        cmd = "echo '" + uri + "' | xclip -selection clipboard -t text/uri-list";
    } else if (std::system("which xsel > /dev/null 2>&1") == 0) {
        // xsel: echo URI | xsel --clipboard --input
        cmd = "echo '" + uri + "' | xsel --clipboard --input";
    } else if (std::system("which wl-copy > /dev/null 2>&1") == 0) {
        // Wayland: wl-copy --type text/uri-list
        cmd = "echo '" + uri + "' | wl-copy --type text/uri-list";
    } else {
        logfile << "Error: no clipboard tool found. Install xclip, xsel, or wl-copy.\n";
        return ERR_CLIP;
    }

    logfile << "Clipboard cmd: " << cmd << "\n";
    int ret = std::system(cmd.c_str());
    if (ret != 0) {
        logfile << "Clipboard command returned " << ret << "\n";
        return ERR_CLIP;
    }

    logfile << "Placed on clipboard as URI: " << uri << "\n";
    return 0;
}
