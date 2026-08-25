# Aangilam

## Complete Product Requirements & Implementation Specification

**Version:** 1.0
**Platform:** macOS
**Application Type:** Native macOS menu-bar utility
**Primary Use Case:** Translate currently selected text instantly
**Default Source Language:** Auto Detect
**Default Target Language:** English
**Default Shortcut:** `⌘⇧T`

---

# 1. IMPORTANT — IMPLEMENTATION INSTRUCTION

This document is the complete specification for the application.

The implementation agent MUST:

* Implement the entire application.
* Make reasonable technical decisions without asking the user questions.
* NOT stop for clarification.
* NOT request an API key.
* NOT request Apple Developer credentials.
* NOT request a preferred UI design.
* NOT request a preferred translation provider.
* NOT leave core functionality as TODO.
* NOT provide only a scaffold.
* NOT stop after creating the Xcode project.
* Build the application.
* Test the application.
* Create the `.app`.
* Create the `.dmg`.

If a required external credential is unavailable, implement the application completely and make the credential configurable later.

The final application must be usable without an API key except for the actual live translation request.

---

# 2. PRODUCT NAME

The application name is:

**Aangilam**

Use this exact name throughout the project.

The application bundle should be:

**Aangilam.app**

The installer should be:

**Aangilam.dmg**

Suggested tagline:

**Understand anything, instantly.**

Do not rename the product.

---

# 3. CORE PRODUCT CONCEPT

Aangilam is a system-wide translation utility.

The user selects text in another application and presses:

**`⌘⇧T`**

Aangilam retrieves the selected text, translates it, and displays the result in a small floating popup.

The user should NOT need to:

* Copy the text manually.
* Open a browser.
* Open Google Translate.
* Open another translation application.
* Paste the text.
* Switch applications.

The ideal workflow is exactly:

**Select → `⌘⇧T` → Translation**

---

# 4. PRIMARY USER WORKFLOW

The primary workflow MUST be:

```text
1. User opens Slack.
2. User receives a Swedish message.
3. User selects the Swedish text with the mouse/trackpad.
4. User presses ⌘⇧T.
5. Aangilam retrieves the selected text.
6. Aangilam automatically detects the source language.
7. Aangilam translates it to English.
8. Aangilam displays the translation in a floating popup.
9. User reads the translation.
10. User can optionally click Copy.
```

There must be NO manual `⌘C` step in the normal workflow.

---

# 5. PRIMARY INPUT METHOD

The primary input mechanism is:

**Currently selected text from the active macOS application.**

Aangilam should attempt to retrieve selected text using macOS Accessibility APIs.

The application must request the necessary macOS Accessibility permission.

The user should see a clear explanation when permission has not yet been granted.

Example:

> Aangilam needs Accessibility permission to read the text you select in other applications.

Button:

**Open System Settings**

---

# 6. ACCESSIBILITY IMPLEMENTATION

Use macOS Accessibility APIs to retrieve selected text from the currently focused application.

The implementation should:

1. Detect the currently focused application.
2. Access the focused UI element.
3. Request its selected-text attribute.
4. Retrieve the selected text.
5. Trim unnecessary whitespace.
6. Validate that usable text exists.
7. Pass the text to the translation service.

The implementation must work with applications that expose selected text through Accessibility APIs.

Primary target:

**Slack**

The implementation should also work with common applications such as:

* Safari
* Chrome
* Microsoft Teams
* Mail
* Notes
* TextEdit
* Messages
* VS Code
* Other standard macOS text applications

Do not build application-specific integrations.

---

# 7. FALLBACK INPUT METHOD

Not every macOS application exposes selected text through Accessibility APIs.

Therefore Aangilam MUST have a fallback.

If selected text cannot be retrieved:

1. Do NOT silently fail.
2. Check whether the clipboard contains usable text.
3. If clipboard text exists, offer/use it as fallback.
4. Clearly indicate that clipboard fallback was used if appropriate.

Fallback message:

> I couldn't access the selected text. I found text in your clipboard and can translate that instead.

Button:

**Translate Clipboard**

Alternative simple fallback behavior:

If clipboard text exists, automatically translate it.

The preferred behavior is:

**Selected text → Accessibility**

