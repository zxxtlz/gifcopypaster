#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#include <windows.h>
#include <shlobj.h>
#include "clipapp.h"

// ---------------------------------------------------------------------------
// CopyToClipboard — Windows
//
// Places the file at pathStr onto the clipboard as CF_HDROP so any app that
// accepts pasted files (Discord, Telegram, WhatsApp Web, etc.) will receive
// the actual GIF/MP4 file rather than just its path as text.
// ---------------------------------------------------------------------------
int CopyToClipboard(const std::string& pathStr)
{
    if (pathStr.empty()) return ERR_PATH;

    // Convert UTF-8 path → wide string for Windows APIs
    int wLen = MultiByteToWideChar(CP_UTF8, 0, pathStr.c_str(), -1, nullptr, 0);
    if (wLen <= 0) return ERR_PATH;

    std::wstring wPath(wLen, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, pathStr.c_str(), -1, wPath.data(), wLen);

    // Build the DROPFILES structure
    // Layout: [DROPFILES header][wide path][null][null]
    SIZE_T dropSize = sizeof(DROPFILES) + (wPath.size() + 2) * sizeof(wchar_t);
    HGLOBAL hMem = GlobalAlloc(GHND, dropSize);
    if (!hMem) return ERR_MEM;

    DROPFILES* pDrop = static_cast<DROPFILES*>(GlobalLock(hMem));
    if (!pDrop) { GlobalFree(hMem); return ERR_MEM; }

    pDrop->pFiles = sizeof(DROPFILES);
    pDrop->fWide  = TRUE;

    wchar_t* dst = reinterpret_cast<wchar_t*>(pDrop + 1);
    wcscpy_s(dst, wPath.size() + 1, wPath.c_str());
    // Double-null terminator is guaranteed by GHND zeroing the allocation.

    GlobalUnlock(hMem);

    // Put it on the clipboard (OS takes ownership of hMem)
    if (!OpenClipboard(nullptr))       { GlobalFree(hMem); return ERR_CLIP; }
    EmptyClipboard();
    if (!SetClipboardData(CF_HDROP, hMem)) {
        CloseClipboard();
        GlobalFree(hMem);
        return ERR_CLIP;
    }
    CloseClipboard();

    logfile << "Placed on clipboard via CF_HDROP: " << pathStr << "\n";
    return 0;
}
