> [!IMPORTANT]
> **Staleness Notice (2026-09-20)**
>
> This document was written during an initial planning pass before any P0–P4 code was executed.
> Many of its findings have since been **resolved or superseded** by actual implementation work.
> The authoritative current state is in [`docs/PROGRESS.md`](PROGRESS.md).
>
> **Resolved items — do NOT redo:**
>
> | Plan finding | Current status |
> |---|---|
> | Splash always `go(/dashboard)` regardless of auth | ✅ Fixed — `SplashScreen` now checks auth state; GoRouter `redirect` callback enforces login |
> | No GoRouter redirect callback | ✅ Fixed — `app_router.dart` has `redirect:` that gates all protected routes |
> | `demo_user_001` hard-coded everywhere | ✅ Partially resolved — auth flow uses `currentUserProvider`; some demo seed data may still reference it |
> | Empty `catch (_) {}` swallowing Firestore errors | ✅ Fixed — repos now use `ErrorMapper.map(e)` and throw `Failure` subclasses |
> | Eligibility engine = widget filter only | ✅ Fixed — `MoTAEligibilityEngine` is a pure-Dart statutory rule engine with income ceilings, category, institution, document checks |
> | Scheme income ceilings wrong vs tribal.nic.in | ✅ Fixed — Pre-Matric ₹2.5L, Post-Matric ₹2.5L, Top Class ₹6L, NOS ₹6L now correct |
> | `image_picker` / `file_picker` unused | ✅ Fixed — `documents_screen.dart` uses `file_picker` for upload; `image_picker` for camera capture |
> | `uploadDocument` never called | ✅ Fixed — FAB on documents screen → `_UploadDocumentSheet` → `DocumentUploadService` → `LiveDocumentsRepository.uploadDocument()` with `putData()` |
> | `LICENSE` file missing | ✅ Created — MIT license |
> | `requirements.txt` in Flutter repo | ✅ Deleted |
> | `firebase.json` references missing `functions/` and `storage.rules` | ✅ Fixed — those blocks removed until the files exist |
> | Hive init only, no boxes opened | ⚠️ Still true — Hive caching is roadmap (Prompt 2 Phase D) |
> | FCM dependency unused | ⚠️ Still true — `firebase_messaging` not imported anywhere in Dart code |
> | Encrypted storage claim | ⚠️ Still false — SHA-256 is integrity hashing, not encryption; README now says so honestly |
> | Chatbot imports broken `api_keys.dart` | ✅ Fixed — chatbot reads `String.fromEnvironment('GEMINI_API_KEY')` |
> | `lib/core/router` vs `lib/core/routing` path | ⚠️ Actual path remains `lib/core/routing/` — rename deferred |
> | `AppErrorView` vs `ErrorView` naming | ⚠️ Not renamed — alias approach deferred |
> | Multilingual support disconnected from settings | ✅ Fixed — `languageCodeProvider` → `currentLocaleProvider` → `MaterialApp.router(locale:)` wired; settings picker persists to `SharedPreferences` |
>
> **Items still valid / not yet started:**
> - P0 `AppConfig` / `DataMode` provider (demo vs live switching)
> - P0 Firestore rules unit tests (`rules_test/`)
> - P2 Live source-system adapters (NSP, SFMP, NOS portal)
> - P3 Link existing application flow, family/multi-child, deficiency centre
> - P4 `storage.rules`, live DigiLocker API, consent subcollection
> - All "Not verified" items at the bottom of this document remain unverified

# PLAN — Prompt 1

Wait for **go** before any P0–P4 code. Prompt 2 is out of scope until Prompt 1’s final gate is green.

Explored: `pubspec.yaml`, `analysis_options.yaml`, `firebase.json`, `firestore.rules`, `firestore.indexes.json`, `README.md`, `requirements.txt`, `.gitignore`, `assets/faq/faq.json`, all 50 Dart files under `lib/`, `test/widget_test.dart`. `LICENSE`, `storage.rules`, `functions/`, and `google-services.json` **do not exist**. `tribal.nic.in/Scholarship.aspx` was fetched for scheme facts (2026-09-20).

---

## How the repo actually differs from the README

