/// DPDP (Digital Personal Data Protection Act 2023) Compliance Guard.
/// Enforces Section 9 obligations regarding children (individuals < 18 years).
class DpdpGuard {
  /// Determines if a student is a minor (< 18 years of age).
  static bool isMinor(DateTime dob, {DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age < 18;
  }

  /// Evaluates whether analytics tracking is permitted under Section 9 of DPDP Act.
  /// Strictly prohibits tracking, behavioral monitoring, or profiling of children.
  static bool isAnalyticsPermittedForStudent({
    required DateTime? dob,
    required bool hasParentalConsent,
  }) {
    if (dob == null) return false;
    final minor = isMinor(dob);
    if (minor) {
      // Under DPDP Act Section 9, behavioral tracking/analytics of children is prohibited.
      return false;
    }
    return true;
  }

  /// Verifies if application submission requires verified guardian consent.
  static bool requiresGuardianConsent(DateTime? dob) {
    if (dob == null) return true; // Default safe
    return isMinor(dob);
  }
}
