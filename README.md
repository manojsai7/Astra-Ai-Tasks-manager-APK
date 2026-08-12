# 🚀 ASTRA — Premium AI Life Scheduler & Task Manager

![ASTRA Banner](https://img.shields.io/badge/ASTRA-v1.0.0--Release-7C65F4?style=for-the-badge&logo=android&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.29.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Auto-Update](https://img.shields.io/badge/Auto--Update-GitHub%20Releases-2EA44F?style=for-the-badge&logo=github&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-C6FF3D?style=for-the-badge)

---

## 📲 DOWNLOAD THE LATEST APK

> The app checks for updates automatically on startup. If you received an "Update Available" prompt, tap **Download & Install** and follow the Android installer.

Get the latest pre-compiled ASTRA release APK directly on your Android phone:

| Architecture | Recommended For | Download |
|---|---|---|
| **ARM64 (64-bit)** | **All modern phones (Recommended)** | [⬇️ `app-arm64-v8a-release.apk`](https://github.com/manojsai7/Ai-Tasks-manager/releases/latest/download/app-arm64-v8a-release.apk) |
| ARMv7 (32-bit) | Older Android devices | [⬇️ `app-armeabi-v7a-release.apk`](https://github.com/manojsai7/Ai-Tasks-manager/releases/latest/download/app-armeabi-v7a-release.apk) |

### 📥 How to Install on Your Android Phone
1. Tap the **ARM64 download link** above on your phone browser.
2. Open the downloaded file → tap **Install**.  
   *(If prompted, enable "Install from Unknown Sources" for your browser.)*
3. Open **ASTRA** — done!

---

## 🔄 HOW TO PUSH AN UPDATE TO YOUR USERS

> This is the complete release workflow. Every time you update the app, follow these 3 steps — your users will be notified automatically next time they open ASTRA.

### Step 1 — Bump the Version in `pubspec.yaml`
```yaml
# pubspec.yaml
version: 1.1.0+2   # ← change BOTH the name (1.1.0) and build number (+2)
```
- **`1.1.0`** is what users see (e.g. "v1.1.0 is available")
- **`+2`** is the Android build number (must always increase)

### Step 2 — Build the Split Release APKs
```bash
flutter build apk --release --split-per-abi
```
This produces 3 APKs in `build/app/outputs/flutter-apk/`:
```
app-arm64-v8a-release.apk      ← most phones (upload this)
app-armeabi-v7a-release.apk    ← older phones (upload this too)
app-x86_64-release.apk         ← emulator only (skip)
```

### Step 3 — Create a GitHub Release
1. Go to **[github.com/manojsai7/Ai-Tasks-manager/releases/new](https://github.com/manojsai7/Ai-Tasks-manager/releases/new)**
2. Set the **Tag** to match your version: `v1.1.0`
3. Write release notes (they show in the update dialog inside ASTRA)
4. Upload both APK files from `build/app/outputs/flutter-apk/`
5. Click **Publish Release**

> ✅ That's it. Every user who opens ASTRA will see the "Update Available" sheet within seconds.

### How It Works (Under the Hood)
```
User opens ASTRA
      │
      ▼ (after first frame, silently)
AppUpdater.check()
      │
      ▼
GET https://api.github.com/repos/manojsai7/Ai-Tasks-manager/releases/latest
      │
      ▼
Compare latestVersion (from GitHub tag) vs currentVersion (from pubspec)
      │
      ┌──────────────┬──────────────────────────────────────────┐
      ▼              ▼
  Same version    Newer version available
  → silent        → Show "Update Available" bottom-sheet
                         │
                         ▼ User taps "Download & Install"
                  Opens GitHub CDN APK link in browser
                         │
                         ▼
                  Android downloads & prompts installer
                         │
                         ▼
                  User taps Install → updated ✅
```

**No server. No billing. No Play Store approval wait. GitHub's CDN is free and fast.**

---

## 💻 QUICK RUN & BUILD GUIDE FOR DEVELOPERS

### 1️⃣ Clone & Install Dependencies
```bash
git clone https://github.com/manojsai7/Ai-Tasks-manager.git
cd Ai-Tasks-manager
flutter pub get
```

### 2️⃣ Run on Connected Device / Emulator
```bash
flutter run
```

### 3️⃣ Build Production Split Release APKs
```bash
flutter build apk --release --split-per-abi
```
The compiled APK will be at: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## 🔑 WHERE TO ADD API KEYS (Step-by-Step)

You need **3 types of credentials**. Here is exactly where they go:

### 1. 🤖 Gemini API Key (For AI Context Extraction)
This is a simple text string used to call Google's Gemini AI.

- **Where to get it**: Go to [Google AI Studio](https://aistudio.google.com/app/apikey) → Click "Create API Key".
- **Where to put it**: Edit `assets/.env`:
   ```env
   GEMINI_API_KEY=YOUR_ACTUAL_GEMINI_API_KEY_HERE
   ```

---

### 2. 📱 Google OAuth 2.0 Client ID (For Gmail + Calendar Sync)
Configured via `android/app/google-services.json`.

#### How to get SHA-1 Fingerprint:
In your terminal, run:
```bash
cd android
./gradlew signingReport
```
Copy the `SHA-1` fingerprint under the `debug` variant and add it to your Google Cloud Console Android OAuth client.

Place `google-services.json` in: [`android/app/google-services.json`](file:///b:/Projects/astra/android/app/google-services.json).

---

### 3. 🔓 Enable APIs in Google Cloud Console
1. Go to [Google Cloud Console > APIs & Services > Library](https://console.cloud.google.com/apis/library).
2. Search for **Gmail API** and click **Enable**.
3. Search for **Google Calendar API** and click **Enable**.

---

## ✨ KEY FEATURES

- 🎨 **Matiks-Inspired Design System**: Dynamic dark mode (`#0A0A0F`), sleek glassmorphism, accent purple, neon lime, and custom display typography.
- 🧠 **Multi-Model Gemini AI Chat**: Automatic fallback across `gemini-3.5-flash` and `gemini-2.5-pro`.
- 🔍 **Email Classifier**: Zero-cost rule-based filter that drops newsletters and promotions before they reach Gemini — only real task emails create tasks.
- ⏰ **Smart Task Parser**: Understands "remind me to take water in 2 mins" and sets the actual reminder time locally — no API call.
- 💬 **Persistent SQLite Chat Sessions**: Multi-session management, auto-naming from prompts, and full history retention.
- 📧 **Gmail & Calendar Auto-Extraction**: Automatically extracts job applications, exam dates, and deadlines from emails into your timeline.
- 🪔 **Panchang & Fasting Calendar**: Pre-computed Ekadashi, Purnima, and Amavasya ritual rules and reminders.
- 🔄 **Auto-Update via GitHub Releases**: Silently checks for new versions on startup — users get a one-tap install prompt when you push a release.