| README / FAQ claim | What the code does |
|---|---|
| Clone + `flutter run` | `main.dart` always calls `Firebase.initializeApp` with dummy `DefaultFirebaseOptions`; Hive init; no `DATA_MODE`. |
| OTP auth | `sendOtp` / `verifyOtp` are delays; splash **always** `go(/dashboard)`; login “Continue as Guest” skips auth. |
| No demo user fallback | Hard-coded `demo_user_001` in auth, applications, documents, apply, providers. |
| Errors visible | Empty `catch (_) {}` in every Firestore repo; live failure silently becomes seed data. Dashboard schemes/DBT errors render `SizedBox.shrink()`. |
| Eligibility engine | Widget filter: category always true for ST/PVTG; `'Post-Matric'` matches **every** scheme; profile unused. |
| Scheme rules | `SchemesRepository.defaultSchemes` with `DateTime.now()+N` deadlines; income ceilings **wrong** vs tribal.nic.in (Pre-Matric ₹2L vs ₹2.5L; NOS ₹8L vs ₹6L; NFST ₹6L vs **no income** on fellowship guidelines). |
| One scholarship | Demo seed has **two** concurrent apps (Post-Matric + Top Class). |
| Link existing application | FAQ describes it; **no screen or adapter**. |
| DigiLocker / upload | `syncDigiLocker` = `Future.delayed`; `uploadDocument` never called; `image_picker` / `file_picker` unused. |
| Encrypted storage / FCM / Hive cache | Hive init only; FCM unused; no encryption. |
| Indexes | Fields `scheme`, `stage`, `paidAt` are **not** on models. Repos query **top-level** `applications` / `documents` / `disbursements` / `notifications`; rules only allow `users/{uid}/**` and `schemes`. |
| `firebase.json` | References missing `functions/` and `storage.rules`. |
| `intl ^0.20.3` | Likely fights `flutter_localizations` pin; `path_provider_android: 2.2.17` override already present. |
| Chatbot | `chatbot_service.dart` imports gitignored `api_keys.dart` (broken extra `../`); Gemini model id `gemini-3.6-flash`. |
| SFMP | `AppConstants` labels it “Scholarship for Minorities”; product meaning is **Canara Bank SFMP** for NFST. |
| Error widget | Exists as `AppErrorView`, not `ErrorView`. |
| Folder `lib/core/router` | Actual path is `lib/core/routing`. |

---

## Phases

### Step 0 — Rules (done in planning)

- Created `.cursor/rules/usma.mdc` with the prescribed content.

### P0 — Fresh clone builds; failures visible

**Goal:** `flutter pub get && flutter run` in demo mode with no local Firebase files; no swallowed errors.

1. **Build breaker.** Delete `lib/core/config/api_keys.template.dart`. Chatbot reads only `String.fromEnvironment('GEMINI_API_KEY')`. Missing-key copy explains `--dart-define=GEMINI_API_KEY=...` (dev-only; Prompt 2 removes it). Empty key → FAQ answers + visible message. Label SIMULATED where FAQ-only.
2. **AppConfig** `lib/core/config/app_config.dart`: `DataMode {demo, live}` from `DATA_MODE` (default `demo`); `useEmulator` from `USE_EMULATOR`. Demo: never `Firebase.initializeApp`. Live: `FirebaseOptions` from dart-defines (`FIREBASE_API_KEY`, `APP_ID`, `PROJECT_ID`, `MESSAGING_SENDER_ID`, `STORAGE_BUCKET`, `AUTH_DOMAIN`). Delete `lib/core/constants/firebase_options.dart`. Crashlytics/Analytics/Messaging **only** in live (and only if plugins initialise without throwing).
3. **Repos split.** Interfaces stay; add `Mock*` (seed, SIMULATED) and `Firestore*` (no demo fallback). Providers switch on `AppConfig.dataMode`. Delete every empty catch; `ErrorMapper.map` → `Failure`; UI `ErrorView`.
4. **Failures.** Promote `Failure` to a **sealed** hierarchy. Keep `ErrorMapper` in `core/errors` (Firebase types allowed there). Domain remains Firebase-free.
5. **Auth.** Remove `demo_user_001` fallbacks. GoRouter `redirect`: signed-out → `/login` (allow splash, login, otp); signed-in STUDENT → app; `/admin` blocked (Prompt 2). Demo login: **Continue as demo student (SIMULATED)** creates an in-memory session (id from `Uuid`, not a magic constant). Live: real `verifyPhoneNumber` + test phone numbers. `completeEkyc` stores **last 4** only.
6. **Move** `lib/core/routing` → `lib/core/router` to match rules. Rename `AppErrorView` → `ErrorView` (keep typedef alias one release if tests break).
7. **Firestore rules + indexes** matching the canonical model and **actual queries**. Student matrix below. `rules_test/` Node package with `@firebase/rules-unit-testing`.
8. **Housekeeping.** MIT `LICENSE`; delete `requirements.txt`; README setup for demo/live/`--dart-define`; drop `functions` from `firebase.json` until Prompt 2; do **not** add `storage.rules` until P4. Run `flutter pub get`; if `intl` vs `flutter_localizations` fails, pin `intl` to the SDK-compatible version and note it. Confirm `assets/faq/faq.json` exists; add new asset dirs in pubspec.

