"use strict";

// ── Context menu setup ────────────────────────────────────────────────────────

browser.runtime.onInstalled.addListener(() => {
  browser.contextMenus.create({
    id: "copy-gif",
    title: "Copy GIF",
    contexts: ["image", "video"],
  });
});

// ── Context menu click handler ────────────────────────────────────────────────

browser.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId !== "copy-gif") return;

  const url = info.srcUrl;
  if (!url) {
    notify("GifCopyPaster", "Could not determine image URL.");
    return;
  }

  notify("GifCopyPaster", "Copying… please wait.");

  let response;
  try {
    response = await browser.runtime.sendNativeMessage(
      "com.syanth.gifcopier",
      { url }
    );
  } catch (err) {
    notify("GifCopyPaster Error", `Native app not reachable: ${err.message ?? err}`);
    return;
  }

  if (response && response.success) {
    notify("GifCopyPaster", "Copied to clipboard!");
  } else {
    const reason = response?.error ?? "Unknown error";
    notify("GifCopyPaster Error", `Failed to copy: ${reason}`);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

function notify(title, message) {
  browser.notifications.create({
    type: "basic",
    iconUrl: "icons/icon48.png",
    title,
    message,
  });
}
