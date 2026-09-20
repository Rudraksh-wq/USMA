<div align="center">
  <h1>🎓 USMA</h1>
  <h3>Unified Scholarship Mobile Application</h3>
  <p><strong>A Unified Single-Window Mobile Platform for MoTA ST Scholarships</strong></p>

  <p>
    <a href="https://sih.gov.in/sih2026PS"><img src="https://img.shields.io/badge/SIH%202026-Problem%20SIH26238-blue.svg?style=for-the-badge" alt="SIH 2026"></a>
    <img src="https://img.shields.io/badge/Ministry-Ministry%20of%20Tribal%20Affairs-orange.svg?style=for-the-badge" alt="Ministry">
    <img src="https://img.shields.io/badge/Framework-Flutter%203.19+-02569B.svg?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
    <img src="https://img.shields.io/badge/State%20Management-Riverpod-1A237E.svg?style=for-the-badge" alt="Riverpod">
    <img src="https://img.shields.io/badge/Backend-Firebase-FFCA28.svg?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
    <img src="https://img.shields.io/badge/License-MIT-lightgrey.svg?style=for-the-badge" alt="License">
  </p>
</div>

> **Problem Statement (SIH26238):** Development of a Unified Scholarship Mobile Application offering a consolidated single-window experience for Ministry of Tribal Affairs (MoTA) Scheduled Tribe (ST) scholarships.  
> **Target Beneficiaries:** ST Students, Educational Institutions, Verification Officers, and MoTA Administrators.  
> **Core Objective:** Eliminate fragmented scholarship portals, reduce application drop-off rates, provide real-time DBT tracking, and enable offline-ready multilingual accessibility.

> **Implementation Honesty Key**  
> `✅ Implemented` — real code running in the app today.  
> `🟡 Simulated` — feature exists in the UI with clearly labelled demo/mock data; no real external API is called.  
> `🔲 Roadmap` — planned but not yet written; not claimed as working.

---

