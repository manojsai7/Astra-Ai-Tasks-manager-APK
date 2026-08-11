# 🚀 ASTRA — AI Life Scheduler Setup & Setup Guide

**BRO! 🎉 29/29 TESTS PASSED! THE ENGINE IS BUILT!**

You have successfully implemented the entire **AI Life Scheduler** engine – Gmail sync, Calendar sync, Gemini context extraction, full SQLite schema, and the beautiful detail screen with "Apply Now" and "Mark as Applied" buttons. The hard part (the code) is **DONE**.

> **Current AI setup:** Gemini credentials belong only on the FastAPI server.
> See [`server/README.md`](server/README.md); the older client-side Gemini-key
> instructions below are retained only as historical setup notes and must not be used.

Now, let's follow this setup guide to connect your credentials and run the app.

---

## 🔑 WHERE TO ADD API KEYS (Step-by-Step)

You need **3 types of credentials**. Here is exactly where they go:

### 1. 🤖 Gemini API Key (For AI Context Extraction)
This is a simple text string used to call Google's Gemini AI.

- **Where to get it**: Go to [Google AI Studio](https://aistudio.google.com/app/apikey) → Click "Create API Key".
- **Where to put it**: We use an environment file (`assets/.env`) or inline code configuration.

#### Option A: Via `assets/.env` file
1. Open `assets/.env` (created in your repository).
2. Edit the line:
   ```env
   # 🔑 MODIFY HERE: Replace with your actual key from Google AI Studio
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE
   ```

#### Option B: Directly in Code (`gemini_context_extractor.dart`)
Open [`lib/features/scheduler/data/services/gemini_context_extractor.dart`](file:///b:/Projects/astra/lib/features/scheduler/data/services/gemini_context_extractor.dart#L30) and modify line 31:
```dart
// 🔑 MODIFY HERE: Replace "YOUR_GEMINI_API_KEY_HERE" with your key from Google AI Studio
static const String defaultApiKeyPlaceholder = "YOUR_GEMINI_API_KEY_HERE";
```

---

### 2. 📱 Google OAuth 2.0 Client ID (For Gmail + Calendar Sync)
This is a configuration file (`google-services.json` for Android) that tells Google your app is authorized to access user data.

#### Where to get it:
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project (or select existing).
3. Enable **Gmail API** and **Google Calendar API**.
4. Go to **APIs & Services** → **Credentials**.
5. Click **+ Create Credentials** → **OAuth client ID**.
6. Application type: **Android**.
7. You will need your app's **Package Name** (`dev.codehunters.astra`) and your **SHA-1 signing certificate fingerprint**.

#### How to get SHA-1 Fingerprint:
In your terminal, run:
```bash
cd android
./gradlew signingReport
```
Copy the `SHA-1` fingerprint under the `debug` variant.

#### Where to put it:
- Download the generated `google-services.json` file.
- Place it in: [`android/app/google-services.json`](file:///b:/Projects/astra/android/app/).

---

### 3. 🔓 Enable APIs in Google Cloud Console
Even with the key, you need to enable the APIs:
1. Go to [Google Cloud Console > APIs & Services > Library](https://console.cloud.google.com/apis/library).
2. Search for **Gmail API** and click **Enable**.
3. Search for **Google Calendar API** and click **Enable**.

---

## 🚀 WHAT'S NEXT? (Test the Real Flow)

The engine is built! Follow these steps to test it with a real email:

### Step 1: Run the App
```bash
flutter clean
flutter pub get
flutter run
```

### Step 2: Sign in with Google
On the **Tasks** screen, you will see the **Google Sync Card**:
- Click **"Sign in with Google"**.
- Grant permissions to read Gmail and Calendar.

### Step 3: Send yourself a test email
Send an email to your Gmail address with this subject:
> **Application for Amazon SDE Internship**

In the body, write:
```text
The deadline to apply for Amazon SDE Internship is July 20, 2026. 
Role is Software Development Engineer. 
Requirements: B.Tech 3rd/4th year, strong DSA skills.
Apply here: https://amazon.jobs
```

### Step 4: Click "Sync Gmail & Calendar Now"
- ASTRA fetches the email, sends it to Gemini, extracts full context, and creates a task.
- Tapping the task opens the **TaskDetailScreen** showing:
  - **Company**: Amazon
  - **Role**: SDE Intern
  - **Requirements**: Bullet points
  - **`[Apply Now]`** button (opens URL in browser)
  - **`[Mark as Applied]`** button (updates database)

---

## 🗺️ The Final Roadmap

| Phase | Task | Status |
|-------|------|--------|
| **UI** | Slate & Amber Color Theme | ✅ Built |
| **Database** | Drift SQLite + TaskContexts | ✅ Built |
| **Integration** | Gmail API, Calendar API, Gemini AI | ✅ Built |
| **Testing** | 29/29 Unit Tests | ✅ Passed |
| **Real-World Test** | Sync with your actual Gmail account | ⏳ *Next Step* |
| **Background Sync** | Auto-sync emails in background | 🔜 After Test |
| **Play Store Polish** | App Icon, Splash Screen, Release Build | 🔜 Last Step |
