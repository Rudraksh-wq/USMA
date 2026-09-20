import { expect } from 'chai';
import { UnifiedVerificationRouter } from '../src/router';
import { VerificationAuditLogger } from '../src/audit_log';
import { VerificationRequest } from '../src/types';

describe('Unified Verification Router & Adapters Test Suite', () => {
  let router: UnifiedVerificationRouter;

  beforeEach(() => {
    router = new UnifiedVerificationRouter();
    VerificationAuditLogger.clear();
  });

  it('1. Router registers all 8 government & portal adapters', () => {
    expect(router.getRegisteredSourcesCount()).to.equal(8);
  });

  it('2. Router maps AADHAAR to UIDAI Adapter', () => {
    const source = router.resolveSource('AADHAAR');
    expect(source.sourceName).to.include('UIDAI');
  });

  it('3. Router maps CASTE_CERTIFICATE to DigiLocker Adapter', () => {
    const source = router.resolveSource('CASTE_CERTIFICATE');
    expect(source.sourceName).to.include('DigiLocker');
  });

  it('4. Router maps STATE_INCOME to State e-District Adapter', () => {
    const source = router.resolveSource('STATE_INCOME');
    expect(source.sourceName).to.include('State e-District');
  });

  it('5. Router maps NET_JRF to UGC-NTA Adapter', () => {
    const source = router.resolveSource('NET_JRF');
    expect(source.sourceName).to.include('UGC-NTA');
  });

  it('6. Persona all-verified: returns status verified with zero diffs', async () => {
    const req: VerificationRequest = {
      requestId: 'req_1',
      applicationId: 'app_1',
      userId: 'user_1',
      sourceType: 'DigiLocker',
      documentOrFieldType: 'CASTE_CERTIFICATE',
      payload: {},
      persona: 'all-verified',
    };

    const res = await router.executeVerification(req);
    expect(res.status).to.equal('verified');
    expect(res.diffs).to.be.empty;
    expect(res.requiresManualReview).to.be.false;
  });

  it('7. Persona name-mismatch: returns status mismatch, requiresManualReview true, NEVER throws', async () => {
    const req: VerificationRequest = {
      requestId: 'req_2',
      applicationId: 'app_2',
      userId: 'user_2',
      sourceType: 'UIDAI',
      documentOrFieldType: 'AADHAAR',
      payload: { name: 'Birsa Munda' },
      persona: 'name-mismatch',
    };

    const res = await router.executeVerification(req);
    expect(res.status).to.equal('mismatch');
    expect(res.requiresManualReview).to.be.true;
    expect(res.diffs.length).to.be.greaterThan(0);
    expect(res.diffs[0].fieldName).to.equal('fullName');
  });

  it('8. Persona income-mismatch: captures diff, sets requiresManualReview true', async () => {
    const req: VerificationRequest = {
      requestId: 'req_3',
      applicationId: 'app_3',
      userId: 'user_3',
      sourceType: 'StateEDistrict',
      documentOrFieldType: 'STATE_INCOME',
      payload: {},
      persona: 'income-mismatch',
    };

    const res = await router.executeVerification(req);
    expect(res.status).to.equal('mismatch');
    expect(res.requiresManualReview).to.be.true;
    expect(res.diffs[0].fieldName).to.equal('familyIncome');
  });

  it('9. Persona source-timeout: handles gracefully with status unavailable and requiresManualReview true', async () => {
    const req: VerificationRequest = {
      requestId: 'req_4',
      applicationId: 'app_4',
      userId: 'user_4',
      sourceType: 'DigiLocker',
      documentOrFieldType: 'CASTE_CERTIFICATE',
      payload: {},
      persona: 'source-timeout',
    };

    const res = await router.executeVerification(req);
    expect(res.status).to.equal('unavailable');
    expect(res.requiresManualReview).to.be.true;
  });

  it('10. Audit log entries are appended without PII', async () => {
    const req: VerificationRequest = {
      requestId: 'req_audit',
      applicationId: 'app_audit',
      userId: 'user_secret_123',
      sourceType: 'StateEDistrict',
      documentOrFieldType: 'STATE_INCOME',
      payload: { secretIncome: '100000', aadhaar: '123456789012' },
      persona: 'income-mismatch',
    };

    await router.executeVerification(req);
    const logs = VerificationAuditLogger.getEntries();
    expect(logs.length).to.equal(1);
    expect(logs[0].requestId).to.equal('req_audit');
    expect(logs[0].mismatchFieldNames).to.include('familyIncome');
    // Ensure no Aadhaar or payload values are leaked into audit log
    const logStr = JSON.stringify(logs[0]);
    expect(logStr).to.not.include('123456789012');
  });
});
