import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../data/documents_repository.dart';
import '../domain/upload_notifier.dart';
import '../domain/upload_service.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  void _openUploadSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _UploadDocumentSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(userDocumentsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync DigiLocker',
            onPressed: () async {
              final uid = user?.id ?? 'demo_user_001';
              await ref.read(documentsRepositoryProvider).syncDigiLocker(uid);
              ref.invalidate(userDocumentsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('DigiLocker documents synced successfully!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('upload_document_fab'),
        onPressed: () => _openUploadSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload Document'),
      ),
      body: Column(
        children: [
          if (AppConfig.isDemo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${AppConfig.simulatedLabel}: Document uploads stored in secure mock wallet.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Government-verified documents via DigiLocker and uploaded certificates are stored here.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: docsAsync.when(
              data: (docs) {
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'No documents found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap "Upload Document" below or sync with DigiLocker.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 88),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, idx) {
                    final doc = docs[idx];
                    final isDigiLocker = doc.source == 'DIGILOCKER';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isDigiLocker ? AppColors.successBg : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              isDigiLocker ? Icons.verified_user_outlined : Icons.description_outlined,
                              color: isDigiLocker ? AppColors.success : AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Issued: ${doc.issuedDate.day}/${doc.issuedDate.month}/${doc.issuedDate.year} • ${doc.source}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                if (doc.sha256 != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'SHA-256: ${doc.sha256!.substring(0, 10)}...',
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textTertiary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(status: doc.verificationStatus, isSmall: true),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingIndicator(message: 'Loading documents...'),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDocumentSheet extends ConsumerStatefulWidget {
  const _UploadDocumentSheet();

  @override
  ConsumerState<_UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<_UploadDocumentSheet> {
  String _selectedType = AppConstants.documentTypes.first;
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  String? _selectedExtension;
  String? _validationError;

  final DocumentUploadService _service = const DocumentUploadService();

  void _validateAndSetFile(Uint8List bytes, String filename) {
    final ext = filename.contains('.') ? filename.split('.').last : '';
    final err = _service.validateFile(bytes, ext);

    setState(() {
      if (err != null) {
        _validationError = err.reason;
        _selectedBytes = null;
        _selectedFileName = null;
        _selectedExtension = null;
      } else {
        _validationError = null;
        _selectedBytes = bytes;
        _selectedFileName = filename;
        _selectedExtension = ext;
      }
    });
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          _validateAndSetFile(file.bytes!, file.name);
        }
      }
    } catch (e) {
      setState(() => _validationError = 'Failed to pick file: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: source);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        _validateAndSetFile(bytes, photo.name);
      }
    } catch (e) {
      setState(() => _validationError = 'Failed to capture image: $e');
    }
  }

  Future<void> _startUpload() async {
    if (_selectedBytes == null || _selectedExtension == null) return;

    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'demo_user_001';
    final title = AppConstants.documentTypeDisplayNames[_selectedType] ?? _selectedType;

    await ref.read(uploadNotifierProvider.notifier).upload(
      bytes: _selectedBytes!,
      extension: _selectedExtension!,
      title: title,
      type: _selectedType.toUpperCase(),
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadNotifierProvider);

    // Listen for completion
    ref.listen<UploadState>(uploadNotifierProvider, (prev, next) {
      if (next is UploadDone) {
        ref.invalidate(userDocumentsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              next.isSimulated
                  ? 'SIMULATED: Document added to mock wallet (pending verification)'
                  : 'Document uploaded successfully — awaiting verification',
            ),
          ),
        );
      }
    });

    final inProgress = uploadState is UploadInProgress;
    final progressVal = uploadState is UploadInProgress ? uploadState.progress : null;
    final uploadError = uploadState is UploadFailed ? uploadState.reason : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Document',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  if (AppConfig.isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        AppConfig.simulatedLabel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Allowed formats: PDF, JPG, PNG (Max: 2 MB). All files are integrity checked using SHA-256.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),

              // Document Type Selector
              const Text('Document Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: AppConstants.documentTypes.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(AppConstants.documentTypeDisplayNames[t] ?? t),
                  );
                }).toList(),
                onChanged: inProgress
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
              ),
              const SizedBox(height: AppSpacing.lg),

              // File Selection Buttons
              const Text('Select File Source', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('pick_pdf_button'),
                      onPressed: inProgress ? null : _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Pick PDF'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('pick_image_button'),
                      onPressed: inProgress
                          ? null
                          : () {
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt_outlined),
                                        title: const Text('Camera'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.camera);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library_outlined),
                                        title: const Text('Gallery'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.gallery);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Selected file preview / card
              if (_selectedFileName != null && _selectedBytes != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedBytes!.length / 1024).toStringAsFixed(1)} KB • SHA-256 verified',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!inProgress)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedBytes = null;
                              _selectedFileName = null;
                              _selectedExtension = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),

              // Validation error banner
              if (_validationError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(color: AppColors.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Upload error banner with retry
              if (uploadError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              uploadError,
                              style: const TextStyle(color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: inProgress ? null : _startUpload,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry Upload'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Progress Indicator
              if (inProgress) ...[
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(value: progressVal),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Uploading & computing SHA-256 integrity hash (${((progressVal ?? 0) * 100).toInt()}%)...',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Upload button
              ElevatedButton.icon(
                key: const Key('submit_upload_button'),
                onPressed: (inProgress || _selectedBytes == null || _validationError != null)
                    ? null
                    : _startUpload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Upload Document'),
              ),
            ],
          ),
        );
      },
    );
  }
}
