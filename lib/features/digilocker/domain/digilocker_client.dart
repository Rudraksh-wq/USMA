// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// DigiLocker OAuth 2.0 PKCE flow interface.
///
/// In production this would call the real DigiLocker API endpoints.
/// In demo/test mode it returns mock data so the app can be demonstrated
/// without network access.
abstract class DigiLockerClient {
  /// Build the authorization URL to open in a browser / WebView.
  String buildAuthUrl({
    required String clientId,
    required String redirectUri,
    required String codeChallenge,
    required String codeChallengeMethod,
    required String state,
  });

  /// Exchange an authorization code for tokens.
  Future<DigiLockerTokenResponse> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  });

  /// Fetch the list of issued documents from DigiLocker for a user.
  Future<List<DigiLockerDocument>> fetchIssuedDocuments(String accessToken);

  /// Download the raw bytes of a specific document.
  Future<Uint8List> downloadDocument(String accessToken, String uri);
}

class DigiLockerTokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String digiLockerId;
  final String name;

  const DigiLockerTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.digiLockerId,
    required this.name,
  });
}

class DigiLockerDocument {
  final String uri;
  final String name;
  final String type;
  final String docType;
  final String issuer;
  final String issuedAt;
  final String? description;

  const DigiLockerDocument({
    required this.uri,
    required this.name,
    required this.type,
    required this.docType,
    required this.issuer,
    required this.issuedAt,
    this.description,
  });

  factory DigiLockerDocument.fromJson(Map<String, dynamic> j) =>
      DigiLockerDocument(
        uri: j['uri'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? '',
        docType: j['docType'] ?? '',
        issuer: j['issuer'] ?? '',
        issuedAt: j['date'] ?? '',
        description: j['description'],
      );
}

// ─── PKCE helpers ────────────────────────────────────────────────────────────

class PkceHelper {
  static String generateVerifier({int length = 64}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }

  static String computeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String generateState({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)])
        .join();
  }
}

// ─── Mock implementation (used in demo mode) ─────────────────────────────────

class MockDigiLockerClient implements DigiLockerClient {
  const MockDigiLockerClient();

  @override
  String buildAuthUrl({
    required String clientId,
    required String redirectUri,
    required String codeChallenge,
    required String codeChallengeMethod,
    required String state,
  }) {
    return 'https://api.digitallocker.gov.in/public/oauth2/1/authorize'
        '?response_type=code'
        '&client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&code_challenge=$codeChallenge'
        '&code_challenge_method=$codeChallengeMethod'
        '&state=$state';
  }

  @override
  Future<DigiLockerTokenResponse> exchangeCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const DigiLockerTokenResponse(
      accessToken: 'MOCK_ACCESS_TOKEN_abc123',
      refreshToken: 'MOCK_REFRESH_TOKEN_def456',
      expiresIn: 3600,
      digiLockerId: 'MOCK_DL_ID_789',
      name: 'Demo ST Student',
    );
  }

  @override
  Future<List<DigiLockerDocument>> fetchIssuedDocuments(
      String accessToken) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const [
      DigiLockerDocument(
        uri: 'in.gov.stgov-CASTCERT-123456',
        name: 'Caste Certificate',
        type: 'CASTCERT',
        docType: 'CASTE_CERTIFICATE',
        issuer: 'State Tribal Welfare Dept.',
        issuedAt: '2024-03-15',
        description: 'ST Category Caste Certificate',
      ),
      DigiLockerDocument(
        uri: 'in.gov.cbse-MARKSHEET-2024-654321',
        name: 'Class XII Marksheet 2024',
        type: 'MARKSHEET',
        docType: 'MARKSHEET',
        issuer: 'Central Board of Secondary Education',
        issuedAt: '2024-06-01',
        description: 'CBSE Class XII Board Marksheet',
      ),
      DigiLockerDocument(
        uri: 'in.gov.uidai-AADHAAR-987654',
        name: 'Aadhaar Card',
        type: 'ADHAR',
        docType: 'AADHAAR',
        issuer: 'UIDAI',
        issuedAt: '2020-01-10',
        description: 'Aadhaar — Unique Identification',
      ),
      DigiLockerDocument(
        uri: 'in.gov.incometax-INCCERT-111222',
        name: 'Income Certificate',
        type: 'INCCERT',
        docType: 'INCOME_CERTIFICATE',
        issuer: 'Revenue Department',
        issuedAt: '2024-04-01',
        description: 'Annual family income certificate',
      ),
    ];
  }

  @override
  Future<Uint8List> downloadDocument(String accessToken, String uri) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Return a minimal mock PDF header
    return Uint8List.fromList(utf8.encode('%PDF-1.4 MOCK DOCUMENT $uri'));
  }
}