Fallback:

**Clipboard text → Clipboard**

The clipboard must NEVER be the primary workflow.

---

# 8. NO CLIPBOARD REQUIREMENT FOR NORMAL USE

The normal workflow must NOT modify or require the clipboard.

Example:

```text
User copies something unrelated.
       ↓
User selects Swedish text in Slack.
       ↓
User presses ⌘⇧T.
       ↓
Aangilam translates selected text.
       ↓
Clipboard remains untouched.
```

The application must not read or monitor the clipboard continuously.

Clipboard access should only happen when required as a fallback.

---

# 9. GLOBAL KEYBOARD SHORTCUT

Default global shortcut:

**`⌘⇧T`**

Meaning:

**Command + Shift + T**

Reason:

* T represents Translate.
* Easy to remember.
* Appropriate for a translation utility.
* Avoids `⌘R`, which commonly means Reload/Refresh.
* Suitable for system-wide use.

The shortcut must work while another application is active.

Example:

```text
Slack active
       ↓
Select text
       ↓
⌘⇧T
       ↓
Aangilam
```

---

# 10. SHORTCUT CONFLICT HANDLING

If `⌘⇧T` cannot be registered:

* Do not crash.
* Do not silently choose another shortcut.
* Show a clear message.
* Allow the user to configure another shortcut.

Message:

> `⌘⇧T` is unavailable because another application is using it.

Button:

**Change Shortcut**

Recommended alternatives:

* `⌘⇧Y`
* `⌘⌥T`
* `⌃⌥T`

The user must be able to record a custom shortcut.

---

# 11. MENU-BAR APPLICATION

Aangilam must run as a menu-bar utility.

It should not show a normal main application window on launch.

The menu-bar menu should contain:

```text
Aangilam

Translate Selection       ⌘⇧T

────────────────────

Settings

About Aangilam

────────────────────

Quit Aangilam
```

Clicking:

**Translate Selection**

must perform the exact same action as pressing `⌘⇧T`.

---

# 12. TRANSLATION DEFAULTS

Default source:

**Auto Detect**

Default target:

**English**

The user should not have to choose Swedish manually.

For example:

```text
Swedish → English
German → English
French → English
Japanese → English
Tamil → English
Spanish → English
```

The application must support any language supported by the selected translation provider.

The product itself must NOT be designed specifically for Swedish.

Swedish is only the primary development/test example.

---

# 13. LANGUAGE SETTINGS

Settings must allow:

### Source language

Default:

**Auto Detect**

Available:

* Auto Detect
* Provider-supported languages

### Target language

Default:

**English**

Available:

* Provider-supported languages

The user can change the target language.

Example:

```text
Source: Auto Detect
Target: English
```

or:

```text
Source: Swedish
Target: German
```

---

# 14. TRANSLATION PROVIDER

Use:

**Google Cloud Translation API**

for the production translation implementation.

Do not ask the user to choose a provider.

Do not implement multiple providers in the MVP.

However, isolate the provider behind a translation service abstraction so additional providers can be added later.

Architecture:

```text
TranslationService
        │
        └── GoogleTranslationService
```

The UI must never directly call Google APIs.

---

# 15. API KEY — CRITICAL REQUIREMENT

The API key is NOT required to build the application.

The API key is NOT required to package the application.

The API key is NOT required to run the application.

The API key is only required to perform a real translation using Google.

The agent must NOT ask the user for the API key.

The agent must NOT stop development because no API key exists.

The user will add the API key after installation.

Initial state:

```text
Provider:
Google Cloud Translation

API Key:
Not configured
```

---

# 16. MISSING API KEY BEHAVIOR

If the user selects text and presses `⌘⇧T` without an API key:

Show:

```text
Translation isn't configured yet.

Add your Google Cloud Translation API key
in Aangilam Settings to start translating.

[ Open Settings ]
```

This is an expected state.

The application must continue working normally.

---

# 17. API KEY STORAGE

Store the API key using:

**macOS Keychain**

Never store the API key in:

* Source code
* Git
* UserDefaults
* JSON configuration files
* Plain-text files
* Logs
* Application bundle

The API key must never be committed to the repository.

---

# 18. API KEY SETTINGS

Settings must provide:

