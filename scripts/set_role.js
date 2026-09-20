#!/usr/bin/env node
/**
 * scripts/set_role.js
 * 
 * Firebase Admin SDK script to provision custom claims (role, state, institutionId)
 * for USMA users.
 * 
 * Usage:
 *   node scripts/set_role.js <uid> <role> [state] [institutionId]
 * 
 * Examples:
 *   node scripts/set_role.js user_123 student
 *   node scripts/set_role.js inst_456 institution_verifier OD INST_001
 *   node scripts/set_role.js state_789 state_officer OD
 *   node scripts/set_role.js min_101 ministry_officer
 *   node scripts/set_role.js adm_999 admin
 */

const admin = require('firebase-admin');

// Allowed roles in USMA RBAC
const VALID_ROLES = [
  'student',
  'institution_verifier',
  'state_officer',
  'ministry_officer',
  'admin'
];

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.error('Error: Insufficient arguments.');
    console.log('Usage: node scripts/set_role.js <uid> <role> [state] [institutionId]');
    process.exit(1);
  }

  const [uid, role, state, institutionId] = args;

  if (!VALID_ROLES.includes(role)) {
    console.error(`Error: Invalid role "${role}". Valid roles: ${VALID_ROLES.join(', ')}`);
    process.exit(1);
  }

  // Initialize Firebase Admin SDK
  if (!admin.apps.length) {
    if (process.env.FIREBASE_AUTH_EMULATOR_HOST) {
      console.log(`Using Auth Emulator at ${process.env.FIREBASE_AUTH_EMULATOR_HOST}`);
      admin.initializeApp({ projectId: 'usma-app-demo' });
    } else {
      admin.initializeApp();
    }
  }

  const customClaims = {
    role,
    ...(state ? { state } : {}),
    ...(institutionId ? { institutionId } : {})
  };

  try {
    await admin.auth().setCustomUserClaims(uid, customClaims);
    console.log(`Successfully updated custom claims for UID: ${uid}`);
    console.log('Claims:', JSON.stringify(customClaims, null, 2));

    // Verify written claims
    const userRecord = await admin.auth().getUser(uid);
    console.log('Verified stored claims:', JSON.stringify(userRecord.customClaims, null, 2));
    process.exit(0);
  } catch (error) {
    console.error(`Failed to set custom claims for UID "${uid}":`, error.message);
    process.exit(1);
  }
}

main();