**Gate P0:** DataMode provider test; auth redirect tests; Firestore error shown via `ErrorView`; student rules tests.

### P1 — Scheme rules + eligibility engine

1. `assets/schemes/scheme_rules.json` (versioned). Five schemes. Values from tribal.nic.in 2026-09-20 where confirmed; else `"needsVerification": true`.
2. Pure Dart `EligibilityEngine` in `lib/features/eligibility/domain`.
3. Extend `UserModel` / profile: `isPvtg`, `dateOfBirth`, `gender`, `disabilityPercent`, `category` (ST default).
4. Both Mock and Firestore scheme repos load the **same JSON asset** (Firestore may overlay cycles later; demo never invents live Firestore rows).

**Gate P1:** ≥20 unit tests (ceiling ±₹1, PVTG, girls/Divyangjan, NOS overseas vs domestic, Top Class institute membership, NFST enrolment, NEEDS_INFO, JSON schema for all five).

### P2 — Verification & integration layer

**Stop-inside-phase:** after writing files, the signatures and status table below are the ones to implement unless you object on **go**.

- `lib/core/integration/` adapters, providers, orchestrator, circuit breaker, clock.
- Status mapping JSON `assets/integration/status_mapping.json`.
- Mock providers + `assets/mock/*.json` scenarios.
- Hidden Settings long-press → Developer scenario switcher (SIMULATED).
- Live stubs: `UnimplementedError('needs MoTA API credentials')`.
- Persist `verificationReports` (student read-only) and `manualReviewCases`.
- Extend rules tests.

**Gate P2:** status outcomes, timeout, retry/backoff, circuit breaker, mismatch does not block, only required providers, mapping including unknown → safe default.

### P3 — Single-window student UX

- `ActiveScholarshipGuard` (pure Dart); fix demo seed (one non-terminal award).
- Eligibility UI: profile default + what-if overrides; grouped Eligible / Not eligible / Needs info.
- Dashboard: unified list, source badge, canonical stepper, last-synced, pull-to-refresh, pending-actions strip.
- Link existing application flow (FAQ already promises it).
- Deficiency: `defectRemark`, Fix now, Resubmit; mock timeline + notification in demo (server-written in live — client must not write those fields).
- Money view: currency (INR/USD); NOS formatted as USD.
- Family: max 5 children; switcher; combined pending actions; per-child guard.
- Application detail: verification chips + Under manual review.

**Gate P3:** guard unit tests; widget tests empty/loading/error/deficiency/manual-review; 360dp × 200% text.

### P4 — Document wallet

- `DigiLockerService` Mock (consent + `assets/mock/digilocker/*.json`) / Live stub.
- Consents in `users/{uid}/consents`; Profile manage/revoke.
- Uploads: picker → compress → SHA-256 → Storage `users/{uid}/documents/{docId}`; PDF/JPG/PNG; **2 MB**; progress + retry. Demo: in-memory SIMULATED store. Call `uploadDocument` from UI.
- `storage.rules` owner-only; add storage block back in `firebase.json`.
- Reuse checklist from scheme `requiredDocuments` ↔ `DocumentType`.
- Validity rules as data (income cert = issuing FY).
- Client cannot set `verificationStatus`.
- Ekyc: demo SIMULATED; live consent stub; never store/log full Aadhaar.

**Gate P4:** reuse/expiry tests (FY boundary); upload progress/failure widget test; rules: client cannot set `verificationStatus`.

### Final Prompt 1 gate

`flutter analyze` clean; `flutter test` green; rules tests green; README honest; `docs/PROGRESS.md` updated; print Not verified list.