```text
Translation Provider

Google Cloud Translation

API Key
[••••••••••••••••]

[ Save ]

[ Test Connection ]

[ Remove API Key ]
```

The full API key must not be displayed after saving.

The user must be able to replace it.

---

# 19. TRANSLATION REQUEST

When translation is requested:

1. Obtain selected text.
2. Validate text.
3. Determine source language automatically unless manually configured.
4. Determine target language.
5. Display loading popup.
6. Send HTTPS request to Google Cloud Translation API.
7. Receive translated text.
8. Display translated text.
9. Allow copying the result.

All API requests must be asynchronous.

Never block the UI thread.

---

# 20. TRANSLATION POPUP

The translation result must appear in a small floating macOS-style window.

The popup should appear near the mouse pointer when technically reliable.

If positioning is unreliable, center it on the active display.

Example:

```text
┌─────────────────────────────────────────┐
│ Swedish                         🇸🇪     │
│                                         │
│ Kan vi ta det här på mötet imorgon?    │
│                                         │
│ English                         🇬🇧     │
│                                         │
│ Can we discuss this in tomorrow's      │
│ meeting?                                │
│                                         │
│                               Copy      │
└─────────────────────────────────────────┘
```

---

# 21. POPUP UI REQUIREMENTS

The popup must:

* Be compact.
* Have rounded corners.
* Have a native macOS appearance.
* Support light mode.
* Support dark mode.
* Have a subtle shadow.
* Display source language.
* Display original text.
* Display target language.
* Display translated text.
* Have a Copy button.
* Support long text.
* Support scrolling.
* Close with Escape.
* Close when clicking outside.
* Support keyboard navigation.

Do not open a large application window.

---

# 22. LOADING STATE

Immediately after `⌘⇧T`:

Show:

> Translating…

The popup should appear immediately.

Do not wait for the API response before displaying the popup.

---

# 23. COPY TRANSLATION

The translation popup must have:

**Copy**

When the user clicks Copy:

* Put translated text into the clipboard.
* Close the popup or visually confirm the copy.
* Show brief confirmation:

> Copied ✓

The clipboard should only be changed when the user explicitly clicks Copy.

---

# 24. EMPTY SELECTION

If there is no selected text:

First attempt clipboard fallback.

If no clipboard text exists:

Show:

> No text selected.

Secondary message:

> Select some text and press `⌘⇧T`.

Do not call the translation API.

---

# 25. LONG TEXT

Support long selected text.

The popup should:

* Limit its maximum width.
* Limit its maximum height.
* Make content scrollable.
* Keep the Copy button visible.

Do not allow very long text to create an enormous popup.

---

# 26. ERROR STATES

## No Accessibility Permission

Show:

> Aangilam needs Accessibility permission to translate selected text.

Button:

**Open System Settings**

---

## No API Key

Show:

> Translation isn't configured yet.

Button:

**Open Settings**

---

## Invalid API Key

Show:

> Your translation API key is invalid.

Button:

**Open Settings**

---

## Network Failure

Show:

> Unable to connect to the translation service.

Button:

**Retry**

---

## API Rate Limit

Show:

> Translation limit reached.

Secondary:

> Check your Google Cloud Translation account.

---

## Unknown Error

Show:

> Something went wrong while translating.

Button:

**Retry**

Never show raw API errors to the user.

---

# 27. SETTINGS

Create a native macOS Settings window.

Sections:

## Translation

```text
Source Language
Auto Detect

Target Language
English

Provider
Google Cloud Translation

API Key
••••••••••••

[ Save ]

[ Test Connection ]
```

## Shortcut

```text
Translate Selection

⌘⇧T

[ Change Shortcut ]
```

## General

```text
Launch at Login        [ OFF ]

Automatically close popup [ OFF ]

Popup timeout          [ 15 seconds ]
```

## Privacy

Explain:

> Aangilam only accesses selected text when you request a translation. It does not continuously monitor your clipboard or Slack.

---

# 28. LAUNCH AT LOGIN

Provide:

**Launch at Login**

Default:

**OFF**

When enabled:

* Aangilam starts automatically.
* It runs as a menu-bar utility.
* It does not open a large window.

