// ============================================================
// USMA — Verification Pipeline Tests
// integration_provider_test.dart
//
// Tests:
//   1  DigiLocker mock provider — identity verified
//   2  StateEDistrict mock provider — mismatch -> manual review
//   3  StateEDistrict mock provider — never auto-rejected
//   4  APAAR mock provider — matching APAAR ID verified
//   5  NSP mock provider — returns PENDING during batch sync
//   6  PFMS mock provider — returns PENDING awaiting NPCI
//   7  All 9 mock providers return valid IntegrationResponse
//   8  MockUnifiedVerificationOrchestrator — full pipeline
//   9  Unified pipeline — manualReview result present
//   10 Unified pipeline — never produces status=failed
//   11 Unified pipeline — extractAndVerifyDocument intel
//   12 Unified pipeline — submitForManualReview succeeds
//   13 Unified pipeline — isSimulated always true
//   14 LiveUnifiedVerificationOrchestrator throws UnimplementedError
//   15 VerificationAuditLog — stores entries, no PII values
//   16 VerificationAuditLog — pendingReviews filter
//   17 Duplicate request ID — independent responses per provider
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/verification/domain/integration_provider.dart';
import 'package:usma/features/verification/data/providers/mock_providers.dart';
import 'package:usma/features/verification/data/unified_verification_orchestrator.dart';
import 'package:usma/features/verification/data/verification_audit_log.dart';
import 'package:usma/features/verification/domain/models/unified_verification_models.dart';

IntegrationRequest _req({
  String id = 'req_001',
  String token = 'demo_student_001',
  Map<String, String>? fields,
}) =>
    IntegrationRequest(
      requestId: id,
      studentId: token,
      fieldsToVerify: fields ??
          {
            'name': 'Rahul Kumar',
            'apaarId': 'APAAR-2024-8819',
            'institutionName': 'Govt. College of Engineering',
          },
      createdAt: DateTime(2026, 9, 20),
    );