---

## Files

### Create

| Path | Phase |
|---|---|
| `.cursor/rules/usma.mdc` | Step 0 (done) |
| `docs/PLAN_PROMPT1.md`, `docs/PROGRESS.md` | planning |
| `LICENSE` | P0 |
| `lib/core/config/app_config.dart` | P0 |
| `lib/core/config/firebase_options_from_env.dart` | P0 |
| `lib/core/errors/error_view.dart` (or rename widget) | P0 |
| `lib/core/router/*` (moved) | P0 |
| `lib/features/*/data/mock_*.dart`, `firestore_*.dart` | P0 |
| `lib/features/auth/domain/user_role.dart` | P0 |
| `rules_test/package.json`, `rules_test/tests/*.js` | P0 |
| `assets/schemes/scheme_rules.json` | P1 |
| `lib/features/eligibility/domain/*` | P1 |
| `lib/core/integration/**` | P2 |
| `assets/integration/status_mapping.json` | P2 |
| `assets/mock/**` | P2–P4 |
| Developer screen + pending actions / link / family / money widgets | P3 |
| `lib/features/documents/data/digilocker_service.dart` | P4 |
| `storage.rules` | P4 |
| Tests under `test/` matching gates | each |

### Change

All existing feature repos, `main.dart`, `app.dart`, router, login/splash/otp/ekyc, dashboard, eligibility, apply, documents, disbursements, notifications, profile, settings, models, `firestore.rules`, `firestore.indexes.json`, `firebase.json`, `pubspec.yaml` (assets, maybe `crypto`, `clock`, drop unused later), README, `AppConstants` (SFMP label, 2 MB limit).

### Delete

- `lib/core/config/api_keys.template.dart`
- `lib/core/constants/firebase_options.dart`
- `requirements.txt`
- `lib/core/routing/` after move
- Empty-catch demo-fallback bodies

### Do not delete yet (Prompt 2)

`google_generative_ai` dependency (P0 only stops crashing); Hive unused usage (Prompt 2 Phase D).

---

## Firestore student rule matrix (P0, extended P2/P4)

Auth required unless noted. Role from **custom claims** (`request.auth.token.role`); missing claim = `STUDENT`.

| Path | Student read | Student create | Student update | Student delete |
|---|---|---|---|---|
| `users/{uid}` own | Y | Y (own uid, no `role`) | Own profile fields only; **not** role | N |
| `users/{uid}/children/{id}` | Y | Y if count < 5 | Y own | Y own |
| `users/{uid}/applications/{id}` | Y | Y if `status` in `{DRAFT,SUBMITTED}`, `profileId` set, **no** sanctionedAmount / timeline / verification / disbursement fields, `canonicalStatus` absent or DRAFT/SUBMITTED | Y **only while DRAFT** on allowed fields (institute, course, academicYear, attachedDocIds, applicant-entered data) | N |
| `.../applications/{id}/timeline/{id}` | Y | N | N | N |
| `users/{uid}/documents/{id}` | Y | Y metadata except `verificationStatus` (server default `PENDING` via rules `request.resource.data.verificationStatus == 'PENDING'`) | Y storagePath/sha256/title/type **if** verificationStatus unchanged | N |
| `users/{uid}/disbursements/{id}` | Y | N | N | N |
| `users/{uid}/notifications/{id}` | Y | N | `read`, `readAt` only | N |
| `users/{uid}/devices/{id}` | Y | Y own | Y token fields | Y |
| `users/{uid}/consents/{id}` | Y | Y | revoke fields | N |
| `users/{uid}/verificationReports/{id}` | Y | N | N | N |
| `users/{uid}/chats/**` | Y | Y messages | N | Y (delete-my-chats later) |
| `schemes/{id}` | Y if authed | N | N | N |
| `manualReviewCases/{id}` | Y if `studentUid == uid` | N | N | N |
| `auditLogs/{id}` | N | N | N | N |

**Allowed client application transitions (one table in `lib/core/config/application_transitions.dart` and mirrored in rules comments + rules tests):**

