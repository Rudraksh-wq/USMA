# USMA — Progress Tracker

> **Last updated:** 2026-09-20  
> **Basis:** verified against actual source code + `git log` (not the original plan's aspirations).

---

## Current State

| Item | Value |
|---|---|
| Flutter SDK constraint | `>=3.19.0`, Dart `>=3.3.0 <4.0.0` |
| `flutter analyze` | ✅ 0 errors · 0 warnings · 29 info-level hints |
| `flutter test` | ✅ 74 tests passed · 0 failed |
| `firebase.json` | ✅ Fixed — `functions` + `storage` blocks removed until those files exist |
| `requirements.txt` | ✅ Deleted — Flutter/Dart project; pubspec.yaml is authoritative |
| `LICENSE` | ✅ Created — MIT |

---

## Features: Actual Implementation Status

### ✅ Fully Implemented (runs in app today)

| Feature | Notes |
|---|---|
| **GoRouter auth redirect** | `redirect:` callback in `app_router.dart` — unauthenticated → `/login`; signed-in → `/dashboard` |
| **SplashScreen auth-aware nav** | Short branded delay, then respects auth state (no hardcoded `go(/dashboard)`) |
| **MoTA Eligibility Engine** | `MoTAEligibilityEngine` in `eligibility_engine.dart` — real statutory rule evaluation (income ceiling, category, institution type, document completeness) across all 5 schemes |
| **5 MoTA Scheme Data Models** | Accurate income ceilings, descriptions, application routes per tribal.nic.in (2026-09-20) |
| **Dashboard** | Unified view: active applications, DBT tracker, deadlines, quick actions |
| **Application lifecycle** | Draft → Submitted stepper, uniqueness guard (blocks duplicate concurrent applications) |
| **DBT Disbursement Tracker** | Stage-by-stage disbursement model (PFMS → Bank) |
| **Chatbot (FAQ mode)** | Context-aware offline FAQ engine in `jago_localization.dart` / `context_aware_scholarship_assistant.dart`; falls back gracefully when Gemini key absent |
| **Document Upload** | `UploadService` (SHA-256 integrity, 2 MB limit, PDF/JPG/PNG); `LiveDocumentsRepository` calls `putData()` + `getDownloadURL()` against Firebase Storage |
| **Multilingual UI** | EN / हिन्दी / ଓଡ଼ିଆ strings wired into Navigation, Settings, Dashboard via `AppLocalization` + `currentLocaleProvider` |
| **Settings — language + dark mode** | Persisted via `SharedPreferences` |
| **Verification / Integration layer** | `MockUnifiedVerificationOrchestrator` + 9 mock government-system providers (DigiLocker, UIDAI, AISHE, UDISE+, APAAR, UGC-NTA, NSP, PFMS, StateEDistrict); all clearly labelled `isSimulated: true` in UI |
| **Auth guard** | OTP login flow; `currentUserProvider`; session-aware routing |
| **Firestore security rules** | `firestore.rules` — student-scoped read/write rules |

---

### 🟡 Simulated / Demo-Only (labelled in UI)

| Feature | What the code actually does | UI label |
|---|---|---|
| **DigiLocker sync** | `MockDocumentsRepository.syncDigiLocker()` = in-memory seed; `LiveDocumentsRepository.syncDigiLocker()` throws `UnimplementedError` | "DEMO MODE" banner on integration screen; snackbar on documents screen |
| **Government API verification** | All 9 integration providers return deterministic mock data — no real UIDAI / DigiLocker / AISHE / PFMS endpoints called | `isSimulated: true` flag; integration screen shows "No real connection to UIDAI, DigiLocker…" |
| **eKYC** | `Future.delayed` with seed data; no UIDAI endpoint | Screen text explains demo |
| **OTP auth** | Phone-number OTP is Firebase Auth (real); "Continue as Guest" creates demo session | — |
| **Gemini AI chatbot** | Used only when `GEMINI_API_KEY` dart-define is provided; otherwise FAQ-only | Falls back silently to FAQ answers |

---

### ❌ Not Implemented (roadmap — do not claim as done)

| Feature | Status | Plan reference |
|---|---|---|
| **Hive offline caching** | `Hive.initFlutter()` called in `main.dart` but **no boxes opened, no data stored** anywhere in the codebase. Dependency in pubspec is unused beyond init. | PLAN_PROMPT1 "Do not delete yet (Prompt 2)" |
| **FCM push notifications** | `firebase_messaging` is in pubspec but **zero Dart usage** — `FirebaseMessaging` is never imported or called. | Future work |
| **Encrypted Storage** | No encryption library present, no cipher code. SHA-256 hash in upload_service is integrity-checking only, not encryption. | Future work |
| **Cloud Functions** | `cloud_functions` in pubspec, `functions/` directory does not exist. | PLAN_PROMPT1 Prompt 2 scope |
| **storage.rules** | File does not exist; removed from `firebase.json` until implemented. | PLAN_PROMPT1 P4 |
| **Live DigiLocker API** | Throws `UnimplementedError`; needs MoTA API credentials. | PLAN_PROMPT1 P4 |
| **Live government integrations** | All 9 providers are mocks. Live stubs throw `UnimplementedError`. | PLAN_PROMPT1 P2 / Prompt 2 |
| **Firestore rules unit tests** | `rules_test/` directory not created yet. | PLAN_PROMPT1 P0 gate |
| **Link existing application flow** | FAQ describes it; no screen or adapter exists. | PLAN_PROMPT1 P3 |
| **Family / multi-child profiles** | Model has single-student only. | PLAN_PROMPT1 P3 |
| **Deficiency centre** | Referenced in dashboard but no deficiency screen. | PLAN_PROMPT1 P3 |
| **Pre-built APK in repo root** | `usma-release.apk` does not exist. | — |

---

## Test Coverage (as of 2026-09-20)

| Test file | Tests | Result |
|---|---|---|
| `auth_redirect_test.dart` | 22 | ✅ |
| `eligibility_engine_test.dart` | 5 | ✅ |
| `scholarship_uniqueness_test.dart` | 2 | ✅ |
| `widget_test.dart` (smoke) | 5 | ✅ |
| `document_upload_test.dart` | 6 | ✅ |
| `integration_provider_test.dart` | 30 | ✅ |
| **Total** | **74** | **✅ All passed** |

---

## Git Log (recent)

```
0d6ece6  improvement on the chatbox from json to context-aware json chatbox and some bug fixed
f7f3f24  bug fixed and some fix in code
9ed3581  Merge pull request #1 from AnanyaAdvika/main
968bff4  update
5035cb6  Add Prompt 1 foundation plan, progress tracker, and project Cursor rules
86036c1  iso fix
5e7577b  chatbox bug fixed and requirement.txt added
7ae5a23  Configure secure local and environment-based Gemini API key handling
```

---

## Next Priorities (from PLAN_PROMPT1.md)

1. **Hive caching** — open boxes, wire offline reads in applications/disbursements repos (Prompt 2 Phase D)
2. **FCM** — wire `FirebaseMessaging.onMessage` → `NotificationsRepository` (Prompt 2)
3. **storage.rules** + restore `firebase.json` storage block (PLAN_PROMPT1 P4)
4. **Live government API stubs** → real credentials (PLAN_PROMPT1 P2 / Prompt 2)
5. **Firestore rules unit tests** in `rules_test/` (PLAN_PROMPT1 P0 gate, still open)
6. **Link existing application** screen (PLAN_PROMPT1 P3)
