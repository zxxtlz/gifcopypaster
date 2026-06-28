# GIFCopier (v2 — GIF-preserving fork)

Right-click any GIF, GIFV, or MP4 on the web and copy it directly to your clipboard.

**Key difference from the original:** GIFs are now copied *as GIFs*, not converted to MP4.

---

## How it works

1. A browser extension adds a **"Copy GIF"** entry to the right-click context menu on images and videos.
2. When you click it, the extension sends the media URL to a small native helper app (`ClipApp`) via the [Native Messaging](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_messaging) protocol.
3. `ClipApp` downloads the file with `curl` and places it on the system clipboard as a file drop.
4. Paste into Discord, Telegram, WhatsApp Web, etc.

---

## Building the native app

### Requirements

| Tool    | Windows              | Linux                        |
|---------|----------------------|------------------------------|
| Compiler | MSVC 2019+ or MinGW | GCC 10+ or Clang 12+         |
| CMake   | 3.16+                | 3.16+                        |
| curl    | Built-in (Win 10+)   | `sudo apt install curl`      |
| Clipboard | —                  | `sudo apt install xclip`     |

### Windows

```bat
cd app
cmake -B build -G "Visual Studio 17 2022"
cmake --build build --config Release
copy build\Release\ClipApp.exe ..\install\
```

### Linux

```bash
cd app
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cp build/ClipApp ../install/
```

---

## Installing

### Windows

1. Build `ClipApp.exe` as above (it ends up in `install/`).
2. Run `install/install.cmd` **as Administrator**.
3. Install the Firefox extension from [AMO](https://addons.mozilla.org/en-US/firefox/addon/gifcopier/).

### Linux

1. Build `ClipApp` as above.
2. `chmod +x install/install.sh && install/install.sh`
3. Install the Firefox extension from [AMO](https://addons.mozilla.org/en-US/firefox/addon/gifcopier/).

Install `xclip` (or `xsel` / `wl-clipboard` for Wayland) if not already present:
```bash
sudo apt install xclip
```

---

## File reference

```
gifcopier/
├── app/
│   ├── clipapp.h        # shared declarations
│   ├── clipapp.cpp      # main() + cross-platform logic (download, messaging)
│   ├── app_win.cpp      # Windows clipboard (CF_HDROP)
│   ├── app_linux.cpp    # Linux clipboard (xclip / xsel / wl-copy)
│   ├── app_test.cpp     # unit tests
│   └── CMakeLists.txt
├── extension/
│   ├── manifest.json    # Firefox WebExtension manifest
│   ├── background.js    # context menu + native messaging
│   └── icons/
│       ├── icon48.png
│       └── icon96.png
└── install/
    ├── install.cmd      # Windows launcher (run as Admin)
    ├── install.ps1      # Windows PowerShell installer
    ├── uninstall.cmd    # Windows uninstaller
    └── install.sh       # Linux installer
```

---

## Clipboard behaviour by file type

| URL ends with | File saved    | Pasted as     |
|---------------|---------------|---------------|
| `.gif`        | `clip.gif`    | GIF file      |
| `.mp4`        | `clip.mp4`    | MP4 video     |
| `.gifv`       | `clip.mp4`    | MP4 video     |
| `.webm`       | `clip.mp4`    | WebM video    |
| other         | `clip.bin`    | raw file      |

---

## Uninstalling

**Windows:** run `install/uninstall.cmd` as Administrator.  
**Linux:** run `install/install.sh --remove`.
