import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../domain/models/unified_verification_models.dart';
import 'verification_chip.dart';

class ManualReviewItem {
  final String reviewId;
  final String applicationId;
  final String studentName;
  final String schemeName;
  final String sourceSystem;
  final String documentOrFieldType;
  final List<MismatchField> diffs;
  final String status; // 'PENDING_REVIEW', 'APPROVED', 'OVERRIDDEN', 'REJECTED'
  final DateTime createdAt;
  final String? resolutionReason;

  const ManualReviewItem({
    required this.reviewId,
    required this.applicationId,
    required this.studentName,
    required this.schemeName,
    required this.sourceSystem,
    required this.documentOrFieldType,
    required this.diffs,
    required this.status,
    required this.createdAt,
    this.resolutionReason,
  });

  ManualReviewItem copyWith({String? status, String? resolutionReason}) {
    return ManualReviewItem(
      reviewId: reviewId,
      applicationId: applicationId,
      studentName: studentName,
      schemeName: schemeName,
      sourceSystem: sourceSystem,
      documentOrFieldType: documentOrFieldType,
      diffs: diffs,
      status: status ?? this.status,
      createdAt: createdAt,
      resolutionReason: resolutionReason ?? this.resolutionReason,
    );
  }
}

class ManualReviewNotifier extends StateNotifier<List<ManualReviewItem>> {
  ManualReviewNotifier()
      : super([
          ManualReviewItem(
            reviewId: 'rev_001',
            applicationId: 'app_pre_matric_101',
            studentName: 'Birsa Munda',
            schemeName: 'Pre-Matric Scholarship for ST Students',
            sourceSystem: 'UIDAI Aadhaar Verification',
            documentOrFieldType: 'AADHAAR_DEMOGRAPHIC',
            diffs: const [
              MismatchField(
                fieldName: 'Full Name',
                declaredValue: 'Birsa Munda',
                certificateValue: 'Birsa Kumar Munda',
                reason: 'Demographic abbreviation match (Middle name variation).',
              ),
            ],
            status: 'PENDING_REVIEW',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          ManualReviewItem(
            reviewId: 'rev_002',
            applicationId: 'app_post_matric_202',
            studentName: 'Sunita Hembram',
            schemeName: 'Post-Matric Scholarship for ST Students',
            sourceSystem: 'State e-District (Odisha)',
            documentOrFieldType: 'INCOME_CERTIFICATE',
            diffs: const [
              MismatchField(
                fieldName: 'Annual Family Income',
                declaredValue: '₹1,80,000',
                certificateValue: '₹2,10,000',
                reason: 'Minor variance between application self-declaration and tehsildar assessment (both within ₹2.50L ceiling).',
              ),
            ],
            status: 'PENDING_REVIEW',
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          ManualReviewItem(
            reviewId: 'rev_003',
            applicationId: 'app_top_class_303',
            studentName: 'Mangal Soren',
            schemeName: 'Top Class Education for ST Students',
            sourceSystem: 'AISHE Gateway',
            documentOrFieldType: 'INSTITUTION_AISHE',
            diffs: const [
              MismatchField(
                fieldName: 'Campus Code',
                declaredValue: 'IIT-BBS-MAIN',
                certificateValue: 'AISHE-U-0355',
                reason: 'Sub-campus code mismatch; requires officer verification against premier list.',
              ),
            ],
            status: 'PENDING_REVIEW',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);

  void resolveReview(String reviewId, String decision, String reason) {
    state = state.map((item) {
      if (item.reviewId == reviewId) {
        return item.copyWith(status: decision, resolutionReason: reason);
      }
      return item;
    }).toList();
  }
}

final manualReviewsProvider =
    StateNotifierProvider<ManualReviewNotifier, List<ManualReviewItem>>(
        (ref) => ManualReviewNotifier());

class ManualReviewQueueScreen extends ConsumerStatefulWidget {
  const ManualReviewQueueScreen({super.key});

  @override
  ConsumerState<ManualReviewQueueScreen> createState() =>
      _ManualReviewQueueScreenState();
}

class _ManualReviewQueueScreenState
    extends ConsumerState<ManualReviewQueueScreen> {
  String _filter = 'ALL';

  void _showResolutionDialog(ManualReviewItem item, String action) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Review: ${item.studentName}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Action: $action Verification for ${item.documentOrFieldType}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Under MoTA audit rules, all manual approvals or overrides require a mandatory justification statement.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Reason / Audit Remarks *',
                  hintText: 'e.g. Verified physical certificate with Tehsildar seal; middle name abbreviation confirmed.',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Please enter a justification of at least 5 characters.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'REJECT' ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                ref
                    .read(manualReviewsProvider.notifier)
                    .resolveReview(item.reviewId, action, reasonController.text.trim());
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Case ${item.reviewId} $action with audit trail.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text('Confirm $action'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allReviews = ref.watch(manualReviewsProvider);
    final reviews = _filter == 'ALL'
        ? allReviews
        : allReviews.where((r) => r.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Verification Review Queue'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            color: AppColors.background,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Reviews'),
                    selected: _filter == 'ALL',
                    onSelected: (s) => setState(() => _filter = 'ALL'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Pending Action'),
                    selected: _filter == 'PENDING_REVIEW',
                    onSelected: (s) => setState(() => _filter = 'PENDING_REVIEW'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Approved'),
                    selected: _filter == 'APPROVED',
                    onSelected: (s) => setState(() => _filter = 'APPROVED'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Overridden'),
                    selected: _filter == 'OVERRIDDEN',
                    onSelected: (s) => setState(() => _filter = 'OVERRIDDEN'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Queue List
          Expanded(
            child: reviews.isEmpty
                ? const Center(
                    child: Text('No manual reviews matching filter.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: reviews.length,
                    itemBuilder: (context, idx) {
                      final item = reviews[idx];
                      final isPending = item.status == 'PENDING_REVIEW';

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isPending
                                ? Colors.deepOrange.withValues(alpha: 0.4)
                                : AppColors.border,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.studentName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  VerificationChip(
                                    status: isPending
                                        ? VerificationStatus.mismatch
                                        : VerificationStatus.verified,
                                    label: item.status,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.schemeName} • App ID: ${item.applicationId}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Source System
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Source: ${item.sourceSystem}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Discrepancy Diff Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: Colors.deepOrange.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Detected Discrepancies:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange),
                                    ),
                                    const SizedBox(height: 4),
                                    ...item.diffs.map((d) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Field: ${d.fieldName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                              Text('• Declared: "${d.declaredValue}"', style: const TextStyle(fontSize: 11)),
                                              Text('• Source System: "${d.certificateValue}"', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                                              Text('• Note: ${d.reason}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),

                              if (item.resolutionReason != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Officer Remark: "${item.resolutionReason}"',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ],

                              if (isPending) ...[
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Approve'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.success,
                                        side: const BorderSide(color: AppColors.success),
                                      ),
                                      onPressed: () => _showResolutionDialog(item, 'APPROVED'),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.rule, size: 16),
                                      label: const Text('Override'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => _showResolutionDialog(item, 'OVERRIDDEN'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
