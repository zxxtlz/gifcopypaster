#include "clipapp.h"
#include <cstdlib>

// ── Globals ───────────────────────────────────────────────────────────────────
std::ofstream logfile;

// ── Entry point ───────────────────────────────────────────────────────────────
int main()
{
    logfile.open("clipapp.log", std::ios::app);
    logfile << "--- GIFCopier native app started ---\n";

    // 1. Read the URL from the browser extension (Native Messaging protocol)
    std::string url;
    try {
        url = ReadURL();
    } catch (...) {
        SendResponse(false, "Failed to read URL from extension");
        return 1;
    }
    logfile << "URL: " << url << "\n";

    // 2. Decide output filename based on URL extension.
    //    We now keep GIFs as GIFs — no forced MP4 conversion.
    std::string destFile;

    if (url.find(".gif")  != std::string::npos ||
        url.find(".GIF")  != std::string::npos)
    {
        destFile = "clip.gif";
    }
    else if (url.find(".mp4")  != std::string::npos ||
             url.find(".MP4")  != std::string::npos ||
             url.find(".gifv") != std::string::npos ||
             url.find(".GIFV") != std::string::npos ||
             url.find(".webm") != std::string::npos)
    {
        destFile = "clip.mp4";
    }
    else
    {
        // Unknown extension — try downloading as-is and let the OS sort it out
        logfile << "Warning: unrecognised extension, saving as clip.bin\n";
        destFile = "clip.bin";
    }

    // 3. Download
    int err = DownloadFile(url, destFile);
    if (err) {
        LogError(err, "download failed");
        SendResponse(false, "Download failed (code " + std::to_string(err) + ")");
        return 1;
    }

    // 4. Copy to clipboard
    fs::path p = fs::current_path() / destFile;
    err = CopyToClipboard(p.string());
    if (err) {
        LogError(err, "clipboard failed");
        SendResponse(false, "Clipboard copy failed (code " + std::to_string(err) + ")");
        return 1;
    }

    logfile << "Success.\n";
    SendResponse(true);
    logfile.close();
    return 0;
}

// ── Native Messaging helpers ──────────────────────────────────────────────────

// The Native Messaging wire format:
//   [4 bytes little-endian length][JSON string]
// The browser sends:  {"url":"https://..."}
// We reply with:      {"success":true} or {"success":false,"error":"..."}

std::string ReadURL()
{
    // Read 4-byte length prefix
    char lenBuf[4];
    if (!std::cin.read(lenBuf, 4))
        throw std::runtime_error("stdin closed before length");

    uint32_t msgLen = *reinterpret_cast<uint32_t*>(lenBuf);
    if (msgLen == 0 || msgLen > 1024 * 1024)
        throw std::runtime_error("implausible message length");

    std::string msg(msgLen, '\0');
    if (!std::cin.read(msg.data(), msgLen))
        throw std::runtime_error("stdin closed before message body");

    logfile << "Raw message: " << msg << "\n";

    // Parse {"url":"<value>"} — simple manual extraction, no JSON lib needed
    auto key = msg.find("\"url\"");
    if (key == std::string::npos)
        throw std::runtime_error("no 'url' key in message");

    auto open = msg.find('"', key + 5);
    if (open == std::string::npos)
        throw std::runtime_error("malformed url value");
    open++;  // skip opening quote
    auto close = msg.find('"', open);
    if (close == std::string::npos)
        throw std::runtime_error("unterminated url string");

    return msg.substr(open, close - open);
}

void SendResponse(bool success, const std::string& error)
{
    std::string body;
    if (success) {
        body = "{\"success\":true}";
    } else {
        body = "{\"success\":false,\"error\":\"" + error + "\"}";
    }

    uint32_t len = static_cast<uint32_t>(body.size());
    std::cout.write(reinterpret_cast<char*>(&len), 4);
    std::cout << body << std::flush;
}

// ── Download ──────────────────────────────────────────────────────────────────

int DownloadFile(const std::string& url, const std::string& destPath)
{
    // Remove stale file first
    std::string rmCmd;
#ifdef _WIN32
    rmCmd = "del /q \"" + destPath + "\" 2>nul";
#else
    rmCmd = "rm -f \"" + destPath + "\"";
#endif
    // Remove stale file first (ignore errors — file may not exist)
    [[maybe_unused]] int rmRet = std::system(rmCmd.c_str());

    // Use curl — universally available on modern Windows 10+, Linux, macOS
    std::string curlCmd = "curl -sL -o \"" + destPath + "\" \"" + url + "\"";
    logfile << "Running: " << curlCmd << "\n";
    int ret = std::system(curlCmd.c_str());
    if (ret != 0) return ERR_DOWNLOAD;

    // Verify a non-empty file was written
    std::error_code ec;
    auto sz = fs::file_size(destPath, ec);
    if (ec || sz == 0) return ERR_DOWNLOAD;

    logfile << "Downloaded " << sz << " bytes to " << destPath << "\n";
    return 0;
}

void LogError(int code, const std::string& detail)
{
    logfile << "Error " << code;
    if (!detail.empty()) logfile << ": " << detail;
    logfile << "\n";
}
