/**
 * rules_test/rules.test.js
 * 
 * Comprehensive Firestore & Storage security rules test suite for USMA.
 * Verified with @firebase/rules-unit-testing.
 */

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');
const { expect } = require('chai');

const PROJECT_ID = 'usma-security-test';

describe('USMA Security Rules Lockdown Test Suite', () => {
  let testEnv;

  before(async () => {
    const firestoreRules = fs.readFileSync(
      path.resolve(__dirname, '../firestore.rules'),
      'utf8'
    );
    let storageRules;
    try {
      storageRules = fs.readFileSync(
        path.resolve(__dirname, '../storage.rules'),
        'utf8'
      );
    } catch (e) {
      storageRules = '';
    }

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: firestoreRules,
        host: '127.0.0.1',
        port: 8080,
      },
      storage: storageRules
        ? {
            rules: storageRules,
            host: '127.0.0.1',
            port: 9199,
          }
        : undefined,
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
      if (testEnv.clearStorage) {
        await testEnv.clearStorage();
      }
    }
  });

  // Helper context generators
  const getUnauthContext = () => testEnv.unauthenticatedContext();
  const getStudentContext = (uid = 'student_od_1') =>
    testEnv.authenticatedContext(uid, { role: 'student' });
  const getOtherStudentContext = () =>
    testEnv.authenticatedContext('student_jh_2', { role: 'student' });
  const getInstVerifierContext = (instId = 'INST_001') =>
    testEnv.authenticatedContext('verifier_1', {
      role: 'institution_verifier',
      institutionId: instId,
    });
  const getStateOfficerContext = (state = 'OD') =>
    testEnv.authenticatedContext('state_off_1', {
      role: 'state_officer',
      state: state,
    });
  const getMinistryOfficerContext = () =>
    testEnv.authenticatedContext('ministry_off_1', {
      role: 'ministry_officer',
    });
  const getAdminContext = () =>
    testEnv.authenticatedContext('admin_1', { role: 'admin' });

  // Seed helper
  const seedDoc = async (collectionPath, docId, data) => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection(collectionPath).doc(docId).set(data);
    });
  };

  // ===========================================================================
  // 1. APPLICATIONS COLLECTION TESTS
  // ===========================================================================
  describe('1. Applications Security & Status Transition Matrix', () => {
    it('ALLOW: Student creates application with Draft status', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_1').set({
          userId: 'student_1',
          schemeId: 'pre_matric_st',
          status: 'Draft',
          createdAt: new Date().toISOString(),
        })
      );
    });

    it('ALLOW: Student creates application with Submitted status', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_2').set({
          userId: 'student_1',
          schemeId: 'post_matric_st',
          status: 'Submitted',
          createdAt: new Date().toISOString(),
        })
      );
    });

    it('DENY: Student creates application with Sanctioned status (Privilege Escalation)', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('applications').doc('app_attack_1').set({
          userId: 'student_1',
          schemeId: 'pre_matric_st',
          status: 'Sanctioned',
          createdAt: new Date().toISOString(),
        })
      );
    });

    it('DENY: Student creates application on behalf of another student (Identity Spoofing)', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('applications').doc('app_spoof').set({
          userId: 'student_2',
          schemeId: 'pre_matric_st',
          status: 'Draft',
          createdAt: new Date().toISOString(),
        })
      );
    });

    it('ALLOW: Student edits own application while in Draft status', async () => {
      await seedDoc('applications', 'app_draft', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        status: 'Draft',
        annualIncome: 150000,
      });

      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_draft').update({
          annualIncome: 180000,
        })
      );
    });

    it('ALLOW: Student transitions Draft -> Submitted', async () => {
      await seedDoc('applications', 'app_submit', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        status: 'Draft',
      });

      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_submit').update({
          status: 'Submitted',
        })
      );
    });

    it('DENY: Student transitions Draft -> Sanctioned directly (Self-Approval Attack)', async () => {
      await seedDoc('applications', 'app_bypass', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        status: 'Draft',
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('applications').doc('app_bypass').update({
          status: 'Sanctioned',
        })
      );
    });

    it('DENY: Student edits application after Submission', async () => {
      await seedDoc('applications', 'app_locked', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        status: 'Submitted',
        annualIncome: 150000,
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('applications').doc('app_locked').update({
          annualIncome: 90000,
        })
      );
    });

    it('ALLOW: Student transitions Returned -> Resubmitted', async () => {
      await seedDoc('applications', 'app_returned', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        status: 'Returned',
      });

      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_returned').update({
          status: 'Resubmitted',
        })
      );
    });

    it('DENY: Deleting application is always forbidden (Audit Trail Preservation)', async () => {
      await seedDoc('applications', 'app_nodelete', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        status: 'Draft',
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('applications').doc('app_nodelete').delete()
      );
    });

    it('ALLOW: Scoped Institution Verifier transitions Submitted -> InstituteVerified', async () => {
      await seedDoc('applications', 'app_verify_inst', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        institutionId: 'INST_001',
        state: 'OD',
        status: 'Submitted',
      });

      const db = getInstVerifierContext('INST_001').firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_verify_inst').update({
          status: 'InstituteVerified',
          remarks: 'All documents verified with institute records.',
          reviewedBy: 'verifier_1',
          reviewedAt: new Date().toISOString(),
        })
      );
    });

    it('DENY: Institution Verifier cannot approve application of another institution (Cross-Tenant)', async () => {
      await seedDoc('applications', 'app_other_inst', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        institutionId: 'INST_999',
        state: 'OD',
        status: 'Submitted',
      });

      const db = getInstVerifierContext('INST_001').firestore();
      await assertFails(
        db.collection('applications').doc('app_other_inst').update({
          status: 'InstituteVerified',
          reviewedBy: 'verifier_1',
        })
      );
    });

    it('DENY: Institution Verifier cannot skip stage to Sanctioned', async () => {
      await seedDoc('applications', 'app_skip_stage', {
        userId: 'student_1',
        schemeId: 'pre_matric_st',
        institutionId: 'INST_001',
        status: 'Submitted',
      });

      const db = getInstVerifierContext('INST_001').firestore();
      await assertFails(
        db.collection('applications').doc('app_skip_stage').update({
          status: 'Sanctioned',
          reviewedBy: 'verifier_1',
        })
      );
    });

    it('ALLOW: Scoped State Officer transitions InstituteVerified -> StateApproved', async () => {
      await seedDoc('applications', 'app_state_flow', {
        userId: 'student_1',
        schemeId: 'post_matric_st',
        institutionId: 'INST_001',
        state: 'OD',
        status: 'InstituteVerified',
      });

      const db = getStateOfficerContext('OD').firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_state_flow').update({
          status: 'StateApproved',
          remarks: 'State quota approved.',
          reviewedBy: 'state_off_1',
          reviewedAt: new Date().toISOString(),
        })
      );
    });

    it('DENY: State Officer cannot act on application in different state (Cross-State)', async () => {
      await seedDoc('applications', 'app_jh_flow', {
        userId: 'student_2',
        schemeId: 'post_matric_st',
        institutionId: 'INST_002',
        state: 'JH',
        status: 'InstituteVerified',
      });

      const db = getStateOfficerContext('OD').firestore();
      await assertFails(
        db.collection('applications').doc('app_jh_flow').update({
          status: 'StateApproved',
          reviewedBy: 'state_off_1',
        })
      );
    });

    it('ALLOW: Ministry Officer transitions StateApproved -> Sanctioned', async () => {
      await seedDoc('applications', 'app_min_flow', {
        userId: 'student_1',
        schemeId: 'top_class_st',
        state: 'OD',
        status: 'StateApproved',
      });

      const db = getMinistryOfficerContext().firestore();
      await assertSucceeds(
        db.collection('applications').doc('app_min_flow').update({
          status: 'Sanctioned',
          remarks: 'Sanction order released.',
          reviewedBy: 'ministry_off_1',
          reviewedAt: new Date().toISOString(),
        })
      );
    });

    it('DENY: Ministry Officer cannot jump directly from Draft to Sanctioned', async () => {
      await seedDoc('applications', 'app_min_illegal', {
        userId: 'student_1',
        schemeId: 'top_class_st',
        state: 'OD',
        status: 'Draft',
      });

      const db = getMinistryOfficerContext().firestore();
      await assertFails(
        db.collection('applications').doc('app_min_illegal').update({
          status: 'Sanctioned',
          reviewedBy: 'ministry_off_1',
        })
      );
    });
  });

  // ===========================================================================
  // 2. DISBURSEMENTS COLLECTION TESTS (PFMS / DBT ZERO CLIENT WRITES)
  // ===========================================================================
  describe('2. Disbursements Zero-Client-Write Lockdown', () => {
    it('DENY: Student cannot write disbursement record', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('disbursements').doc('disb_1').set({
          userId: 'student_1',
          amount: 25000,
          status: 'SUCCESS',
        })
      );
    });

    it('DENY: Institution Verifier cannot write disbursement record', async () => {
      const db = getInstVerifierContext('INST_001').firestore();
      await assertFails(
        db.collection('disbursements').doc('disb_2').set({
          userId: 'student_1',
          amount: 25000,
          status: 'SUCCESS',
        })
      );
    });

    it('DENY: State Officer cannot write disbursement record (Zero Client Writes)', async () => {
      const db = getStateOfficerContext('OD').firestore();
      await assertFails(
        db.collection('disbursements').doc('disb_3').set({
          userId: 'student_1',
          amount: 25000,
          status: 'SUCCESS',
        })
      );
    });

    it('ALLOW: Student can read own disbursement', async () => {
      await seedDoc('disbursements', 'disb_own', {
        userId: 'student_1',
        amount: 25000,
        status: 'SUCCESS',
        state: 'OD',
      });

      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('disbursements').doc('disb_own').get()
      );
    });

    it('DENY: Student cannot read another student disbursement', async () => {
      await seedDoc('disbursements', 'disb_other', {
        userId: 'student_2',
        amount: 30000,
        status: 'SUCCESS',
        state: 'OD',
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('disbursements').doc('disb_other').get()
      );
    });

    it('DENY: State officer cannot read disbursement in another state', async () => {
      await seedDoc('disbursements', 'disb_jh', {
        userId: 'student_jh',
        amount: 30000,
        status: 'SUCCESS',
        state: 'JH',
      });

      const db = getStateOfficerContext('OD').firestore();
      await assertFails(
        db.collection('disbursements').doc('disb_jh').get()
      );
    });
  });

  // ===========================================================================
  // 3. DOCUMENTS COLLECTION TESTS
  // ===========================================================================
  describe('3. Documents Vault Security', () => {
    it('ALLOW: Student creates document with PENDING status', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('documents').doc('doc_caste').set({
          userId: 'student_1',
          type: 'CASTE_CERTIFICATE',
          verificationStatus: 'PENDING',
          fileUrl: 'https://storage/caste.pdf',
        })
      );
    });

    it('DENY: Student creates document with VERIFIED status (Self-Verification Attack)', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('documents').doc('doc_spoofed').set({
          userId: 'student_1',
          type: 'CASTE_CERTIFICATE',
          verificationStatus: 'VERIFIED',
          verifiedBy: 'student_1',
        })
      );
    });

    it('DENY: Student updates verificationStatus to VERIFIED', async () => {
      await seedDoc('documents', 'doc_pending', {
        userId: 'student_1',
        type: 'INCOME_CERTIFICATE',
        verificationStatus: 'PENDING',
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('documents').doc('doc_pending').update({
          verificationStatus: 'VERIFIED',
        })
      );
    });

    it('ALLOW: Scoped Verifier updates document verificationStatus', async () => {
      await seedDoc('documents', 'doc_to_verify', {
        userId: 'student_1',
        type: 'INCOME_CERTIFICATE',
        institutionId: 'INST_001',
        state: 'OD',
        verificationStatus: 'PENDING',
      });

      const db = getInstVerifierContext('INST_001').firestore();
      await assertSucceeds(
        db.collection('documents').doc('doc_to_verify').update({
          verificationStatus: 'VERIFIED',
          verifiedBy: 'verifier_1',
          verifiedAt: new Date().toISOString(),
          verifierRemarks: 'Match found on State e-District portal.',
        })
      );
    });

    it('DENY: Verifier cannot alter document fileUrl (Integrity)', async () => {
      await seedDoc('documents', 'doc_tamper_check', {
        userId: 'student_1',
        type: 'INCOME_CERTIFICATE',
        institutionId: 'INST_001',
        fileUrl: 'https://storage/orig.pdf',
        verificationStatus: 'PENDING',
      });

      const db = getInstVerifierContext('INST_001').firestore();
      await assertFails(
        db.collection('documents').doc('doc_tamper_check').update({
          fileUrl: 'https://storage/tampered.pdf',
        })
      );
    });

    it('DENY: Student deletes verified or linked document', async () => {
      await seedDoc('documents', 'doc_linked', {
        userId: 'student_1',
        type: 'CASTE_CERTIFICATE',
        verificationStatus: 'VERIFIED',
        isLinked: true,
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('documents').doc('doc_linked').delete()
      );
    });
  });

  // ===========================================================================
  // 4. DEFICIENCIES COLLECTION TESTS
  // ===========================================================================
  describe('4. Deficiencies Lifecycle & Scope', () => {
    it('DENY: Student cannot create deficiency', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('deficiencies').doc('def_1').set({
          userId: 'student_1',
          description: 'Fake deficiency',
        })
      );
    });

    it('ALLOW: Scoped Officer creates deficiency for student', async () => {
      const db = getInstVerifierContext('INST_001').firestore();
      await assertSucceeds(
        db.collection('deficiencies').doc('def_real').set({
          userId: 'student_1',
          applicationId: 'app_1',
          institutionId: 'INST_001',
          state: 'OD',
          status: 'OPEN',
          description: 'Income certificate is blurred. Upload valid document.',
          createdAt: new Date().toISOString(),
        })
      );
    });

    it('ALLOW: Student replies to deficiency with response text and attachment', async () => {
      await seedDoc('deficiencies', 'def_open', {
        userId: 'student_1',
        applicationId: 'app_1',
        status: 'OPEN',
        description: 'Income certificate is blurred.',
      });

      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('deficiencies').doc('def_open').update({
          studentResponse: 'Uploaded clear copy of income certificate.',
          responseAttachments: ['https://storage/clean_income.pdf'],
          respondedAt: new Date().toISOString(),
        })
      );
    });

    it('DENY: Student cannot close or resolve deficiency', async () => {
      await seedDoc('deficiencies', 'def_attempt_resolve', {
        userId: 'student_1',
        applicationId: 'app_1',
        status: 'OPEN',
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('deficiencies').doc('def_attempt_resolve').update({
          status: 'RESOLVED',
        })
      );
    });
  });

  // ===========================================================================
  // 5. USERS COLLECTION & SUBCOLLECTIONS
  // ===========================================================================
  describe('5. Users Collection & Subcollection Protection', () => {
    it('DENY: Student creates user doc claiming role: admin', async () => {
      const db = getStudentContext('student_new').firestore();
      await assertFails(
        db.collection('users').doc('student_new').set({
          name: 'Student New',
          role: 'admin',
        })
      );
    });

    it('DENY: Student updates protected field stCategory or isVerified', async () => {
      await seedDoc('users', 'student_1', {
        name: 'Birsa Munda',
        stCategory: 'ST',
        isVerified: false,
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('users').doc('student_1').update({
          isVerified: true,
        })
      );
    });

    it('ALLOW: Student writes to allowed subcollection (devices/consents)', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('users').doc('student_1').collection('devices').doc('dev_1').set({
          fcmToken: 'token_abc',
          platform: 'android',
        })
      );
    });

    it('DENY: Student writes to arbitrary wildcard subcollection', async () => {
      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('users').doc('student_1').collection('privileged_internal').doc('hack').set({
          hacked: true,
        })
      );
    });
  });

  // ===========================================================================
  // 6. NOTIFICATIONS COLLECTION
  // ===========================================================================
  describe('6. Notifications Integrity', () => {
    it('ALLOW: Student marks notification as read', async () => {
      await seedDoc('notifications', 'notif_1', {
        userId: 'student_1',
        title: 'Application Status',
        body: 'Your application is verified.',
        isRead: false,
      });

      const db = getStudentContext('student_1').firestore();
      await assertSucceeds(
        db.collection('notifications').doc('notif_1').update({
          isRead: true,
        })
      );
    });

    it('DENY: Student modifies notification title or body', async () => {
      await seedDoc('notifications', 'notif_2', {
        userId: 'student_1',
        title: 'Application Returned',
        body: 'Deficiency found.',
        isRead: false,
      });

      const db = getStudentContext('student_1').firestore();
      await assertFails(
        db.collection('notifications').doc('notif_2').update({
          body: 'Application Sanctioned 100000 rupees',
        })
      );
    });
  });
});