- Client: `→ DRAFT`, `DRAFT → DRAFT` (edit), `DRAFT → SUBMITTED`.
- Client may **not** set: `INSTITUTE_VERIFIED`, `DISTRICT_STATE_VERIFIED`, `SANCTIONED`, `DBT_INITIATED`, `CREDITED`, `ACTION_REQUIRED`, `UNDER_MANUAL_REVIEW`, `REJECTED`, `WITHDRAWN` (Withdrawn in live = callable in Prompt 2; demo Mock may simulate).
- Server/verification layer only: all other transitions, `sanctionedAmount`, timeline docs, verification fields.

**Indexes (query → index comments in repos + `firestore.indexes.json`):**

- `users/{uid}/applications` orderBy `updatedAt` desc
- `users/{uid}/notifications` where `read` + orderBy `createdAt` desc
- `users/{uid}/disbursements` orderBy `disbursementDate` desc
- `users/{uid}/documents` orderBy `uploadedAt` desc
- `manualReviewCases` where `studentUid` == (equality; may need composite if we add status later)

Drop current invalid collectionGroup indexes on `scheme`/`stage`/`paidAt`.

---

## Provider list (Riverpod)

| Provider | Selects |
|---|---|
| `appConfigProvider` | `AppConfig.fromEnvironment()` |
| `firebaseAuthProvider` / `firestoreProvider` / `firebaseStorageProvider` | null in demo; instance in live |
| `authRepositoryProvider` | `MockAuthRepository` / `FirebaseAuthRepository` |
| `schemesRepositoryProvider` | `MockSchemesRepository` / `FirestoreSchemesRepository` (both JSON) |
| `applicationsRepositoryProvider` | Mock / Firestore |
| `documentsRepositoryProvider` | Mock / Firestore |
| `disbursementsRepositoryProvider` | Mock / Firestore |
| `notificationsRepositoryProvider` | Mock / Firestore |
| `verificationOrchestratorProvider` | Mock providers vs Live stubs |
| `sourceSystemAdaptersProvider` | map of Mock/Live adapters |
| `digiLockerServiceProvider` | Mock / Live stub |
| `activeProfileIdProvider` | self uid or selected child |
| `routerProvider` | redirect uses auth + role |
| Existing UI providers | rewritten to throw `Failure`, no `demo_user_001` |

---

## Test list

### P0
- `app_config_test.dart` — default demo; live from define
- `provider_selection_test.dart` — Mock vs Firestore by DataMode
- `auth_guard_test.dart` — signed-out → login; signed-in → home (not splash loop)
- `error_view_failure_test.dart` — fake Firestore throws → `ErrorView` visible, seed not shown
- `rules_test/student.test.js` — matrix above

### P1 (≥20)
- Income = ceiling, ceiling+1, ceiling−1 for Pre/Post (2.5L) and Top/NOS (6L)
- NFST: no income fail if we adopt “no ceiling”; still test Masters+M.Phil/PhD enrolment
- PVTG preference flag (does not auto-fail others)
- Girls / Divyangjan preference flags
- NOS: overseas admission required; domestic → NOT_ELIGIBLE
- Top Class: institute on list / not on list
- Missing income or education → NEEDS_INFO
- JSON schema: required keys for all five `schemeId`s

### P2
- Each `VerificationStatus` outcome
- Timeout; retry+backoff (fake clock)
- Circuit breaker open / half-open / close
- Mismatch → ManualReviewCase, application still SUBMITTED/UNDER_MANUAL_REVIEW, not blocked
- Only `requiredVerificationProviders` invoked
- NSP, SFMP, NOS unknown status → `ActionRequired` (safe default)

### P3
- Guard: any source non-terminal blocks; Rejected/Withdrawn do not; Credited still blocks until `awardEndDate`
- Widget: empty, loading, error, deficiency, manual-review
- Golden or pump at width 360, `textScaleFactor: 2.0`

### P4
- Checklist reuse / missing / expiring
- Income cert FY boundary (31 Mar / 1 Apr)
- Upload progress + failure widget
- Rules: client write `verificationStatus: VERIFIED` denied

---

## P2 interface signatures and canonical status (review on go)