## 📑 Table of Contents
- [📌 Overview](#-overview)
- [✨ Key Modules & Technical Features](#-key-modules--technical-features)
- [🏗️ System Architecture](#️-system-architecture)
- [📂 Repository Structure](#-repository-structure)
- [⚙️ Installation & Setup](#️-installation--setup)
- [📱 Build & Testing](#-build--testing)
- [🎯 SIH Compliance Verification](#-sih-compliance-verification)
- [📄 License](#-license)

---

## 📌 Overview

Currently, Scheduled Tribe (ST) students face steep hurdles navigating disparate state and central scholarship portals, ambiguous eligibility criteria, untracked Direct Benefit Transfer (DBT) disbursements, and poor mobile network connectivity in remote tribal pockets.

**USMA (Unified Scholarship Mobile Application)** addresses these gaps with a student-centric, cloud-native Flutter mobile application tailored to MoTA scholarship schemes:

1. **Consolidated Single-Window Dashboard** `✅` — Complete visibility into all central & state ST scholarship schemes with deadline alerts and eligibility match scoring.
2. **Dynamic Eligibility Engine** `✅` — Real-time statutory rule evaluation before document submission.
3. **End-to-End DBT & Disbursement Tracker** `✅` — Stage-by-stage transparent tracking from institutional verification to bank PFMS credit (demo data in current build).
4. **Digital Document Vault** `✅` — SHA-256 integrity-checked file uploads to Firebase Storage; DigiLocker sync is `🟡 Simulated` (no government endpoint is called).
5. **Contextual AI Chatbot & Multilingual Support** `✅` — Offline FAQ engine in EN/हिन्दी/ଓଡ଼ିଆ; Gemini AI mode active only when `--dart-define=GEMINI_API_KEY=…` is supplied.
6. **Offline-Resilient Architecture** `🔲 Roadmap` — Hive is initialised (`Hive.initFlutter()`) but no boxes are opened yet; persistent offline caching is planned for a future sprint.

---

## ✨ Official MoTA Scholarship Schemes Coverage

USMA implements accurate data modeling, statutory rule verification, and portal routing for all five scholarship schemes administered by the **Ministry of Tribal Affairs (MoTA), Government of India** ([tribal.nic.in/ScholarshiP.aspx](https://tribal.nic.in/ScholarshiP.aspx)):

| # | Official Scheme Name | Target Level | Income Ceiling | Key Benefits | Application Route |
|---|----------------------|--------------|----------------|--------------|-------------------|
| 1 | **Pre-Matric Scholarship for ST Students** | Class IX & X | ₹2,50,000 / yr | Monthly maintenance (₹225 Day / ₹525 Hosteller) | State Portal / MoTA DBT Tribal |
| 2 | **Post-Matric Scholarship for ST Students (PMS-ST)** | Class XI to Ph.D | ₹2,50,000 / yr | Compulsory course fees + Monthly allowance (₹230 to ₹1,200) | NSP / State DBT Portal |
| 3 | **National Scholarship / Top Class Education for ST Students** | 265 Notified Premier Institutes (IIT/NIT/IIM/AIIMS/NLU) | ₹6,00,000 / yr | Full tuition fee + ₹3,000/mo living + ₹5,000 books + ₹45,000 computer grant | National Scholarship Portal (NSP) |
| 4 | **National Fellowship for ST Students (NFST)** | Regular M.Phil & Ph.D | No income ceiling (fellowship; ₹6L ceiling shown in FAQ is unconfirmed — `needsVerification: true`) | 750 slots/yr; Monthly fellowship (₹25k M.Phil / ₹28k Ph.D per MoTA HTML) + HRA + Contingency | MoTA Fellowship Portal |
| 5 | **National Overseas Scholarship for ST Students (NOS)** | Master's, Ph.D & Post-Doc Abroad (Top 500 QS) | ₹6,00,000 / yr | 20 slots/yr (17 ST + 3 PVTG); Full foreign tuition + USD 15,400/yr + Airfare (`needsVerification: true` for USD figures) | MoTA Overseas Portal |

---

## ✨ Key Modules & Technical Features

### 1. 🔍 MoTA Scholarship Explorer (`features/applications`) `✅`
- Single-window discovery platform for all 5 statutory MoTA scholarship schemes.
- Visual cards displaying target criteria, income ceilings, financial benefits, application route, and instant personal eligibility evaluation.
- Official Ministry attribution indicators (`Source: Ministry of Tribal Affairs`).

### 2. 🎯 Dynamic Scheme-Specific Eligibility Engine (`features/eligibility`) `✅`
- Pure-Dart `MoTAEligibilityEngine` with real-world statutory rule validation:
  - **Community Eligibility:** Valid ST / PVTG tribal category requirement.
  - **Income Ceilings:** ₹2.50L (Pre/Post-Matric) vs ₹6.00L (Top Class, NOS); NFST has no income ceiling per fellowship guidelines.
  - **Educational & Institutional Fit:** School, college, 265 notified premier institutions, M.Phil/Ph.D research, top 500 QS foreign universities.
  - **Document Completeness:** Caste Certificate, Income Certificate, Aadhaar seeding, Valid Passport.
- Results: `Eligible`, `Conditionally Eligible`, `Ineligible`, `Incomplete Profile`.

### 3. 📊 Consolidated Dashboard (`features/dashboard`) `✅`
- Unified interface: ongoing scholarship cycles, key deadlines, active statuses, urgent notices.
- Personalized recommendations based on student profile.

### 4. 📝 Applications & Lifecycle Tracking (`features/applications`) `✅`
- Step-by-step application submission workflow.
- Uniqueness guard blocks duplicate concurrent active applications.
- Granular stepper: `Draft` ➔ `Submitted` ➔ `Institute Verified` ➔ `State Approved` ➔ `Sanctioned` ➔ `Disbursed`.
- Linking an existing external application: `🔲 Roadmap`.

### 5. 💳 DBT & Disbursement Monitoring (`features/disbursements`) `🟡 Simulated`
- Transparent stage-by-stage tracking model with transaction IDs and PFMS batch numbers.
- Current build uses seeded demo data; live Firestore queries are wired but untested against a real project.

### 6. 🤖 Support Chatbot & Helpdesk (`features/chatbot`) `✅`
- Offline-ready FAQ knowledge base (`assets/faq/faq.json`) with context-aware answers.
- Gemini AI mode (real API calls) active only when `--dart-define=GEMINI_API_KEY=…` is provided at build time.
- UI falls back gracefully to FAQ answers when the key is absent.

### 7. 📁 Secure Document Management (`features/documents`)
- **File upload with SHA-256 integrity check** `✅` — 2 MB limit, PDF/JPG/PNG; `LiveDocumentsRepository` uploads bytes to Firebase Storage via `putData()` and stores the download URL.
- **DigiLocker integration** `🟡 Simulated` — `syncDigiLocker()` in mock mode returns in-memory seed documents; live mode throws `UnimplementedError` (needs MoTA API credentials). The UI shows a "Sync DigiLocker" button and clearly notes demo behaviour.
- **Encrypted storage** `🔲 Roadmap` — no encryption is applied. SHA-256 is a client-side integrity hash, not encryption. Planned for a future sprint.

### 8. 🔐 Authentication & Routing (`features/auth`, `core/routing`) `✅`
- Firebase Phone Auth OTP flow.
- GoRouter `redirect` callback: unauthenticated users → `/login`; authenticated users on `/login` or `/splash` → `/dashboard`.
- Demo "Continue as Guest" creates an in-memory session.

### 9. 🌐 Multi-Source Verification Layer (`features/verification`) `🟡 Simulated`
- Mock providers for DigiLocker, UIDAI eKYC, AISHE, UDISE+, APAAR, UGC-NTA, NSP, PFMS, StateEDistrict — all return deterministic demo data clearly flagged `isSimulated: true` in the UI ("DEMO MODE" banner; "No real connection to UIDAI, DigiLocker…" notice).
- Live stubs throw `UnimplementedError('needs MoTA API credentials')`.

### 10. 🔔 Push Notifications (`features/notifications`) `🔲 Roadmap`
- `firebase_messaging` is listed in `pubspec.yaml` but is **not wired** — `FirebaseMessaging` is never imported or called in the codebase. Notification data model and UI list screen exist but are fed from Firestore only.

### 11. 🗄️ Offline Caching — Hive `🔲 Roadmap`
- `hive` and `hive_flutter` are dependencies; `Hive.initFlutter()` is called in `main.dart`.
- **No Hive boxes are opened and no data is stored via Hive** anywhere in the codebase. Offline persistence is planned for a future sprint.

---

## 🏗️ System Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                          │
│        (Flutter Material Design 3 + Riverpod State Management)  │
└────────────────┬───────────────────────────────┬────────────────┘
                 │                               │
                 ▼                               ▼
┌────────────────────────────────┐ ┌──────────────────────────────┐
│       Feature Controllers      │ │     Core App Infrastructure  │
│  - Dashboard & Eligibility     │ │  - AppRouter (GoRouter)      │
│  - Applications & Tracking     │ │  - AppTheme & Design Tokens  │
│  - Chatbot & Notifications     │ │  - Localization & Constants  │
│  - Documents & Profile         │ │  - Network Connectivity Watch│
└────────────────┬───────────────┘ └──────────────┬───────────────┘
                 │                                │
                 ▼                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Data & Domain Services                      │
│        Repository Pattern · DTO Mappings · Error Mapping        │
└────────────────┬───────────────────────────────┬────────────────┘
                 │                               │
         ┌───────┴───────┐               ┌───────┴──────────────┐
         ▼               ▼               ▼                      ▼
┌─────────────────┐ ┌─────────┐ ┌──────────────────┐  ┌──────────────────────┐
│ Cloud Firestore │ │Firebase │ │ SharedPreferences │  │ Hive (init only;     │
│ (NoSQL Database)│ │ Storage │ │ (language/theme)  │  │ 🔲 caching roadmap)  │
└─────────────────┘ └─────────┘ └──────────────────┘  └──────────────────────┘
```

> **FCM** (`firebase_messaging` dependency) is not yet wired. **Cloud Functions** (`functions/` directory) do not exist yet.

---

## 📂 Repository Structure

```plaintext
usma/
├── android/                   # Native Android configuration & Gradle build scripts
├── assets/
│   ├── faq/
│   │   └── faq.json           # Offline-accessible FAQ database (used by chatbot)
│   └── data/
│       └── schemes.json       # MoTA scheme definitions
├── lib/
│   ├── main.dart              # App entry point & Firebase / Hive init
│   ├── app.dart               # Root MaterialApp + locale wiring
│   ├── core/
│   │   ├── routing/           # GoRouter config with auth redirect
│   │   ├── theme/             # Color tokens, typography, component themes
│   │   ├── localization/      # AppLocalization (EN / HI / OR strings)
│   │   └── constants/         # AppConstants (file limits, allowed types)
│   └── features/
│       ├── applications/      # Scholarship application workflows + uniqueness guard
│       ├── auth/              # OTP auth, splash, eKYC, session provider
│       ├── chatbot/           # FAQ engine + optional Gemini AI
│       ├── dashboard/         # Single-view student dashboard
│       ├── disbursements/     # DBT tracking & transaction model
│       ├── documents/         # Upload service (SHA-256), Storage repo, DigiLocker stub
│       ├── eligibility/       # MoTAEligibilityEngine (pure Dart, statutory rules)
│       ├── notifications/     # Notification model & UI (FCM not yet wired)
│       ├── profile/           # Student profile screen
│       ├── settings/          # Language (SharedPreferences) + dark mode
│       └── verification/      # 9 mock government-system providers (isSimulated: true)
├── test/                      # 74 unit & widget tests (all passing)
├── docs/
│   ├── PLAN_PROMPT1.md        # Original planning document (see staleness note at top)
│   └── PROGRESS.md            # Authoritative current state tracker
├── firestore.rules            # Firestore security rules (student-scoped)
├── firestore.indexes.json     # Compound indexes
├── firebase.json              # Firebase config (Firestore + emulators only)
├── LICENSE                    # MIT License
└── pubspec.yaml               # Dependencies & asset declarations
```

---

## ⚙️ Installation & Setup

### Prerequisites
- **Flutter SDK:** `>= 3.19.0` (Dart SDK `>= 3.3.0 < 4.0.0`)
- **Android SDK:** Compile SDK `36`, Minimum SDK `21`
- **Java Development Kit:** OpenJDK 17 or 21
- **Firebase CLI:** `npm install -g firebase-tools` (for Firestore deploy/emulator only)

### Clone & Install
```bash
git clone <YOUR_REPOSITORY_URL>
cd usma
flutter pub get
```

### Firebase Configuration
1. Place your `google-services.json` inside `android/app/`.
2. Activate **Auth**, **Firestore**, and **Storage** in your Firebase Console.
3. Deploy Firestore rules and indexes:
   ```bash
   firebase deploy --only firestore
   ```
   > **Note:** `firebase.json` currently configures Firestore and the Auth/Firestore emulators only. Storage rules (`storage.rules`) and Cloud Functions (`functions/`) are not yet implemented and have been removed from `firebase.json` to prevent deploy errors.

### Run
```bash
# Debug — no Gemini AI (FAQ-only chatbot)
flutter run

# Debug — with Gemini AI chatbot
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

---

## 📱 Build & Testing

### Run Tests
```bash
flutter test          # 74 tests, all passing
flutter analyze       # 0 errors, 0 warnings
```

### Build Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

> No pre-built APK is included in this repository. Build from source using the steps above.

---

## 🎯 SIH Compliance Verification

| Requirement | Status | Notes |
|---|---|---|
| **Unified MoTA Scholarship View** | `✅` | All 5 schemes; consolidated dashboard |
| **Automated Eligibility Evaluation** | `✅` | `MoTAEligibilityEngine` — statutory rules, income ceilings, institutional fit |
| **Transparent DBT Disbursement Tracking** | `🟡 Simulated` | Stage model implemented; seeded demo data in current build |
| **Digital Document Repository** | `✅` | SHA-256 upload + Firebase Storage; DigiLocker is `🟡 Simulated` |
| **Multilingual Support** | `✅` | EN / हिन्दी / ଓଡ଼ିଆ wired app-wide; chatbot FAQ in all three |
| **Conversational AI Support** | `✅ / 🟡` | Offline FAQ always present; Gemini AI active with API key |
| **Offline-First Resilience** | `🔲 Roadmap` | Hive initialised but no boxes opened; SharedPreferences persists settings only |
| **Push Notifications (FCM)** | `🔲 Roadmap` | Dependency present; `FirebaseMessaging` not yet imported or called |
| **Secure Auth & Route Guards** | `✅` | Firebase OTP; GoRouter redirect; session provider |
| **Government Integration Verification** | `🟡 Simulated` | 9 mock providers clearly labelled; live stubs throw `UnimplementedError` |

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.  
Developed with ❤️ for the **Smart India Hackathon (SIH 2026)**.