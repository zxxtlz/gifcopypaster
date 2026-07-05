#pragma once

#include <string>
#include <iostream>
#include <fstream>
#include <filesystem>

namespace fs = std::filesystem;

// ── Error codes ───────────────────────────────────────────────────────────────
#define ERR_MEM      11   // memory allocation failed
#define ERR_CLIP     12   // native clipboard call failed
#define ERR_PATH     13   // invalid or missing file path
#define ERR_DOWNLOAD 20   // curl download failed / empty file
#define ERR_FORMAT   21   // unrecognised URL format

extern std::ofstream logfile;

// Implemented per-platform in app_win.cpp / app_linux.cpp
int  CopyToClipboard(const std::string& pathStr);

// Implemented in clipapp.cpp (cross-platform)
std::string ReadURL();
void        SendResponse(bool success, const std::string& error = "");
int         DownloadFile(const std::string& url, const std::string& destPath);
void        LogError(int code, const std::string& detail = "");
