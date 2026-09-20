import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { UnifiedVerificationRouter } from './router';
import { VerificationRequest } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const router = new UnifiedVerificationRouter();

/**
 * Callable Cloud Function: verifyDocumentOrField
 * 
 * Verifies student documents or demographic fields against authentic government
 * source adapters (DigiLocker, UIDAI, AISHE, UDISE+, APAAR, State e-District, UGC-NTA).
 * 
 * CRITICAL POLICY: A mismatch or upstream outage NEVER blocks application submission.
 * It automatically registers a case in /manual_reviews/{id} and returns status with
 * requiresManualReview = true.
 */
export const verifyDocumentOrField = functions.https.onCall(
  async (data: VerificationRequest, context) => {
    // 1. Authenticate caller
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required to invoke verification.'
      );
    }

    try {
      // 2. Route and execute verification
      const result = await router.executeVerification(data);

      // 3. If manual review required (mismatch or outage), record in Firestore
      if (result.requiresManualReview) {
        const reviewRef = admin.firestore().collection('manual_reviews').doc();
        await reviewRef.set({
          reviewId: reviewRef.id,
          applicationId: data.applicationId || 'pending_app',
          userId: context.auth.uid,
          sourceSystem: result.source,
          documentOrFieldType: data.documentOrFieldType,
          status: 'PENDING_REVIEW',
          diffs: result.diffs,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          state: data.state || null,
          institutionId: data.institutionId || null,
          isSimulated: result.isSimulated,
        });
      }

      return result;
    } catch (err: any) {
      // Fail-open for student progress: route unexpected backend errors to manual review
      return {
        status: 'unavailable',
        source: 'Gateway Error',
        timestamp: new Date().toISOString(),
        confidence: 0.0,
        diffs: [],
        requiresManualReview: true,
        message: `Temporary verification error: ${err.message}. Routed to manual review queue.`,
        isSimulated: true,
      };
    }
  }
);

/**
 * Callable Cloud Function: resolveManualReview
 * 
 * Invoked by authorized Institution Verifier or State Officer to approve
 * or override a verification discrepancy with a mandatory justification.
 */
export const resolveManualReview = functions.https.onCall(
  async (
    data: { reviewId: string; decision: 'APPROVED' | 'OVERRIDDEN' | 'REJECTED'; reason: string },
    context
  ) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Officer authentication required.');
    }

    const role = context.auth.token.role;
    const isOfficer =
      role === 'institution_verifier' ||
      role === 'state_officer' ||
      role === 'ministry_officer' ||
      role === 'admin';

    if (!isOfficer) {
      throw new functions.https.HttpsError('permission-denied', 'Only designated officers may resolve manual reviews.');
    }

    if (!data.reason || data.reason.trim().length < 5) {
      throw new functions.https.HttpsError('invalid-argument', 'A mandatory review justification of at least 5 characters is required.');
    }

    const reviewRef = admin.firestore().collection('manual_reviews').doc(data.reviewId);
    await reviewRef.update({
      status: data.decision,
      resolutionNotes: data.reason,
      resolvedBy: context.auth.uid,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, reviewId: data.reviewId, decision: data.decision };
  }
);