```dart
enum DataMode { demo, live }

enum SourceSystem { nsp, sfmp, nosPortal, statePortal }

enum CanonicalStatus {
  draft,
  submitted,
  instituteVerified,
  districtStateVerified,
  sanctioned,
  dbtInitiated,
  credited,
  actionRequired,
  underManualReview,
  rejected,
  withdrawn,
}

enum VerificationOutcome { verified, mismatch, unavailable, needsManualReview }

enum UserRole { student, instituteNodal, districtWelfare, stateNodal, motaAdmin }

abstract class SourceSystemAdapter {
  SourceSystem get system;
  Future<List<UnifiedApplication>> fetchApplications(StudentRef student);
  Future<UnifiedApplication> fetchStatus(SourceRef ref);
  Future<List<UnifiedDisbursement>> fetchDisbursements(SourceRef ref);
}

class UnifiedApplication { /* sourceSystem, sourceReferenceId, schemeId, canonicalStatus, currency, lastSyncedAt, profileId */ }

class UnifiedDisbursement { /* sourceSystem, sourceReferenceId, schemeId, canonicalStatus, currency, lastSyncedAt, amount, utr */ }

abstract class VerificationProvider {
  String get id;
  Future<List<VerificationCheck>> verify({
    required StudentSnapshot student,
    required ApplicationSnapshot application,
    required SchemeRule scheme,
    required Clock clock,
  });
}

abstract class VerificationOrchestrator {
  Future<VerificationReport> verify({
    required StudentSnapshot student,
    required ApplicationSnapshot application,
    required SchemeRule scheme,
  });
}
```

Providers (one class each, Mock + Live stub): DigiLocker, UidaiEkyc, StateEDistrict, Aishe, UdisePlus, Apaar, UgcNta, NpciPfms.

**Canonical stepper (dashboard):** Submitted → Institute verified → District/State verified → Sanctioned → DBT initiated → Credited.

**Status mapping (data, not code):** `assets/integration/status_mapping.json` columns `nsp`, `sfmp`, `nos_portal`, `state_portal`. Unknown → `actionRequired`. Proposed seed rows (NSP/SFMP/NOS labels are **illustrative of common portal language**, marked `needsVerification: true` — we do not have official API enums):

| Canonical | NSP examples | SFMP examples | NOS examples |
|---|---|---|---|
| submitted | SUBMITTED, APPLIED | APPLICATION_RECEIVED | SUBMITTED |
| instituteVerified | INSTITUTE_VERIFIED | INSTITUTE_OK | — |
| districtStateVerified | STATE_VERIFIED, DISTRICT_VERIFIED | — | — |
| sanctioned | SANCTIONED, MINISTRY_APPROVED | FELLOWSHIP_AWARDED | AWARDED |
| dbtInitiated | PFMS_SENT, DBT_INITIATED | PAYMENT_INITIATED | PAYMENT_INITIATED |
| credited | DISBURSED, CREDITED | CREDITED | CREDITED |
| actionRequired | DEFICIENCY, ACTION_REQUIRED | QUERY_RAISED | DOCUMENT_PENDING |
| underManualReview | MANUAL_REVIEW | MANUAL_REVIEW | MANUAL_REVIEW |
| rejected | REJECTED | REJECTED | REJECTED |
| withdrawn | WITHDRAWN | WITHDRAWN | WITHDRAWN |

---

## Ambiguities and proposed defaults

