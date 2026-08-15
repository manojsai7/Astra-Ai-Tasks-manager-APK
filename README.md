# 🚀 ASTRA — Production AI Assistant & Life Operating System

![ASTRA Banner](https://img.shields.io/badge/ASTRA-v1.0.0--Release-7C65F4?style=for-the-badge&logo=android&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-3.29.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-228%20Passing-brightgreen?style=for-the-badge&logo=dart)
![Auto-Update](https://img.shields.io/badge/Auto--Update-GitHub%20Releases-2EA44F?style=for-the-badge&logo=github&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-C6FF3D?style=for-the-badge)

---

## 📲 DOWNLOAD THE LATEST APK

> The app automatically checks for releases on startup. If an update is available, you will receive a clean in-app prompt with changelog notes.

Get the latest release APK directly for your Android phone:

| Architecture | Recommended For | Download Link |
|---|---|---|
| **ARM64 (64-bit)** | **All modern Android phones (Recommended)** | [⬇️ `app-arm64-v8a-release.apk`](https://github.com/manojsai7/Ai-Tasks-manager/releases/latest/) |
| ARMv7 (32-bit) | Older Android devices | [⬇️ `app-armeabi-v7a-release.apk`](https://github.com/manojsai7/Ai-Tasks-manager/releases/latest/download/app-armeabi-v7a-release.apk) |

### 📥 Installation Steps:
1. Tap the **ARM64 download link** on your device.
2. Open the downloaded `.apk` file $\rightarrow$ tap **Install**.  
   *(Enable "Install from Unknown Sources" if prompted by your browser).*
3. Open **ASTRA** $\rightarrow$ Ready to go!

---

## 🧠 SYSTEM ARCHITECTURE & AI PIPELINE

ASTRA is built with a **deterministic + ML hybrid architecture** prioritizing zero silent failures, exact-time local reminders, and bi-directional Google Calendar sync.

```text
User Input Query
      │
      ▼
Set A Intent Classifier (FastAPI ML + Deterministic Rules)
      │
      ├─► LIST_TASKS / SYNC_EMAIL / GET_PANCHANG / COMPLETE_TASK (Authoritative Fast-Path)
      │
      └─► CREATE_TASK / CREATE_REMINDER / CREATE_CALENDAR_EVENT / UPDATE_TASK
            │
            ▼
      Set B Event Classifier (TF-IDF + Ridge Classifier)
            │
            ▼
      AstraSemanticEngine (Entity, Action & Title Extraction)
            │
            ▼
      AstraTemporalEngine (IST Canonical Time & Recurrence Parsing: DAILY, WEEKDAYS, WEEKLY, MONTHLY)
            │
            ▼
      AstraExecutionGate (Safety Check: Past-Time & Ambiguity Confirmation)
            │
      ┌─────┴────────────────────────┐
      ▼                              ▼
  CONFIRM (Disambiguation)        EXECUTE
                                     │
                                     ▼
                           AstraCommandExecutor
                                     │
                         ┌───────────┴────────────┐
                         ▼                        ▼
               Local Drift DB Task        Google Calendar Writer
              + Exact Alarm Reminders      (Best-Effort Non-Blocking Sync)
```

### Key Architectural Invariants:
1. **Safety & Ambiguity Gate:** Multi-match task updates or ambiguous times (e.g. `today at 6pm` when current time is 9pm) require explicit user confirmation.
2. **Local-First Reliability:** Google Calendar failures or offline mode **never destroy or drop** local task creation.
3. **Exact Android Alarms:** Diagnostic logging tracks `exactAllowWhileIdle` vs fallback scheduling across Android versions.
4. **Interactive Request Cancellation:** Real-time generation tokens allow users to **STOP** active processing instantly without late database side-effects.

---

## 💻 DEVELOPER SETUP & LOCAL RUN

### 1️⃣ Prerequisites
- Flutter SDK `3.29.0` or later
- Python 3.10+ (for FastAPI local classifier server)
- Android SDK (API 33+ recommended for exact alarms)

### 2️⃣ Clone & Install
```bash
git clone https://github.com/manojsai7/Ai-Tasks-manager.git
cd Ai-Tasks-manager
flutter pub get
```

### 3️⃣ Backend ML Server Setup
```bash
cd server
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 4️⃣ Run the Flutter App
```bash
# Point to your local server IP (or emulator localhost)
flutter run --dart-define=ASTRA_BACKEND_URL=http://<YOUR_LAN_IP>:8000
```

---

## 🧪 COMPREHENSIVE AUTOMATED TEST SUITE

The codebase is covered by **228 formal automated tests** across all architectural boundaries:

```bash
flutter test
```

### Test Coverage Highlights:
- **Set A & Set B ML Intent Providers:** Real client contract parsing & fallback modes.
- **Temporal & Recurrence Engine:** Daily, Weekdays, Weekly, Monthly, and multi-missed occurrence recovery.
- **Safety Gate & Ambiguity Protection:** `AstraTaskResolver` zero-write guarantees for update operations.
- **Google Calendar Writer Integration:** OAuth scope validation, mock calendar events, and recurring event synchronization.
- **Lifecycle & Snooze Synchronization:** Guaranteed $T + 10\text{m}$ task due-date sync with active reminder state.
- **Stop Button & Request Cancellation:** Request generation tokens prevent late response mutations.

---

## 🔑 CONFIGURATION & CREDENTIALS GUIDE

> [!WARNING]
> **NEVER COMMIT REAL CREDENTIALS OR SECRETS TO PUBLIC VERSION CONTROL.**  
> Always use local environment variables or template files (`.env.example`).

### 1. 🤖 Gemini AI API Key (Optional LLM Fallback)
Copy the example environment file and add your key from Google AI Studio:
```env
# assets/.env.example -> assets/.env
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
```

### 2. 📱 Google OAuth 2.0 (For Gmail & Google Calendar Sync)
1. Register your debug SHA-1 fingerprint in the Google Cloud Console:
   ```bash
   cd android && ./gradlew signingReport
   ```
2. Download `google-services.json` and place it at: `android/app/google-services.json`.
3. Enable **Google Calendar API** and **Gmail API** in your Google Cloud project.

---

## 🔄 RELEASE & DEPLOYMENT WORKFLOW

1. Bump the version in `pubspec.yaml` (e.g. `version: 1.1.0+2`).
2. Build release split APKs:
   ```bash
   flutter build apk --release --split-per-abi
   ```
3. Create a new release at [github.com/manojsai7/Ai-Tasks-manager/releases/new](https://github.com/manojsai7/Ai-Tasks-manager/releases/new) matching tag `v1.1.0`.
4. Upload `app-arm64-v8a-release.apk` and publish. Installed ASTRA devices will detect the update automatically!

---

## 📄 LICENSE

Distributed under the MIT License. See `LICENSE` for more information.
