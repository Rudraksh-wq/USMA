import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/coverage_gap/domain/coverage_gap_matching_service.dart';

void main() {
  group('CoverageGapMatchingService & Privacy Suppression Tests', () {
    const service = CoverageGapMatchingService();

    test('pseudonymiseId creates deterministic, non-reversible SHA-256 HMAC hash', () {
      final h1 = service.pseudonymiseId('APAAR_2026_987654321');
      final h2 = service.pseudonymiseId('APAAR_2026_987654321');
      final h3 = service.pseudonymiseId('APAAR_2026_111111111');

      expect(h1, equals(h2));
      expect(h1, isNot(equals(h3)));
      expect(h1.length, 64); // 32 bytes hex encoded = 64 chars
    });

    test('calculates coverage metric and percentage accurately', () {
      final metric = service.calculateDistrictGap(
        state: 'Odisha',
        district: 'Mayurbhanj',
        totalEnrolledST: 1000,
        scholarshipBeneficiaries: 750,
      );

      expect(metric.uncoveredGap, 250);
      expect(metric.coveragePercentage, 75.0);
      expect(metric.isSuppressed, isFalse);
    });

    test('small-cell suppression triggers for counts < 10', () {
      expect(CoverageGapMatchingService.shouldSuppress(0), isFalse);
      expect(CoverageGapMatchingService.shouldSuppress(4), isTrue);
      expect(CoverageGapMatchingService.shouldSuppress(9), isTrue);
      expect(CoverageGapMatchingService.shouldSuppress(10), isFalse);
      expect(CoverageGapMatchingService.shouldSuppress(150), isFalse);
    });

    test('formatCellCount displays suppression tag for small cells to prevent re-identification', () {
      expect(CoverageGapMatchingService.formatCellCount(0), '0');
      expect(CoverageGapMatchingService.formatCellCount(7), contains('< 10'));
      expect(CoverageGapMatchingService.formatCellCount(120), '120');
    });
  });
}
