# ASTRA — System Architecture

**Document Version:** 1.0  
**Architecture Stage:** V1  
**Primary Platform:** Android  
**Client Framework:** Flutter  
**Native Android Layer:** Kotlin  

---

# 1. Architecture Goals

ASTRA must be:

- Reliable
- Offline-first
- Modular
- Testable
- Secure
- Auditable
- AI-assisted but deterministic
- Maintainable by human and AI developers

The architecture must prevent AI-specific logic from becoming tightly coupled to core application logic.

---

# 2. High-Level Architecture

ASTRA uses a layered mobile and cloud architecture.

```text
┌──────────────────────────────────────┐
│           ANDROID DEVICE             │
│                                      │
│  ┌────────────────────────────────┐  │
│  │       Flutter UI Layer         │  │
│  │                                │  │
│  │ Home                           │  │
│  │ Inbox                          │  │
│  │ Tasks                          │  │
│  │ Planner                        │  │
│  │ Focus                          │  │
│  │ Calendar                       │  │
│  │ Settings                       │  │
│  └───────────────┬────────────────┘  │
│                  │                   │
│  ┌───────────────▼────────────────┐  │
│  │       Application Layer        │  │
│  │                                │  │
│  │ Use Cases                      │  │
│  │ State Management               │  │
│  │ Validation                     │  │
│  │ Business Rules                 │  │
│  └───────────────┬────────────────┘  │
│                  │                   │
│  ┌───────────────▼────────────────┐  │
│  │          Domain Layer          │  │
│  │                                │  │
│  │ Entities                       │  │
│  │ Repository Contracts           │  │
│  │ Domain Services                │  │
│  └───────────────┬────────────────┘  │
│                  │                   │
│  ┌───────────────▼────────────────┐  │
│  │           Data Layer           │  │
│  │                                │  │
│  │ Drift / SQLite                 │  │
│  │ Remote API                     │  │
│  │ Repository Implementations     │  │
│  │ Synchronization                │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │     Native Android Layer       │  │
│  │             Kotlin             │  │
│  │                                │  │
│  │ Share Intent                   │  │
│  │ Alarm Scheduling               │  │
│  │ Boot Recovery                  │  │
│  │ Android System Integration     │  │
│  └────────────────────────────────┘  │
└──────────────────┬───────────────────┘
                   │ HTTPS
                   ▼
┌──────────────────────────────────────┐
│              CLOUD                   │
│                                      │
│  Supabase Auth                       │
│  PostgreSQL                          │
│  Row Level Security                  │
│  Edge Functions                     │
│                                      │
│             │                        │
│             ▼                        │
│       AI Extraction Service          │
│             │                        │
│             ▼                        │
│         Gemini API                   │
└──────────────────────────────────────┘