void main() {
  // 1 DigiLocker mock provider
  group('DigiLocker Mock Provider', () {
    test('returns VERIFIED with all identity fields confirmed', () async {
      final provider = DigiLockerMockProvider();
      expect(provider.system, GovernmentSystem.digiLocker);
      expect(provider.isSimulated, isTrue);
      final response = await provider.verify(_req());
      expect(response.status, IntegrationStatus.verified);
      expect(response.verifiedFields, contains('name'));
      expect(response.verifiedFields, contains('aadhaarLast4'));
      expect(response.mismatchedFields, isEmpty);
      expect(response.requiresManualReview, isFalse);
      expect(response.isSimulated, isTrue);
    });
  });

  // 2+3 StateEDistrict — mismatch -> manual review, never rejected
  group('StateEDistrict Mock Provider', () {
    test('detects name abbreviation mismatch and routes to manual review', () async {
      final provider = StateEDistrictMockProvider();
      final response = await provider.verify(_req(fields: {
        'name': 'Sunita Marandi',
        'stCertificateId': 'ST-2022-8819',
      }));
      expect(response.status, IntegrationStatus.mismatch);
      expect(response.requiresManualReview, isTrue);
      expect(response.mismatchedFields, contains('name'));
      expect(response.status, isNot(IntegrationStatus.failed));
    });

    test('does NOT auto-reject on mismatch', () async {
      final provider = StateEDistrictMockProvider();
      final response = await provider.verify(
          _req(fields: {'name': 'Priya Oraon', 'stCertificateId': 'ST-001'}));
      expect(response.status, isNot(IntegrationStatus.failed));
    });
  });

  // 4 APAAR
  group('APAAR Mock Provider', () {
    test('verifies matching APAAR ID', () async {
      final provider = APAARMockProvider();
      final response =
          await provider.verify(_req(fields: {'apaarId': 'APAAR-2024-0001'}));
      expect(response.status, IntegrationStatus.verified);
    });
  });

  // 5 NSP
  group('NSP Mock Provider', () {
    test('returns PENDING during batch sync', () async {
      final provider = NSPMockProvider();
      final response = await provider.verify(_req());
      expect(response.status, IntegrationStatus.pending);
      expect(response.error, isNotNull);
    });
  });

  // 6 PFMS
  group('PFMS Mock Provider', () {
    test('returns PENDING awaiting NPCI settlement', () async {
      final provider = PFMSMockProvider();
      final response = await provider.verify(_req());
      expect(response.status, IntegrationStatus.pending);
    });
  });

  // 7 All 9 providers
  group('Multiple providers', () {
    test('all 9 providers return valid IntegrationResponse', () async {
      final providers = <IntegrationProvider>[
        DigiLockerMockProvider(),
        UDISEMockProvider(),
        APAARMockProvider(),
        AISHEMockProvider(),
        NSPMockProvider(),
        PFMSMockProvider(),
        StateEDistrictMockProvider(),
        UGCMockProvider(),
        NTAMockProvider(),
      ];
      for (final p in providers) {
        final response = await p.verify(_req());
        expect(response.sourceSystem, p.system);
        expect(response.requestId, isNotEmpty);
        expect(response.timestamp, isNotNull);
        expect(response.isSimulated, isTrue,
            reason: ' must be marked simulated');
      }
    });
  });

  // 8-13 MockUnifiedVerificationOrchestrator
  group('MockUnifiedVerificationOrchestrator', () {
    late MockUnifiedVerificationOrchestrator orchestrator;
    setUp(() => orchestrator = MockUnifiedVerificationOrchestrator());

    test('runUnifiedVerification returns non-empty list', () async {
      final results =
          await orchestrator.runUnifiedVerification('demo_student_001');
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(4));
    });

    test('all results are marked isSimulated = true', () async {
      final results =
          await orchestrator.runUnifiedVerification('demo_student_001');
      for (final r in results) {
        expect(r.isSimulated, isTrue);
      }
    });

    test('at least one result has status = verified', () async {
      final results =
          await orchestrator.runUnifiedVerification('demo_student_001');
      expect(results.any((r) => r.status == VerificationStatus.verified),
          isTrue);
    });

    test('mismatch result has requiresManualReview=true, never failed',
        () async {
      final results =
          await orchestrator.runUnifiedVerification('demo_student_001');
      final manual =
          results.where((r) => r.status == VerificationStatus.manualReview);
      expect(manual, isNotEmpty);
      for (final r in manual) {
        expect(r.requiresManualReview, isTrue);
        expect(r.status, isNot(VerificationStatus.failed));
      }
    });

    test('no result has status = failed (mismatch policy)', () async {
      final results =
          await orchestrator.runUnifiedVerification('demo_student_001');
      for (final r in results) {
        expect(r.status, isNot(VerificationStatus.failed));
      }
    });

    test('extractAndVerifyDocument — income certificate has mismatches',
        () async {
      final intel = await orchestrator.extractAndVerifyDocument(
        documentType: 'INCOME_CERTIFICATE',
        fileUrl: 'https://example.com/income.pdf',
        studentProfile: {'name': 'Sunita Marandi'},
      );
      expect(intel.documentType, 'INCOME_CERTIFICATE');
      expect(intel.confidence, greaterThan(0.5));
      expect(intel.mismatches, isNotEmpty);
      expect(intel.isVerified, isFalse);
    });

    test('extractAndVerifyDocument — caste certificate is clean', () async {
      final intel = await orchestrator.extractAndVerifyDocument(
        documentType: 'CASTE_CERTIFICATE',
        fileUrl: 'https://example.com/caste.pdf',
        studentProfile: {'name': 'Sunita Marandi'},
      );
      expect(intel.isVerified, isTrue);
      expect(intel.mismatches, isEmpty);
      expect(intel.confidence, greaterThan(0.9));
    });

    test('submitForManualReview completes without throwing', () async {
      await expectLater(
        orchestrator.submitForManualReview(
          VerificationType.incomeCertificate,
          'Name abbreviation mismatch detected by automated pipeline.',
        ),
        completes,
      );
    });
  });

  // 14 LiveUnifiedVerificationOrchestrator guard
  group('LiveUnifiedVerificationOrchestrator', () {
    late LiveUnifiedVerificationOrchestrator live;
    setUp(() => live = LiveUnifiedVerificationOrchestrator());

    test('runUnifiedVerification throws UnimplementedError', () {
      expect(() => live.runUnifiedVerification('any'), throwsUnimplementedError);
    });

    test('extractAndVerifyDocument throws UnimplementedError', () {
      expect(
        () => live.extractAndVerifyDocument(
          documentType: 'INCOME',
          fileUrl: 'https://example.com/doc.pdf',
          studentProfile: {},
        ),
        throwsUnimplementedError,
      );
    });

    test('submitForManualReview throws UnimplementedError', () {
      expect(
        () => live.submitForManualReview(VerificationType.identity, 'reason'),
        throwsUnimplementedError,
      );
    });
  });

  // 15+16 Audit log
  group('VerificationAuditLog', () {
    test('stores entries and exposes field names but not PII values', () {
      final log = VerificationAuditLog();
      log.record(VerificationAuditEntry(
        verificationId: 'vrf_001',
        studentToken: 'demo_token',
        source: GovernmentSystem.digiLocker,
        timestamp: DateTime.now(),
        status: IntegrationStatus.verified,
        fieldsChecked: ['name', 'dob', 'aadhaarLast4'],
        mismatchedFieldNames: [],
        reviewRequired: false,
        isSimulated: true,
      ));
      final entries = log.entriesForStudent('demo_token');
      expect(entries.length, 1);
      expect(entries.first.fieldsChecked, contains('name'));
      final map = entries.first.toMap();
      expect(map.containsKey('aadhaarNumber'), isFalse);
      expect(map.containsKey('bankAccount'), isFalse);
    });

    test('pendingReviews filters entries requiring manual review', () {
      final log = VerificationAuditLog();
      log.record(VerificationAuditEntry(
        verificationId: 'vrf_002',
        studentToken: 'demo_token',
        source: GovernmentSystem.stateEDistrict,
        timestamp: DateTime.now(),
        status: IntegrationStatus.mismatch,
        fieldsChecked: ['name'],
        mismatchedFieldNames: ['name'],
        reviewRequired: true,
        isSimulated: true,
      ));
      log.record(VerificationAuditEntry(
        verificationId: 'vrf_003',
        studentToken: 'demo_token',
        source: GovernmentSystem.digiLocker,
        timestamp: DateTime.now(),
        status: IntegrationStatus.verified,
        fieldsChecked: ['name', 'dob'],
        reviewRequired: false,
        isSimulated: true,
      ));
      expect(log.pendingReviews.length, 1);
      expect(log.pendingReviews.first.verificationId, 'vrf_002');
    });
  });

  // 17 Duplicate request ID
  group('Duplicate verification', () {
    test('same requestId produces independent responses per provider', () async {
      const sharedId = 'shared_req_001';
      final r1 = await DigiLockerMockProvider().verify(_req(id: sharedId));
      final r2 = await UDISEMockProvider().verify(_req(id: sharedId));
      expect(r1.sourceSystem, GovernmentSystem.digiLocker);
      expect(r2.sourceSystem, GovernmentSystem.udisePlus);
      expect(r1.requestId, equals(r2.requestId));
    });
  });
}