Use the appropriate native macOS mechanism for launch-at-login behavior.

---

# 29. POPUP AUTO-CLOSE

Provide:

**Automatically close popup**

Default:

**OFF**

If enabled:

Default timeout:

**15 seconds**

Allow reasonable values between:

**5–60 seconds**

---

# 30. ACCESSIBILITY PERMISSION

On first attempt to use selected-text translation:

If Accessibility permission is missing:

1. Explain why it is required.
2. Provide a button to open the correct macOS System Settings page.
3. Do not crash.
4. After permission is granted, allow the user to retry.

The application must detect whether permission is available.

---

# 31. PRIVACY

Aangilam must NOT:

* Continuously monitor clipboard changes.
* Continuously monitor Slack.
* Read Slack APIs.
* Record user activity.
* Track applications.
* Upload text without user action.
* Maintain a user account.
* Store translation history remotely.
* Send analytics in MVP.

Text is sent to Google only after the user explicitly requests translation.

---

# 32. SECURITY

Use HTTPS for all translation requests.

Never log:

* API keys.
* Selected text.
* Translated text.

Do not include credentials in crash logs.

Do not include API credentials in the repository.

Use macOS Keychain for credentials.

---

# 33. DEVELOPMENT WITHOUT API KEY

The agent must implement a mock translation provider for testing.

Architecture:

```text
TranslationService
       │
       ├── GoogleTranslationService
       │
       └── MockTranslationService
```

Mock provider is for development/tests only.

Example:

Input:

```text
Kan vi ta det här på mötet imorgon?
```

Mock output:

```text
Can we discuss this in tomorrow's meeting?
```

This allows the agent to verify the complete workflow without credentials.

The production build must use Google Translation.

The production build must start with no API key configured.

---

# 34. TESTING WITHOUT API KEY

The agent MUST test the following without requiring a real API key:

* App launch.
* Menu bar.
* Settings.
* Accessibility permission state.
* Shortcut registration.
* Selection retrieval.
* Clipboard fallback.
* Loading popup.
* Translation popup.
* Copy button.
* Clipboard behavior.
* Error states.
* Settings persistence.
* Keychain behavior.
* Mock translation workflow.

The agent must not claim that live Google translation was tested if no API key was available.

---

# 35. CLIPBOARD FALLBACK TEST

Test this exact scenario:

1. Select text in an application that does not expose selected text.
2. Copy some text.
3. Press `⌘⇧T`.
4. Aangilam should use the clipboard fallback.

The fallback must be documented in the README.

---

# 36. APPLICATION ARCHITECTURE

Use native:

* Swift
* SwiftUI
* AppKit where necessary
* Foundation
* URLSession
* Security/Keychain APIs
* Accessibility APIs
* Native macOS menu-bar APIs

Avoid Electron.

Avoid unnecessary third-party frameworks.

The application should have low CPU and memory usage while idle.

---

# 37. RECOMMENDED PROJECT STRUCTURE

```text
Aangilam/
│
├── App/
│   ├── AangilamApp.swift
│   └── AppDelegate.swift
│
├── Accessibility/
│   └── SelectedTextReader.swift
│
├── Clipboard/
│   └── ClipboardManager.swift
│
├── Shortcut/
│   └── GlobalShortcutManager.swift
│
├── Translation/
│   ├── TranslationService.swift
│   ├── GoogleTranslationService.swift
│   ├── MockTranslationService.swift
│   └── TranslationModels.swift
│
├── Popup/
│   ├── TranslationPopupView.swift
│   └── PopupController.swift
│
├── MenuBar/
│   └── MenuBarView.swift
│
├── Settings/
│   └── SettingsView.swift
│
├── Security/
│   └── KeychainManager.swift
│
├── Tests/
│
└── Resources/
```

The exact structure may differ, but the separation of responsibilities must remain.

---

# 38. APPLICATION STATE

Implement clear states:

```text
ready
readingSelection
loading
translated
noSelection
accessibilityPermissionRequired
apiKeyMissing
authenticationError
networkError
rateLimited
unknownError
```

The UI must react appropriately to each state.

---

# 39. APPLICATION STARTUP

When Aangilam launches:

