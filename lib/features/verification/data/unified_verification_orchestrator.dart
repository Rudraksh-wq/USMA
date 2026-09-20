// ============================================================
// USMA — Unified Verification Orchestrator  (CANONICAL)
// unified_verification_orchestrator.dart
//
// This is the single, authoritative verification pipeline.
// The old integration_orchestrator.dart and
// verification_gateways.dart have been retired in favour of
// this file.
//
// Mock/Live split:
//   AppConfig.useLiveVerification == false (default)
//     → MockUnifiedVerificationOrchestrator (SIMULATED data)
//   AppConfig.useLiveVerification == true
//     → LiveUnifiedVerificationOrchestrator (throws
//       UnimplementedError — prevents accidental calls to real
//       government endpoints during development/testing)
//
// Mismatch policy  : never auto-reject → manualReview
// Unavailable policy: retry × 2, 800 ms back-off → manualReview
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/integration_provider.dart' show GovernmentSystem;
import '../domain/models/unified_verification_models.dart';

abstract class IUnifiedVerificationOrchestrator {
  Future<List<VerificationResult>> runUnifiedVerification(String userId);
  Future<ExtractedDocumentIntel> extractAndVerifyDocument({
    required String documentType,
    required String fileUrl,
    required Map<String, String> studentProfile,
  });
  Future<void> submitForManualReview(VerificationType type, String reason);
}

class MockUnifiedVerificationOrchestrator implements IUnifiedVerificationOrchestrator {
  @override
  Future<List<VerificationResult>> runUnifiedVerification(String userId) async {
    final now = DateTime.now();
    return [
      VerificationResult(
        verificationType: VerificationType.identity,
        sourceSystem: 'UIDAI Aadhaar Gateway (Mock API)',
        status: VerificationStatus.verified,
        confidence: 0.99,
        verifiedAt: now.subtract(const Duration(days: 30)),
        requiresManualReview: false,
      ),
      VerificationResult(
        verificationType: VerificationType.stCertificate,
        sourceSystem: 'State e-District Portal (Mock API)',
        status: VerificationStatus.verified,
        confidence: 0.98,
        verifiedAt: now.subtract(const Duration(days: 25)),
        requiresManualReview: false,
      ),
      VerificationResult(
        verificationType: VerificationType.incomeCertificate,
        sourceSystem: 'State Revenue Department (Mock API)',
        status: VerificationStatus.manualReview,
        confidence: 0.72,
        verifiedAt: now.subtract(const Duration(days: 2)),
        requiresManualReview: true,
        mismatchFields: const [
          MismatchField(
            fieldName: 'Applicant / Parent Name Spelling',
            declaredValue: 'Sunita Marandi',
            certificateValue: 'Sunita M.',
            reason: 'Partial abbreviation mismatch between application profile and revenue record.',
          ),
        ],
        errorMessage: 'Name variance detected. Routed to manual verification officer.',
      ),
      VerificationResult(
        verificationType: VerificationType.academicRecord,
        sourceSystem: 'DigiLocker CBSE / State Board (Mock API)',
        status: VerificationStatus.verified,
        confidence: 0.96,
        verifiedAt: now.subtract(const Duration(days: 20)),
        requiresManualReview: false,
      ),
      VerificationResult(
        verificationType: VerificationType.institution,
        sourceSystem: 'AISHE / UDISE+ Registry (Mock API)',
        status: VerificationStatus.verified,
        confidence: 0.95,
        verifiedAt: now.subtract(const Duration(days: 15)),
        requiresManualReview: false,
      ),
      VerificationResult(
        verificationType: VerificationType.bankAccount,
        sourceSystem: 'PFMS / NPCI Aadhaar Mapper (Mock API)',
        status: VerificationStatus.pending,
        confidence: 0.80,
        verifiedAt: now,
        requiresManualReview: false,
        errorMessage: 'Awaiting daily batch settlement confirmation from NPCI mapper.',
      ),
    ];
  }

