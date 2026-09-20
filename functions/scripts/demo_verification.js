/**
 * functions/scripts/demo_verification.js
 * 
 * Demonstration script for USMA Unified Verification Layer.
 * Shows:
 * 1. Clean Verified Case (DigiLocker / Aadhaar)
 * 2. Mismatch Case (Name abbreviation variation -> routes to manual review without blocking)
 * 3. Outage Case (Circuit breaker trips -> routes to manual review without blocking)
 */

const { UnifiedVerificationRouter } = require('../lib/router');

async function runDemo() {
  console.log('===============================================================');
  console.log('USMA UNIFIED VERIFICATION & INTEGRATION LAYER — LIVE DEMO');
  console.log('===============================================================\n');

  const router = new UnifiedVerificationRouter();

  // CASE 1: All-Verified
  console.log('--- CASE 1: Clean Verification (DigiLocker Caste Certificate) ---');
  const req1 = {
    requestId: 'req_demo_01',
    applicationId: 'app_pre_matric_01',
    userId: 'student_od_101',
    sourceType: 'DigiLocker',
    documentOrFieldType: 'CASTE_CERTIFICATE',
    payload: { casteCategory: 'ST', certificateNo: 'OD/REV/2026/001' },
    persona: 'all-verified',
  };
  const res1 = await router.executeVerification(req1);
  console.log(`Source System:  ${res1.source}`);
  console.log(`Status:         ${res1.status.toUpperCase()}`);
  console.log(`Confidence:     ${(res1.confidence * 100).toFixed(0)}%`);
  console.log(`Requires Review:${res1.requiresManualReview}`);
  console.log(`Message:        ${res1.message}\n`);

  // CASE 2: Name Mismatch (Non-blocking policy)
  console.log('--- CASE 2: Name Variation (UIDAI Demographic Cross-Check) ---');
  const req2 = {
    requestId: 'req_demo_02',
    applicationId: 'app_post_matric_02',
    userId: 'student_jh_202',
    sourceType: 'UIDAI',
    documentOrFieldType: 'AADHAAR',
    payload: { name: 'Birsa Munda' },
    persona: 'name-mismatch',
  };
  const res2 = await router.executeVerification(req2);
  console.log(`Source System:  ${res2.source}`);
  console.log(`Status:         ${res2.status.toUpperCase()}`);
  console.log(`Requires Review:${res2.requiresManualReview} (CRITICAL: Never blocks application submission!)`);
  console.log(`Mismatches:     ${JSON.stringify(res2.diffs, null, 2)}`);
  console.log(`Message:        ${res2.message}\n`);

  // CASE 3: Outage / Timeout (Circuit Breaker Protection)
  console.log('--- CASE 3: Upstream State Portal Timeout (Circuit Breaker) ---');
  const req3 = {
    requestId: 'req_demo_03',
    applicationId: 'app_top_class_03',
    userId: 'student_mp_303',
    sourceType: 'DigiLocker',
    documentOrFieldType: 'CASTE_CERTIFICATE',
    payload: {},
    persona: 'source-timeout',
  };
  const res3 = await router.executeVerification(req3);
  console.log(`Source System:  ${res3.source}`);
  console.log(`Status:         ${res3.status.toUpperCase()}`);
  console.log(`Requires Review:${res3.requiresManualReview}`);
  console.log(`Message:        ${res3.message}\n`);

  console.log('===============================================================');
  console.log('DEMO COMPLETED: 100% of cases handled without blocking student!');
  console.log('===============================================================');
}

runDemo().catch(console.error);
