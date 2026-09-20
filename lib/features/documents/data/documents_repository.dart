import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failures.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/models/document_model.dart';

abstract class IDocumentsRepository {
  Future<List<DocumentModel>> getDocuments(String userId);
  /// [fileBytes] is required for live Storage uploads; mock ignores it.
  Future<DocumentModel> uploadDocument(DocumentModel document, {Uint8List? fileBytes});
  Future<void> syncDigiLocker(String userId);
}

List<DocumentModel> _simulatedWallet(String userId) {
  final now = DateTime.now();
  return [
    DocumentModel(
      id: 'doc_aadhaar_01',
      userId: userId,
      title: 'Aadhaar Card',
      type: 'AADHAAR',
      source: 'DIGILOCKER',
      fileUrl: 'simulated://wallet/aadhaar',
      uri: 'in.gov.uidai:aadhaar:XXXXXXXX4829',
      verificationStatus: 'VERIFIED',
      issuedDate: DateTime(2021, 5, 12),
      uploadedAt: now.subtract(const Duration(days: 90)),
      sizeBytes: 420000,
    ),
    DocumentModel(
      id: 'doc_caste_02',
      userId: userId,
      title: 'Scheduled Tribe (ST) Certificate',
      type: 'CASTE_CERTIFICATE',
      source: 'DIGILOCKER',
      fileUrl: 'simulated://wallet/st-certificate',
      uri: 'in.gov.edistrict:caste:ST-2022-8819',
      verificationStatus: 'VERIFIED',
      issuedDate: DateTime(2022, 7, 19),
      uploadedAt: now.subtract(const Duration(days: 85)),
      sizeBytes: 512000,
    ),
    DocumentModel(
      id: 'doc_income_03',
      userId: userId,
      title: 'Annual Income Certificate',
      type: 'INCOME_CERTIFICATE',
      source: 'STATE_EDISTRICT',
      fileUrl: 'simulated://wallet/income',
      uri: 'in.gov.edistrict:income:INC-2025-9921',
      verificationStatus: 'VERIFIED',
      issuedDate: DateTime(2025, 4, 10),
      uploadedAt: now.subtract(const Duration(days: 30)),
      sizeBytes: 380000,
    ),
  ];
}

class MockDocumentsRepository implements IDocumentsRepository {
  final Map<String, List<DocumentModel>> _byUser = {};

  List<DocumentModel> _ensure(String userId) {
    return _byUser.putIfAbsent(userId, () => _simulatedWallet(userId));
  }

  @override
  Future<List<DocumentModel>> getDocuments(String userId) async {
    if (userId.isEmpty) throw const AuthFailure('Sign in to open the document wallet.');
    return List.unmodifiable(_ensure(userId));
  }

  @override
  Future<DocumentModel> uploadDocument(DocumentModel document, {Uint8List? fileBytes}) async {
    // Demo mode: ignore fileBytes, store in-memory.
    _ensure(document.userId).insert(0, document);
    return document;
  }

  @override
  Future<void> syncDigiLocker(String userId) async {
    // SIMULATED DigiLocker pull — no government endpoint is called.
    _ensure(userId);
  }
}

class LiveDocumentsRepository implements IDocumentsRepository {
  LiveDocumentsRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<List<DocumentModel>> getDocuments(String userId) async {
    if (userId.isEmpty) throw const AuthFailure('Sign in to open the document wallet.');
    try {
      final snap = await _firestore
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .get();
      return snap.docs
          .map((d) => DocumentModel.fromMap(d.data(), d.id))
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<DocumentModel> uploadDocument(DocumentModel document, {Uint8List? fileBytes}) async {
    try {
      DocumentModel finalDoc = document;

      if (fileBytes != null && document.storagePath != null) {
        // Upload bytes to Firebase Storage
        final ref = _storage.ref(document.storagePath!);
        final metadata = SettableMetadata(
          contentType: _mimeFromPath(document.storagePath!),
          customMetadata: {
            'userId': document.userId,
            'documentType': document.type,
            if (document.sha256 != null) 'sha256': document.sha256!,
          },
        );
        final task = await ref.putData(fileBytes, metadata);
        final downloadUrl = await task.ref.getDownloadURL();

        // Rebuild model with real download URL
        finalDoc = DocumentModel(
          id: document.id,
          userId: document.userId,
          title: document.title,
          type: document.type,
          source: document.source,
          fileUrl: downloadUrl,
          uri: document.uri,
          verificationStatus: document.verificationStatus,
          issuedDate: document.issuedDate,
          uploadedAt: document.uploadedAt,
          sizeBytes: document.sizeBytes,
          sha256: document.sha256,
          storagePath: document.storagePath,
        );
      }

      await _firestore
          .collection('documents')
          .doc(finalDoc.id)
          .set(finalDoc.toMap());
      return finalDoc;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// Derives a MIME type from the Storage path extension.
  String _mimeFromPath(String path) {
    if (path.endsWith('.pdf')) return 'application/pdf';
    if (path.endsWith('.png')) return 'image/png';
    return 'image/jpeg'; // jpg / jpeg
  }

  @override
  Future<void> syncDigiLocker(String userId) async {
    throw const IntegrationFailure(
      'DigiLocker sync must run through the USMA backend. This app does not call government endpoints.',
    );
  }
}

/// Firebase Storage singleton — parallel to [firestoreProvider] in auth_repository.dart.
final storageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

final documentsRepositoryProvider = Provider<IDocumentsRepository>((ref) {
  if (AppConfig.isDemo) return MockDocumentsRepository();
  return LiveDocumentsRepository(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
  );
});

final userDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw const AuthFailure('Sign in to open the document wallet.');
  return ref.watch(documentsRepositoryProvider).getDocuments(user.id);
});
