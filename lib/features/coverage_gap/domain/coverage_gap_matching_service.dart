import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Pseudonymisation and Small-Cell Suppression Engine for MoTA Coverage Gap Analytics.
class CoverageGapMatchingService {
  final String saltKey;

  const CoverageGapMatchingService({this.saltKey = 'MOTA_SIH26238_SALT_APAAR'});

  /// Pseudonymise an APAAR or Aadhaar identifier using HMAC-SHA256.
  /// Never stores or transmits plaintext identifiers in analytics feeds.
  String pseudonymiseId(String rawIdentifier) {
    final key = utf8.encode(saltKey);
    final bytes = utf8.encode(rawIdentifier.trim().toUpperCase());
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// Evaluates coverage gap between enrolled students and active applicants.
  CoverageMetric calculateDistrictGap({
    required String state,
    required String district,
    required int totalEnrolledST,
    required int scholarshipBeneficiaries,
  }) {
    final rawGap = totalEnrolledST - scholarshipBeneficiaries;
    final gapCount = rawGap < 0 ? 0 : rawGap;
    final percentage = totalEnrolledST > 0
        ? ((scholarshipBeneficiaries / totalEnrolledST) * 100)
        : 0.0;

    return CoverageMetric(
      state: state,
      district: district,
      totalEnrolledST: totalEnrolledST,
      beneficiaries: scholarshipBeneficiaries,
      uncoveredGap: gapCount,
      coveragePercentage: percentage,
      isSuppressed: shouldSuppress(scholarshipBeneficiaries) || shouldSuppress(gapCount),
    );
  }

  /// Small-cell suppression rule: cells with counts < 10 are suppressed or masked
  /// to protect individual ST student identity in sparsely populated habitations.
  static bool shouldSuppress(int count) {
    return count > 0 && count < 10;
  }

  /// Formats cell count honoring privacy suppression rules.
  static String formatCellCount(int count) {
    if (count == 0) return '0';
    if (shouldSuppress(count)) {
      return '< 10 (Suppressed for DPDP Privacy)';
    }
    return count.toString();
  }
}

class CoverageMetric {
  final String state;
  final String district;
  final int totalEnrolledST;
  final int beneficiaries;
  final int uncoveredGap;
  final double coveragePercentage;
  final bool isSuppressed;

  const CoverageMetric({
    required this.state,
    required this.district,
    required this.totalEnrolledST,
    required this.beneficiaries,
    required this.uncoveredGap,
    required this.coveragePercentage,
    required this.isSuppressed,
  });
}
