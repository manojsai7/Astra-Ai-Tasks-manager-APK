# 🚀 ASTRA — Premium AI Life Scheduler & Task Manager

![ASTRA Banner](https://img.shields.io/badge/ASTRA-v1.0.0--Release-7C65F4?style=for-the-badge&logo=android&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.29.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-C6FF3D?style=for-the-badge)

---

## 📲 DOWNLOAD THE READY-TO-USE APP (APK)

Get the pre-compiled, production-optimized ASTRA release APK directly on your Android phone!

| Architecture | Recommended Device | Direct Release APK | Size |
|---|---|---|---|
| **ARM64 (64-bit)** | **Modern Android Phones (Recommended)** | [⬇️ Download `app-arm64-v8a-release.apk`](https://github.com/manojsai7/Ai-Tasks-manager/releases/latest/download/app-arm64-v8a-release.apk) | **22.3 MB** |
| ARMv7 (32-bit) | Older Android Devices | [⬇️ Download `app-armeabi-v7a-release.apk`](https://github.com/manojsai7/Ai-Tasks-manager/releases/latest/download/app-armeabi-v7a-release.apk) | **19.9 MB** |

### 📥 How to Install on Your Android Phone:
1. Tap the **[Download `app-arm64-v8a-release.apk`](https://github.com/manojsai7/Ai-Tasks-manager/releases/latest/download/app-arm64-v8a-release.apk)** link above on your phone browser.
2. Open the downloaded file and tap **Install** *(if prompted, enable "Install from Unknown Sources" for your browser)*.
3. Open **ASTRA** and experience the Matiks-inspired AI Life Scheduler!

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
- 🧠 **Multi-Model Gemini AI Chat**: Automatic fallback across `gemini-1.5-flash`, `gemini-2.0-flash`, and `gemini-pro`.
- 💬 **Persistent SQLite Chat Sessions**: Multi-session management, auto-naming from prompts, and full history retention.
- 📧 **Gmail & Calendar Auto-Extraction**: Automatically extracts job applications, exam dates, and deadlines from emails into your timeline.
- 🪔 **Panchang & Fasting Calendar**: Pre-computed Ekadashi, Purnima, and Amavasya ritual rules and reminders.