1. **NFST income.** Fellowship guidelines (MoTA PDF copy) state **no income criterion** for the fellowship sub-scheme; in-app FAQ says ₹6L. **Default:** `incomeCeilingInr: null` + `needsVerification: true`. Do not fail NFST on income.
2. **Top Class institute list.** tribal.nic.in cites **265** institutes (also 252/246 in older text). Full PDF list not parsed into 265 names here. **Default:** JSON array of well-known notified types (IIT/NIT/IIM/AIIMS/NLU **names we can cite from public lists**) plus `"notifiedInstituteCount": 265`, `"listIncomplete": true`, `"needsVerification": true`. Engine: if listIncomplete and institute not found → `NEEDS_INFO` (not hard NOT_ELIGIBLE), unless `requireListedInstitute: true` and we have an exact id match.
3. **Application cycles / deadlines.** No confirmed AY 2026-27 close dates from the live page (NOS showed a **2025-26** extension to 15 Jul 2025, now historical). **Default:** `cycle: { "label": "unconfirmed", "needsVerification": true }` and eligibility does not fail solely on deadline unless `deadline` is present and `needsVerification` is false.
4. **NOS amounts.** tribal.nic.in confirms 20 awards (17 ST + 3 PVTG) and ₹6L income; USD maintenance **15,400** and contingency **1,532** appear in our FAQ, not in the HTML I fetched. **Default:** put USD figures with `needsVerification: true`.
5. **Pre/Post rates.** FAQ has day-scholar/hosteller rupees; HTML confirms ₹2.5L income, not the monthly rates in the snippet I used. **Default:** income from HTML; monthly rates from FAQ with `needsVerification: true`.
6. **NFST stipend.** HTML: M.Phil ₹25,000 / Ph.D ₹28,000 per month; page also mentions revised rates w.e.f. 1.1.2023. **Default:** use HTML figures + `needsVerification: true` for whether 2023 revision superseded them.
7. **One-scholarship + Credited.** Holding a credited award still blocks a second. Terminal for new apply: `rejected`, `withdrawn`, or `credited` with `awardEndDate < today`.
8. **Demo seed.** Single Post-Matric app `submitted`/`sanctioned` (one only). Extra Top Class seed **deleted** so the guard is honest.
9. **Demo identity.** No `demo_user_001`. Session uid = `Uuid.v4()` after SIMULATED login; seed data keyed to that session via Mock repos, not Firestore.
10. **Router path.** Move `routing` → `router`.
11. **ErrorView name.** Rename `AppErrorView` → `ErrorView`.
12. **Timeline storage.** Subcollection `timeline` is canonical; UI joins. Client submit does **not** write timeline (Mock orchestrator writes it in demo as “verification layer”).
13. **Apply screen today writes `sanctionedAmount` and timeline.** Stop. Client send `null`/omit; Mock verification layer may fill later.
14. **Disbursement user filter.** Store under `users/{uid}/disbursements`; never collection-wide get.
15. **Guest path.** Remove “skip to dashboard”. Only SIMULATED demo student or live OTP.
16. **Splash.** Short branded splash then redirect respects auth guard (not a hard dashboard jump).
17. **SFMP display name.** “Scholarship Fellowship Management Portal (Canara Bank)”.
18. **`intl` conflict.** Prefer whatever version `flutter_localizations` requires; document the pin.
19. **Circuit breaker defaults.** 3 failures → open 30s; half-open 1 probe; injected clock/delays.
20. **Orchestrator timeout.** 2.5s per provider default.
21. **Manual review assignee.** ST/income/domicile mismatch → `DISTRICT_WELFARE`; institute/AISHE → `INSTITUTE_NODAL`; else `STATE_NODAL`. SLA 7 days.
22. **Family.** Guardian is the Firebase user; children are profiles, not extra Auth users (Prompt 2 can add true multi-account).
23. **SIH badge / problem ID / “encrypted storage” / root APK.** Prompt 1 README will **stop claiming** encrypted Hive, pre-built APK, and “production build”. Keep MoTA/SIH framing as **intended entry** without asserting problem ID unless you confirm. Prompt 2 will finish honesty pass.
24. **Chatbot Gemini model id.** Do not invent a current model; if key present, use `gemini-2.0-flash` only if we confirm at implement time via package docs; otherwise FAQ-only. Prompt 2 removes client Gemini.
25. **Ekyc live.** No UIDAI endpoint; Live throws `UnimplementedError('needs MoTA API credentials')`; UI explains SIMULATED in demo.
26. **Rules tests runner.** `firebase emulators:exec --only firestore npm test` from `rules_test/`.
27. **P2 “post signatures then continue”.** Signatures are in this plan. On **go**, P2 will implement these unless you reply with edits.

---

## Not verified (planning time)

- Did not run `flutter pub get`, `flutter analyze`, `flutter test`, or the emulator.
- Did not open every linked PDF on tribal.nic.in (institute list of 265, latest NFST rate revision, Pre/Post monthly rates).
- Did not confirm NSP / SFMP / NOS **API status enumerations** — mapping table is a SIMULATED default.
- Did not confirm DigiLocker / UIDAI / AISHE / UDISE+ / APAAR / UGC-NTA / PFMS endpoints (none will be invented).
- NOS USD figures and NFST ₹6L FAQ vs no-income PDF conflict.
- SIH problem ID `SIH26238` and “Ministry Production Build” in Settings.
- Whether current stable Flutter accepts `intl ^0.20.3`.
- Live Firebase project, test phone numbers, App Check (Prompt 2).

---

## After you type **go**

Execute P0 → gate + commit `p0: <summary>` → P1 → … → P4 → final gate. Update `docs/PROGRESS.md` after each phase. If a gate stays red after 2 fix attempts, stop and report.
