// ============================================================
// USMA — Document Upload Service
// upload_service.dart
//
// Pure Dart — no Flutter / Firebase dependency.
// Responsibilities:
//   1. Validate file (size <= 2 MB, extension in allowlist)
//   2. Compute SHA-256 hex digest of raw bytes
//   3. Build a DocumentModel and call repo.uploadDocument()
//
// The SIMULATED / Live split is determined by which
// IDocumentsRepository implementation is injected (Mock vs Live).
// ============================================================

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../data/documents_repository.dart';
import 'models/document_model.dart';

// ─── Result types ─────────────────────────────────────────────
sealed class UploadResult {}

class UploadSuccess extends UploadResult {
  final DocumentModel document;
  UploadSuccess(this.document);
}

class UploadFailure extends UploadResult {
  final String reason;
  UploadFailure(this.reason);
}

// ─── Service ──────────────────────────────────────────────────
class DocumentUploadService {
  const DocumentUploadService();

  // ── Validation ──────────────────────────────────────────────
  /// Returns an [UploadFailure] if the file violates any constraint,
  /// or null if the file is acceptable.
  UploadFailure? validateFile(Uint8List bytes, String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (!AppConstants.allowedExtensions.contains(ext)) {
      return UploadFailure(
        'Only PDF, JPG, PNG files are accepted. '
        'Please pick a supported file type.',
      );
    }
    if (bytes.length > AppConstants.maxFileSizeBytes) {
      final sizeMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      return UploadFailure(
        'File is $sizeMb MB. Maximum allowed size is 2 MB. '
        'Please compress or crop the file and try again.',
      );
    }
    return null;
  }

  // ── SHA-256 ─────────────────────────────────────────────────
  /// Returns the lowercase SHA-256 hex digest of [bytes].
  /// Used for client-side integrity checking — not encryption.
  String sha256Hex(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ── Upload ──────────────────────────────────────────────────
  /// Validates, hashes, builds a [DocumentModel], then persists
  /// via [repo.uploadDocument]. Returns [UploadSuccess] or
  /// [UploadFailure] — never throws.
  Future<UploadResult> upload({
    required Uint8List bytes,
    required String extension,
    required String title,
    required String type,
    required String userId,
    required IDocumentsRepository repo,
    bool isDemo = false,
  }) async {
    // 1. Validate
    final validationError = validateFile(bytes, extension);
    if (validationError != null) return validationError;

    // 2. SHA-256
    final hash = sha256Hex(bytes);

    // 3. Build model
    final docId = const Uuid().v4();
    final ext = extension.toLowerCase().replaceAll('.', '');
    final storagePath = isDemo
        ? 'simulated://documents/$userId/$docId.$ext'
        : 'users/$userId/documents/$docId.$ext';

    final document = DocumentModel(
      id: docId,
      userId: userId,
      title: title,
      type: type,
      source: 'MANUAL_UPLOAD',
      // In demo mode the mock repo stores in-memory; fileUrl is a placeholder.
      // In live mode the repo replaces this with the Firebase Storage download URL.
      fileUrl: isDemo
          ? 'simulated://wallet/${type.toLowerCase()}/$docId'
          : '', // live repo fills this after Storage upload
      verificationStatus: 'PENDING',
      issuedDate: DateTime.now(),
      uploadedAt: DateTime.now(),
      sizeBytes: bytes.length,
      sha256: hash,
      storagePath: storagePath,
    );

    // 4. Persist
    try {
      final saved = await repo.uploadDocument(document, fileBytes: bytes);
      return UploadSuccess(saved);
    } catch (e) {
      return UploadFailure('Upload failed: ${e.toString()}');
    }
  }
}
