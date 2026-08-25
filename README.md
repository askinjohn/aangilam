# Aangilam

**Understand anything, instantly.**

A native macOS menu-bar translator. Select text in any app, press a shortcut, and read the translation in a floating panel.

---

## What you get

### Translate
- Select text → press the shortcut → see the translation
- **Apple Translation** on-device (macOS 15+), no API key
- **Google Cloud Translation** if you want wider language coverage
- Auto Detect → English by default; source and target are yours to set

### Panel
- Resizable, scrollable floating window
- Original and translation side by side, or translation only
- Copy when you want the result on the clipboard

### Stay out of the way
- Menu bar only — no Dock icon
- Configurable global shortcut
- Launch at login and auto-close, if you want them

---

## Who it’s for

Anyone who reads other languages in Slack, Mail, the browser, or documents and wants the meaning without leaving the page.

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

### First launch

Enable **Aangilam** in **System Settings → Privacy & Security → Accessibility** so it can read the text you select.

---

## Using Aangilam

1. Select text in any app.  
2. Press the translate shortcut (default **`⌘⇧T`**), or **Translate Selection** in the menu bar.  
3. Read the panel. Resize it, scroll, copy, or close it.

**Settings** covers provider, languages, shortcut, popup layout, launch at login, and privacy.

---

## Privacy

Aangilam reads selected text only when you ask for a translation.

- **Apple Translation** runs on your Mac.  
- **Google** is used only if you choose that provider.

---

## License

MIT
