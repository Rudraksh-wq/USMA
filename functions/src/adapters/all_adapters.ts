import { FieldDiff, VerificationRequest, VerificationResult, VerificationSource } from '../types';

// =============================================================================
// 1. DIGILOCKER ADAPTER
// =============================================================================
export class DigiLockerAdapter implements VerificationSource {
  readonly sourceName = 'DigiLocker (API Setu / MeitY)';
  readonly supportedTypes = ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'MARKSHEET', 'DOMICILE'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    if (request.persona === 'source-timeout') {
      await new Promise((_, reject) => setTimeout(() => reject(new Error('Gateway Timeout (504)')), 6000));
    }

    // VERIFY: Real integration uses OAuth2.0 Token + API Setu URI fetch
    // Endpoint: https://api.digitallocker.gov.in/public/oauth2/1/xml/issued
    const isMock = true; // Controlled by config flag

    return {
      status: 'verified',
      source: this.sourceName,
      timestamp: new Date().toISOString(),
      confidence: 0.99,
      diffs: [],
      requiresManualReview: false,
      message: 'Cryptographically verified with DigiLocker issued repository.',
      isSimulated: isMock,
    };
  }
}

// =============================================================================
// 2. UIDAI ADAPTER (Name & DoB match only, NO Aadhaar stored/logged)
// =============================================================================
export class UidaiAdapter implements VerificationSource {
  readonly sourceName = 'UIDAI Aadhaar Verification';
  readonly supportedTypes = ['AADHAAR', 'IDENTITY'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    if (request.persona === 'source-timeout') {
      await new Promise((_, reject) => setTimeout(() => reject(new Error('UIDAI CIDR Service Timeout')), 6000));
    }

    const diffs: FieldDiff[] = [];
    let status: 'verified' | 'mismatch' = 'verified';

    if (request.persona === 'name-mismatch') {
      diffs.push({
        fieldName: 'fullName',
        declaredValue: request.payload.name || 'Birsa Munda',
        sourceValue: 'Birsa Kumar Munda',
        reason: 'Name abbreviation mismatch between application and Aadhaar demographic vault.',
      });
      status = 'mismatch';
    }

    // VERIFY: Real integration requires UIDAI KUA/ASA license & biometric/OTP eKYC Auth API
    return {
      status,
      source: this.sourceName,
      timestamp: new Date().toISOString(),
      confidence: status === 'verified' ? 0.98 : 0.75,
      diffs,
      requiresManualReview: status === 'mismatch', // CRITICAL: Never auto-rejects!
      message: status === 'verified' ? 'Identity demographic match confirmed.' : 'Demographic variation routed to manual review.',
      isSimulated: true,
    };
  }
}

// =============================================================================
// 3. AISHE ADAPTER (Higher Education Institutions)
// =============================================================================
export class AisheAdapter implements VerificationSource {
  readonly sourceName = 'AISHE (All India Survey on Higher Education)';
  readonly supportedTypes = ['INSTITUTION_HIGHER_EDU', 'COLLEGE_RECOGNITION'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    // VERIFY: Real integration uses Ministry of Education AISHE API
    return {
      status: 'verified',
      source: this.sourceName,
      timestamp: new Date().toISOString(),
      confidence: 0.95,
      diffs: [],
      requiresManualReview: false,
      message: 'Institution code recognized in official AISHE directory.',
      isSimulated: true,
    };
  }
}

// =============================================================================
// 4. UDISE+ ADAPTER (School Education Class 1-12)
// =============================================================================
export class UdiseAdapter implements VerificationSource {
  readonly sourceName = 'UDISE+ (Unified District Information System for Education)';
  readonly supportedTypes = ['SCHOOL_RECOGNITION', 'PRE_MATRIC_ENROLMENT'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    // VERIFY: Real integration uses MoE UDISE+ School Verification Gateway
    return {
      status: 'verified',
      source: this.sourceName,
      timestamp: new Date().toISOString(),
      confidence: 0.95,
      diffs: [],
      requiresManualReview: false,
      message: 'School registration verified in UDISE+ national database.',
      isSimulated: true,
    };
  }
}

// =============================================================================
// 5. APAAR ADAPTER (One Nation One Student ID / EduLocker)
// =============================================================================
export class ApaarAdapter implements VerificationSource {
  readonly sourceName = 'APAAR (Automated Permanent Academic Account Registry)';
  readonly supportedTypes = ['APAAR_ID', 'STUDENT_REGISTRY'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    // VERIFY: Real integration uses APAAR API on API Setu
    return {
      status: 'verified',
      source: this.sourceName,
      timestamp: new Date().toISOString(),
      confidence: 0.97,
      diffs: [],
      requiresManualReview: false,
      message: 'APAAR ID active and linked with academic credentials.',
      isSimulated: true,
    };
  }
}

// =============================================================================
// 6. STATE E-DISTRICT ADAPTER (ST/PVTG, Income, Domicile)
// =============================================================================
export class StateEDistrictAdapter implements VerificationSource {
  readonly sourceName = 'State e-District Portal';
  readonly supportedTypes = ['STATE_CASTE', 'STATE_INCOME', 'STATE_DOMICILE'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    const diffs: FieldDiff[] = [];
    let status: 'verified' | 'mismatch' = 'verified';

    if (request.persona === 'income-mismatch') {
      diffs.push({
        fieldName: 'familyIncome',
        declaredValue: '₹1,50,000',
        sourceValue: '₹2,60,000',
        reason: 'State revenue records report income exceeding declared amount.',
      });
      status = 'mismatch';
    }

    // VERIFY: Real integration requires state-specific e-District APIs (e.g., edistrict.odisha.gov.in)
    return {
      status,
      source: `${this.sourceName} (${request.state || 'National'})`,
      timestamp: new Date().toISOString(),
      confidence: status === 'verified' ? 0.96 : 0.70,
      diffs,
      requiresManualReview: status === 'mismatch',
      message: status === 'verified' ? 'State revenue certificate verified.' : 'Discrepancy detected; sent to officer review queue.',
      isSimulated: true,
    };
  }
}

// =============================================================================
// 7. UGC-NTA ADAPTER (NET / JRF Verification for NFST)
// =============================================================================
export class UgcNtaAdapter implements VerificationSource {
  readonly sourceName = 'UGC-NTA National Testing Agency Gateway';
  readonly supportedTypes = ['NET_JRF', 'RESEARCH_ENTRANCE'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    // VERIFY: Real integration uses NTA Score Verification API
    return {
      status: 'verified',
      source: this.sourceName,
      timestamp: new Date().toISOString(),
      confidence: 0.99,
      diffs: [],
      requiresManualReview: false,
      message: 'UGC-NET qualification verified against NTA result repository.',
      isSimulated: true,
    };
  }
}

// =============================================================================
// 8. SCHEME STATUS ADAPTER (NSP, SFMP, NOS Active Awards)
// =============================================================================
export class SchemeStatusAdapter implements VerificationSource {
  readonly sourceName = 'Multi-Portal Scheme Status Bridge (NSP / SFMP / NOS)';
  readonly supportedTypes = ['SCHEME_AWARD_STATUS', 'PORTAL_CROSS_CHECK'];

  async verify(request: VerificationRequest): Promise<VerificationResult> {
    // VERIFY: Real integration bridges NSP (scholarships.gov.in), Canara Bank SFMP, and NOS portal
    return {
      status: 'verified',
      source: this.sourceName,
      timestamp: new Date().toISOString(),
      confidence: 0.94,
      diffs: [],
      requiresManualReview: false,
      message: 'Cross-portal active award verification completed.',
      isSimulated: true,
    };
  }
}
