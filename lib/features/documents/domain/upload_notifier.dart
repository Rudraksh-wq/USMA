// ============================================================
// USMA — Upload Progress Notifier
// upload_notifier.dart
//
// Riverpod state machine for the document upload flow:
//   idle → inProgress → done | failed
//
// Retry is supported: call upload() again with the same args.
// ============================================================

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../data/documents_repository.dart';
import 'models/document_model.dart';
import 'upload_service.dart';

// ─── State ────────────────────────────────────────────────────
sealed class UploadState {}

class UploadIdle extends UploadState {
  UploadIdle();
}

class UploadInProgress extends UploadState {
  /// 0.0 → 1.0; for demo/mock this jumps to 1.0 after a short delay.
  final double progress;
  UploadInProgress(this.progress);
}

class UploadDone extends UploadState {
  final DocumentModel document;
  final bool isSimulated;
  UploadDone(this.document, {required this.isSimulated});
}

class UploadFailed extends UploadState {
  final String reason;
  UploadFailed(this.reason);
}

// ─── Notifier ─────────────────────────────────────────────────
class UploadNotifier extends Notifier<UploadState> {
  @override
  UploadState build() => UploadIdle();

  Future<void> upload({
    required Uint8List bytes,
    required String extension,
    required String title,
    required String type,
    required String userId,
  }) async {
    state = UploadInProgress(0.0);

    final repo = ref.read(documentsRepositoryProvider);
    const service = DocumentUploadService();

    // Validate first (sync) before showing any progress
    final validationError = service.validateFile(bytes, extension);
    if (validationError != null) {
      state = UploadFailed(validationError.reason);
      return;
    }

    // Simulate progress tick for demo mode UX
    if (AppConfig.isDemo) {
      state = UploadInProgress(0.3);
      await Future.delayed(const Duration(milliseconds: 300));
      state = UploadInProgress(0.7);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    state = UploadInProgress(0.9);

    final result = await service.upload(
      bytes: bytes,
      extension: extension,
      title: title,
      type: type,
      userId: userId,
      repo: repo,
      isDemo: AppConfig.isDemo,
    );

    if (result is UploadSuccess) {
      state = UploadDone(result.document, isSimulated: AppConfig.isDemo);
    } else if (result is UploadFailure) {
      state = UploadFailed(result.reason);
    }
  }

  void reset() => state = UploadIdle();
}

// ─── Provider ─────────────────────────────────────────────────
final uploadNotifierProvider =
    NotifierProvider<UploadNotifier, UploadState>(UploadNotifier.new);
