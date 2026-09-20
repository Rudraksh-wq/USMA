import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../auth/data/auth_repository.dart';
import '../data/schemes_repository.dart';
import '../data/applications_repository.dart';
import '../domain/models/application_model.dart';
import '../domain/scholarship_uniqueness.dart';

class ApplyScreen extends ConsumerStatefulWidget {
  final String schemeId;

  const ApplyScreen({super.key, required this.schemeId});

  @override
  ConsumerState<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends ConsumerState<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instituteController = TextEditingController(text: 'National Institute of Technology, Rourkela');
  final _courseController = TextEditingController(text: 'B.Tech Computer Science (Year 3)');
  final _academicYearController = TextEditingController(text: '2026-2027');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _instituteController.dispose();
    _courseController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication(String schemeTitle, double maxAmount) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? 'demo_user_001';

      // 1. Fetch user's existing applications via repository / provider
      final repo = ref.read(applicationsRepositoryProvider);
      final existingApps = await repo.getApplications(userId);

      // 2. Uniqueness pre-check
      const uniqueness = ScholarshipUniqueness();
      final conflict = uniqueness.conflictIfApplying(
        existing: existingApps,
        userId: userId,
      );

      if (conflict != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Application Blocked',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Text(
                conflict.message,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Dismiss'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go(AppRoutes.applications);
                  },
                  child: const Text('View Active Application'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final appId = 'APP-2026-ST-${(1000 + DateTime.now().millisecond % 9000)}';

      final newApp = ApplicationModel(
        id: appId,
        userId: userId,
        schemeId: widget.schemeId,
        schemeTitle: schemeTitle,
        academicYear: _academicYearController.text.trim(),
        instituteName: _instituteController.text.trim(),
        courseName: _courseController.text.trim(),
        sanctionedAmount: maxAmount,
        status: 'SUBMITTED',
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timeline: [
          TimelineEvent(
            title: 'Application Submitted',
            description: 'Application successfully pre-verified with DigiLocker documents.',
            timestamp: DateTime.now(),
            isCompleted: true,
          ),
          TimelineEvent(
            title: 'Institute Verification (AISHE)',
            description: 'Sent to Nodal Officer for academic verification.',
            timestamp: DateTime.now().add(const Duration(days: 3)),
            isCompleted: false,
          ),
        ],
      );

      await repo.submitApplication(newApp);

      ref.invalidate(userApplicationsProvider);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Application Submitted!'),
              ],
            ),
            content: Text('Your application reference ID is $appId. You will receive SMS & push notifications as status updates occur.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppRoutes.applications);
                },
                child: const Text('Track Application'),
              ),
            ],
          ),
        );
      }
    } on ConflictFailure catch (conflict) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Application Blocked',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              conflict.message,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Dismiss'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppRoutes.applications);
                },
                child: const Text('View Active Application'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final schemeAsync = ref.watch(schemeDetailProvider(widget.schemeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholarship Application'),
      ),
      body: schemeAsync.when(
        data: (scheme) {
          final title = scheme?.title ?? 'MoTA ST Scholarship';
          final amount = scheme?.maxAmount ?? 85000.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text('Pre-filled Beneficiary Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: AppSpacing.xs),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          _buildProfileRow('Full Name', user?.name ?? 'Sunita Marandi'),
                          _buildProfileRow('Aadhaar Number', 'XXXX-XXXX-${user?.aadhaarLast4 ?? "4829"} (Verified)'),
                          _buildProfileRow('ST Community', user?.tribe ?? 'Santhal'),
                          _buildProfileRow('State & District', '${user?.state ?? "Odisha"}, ${user?.district ?? "Mayurbhanj"}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text('Academic Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Institution Name (AISHE Registered)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _instituteController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter institution name' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Course Name & Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _courseController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.book_rounded),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter course name' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Academic Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _academicYearController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: AppColors.success),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'DigiLocker documents (ST Caste Certificate & Income Certificate) attached automatically.',
                            style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitApplication(title, amount),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Submit Application with DigiLocker'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Error loading scheme details'),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
