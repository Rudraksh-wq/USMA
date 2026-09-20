/// Consent record for DigiLocker data access.
class DigiLockerConsent {
  final String userId;
  final DateTime grantedAt;
  final List<String> grantedScopes;
  final String purpose;

  const DigiLockerConsent({
    required this.userId,
    required this.grantedAt,
    required this.grantedScopes,
    required this.purpose,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'grantedAt': grantedAt.toIso8601String(),
        'grantedScopes': grantedScopes,
        'purpose': purpose,
      };

  factory DigiLockerConsent.fromMap(Map<String, dynamic> m) =>
      DigiLockerConsent(
        userId: m['userId'] ?? '',
        grantedAt: DateTime.tryParse(m['grantedAt'] ?? '') ?? DateTime.now(),
        grantedScopes: List<String>.from(m['grantedScopes'] ?? []),
        purpose: m['purpose'] ?? '',
      );

  static const String scholarshipPurpose =
      'To fetch government-issued documents (caste certificate, income '
      'certificate, marksheets, Aadhaar) for verifying eligibility under '
      'Ministry of Tribal Affairs scholarship schemes (Pre-Matric, '
      'Post-Matric, Top Class, NFST, NOS). Your documents are never stored '
      'without your consent and are only shared with authorised government '
      'officials for verification.';

  static const List<String> requiredScopes = [
    'openid',
    'files.issueddoc.read',
    'files.issueddoc.download',
  ];
}
