# Aangilam

**Understand anything, instantly.**

A native macOS menu-bar translator. Select text in any app, press a shortcut, and read the translation in a floating panel. No browser, no copy-paste in the usual flow.

---

## What you get

### Translate
- **Select → shortcut → translation** — default `⌘⇧T`
- **Apple Translation** — on-device, no API key (macOS 15+)
- **Google Cloud Translation** — optional, for broader language coverage
- **Auto Detect → English** by default; source and target are configurable

### Capture
- Reads **selected text** via Accessibility when the app exposes it
- For editors that hide selection (Slack, VS Code, Chrome), copies internally and **restores your clipboard**
- Clipboard fallback only when selection cannot be read

### Panel
- Resizable, scrollable floating window
- Original + translation side by side, or **translation only**
- Copy the result when you want it on the clipboard

### Stay out of the way
- Menu bar only — no Dock icon
- Launch at login (off by default)
- Optional auto-close for the panel

---

## Who it’s for

Anyone who needs to understand text in other apps without switching to a translator — Slack, Mail, the browser, code, or documents.

---

## Requirements

| | |
|--|--|
| **OS** | macOS 14+ (Apple Translation needs macOS 15+) |
| **Build** | Xcode 15+ |
| **Apple Translation** | No account, no key |
| **Google (optional)** | Cloud Translation API key |

---

## Get started

```bash
git clone https://github.com/askinjohn/aangilam.git
cd aangilam
chmod +x Scripts/package_dmg.sh Scripts/run.sh
./Scripts/package_dmg.sh
./Scripts/run.sh
```

| Output | Where |
|--------|--------|
| App | `./build/Aangilam.app` |
| Disk image | `./build/Aangilam.dmg` |

Or open `Aangilam.xcodeproj` in Xcode and run the **Aangilam** scheme.

The first time you open an unsigned build, macOS may show a Gatekeeper warning: **System Settings → Privacy & Security → Open Anyway**, or right-click the app → **Open**.

### First launch permissions

| Permission | Purpose |
|------------|---------|
| Accessibility | Read the text you selected in another app |

Enable **Aangilam** in **System Settings → Privacy & Security → Accessibility**, then quit and reopen the app.

---

## Using Aangilam

1. Select text in any app.  
2. Press **`⌘⇧T`** (or **Translate Selection** in the menu bar).  
3. Read the panel. Drag a corner to resize. Close with **×** or Escape.  
4. Click **Copy** only if you want the translation on the clipboard.

**Slack** already uses `⌘⇧T` for Threads. Change Aangilam’s shortcut in **Settings → Shortcut** (for example `⌘⇧Y`, `⌘⌥T`, or `⌃⌥T`).

**Settings**

| Tab | What it controls |
|-----|------------------|
| Translation | Provider (Apple or Google), languages, Google API key |
| Shortcut | Global shortcut |
| General | Launch at login, popup layout (original + translation, or translation only), auto-close |
| Privacy | What Aangilam does and does not access |

---

## Google Cloud Translation (optional)

Apple Translation is the default and needs no key. To use Google:

1. Enable **Cloud Translation API** in a Google Cloud project.  
2. Create an API key (restrict it to Translation if you can).  
3. **Aangilam → Settings → Translation → Google Cloud Translation**.  
4. Paste the key → **Save** → **Test Connection**.

The key is stored in the macOS Keychain, not in the project.

The first **500,000 characters per month** on Google’s Basic API are free; usage after that is billed by Google.

---

## Privacy

Aangilam only reads selected text when you ask for a translation. It does not watch Slack or the clipboard in the background.

- **Apple Translation** runs on your Mac.  
- **Google** is used only if you choose that provider and press translate.

---

## Development

```bash
xcodebuild -scheme Aangilam -destination 'platform=macOS' test
./Scripts/package_dmg.sh
```

Unit tests use a mock translator. Set `AANGILAM_USE_MOCK=1` in Debug to skip live providers.

---

## License

MIT
