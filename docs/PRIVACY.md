# USMA Privacy & DPDP Act 2023 Compliance Architecture

This document details the data privacy safeguards implemented in USMA (Unified Scholarship Mobile Application) for the Ministry of Tribal Affairs (SIH 2026 PS SIH26238).

## 1. Statutory Grounding: DPDP Act 2023
USMA processes sensitive personal identifiers (Aadhaar, Caste certificates, Income certificates, Bank account details) of Scheduled Tribe citizens. The system complies with:
- **Purpose Limitation (Section 6):** Data collected solely for statutory scholarship eligibility, verification, and Direct Benefit Transfer (DBT).
- **Data Minimization:** Integration layers fetch only verified attestations (e.g. valid ST certificate true/false and validity dates) rather than downloading entire document sets when not strictly necessary.
- **Children's Privacy Protections (Section 9):**
  - Minors are identified using date of birth.
  - Parental / Guardian consent is verified prior to submission for Pre-Matric ST students.
  - Behavioral analytics and tracking are unconditionally disabled for all minor profiles.

## 2. Technical Safeguards
### Client-Side PII Masking & Logging
- **Aadhaar Numbers:** 12-digit numbers are scrubbed to `XXXX-XXXX-1234`.
- **Mobile Numbers:** Scrubbed to `XXXXXX1234`.
- **Bank Accounts:** Scrubbed to `XXXXXX1234`.
- Automated `PiiRedactor` sanitizes all client-side error telemetry and debug logs.

### Storage & Transmission
- TLS 1.3 encryption in transit for all Cloud Function and Firebase API calls.
- Integrity verification using client-computed SHA-256 digests.
- Pseudonymised analytics via HMAC-SHA256 hashing so that coverage gap consoles never process plaintext APAAR / Aadhaar numbers.
- Small-cell suppression (<10 count masked) prevents re-identification in tribal habitations with sparse student counts.