  @override
  Future<ExtractedDocumentIntel> extractAndVerifyDocument({
    required String documentType,
    required String fileUrl,
    required Map<String, String> studentProfile,
  }) async {
    if (documentType.toUpperCase().contains('INCOME')) {
      return const ExtractedDocumentIntel(
        documentType: 'INCOME_CERTIFICATE',
        extractedFields: {
          'Name': 'Sunita M.',
          'Annual Income': '₹1,80,000',
          'Issuing Authority': 'Tehsildar, Baripada',
          'Validity': '2026-2027',
        },
        mismatches: [
          MismatchField(
            fieldName: 'Name',
            declaredValue: 'Sunita Marandi',
            certificateValue: 'Sunita M.',
            reason: 'Initial vs expanded surname variance.',
          ),
        ],
        confidence: 0.88,
        isVerified: false,
      );
    }

    return const ExtractedDocumentIntel(
      documentType: 'CASTE_CERTIFICATE',
      extractedFields: {
        'Name': 'Sunita Marandi',
        'Tribe': 'Santhal (Scheduled Tribe)',
        'Certificate No': 'ST-2022-8819',
        'State': 'Odisha',
      },
      mismatches: [],
      confidence: 0.98,
      isVerified: true,
    );
  }

  @override
  Future<void> submitForManualReview(VerificationType type, String reason) async {
    // Simulated submission to District Nodal Officer workflow
  }
}

// ─────────────────────────────────────────────────────────────
// Live path — intentionally unimplemented.
// Throws UnimplementedError to prevent accidental calls to real
// government endpoints until production credentials & contracts
// are in place.  Swap each method body for a real HTTP adapter
// when the integration is officially ready.
// ─────────────────────────────────────────────────────────────
class LiveUnifiedVerificationOrchestrator
    implements IUnifiedVerificationOrchestrator {
  @override
  Future<List<VerificationResult>> runUnifiedVerification(String userId) =>
      throw UnimplementedError(
        'LiveUnifiedVerificationOrchestrator.runUnifiedVerification '
        'is not yet implemented. '
        'Real government API calls (UIDAI, DigiLocker, AISHE, UDISE+, '
        'APAAR, State e-District, UGC-NTA) require production credentials '
        'and MoTA/NIC approval before being enabled.',
      );

  @override
  Future<ExtractedDocumentIntel> extractAndVerifyDocument({
    required String documentType,
    required String fileUrl,
    required Map<String, String> studentProfile,
  }) =>
      throw UnimplementedError(
        'LiveUnifiedVerificationOrchestrator.extractAndVerifyDocument '
        'is not yet implemented.',
      );

  @override
  Future<void> submitForManualReview(VerificationType type, String reason) =>
      throw UnimplementedError(
        'LiveUnifiedVerificationOrchestrator.submitForManualReview '
        'is not yet implemented.',
      );
}

// ─────────────────────────────────────────────────────────────
// Riverpod providers
// ─────────────────────────────────────────────────────────────
final unifiedVerificationOrchestratorProvider =
    Provider<IUnifiedVerificationOrchestrator>((ref) {
  // Toggle to LiveUnifiedVerificationOrchestrator() when production
  // credentials & government API contracts are provisioned.
  return MockUnifiedVerificationOrchestrator();
});

final unifiedVerificationListProvider =
    FutureProvider<List<VerificationResult>>((ref) async {
  return ref
      .watch(unifiedVerificationOrchestratorProvider)
      .runUnifiedVerification('demo_user_001');
});

// ─────────────────────────────────────────────────────────────
// Integration system connectivity snapshot
// (migrated from the retired integration_orchestrator.dart)
//
// Used by IntegrationStatusScreen to show per-system demo status.
// ─────────────────────────────────────────────────────────────
class IntegrationSystemStatus {
  final GovernmentSystem system;
  final bool isConnected;
  final bool isSimulated;
  final String statusLabel;

  const IntegrationSystemStatus({
    required this.system,
    required this.isConnected,
    required this.isSimulated,
    required this.statusLabel,
  });
}

/// Lightweight connectivity snapshot — one entry per government system.
/// All entries are SIMULATED (demo mode). No real network calls are made.
final integrationStatusListProvider =
    FutureProvider<List<IntegrationSystemStatus>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return const [
    IntegrationSystemStatus(
      system: GovernmentSystem.digiLocker,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.udisePlus,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.apaar,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.aishe,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.pfms,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.stateEDistrict,
      isConnected: false,
      isSimulated: true,
      statusLabel: 'Manual Review',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.nsp,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.ugc,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
    IntegrationSystemStatus(
      system: GovernmentSystem.nta,
      isConnected: true,
      isSimulated: true,
      statusLabel: 'Demo Connected',
    ),
  ];
});
