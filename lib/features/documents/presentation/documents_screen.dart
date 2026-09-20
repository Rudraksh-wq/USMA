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
        title: const Text('Document Wallet'),
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
                  const SnackBar(content: Text('DigiLocker documents synced successfully!')),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('upload_document_fab'),
        onPressed: () => _openUploadSheet(context),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Document'),
      ),
      body: Column(
        children: [
          if (AppConfig.isDemo)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              color: Colors.purple.shade50,
              child: Row(
                children: [
                  Icon(Icons.science_outlined, color: Colors.purple.shade700, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${AppConfig.simulatedLabel} Document uploads are stored locally in mock wallet.',
                      style: TextStyle(fontSize: 12, color: Colors.purple.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.primary.withOpacity(0.08),
            child: const Row(
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 20),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Government-verified documents via DigiLocker or client-hashed uploads (SHA-256 integrity check) eliminate physical submissions.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: docsAsync.when(
              data: (docs) {
                if (docs.isEmpty) {
                  return const Center(child: Text('No documents found. Tap "Upload Document" to add one.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 80),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, idx) {
                    final doc = docs[idx];
                    final isDigiLocker = doc.source == 'DIGILOCKER';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDigiLocker ? AppColors.infoBg : AppColors.surfaceVariant,
                          child: Icon(
                            isDigiLocker ? Icons.verified_user : Icons.file_present_rounded,
                            color: isDigiLocker ? AppColors.info : AppColors.primary,
                          ),
                        ),
                        title: Text(doc.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Issued: ${doc.issuedDate.day}/${doc.issuedDate.month}/${doc.issuedDate.year} • ${doc.source}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            if (doc.sha256 != null)
                              Text(
                                'SHA-256: ${doc.sha256!.substring(0, 10)}...',
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                        trailing: StatusBadge(status: doc.verificationStatus, isSmall: true),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Document',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (AppConfig.isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Text(
                        AppConfig.simulatedLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Allowed formats: PDF, JPG, PNG (Max: 2 MB). All files are integrity checked using SHA-256.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),

              // Document Type Selector
              const Text('Document Type', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
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
              const Text('Select Source', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('pick_pdf_button'),
                      onPressed: inProgress ? null : _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf),
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
                                        leading: const Icon(Icons.camera_alt),
                                        title: const Text('Camera'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickImage(ImageSource.camera);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library),
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
                      icon: const Icon(Icons.photo_camera),
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedBytes!.length / 1024).toStringAsFixed(1)} KB • Integrity: SHA-256 client verified',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!inProgress)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 12),
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              uploadError,
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: inProgress ? null : _startUpload,
                          icon: const Icon(Icons.refresh, size: 16),
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
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload Document'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
