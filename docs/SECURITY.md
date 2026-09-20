# USMA Security Architecture & Lockdown Specification (Phase 1)

## Overview
USMA handles critical identity, educational, caste verification, and Direct Benefit Transfer (DBT) data for Scheduled Tribe students under the Ministry of Tribal Affairs (MoTA). This document defines the Role-Based Access Control (RBAC) model, Firestore & Storage security rules, and audit requirements.

---

## 1. Role-Based Access Control (RBAC) Matrix

USMA enforces security through Firebase Authentication custom claims (`role`, `state`, `institutionId`).

| Role | Scope | Description |
|---|---|---|
| `student` | Own User ID (`request.auth.uid`) | ST applicant or student beneficiary |
| `institution_verifier` | `institutionId` claim | College/School Nodal Officer verifying admission & academic credentials |
| `state_officer` | `state` claim (e.g. `OD`, `JH`) | State Tribal Welfare Department verifying caste, income quota |
| `ministry_officer` | Nationwide | MoTA Central Project Officer sanctioning funds & DBT approval |
| `admin` | Nationwide | System administrator / IT DA |

---

## 2. Role x Collection Permission Matrix

| Collection | Student | Institution Verifier | State Officer | Ministry Officer / Admin | Backend / Functions |
|---|---|---|---|---|---|
| `/users/{uid}` | Read/Update own (unprivileged fields) | Read scoped by `institutionId` | Read scoped by `state` | Read all | Read/Write all |
| `/users/{uid}/devices` | Read/Write own | No access | No access | No access | Full access |
| `/applications/{id}` | Read own; Create (Draft/Submitted); Update (Draft/Returned only) | Read scoped; Update (Submitted/Resubmitted -> InstituteVerified/Returned/Rejected) | Read scoped; Update (InstituteVerified -> StateApproved/Returned/Rejected) | Read all; Update (StateApproved -> Sanctioned/Rejected) | Full access |
| `/documents/{id}` | Read own; Upload (Pending); No delete if linked/verified | Read scoped; Update verification fields only | Read scoped; Update verification fields only | Read all; Update verification fields only | Full access |
| `/disbursements/{id}` | Read own | No access | Read scoped by `state` | Read all | **ONLY write authority** (PFMS webhook/Cloud Function) |
| `/deficiencies/{id}` | Read own; Update (`studentResponse`, attachments) | Read/Create/Close scoped | Read/Create/Close scoped | Read/Create/Close all | Full access |
| `/notifications/{id}` | Read own; Update (`read`/`isRead` only) | Create scoped | Create scoped | Create all | Full access |
| `/manual_reviews/{id}`| No access | Read/Resolve scoped | Read/Resolve scoped | Read/Resolve all | Full access |
| `/schemes/{id}` | Read all | Read all | Read all | Full access | Full access |

---

## 3. Application Lifecycle Status Transition Table

Applications adhere to a strict Finite State Machine (FSM). Unauthorized jumps (e.g., student jumping to `Sanctioned` or verifier jumping to `Sanctioned`) are rejected at the database rule layer.

```
       [Draft]
          │
          ▼ (Student submit)
     [Submitted] ◄──────────────────────┐
          │                             │ (Student resubmit)
          ▼ (Institute Verifier)        │
 [InstituteVerified]              [Returned] (Deficiency raised)
          │                             ▲
          ▼ (State Officer)             │
   [StateApproved] ─────────────────────┘
          │
          ▼ (Ministry Officer)
    [Sanctioned]
          │
          ▼ (Cloud Function / PFMS)
    [Disbursed]
```

### Transition Enforcement

| From Status | To Status | Allowed Actor | Required Affected Keys Subset |
|---|---|---|---|
| *None* | `Draft`, `Submitted` | `student` (`userId == auth.uid`) | Initial form fields |
| `Draft` | `Draft`, `Submitted`, `Withdrawn` | `student` (`userId == auth.uid`) | Student form fields |
| `Submitted` | `InstituteVerified`, `Returned`, `Rejected` | `institution_verifier` (`institutionId` match) | `['status', 'remarks', 'instituteRemarks', 'reviewedBy', 'reviewedAt', 'updatedAt', 'verificationStages']` |
| `Returned` | `Resubmitted`, `Withdrawn` | `student` (`userId == auth.uid`) | Student form fields + `status` |
| `Resubmitted`| `InstituteVerified`, `Returned`, `Rejected` | `institution_verifier` (`institutionId` match) | Verifier audit fields |
| `InstituteVerified` | `StateApproved`, `Returned`, `Rejected` | `state_officer` (`state` match) | State officer audit fields |
| `StateApproved` | `Sanctioned`, `Rejected` | `ministry_officer`, `admin` | Ministry sanction audit fields |
| `Sanctioned` | `Disbursed` | Cloud Functions / Admin SDK only | Backend write only |

---

## 4. Document Vault & Storage Security

### Cloud Storage (`storage.rules`)
- **Default Policy:** Deny all read and write requests.
- **Upload Location:** `/users/{uid}/documents/{fileName}`.
- **Upload Constraints:**
  - Owner only (`request.auth.uid == uid`).
  - Max file size: **5 MB**.
  - Content types restricted to: `application/pdf`, `image/jpeg`, `image/png`.
- **Read Access:** Document owner or authenticated officer (`isOfficerOrAdmin()`).

### Firestore Documents Metadata
- **Integrity Rule:** Students cannot set `verificationStatus: 'VERIFIED'`, `verifiedBy`, or `verifiedAt`.
- **Officer Constraint:** Officers can only modify `verificationStatus`, `verifiedBy`, `verifiedAt`, and `verifierRemarks`. They cannot tamper with `fileUrl`, `type`, or student metadata.
- **Immutability:** Once a document is linked to an application or verified, it cannot be deleted by the student.

---

## 5. Direct Benefit Transfer (DBT) Security

Disbursement records under `/disbursements/{disbursementId}` represent financial transfers through the Public Financial Management System (PFMS) / NPCI Aadhaar Payment Bridge:
- **Zero Client Writes:** All write operations (`create`, `update`, `delete`) are disabled in `firestore.rules`.
- Only server-side Cloud Functions executing with Firebase Admin SDK or secured webhooks can generate or update disbursements.
- Read access is strictly scoped: students can read only their own disbursements, state officers can read records matching their state, and central ministry officers have nationwide read access.

---

## 6. Custom Claims Provisioning

Role custom claims must be provisioned via the Admin SDK using `scripts/set_role.js`.

```bash
# Set student
node scripts/set_role.js <uid> student

# Set college nodal verifier (scoped to institution INST_001 in Odisha)
node scripts/set_role.js <uid> institution_verifier OD INST_001

# Set state officer (scoped to Jharkhand)
node scripts/set_role.js <uid> state_officer JH

# Set central ministry officer
node scripts/set_role.js <uid> ministry_officer

# Set administrator
node scripts/set_role.js <uid> admin
```

---

## 7. Automated Security Test Suite

The security rules test suite is located in `rules_test/` and uses `@firebase/rules-unit-testing`:
- Over 30 allow/deny test cases.
- Validates prevention of privilege escalation, cross-tenant leaks, self-approval attacks, parameter tampering, and disbursement injection.
- Run via Firebase Emulator Suite:
  ```bash
  firebase emulators:exec "npm test" --only firestore,storage,auth
  ```
