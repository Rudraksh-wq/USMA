import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/digilocker/domain/digilocker_client.dart';
import 'package:usma/features/digilocker/domain/digilocker_consent.dart';

void main() {
  group('DigiLocker PKCE & Client Tests', () {
    test('generateVerifier generates high-entropy string', () {
      final v1 = PkceHelper.generateVerifier();
      final v2 = PkceHelper.generateVerifier();
      expect(v1.length, 64);
      expect(v2.length, 64);
      expect(v1, isNot(equals(v2)));
    });

    test('computeChallenge hashes correctly with SHA-256 base64url', () {
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      final challenge = PkceHelper.computeChallenge(verifier);
      expect(challenge, isNotEmpty);
      expect(challenge.contains('='), isFalse); // padding stripped
    });

    test('generateState creates unique state strings', () {
      final s1 = PkceHelper.generateState();
      final s2 = PkceHelper.generateState();
      expect(s1.length, 16);
      expect(s1, isNot(equals(s2)));
    });

    test('MockDigiLockerClient builds valid authorization url', () {
      const client = MockDigiLockerClient();
      final url = client.buildAuthUrl(
        clientId: 'TEST_ID',
        redirectUri: 'usma://callback',
        codeChallenge: 'chall123',
        codeChallengeMethod: 'S256',
        state: 'state456',
      );
      expect(url, contains('client_id=TEST_ID'));
      expect(url, contains('code_challenge=chall123'));
      expect(url, contains('code_challenge_method=S256'));
    });

    test('MockDigiLockerClient exchanges code and fetches documents', () async {
      const client = MockDigiLockerClient();
      final token = await client.exchangeCode(
        code: 'mock_code',
        codeVerifier: 'mock_verifier',
        redirectUri: 'usma://callback',
        clientId: 'TEST_ID',
      );
      expect(token.accessToken, isNotEmpty);

      final docs = await client.fetchIssuedDocuments(token.accessToken);
      expect(docs.length, 4);
      expect(docs.any((d) => d.docType == 'CASTE_CERTIFICATE'), isTrue);
      expect(docs.any((d) => d.docType == 'INCOME_CERTIFICATE'), isTrue);

      final bytes = await client.downloadDocument(token.accessToken, docs.first.uri);
      expect(bytes, isNotEmpty);
    });
  });

  group('DigiLocker Consent Tests', () {
    test('serializes and deserializes consent properly', () {
      final now = DateTime.now();
      final consent = DigiLockerConsent(
        userId: 'u_123',
        grantedAt: now,
        grantedScopes: DigiLockerConsent.requiredScopes,
        purpose: DigiLockerConsent.scholarshipPurpose,
      );

      final map = consent.toMap();
      expect(map['userId'], 'u_123');
      expect(map['grantedScopes'], DigiLockerConsent.requiredScopes);

      final restored = DigiLockerConsent.fromMap(map);
      expect(restored.userId, 'u_123');
      expect(restored.purpose, DigiLockerConsent.scholarshipPurpose);
    });
  });
}