1. Start as a menu-bar application.
2. Register the global shortcut.
3. Load settings.
4. Check API-key availability.
5. Do NOT call the translation API.
6. Do NOT read the clipboard.
7. Do NOT request translation.
8. Remain idle.

The application should consume minimal resources while idle.

---

# 40. FIRST RUN

On first launch:

Show a lightweight onboarding/settings experience only if necessary.

Explain:

> Aangilam translates text you select anywhere on your Mac.

Then:

> To use `⌘⇧T`, Aangilam needs Accessibility permission.

Provide:

**Open Accessibility Settings**

Do not require API-key configuration during onboarding.

The user should be able to configure the API key later.

---

# 41. MENU BAR STATUS

The menu-bar icon should indicate the app is running.

If API key is missing, do NOT make the entire app appear broken.

The application can optionally show a small status indicator in Settings, but the menu-bar icon should remain normal.

---

# 42. ABOUT SCREEN

About should display:

**Aangilam**

**Understand anything, instantly.**

Version number.

A simple statement:

> A lightweight macOS utility for instant text translation.

---

# 43. ACCESSIBILITY AND KEYBOARD SUPPORT

Support:

* VoiceOver where practical.
* Keyboard navigation.
* Escape to close popup.
* Enter to Copy when Copy is focused.
* Standard macOS accessibility labels.

---

# 44. PERFORMANCE

The application must:

* Start quickly.
* Remain lightweight.
* Not continuously poll other applications.
* Not continuously monitor clipboard.
* Perform translation asynchronously.
* Avoid unnecessary background processes.

---

# 45. SUPPORTED MACOS

Build for modern macOS.

Use the minimum deployment target that is practical for the native APIs used.

Prefer compatibility with recent supported macOS versions rather than requiring the newest OS unnecessarily.

The agent should choose the appropriate deployment target based on the available Xcode/macOS build environment.

Do not ask the user.

---

# 46. DISTRIBUTION

Create:

**Aangilam.dmg**

The DMG should contain:

```text
Aangilam.app
        ↓
Applications
```

The DMG should be clean and simple.

The user should be able to drag the application into Applications.

---

# 47. CODE SIGNING

If Apple Developer credentials are available:

* Sign the app.
* Sign the DMG where appropriate.
* Notarize the application if possible.

If Apple Developer credentials are NOT available:

* Build the application anyway.
* Create an unsigned DMG.
* Do not stop.
* Clearly document that macOS may display a Gatekeeper warning.
* Provide instructions in README for opening the unsigned app.

Never claim notarization unless it was actually completed.

---

# 48. README REQUIREMENTS

Create a comprehensive README containing:

## What Aangilam does

Explain:

> Select text anywhere → press `⌘⇧T` → get a translation.

## Installation

Explain how to install the DMG.

## Accessibility Permission

Explain why it is needed and how to enable it.

## API Key

Explain that the API key is optional during installation but required for live translation.

Explain:

1. Obtain Google Cloud Translation API credentials.
2. Open Aangilam Settings.
3. Paste API key.
4. Save.
5. Test Connection.

## Keyboard Shortcut

Explain:

`⌘⇧T`

## Clipboard Fallback

Explain that selected text is the primary method and clipboard is only used when selected text cannot be retrieved.

## Troubleshooting

Cover:

* Accessibility permission
* Shortcut conflict
* Missing API key
* Invalid API key
* Network problems
* Gatekeeper warning

---

# 49. TEST CASES

The agent MUST execute or implement tests for:

## Test 1 — Swedish

Input:

```text
Kan vi ta det här på mötet imorgon?
```

Expected mock output:

```text
Can we discuss this in tomorrow's meeting?
```

## Test 2 — German

Input:

```text
Wie geht es dir?
```

Expected:

A valid English translation.

## Test 3 — Tamil

Input:

Tamil text.

Expected:

Valid English translation through the translation provider/mock.

## Test 4 — Japanese

Input:

Japanese text.

Expected:

Valid English translation.

## Test 5 — Unicode

Input containing:

```text
å ä ö é ü 日本語 தமிழ் 한국어
```

Must not corrupt text.

## Test 6 — Multi-line

Input containing multiple lines.

Must preserve readable formatting.

## Test 7 — No selection

Must show the no-selection/fallback state.

