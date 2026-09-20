import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/documents/data/documents_repository.dart';
import 'package:usma/features/documents/domain/models/document_model.dart';
import 'package:usma/features/documents/domain/upload_service.dart';

void main() {
  group('DocumentUploadService Unit Tests', () {
    const service = DocumentUploadService();

    test('validateFile rejects files exceeding 2 MB limit', () {
      // 2 MB + 1 byte
      final oversizedBytes = Uint8List(2 * 1024 * 1024 + 1);
      final failure = service.validateFile(oversizedBytes, 'pdf');

      expect(failure, isNotNull);
      expect(failure!.reason, contains('Maximum allowed size is 2 MB'));
    });

    test('validateFile rejects disallowed file extensions', () {
      final validBytes = Uint8List(100);
      final failure = service.validateFile(validBytes, 'docx');

      expect(failure, isNotNull);
      expect(failure!.reason, contains('Only PDF, JPG, PNG files are accepted'));
    });

    test('validateFile accepts valid PDF, JPG, and PNG under 2 MB', () {
      final validBytes = Uint8List(1024 * 500); // 500 KB

      expect(service.validateFile(validBytes, 'pdf'), isNull);
      expect(service.validateFile(validBytes, '.jpg'), isNull);
      expect(service.validateFile(validBytes, 'png'), isNull);
    });

    test('sha256Hex produces correct lowercase hex digest', () {
      // Known SHA-256 for 'hello world'
      // echo -n "hello world" | shasum -a 256 -> b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9
      final bytes = Uint8List.fromList('hello world'.codeUnits);
      final hash = service.sha256Hex(bytes);

      expect(hash, equals('b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'));
    });

    test('upload successfully creates DocumentModel and persists to mock repository in demo mode', () async {
      final repo = MockDocumentsRepository();
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = await service.upload(
        bytes: bytes,
        extension: 'pdf',
        title: 'ST Certificate',
        type: 'ST_CERTIFICATE',
        userId: 'student_123',
        repo: repo,
        isDemo: true,
      );

      expect(result, isA<UploadSuccess>());
      final success = result as UploadSuccess;
      expect(success.document.title, equals('ST Certificate'));
      expect(success.document.type, equals('ST_CERTIFICATE'));
      expect(success.document.source, equals('MANUAL_UPLOAD'));
      expect(success.document.verificationStatus, equals('PENDING'));
      expect(success.document.sha256, isNotNull);
      expect(success.document.storagePath, startsWith('simulated://documents/student_123/'));

      // Check repo has the document
      final docs = await repo.getDocuments('student_123');
      expect(docs.any((d) => d.id == success.document.id), isTrue);
    });

    test('upload returns UploadFailure when repository throws exception', () async {
      final repo = _FailingDocumentsRepository();
      final bytes = Uint8List.fromList([1, 2, 3]);

      final result = await service.upload(
        bytes: bytes,
        extension: 'png',
        title: 'Income Certificate',
        type: 'INCOME',
        userId: 'student_123',
        repo: repo,
        isDemo: true,
      );

      expect(result, isA<UploadFailure>());
      final failure = result as UploadFailure;
      expect(failure.reason, contains('Upload failed: Exception: Storage error'));
    });
  });
}

class _FailingDocumentsRepository implements IDocumentsRepository {
  @override
  Future<List<DocumentModel>> getDocuments(String userId) async => [];

  @override
  Future<void> syncDigiLocker(String userId) async {}

  @override
  Future<DocumentModel> uploadDocument(DocumentModel document, {Uint8List? fileBytes}) async {
    throw Exception('Storage error');
  }
}
