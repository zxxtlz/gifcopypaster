#include "gtest/gtest.h"
#include "clipapp.h"
#include <fstream>

// Stub logfile for tests
std::ofstream logfile;

TEST(DownloadFileTest, DownloadRealGif) {
    // Uses a small, stable public GIF
    int err = DownloadFile("https://i.imgur.com/FKSBCVT.mp4", "test_clip.mp4");
    EXPECT_EQ(err, 0);

    std::error_code ec;
    auto sz = fs::file_size("test_clip.mp4", ec);
    EXPECT_FALSE(ec);
    EXPECT_GT(sz, 0u);
}

TEST(CopyToClipboardTest, EmptyPath) {
    // Empty path should return an error code, not crash
    int err = CopyToClipboard("");
    EXPECT_NE(err, 0);
}

TEST(CopyToClipboardTest, MissingFile) {
    // Pointing at a non-existent file — behaviour varies by OS but should not crash
    int err = CopyToClipboard("/nonexistent/path/clip.gif");
    // We don't mandate a specific code, just that it doesn't throw
    (void)err;
    SUCCEED();
}