## Test 8 — No API key

Must show configuration message.

## Test 9 — Copy

Copy button must place translation in clipboard.

## Test 10 — Clipboard preservation

Normal selected-text translation must NOT modify clipboard.

## Test 11 — Accessibility unavailable

Must show permission instructions.

## Test 12 — Shortcut conflict

Must show conflict handling.

## Test 13 — Network failure

Must show retry state.

---

# 50. ACCEPTANCE TEST — PRIMARY WORKFLOW

The most important acceptance test is:

```text
1. Open Slack.
2. Find a Swedish message.
3. Select the message text.
4. Do NOT press ⌘C.
5. Press ⌘⇧T.
6. Aangilam retrieves the selection.
7. Aangilam shows the translation popup.
8. English translation appears.
9. Click Copy.
10. Paste the translation into another application.
```

This is the primary product experience.

If the user has to press `⌘C` during the normal workflow, the implementation has failed the primary UX requirement.

---

# 51. SECONDARY ACCEPTANCE TEST — CLIPBOARD FALLBACK

```text
1. Use an application that does not expose selected text.
2. Copy text.
3. Press ⌘⇧T.
4. Aangilam detects that selected text is unavailable.
5. Aangilam uses clipboard text.
6. Translation appears.
```

---

# 52. ACCEPTANCE TEST — NO API KEY

```text
1. Install Aangilam.
2. Do not configure an API key.
3. Launch Aangilam.
4. Menu bar appears.
5. Settings opens.
6. Shortcut works.
7. Select text.
8. Press ⌘⇧T.
9. Aangilam displays:
   "Translation isn't configured yet."
10. Open Settings works.
```

The app must NOT crash.

The app must NOT refuse to launch.

The app must NOT refuse to build.

---

# 53. FINAL BUILD REQUIREMENTS

The implementation agent MUST produce:

1. Complete Xcode project.
2. Complete source code.
3. Unit tests.
4. UI/integration tests where practical.
5. README.
6. Working `.app`.
7. Working `.dmg`.
8. No API key embedded in the project.
9. No credentials committed to source.
10. Production configuration using Google Translation as provider.
11. Mock provider for credential-free testing.

---

# 54. FINAL OUTPUT

The final deliverable must be:

**Aangilam.dmg**

The agent must provide the exact path to the generated DMG.

Example:

```text
build/Aangilam.dmg
```

The agent must verify that the file exists before declaring the task complete.

---

# 55. ABSOLUTE IMPLEMENTATION RULES

The agent must follow these rules:

### Rule 1

Do not ask the user questions.

### Rule 2

Do not wait for an API key.

### Rule 3

Do not wait for Apple Developer credentials.

### Rule 4

Do not stop at project scaffolding.

### Rule 5

Do not implement clipboard as the primary workflow.

### Rule 6

The primary workflow is:

**Select → `⌘⇧T` → Translate**

### Rule 7

Clipboard is only the fallback.

### Rule 8

Do not continuously monitor clipboard.

### Rule 9

Do not build a Slack integration.

### Rule 10

Do not build a web application.

### Rule 11

Build a native macOS menu-bar utility.

### Rule 12

Use Google Cloud Translation as the live translation provider.

### Rule 13

Store API credentials in Keychain.

### Rule 14

Support Auto Detect → English by default.

### Rule 15

Make source and target languages configurable.

### Rule 16

Handle missing API credentials gracefully.

### Rule 17

Use a mock provider to test the application without credentials.

### Rule 18

Create the `.app`.

### Rule 19

Create the `.dmg`.

### Rule 20

Do not declare completion until the build and DMG have been verified.

---

# 56. DEFINITION OF DONE

Aangilam is DONE only when this works:

```text
                 AANGILAM

          Select text anywhere
                   ↓
                ⌘⇧T
                   ↓
        Read selected text
                   ↓
           Detect language
                   ↓
             Translate
                   ↓
        ┌──────────────────┐
        │ English           │
        │                   │
        │ Translation text  │
        │                   │
        │       Copy        │
        └──────────────────┘
```

The user should experience the application as:

> **“I select something, press `⌘⇧T`, and immediately understand it.”**

That is the entire core product.

Everything else is secondary.
