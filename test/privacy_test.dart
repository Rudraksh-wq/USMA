import 'package:flutter_test/flutter_test.dart';
import 'package:usma/core/privacy/dpdp_guard.dart';
import 'package:usma/core/privacy/pii_redactor.dart';

void main() {
  group('PiiRedactor Tests', () {
    test('masks 12-digit Aadhaar numbers', () {
      const raw = 'Student Aadhaar is 1234 5678 9012 for verification';
      final masked = PiiRedactor.maskAadhaar(raw);
      expect(masked, contains('XXXX-XXXX-9012'));
      expect(masked.contains('1234 5678'), isFalse);
    });

    test('masks 10-digit Indian phone numbers', () {
      const raw = 'Contact candidate at 9876543210 immediately';
      final masked = PiiRedactor.maskPhone(raw);
      expect(masked, contains('XXXXXX3210'));
      expect(masked.contains('987654'), isFalse);
    });

    test('masks bank account numbers', () {
      const raw = 'DBT credited to account 123456789012 successfully';
      final masked = PiiRedactor.maskBankAccount(raw);
      expect(masked, contains('XXXXXX9012'));
    });

    test('redactLogMessage handles combined multi-PII log strings', () {
      const log = 'User phone: 9876543210, Aadhaar: 123456789012, Bank: 998877665544';
      final cleaned = PiiRedactor.redactLogMessage(log);
      expect(cleaned, contains('XXXXXX3210'));
      expect(cleaned, contains('XXXX-XXXX-9012'));
      expect(cleaned, contains('XXXXXX5544'));
    });
  });

  group('DpdpGuard Minor Protection Tests', () {
    test('correctly identifies minor under 18', () {
      final now = DateTime(2026, 9, 20);
      final minorDob = DateTime(2010, 5, 15); // 16 years old
      final adultDob = DateTime(2004, 1, 10); // 22 years old

      expect(DpdpGuard.isMinor(minorDob, referenceDate: now), isTrue);
      expect(DpdpGuard.isMinor(adultDob, referenceDate: now), isFalse);
    });

    test('prohibits analytics tracking for minors under Section 9 of DPDP', () {
      final minorDob = DateTime(2012, 1, 1);
      final adultDob = DateTime(2002, 1, 1);

      expect(
        DpdpGuard.isAnalyticsPermittedForStudent(dob: minorDob, hasParentalConsent: true),
        isFalse,
      );
      expect(
        DpdpGuard.isAnalyticsPermittedForStudent(dob: adultDob, hasParentalConsent: false),
        isTrue,
      );
    });

    test('requires guardian consent for minor applicants', () {
      final minorDob = DateTime(2011, 8, 20);
      final adultDob = DateTime(2003, 3, 14);

      expect(DpdpGuard.requiresGuardianConsent(minorDob), isTrue);
      expect(DpdpGuard.requiresGuardianConsent(adultDob), isFalse);
    });
  });
}
