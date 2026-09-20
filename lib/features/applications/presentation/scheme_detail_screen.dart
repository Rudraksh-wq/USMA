import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/data/auth_repository.dart';
import '../data/applications_repository.dart';
import '../data/schemes_repository.dart';
import '../domain/scholarship_uniqueness.dart';

class SchemeDetailScreen extends ConsumerWidget {
  final String schemeId;

  const SchemeDetailScreen({super.key, required this.schemeId});

  Future<void> _launchUrl(String urlStr) async {
    final uri = Uri.tryParse(urlStr);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motaSchemeAsync = ref.watch(motaSchemeDetailProvider(schemeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Details'),
      ),
      body: motaSchemeAsync.when(
        data: (scheme) {
          if (scheme == null) {
            return const Center(child: Text('Scheme not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Text(
                              'Source: Ministry of Tribal Affairs',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          Text(
                            scheme.shortName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        scheme.schemeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _buildDetailBadge(
                            icon: Icons.currency_rupee_rounded,
                            label: 'Income Limit',
                            value: scheme.incomeLimit.formattedLimit,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _buildDetailBadge(
                            icon: Icons.school_outlined,
                            label: 'Level',
                            value: scheme.targetEducationLevel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Description
                const Text(
                  'About the Scheme',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  scheme.description,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Who Can Apply
                const Text(
                  'Target Beneficiaries',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    scheme.whoCanApply,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Eligibility Criteria
                const Text(
                  'Eligibility Criteria',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final criterion in scheme.eligibilityCriteria)
                  _buildCriterionItem(criterion),
                const SizedBox(height: AppSpacing.xl),

                // Benefits & Financial Rates
                const Text(
                  'Scholarship Benefits & Allowances',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildBenefitItem('Maintenance Allowance', scheme.scholarshipBenefits.maintenanceAllowance),
                _buildBenefitItem('Fee Coverage', scheme.scholarshipBenefits.feeCoverage),
                if (scheme.scholarshipBenefits.otherAllowances.isNotEmpty)
                  _buildBenefitItem('Other Allowances', scheme.scholarshipBenefits.otherAllowances),
                _buildBenefitItem('Funding Pattern', scheme.scholarshipBenefits.fundSharingRatio),
                const SizedBox(height: AppSpacing.xl),

                // Verification Pipeline
                if (scheme.verificationStages.isNotEmpty) ...[
                  const Text(
                    'Multi-Level Verification Pipeline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final stage in scheme.verificationStages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primary,
                            child: Text('${stage.order}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stage.stageName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Text('Authority: ${stage.authority} • SLA: ${stage.slaDays} days', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                const SizedBox(height: 2),
                                Text(stage.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Required Documents
                const Text(
                  'Required Documents (DigiLocker / Manual)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final doc in scheme.requiredDocuments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(doc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),

                // Application Route & External Portal
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.open_in_new, color: AppColors.info, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Official Portal: ${scheme.applicationPortal.portalName}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.info),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheme.applicationPortal.routingInstructions,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Grievance Information
                const Text(
                  'Grievance & Support Cell',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Division: ${scheme.grievanceInformation.division}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Email: ${scheme.grievanceInformation.nodalEmail}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Helpline: ${scheme.grievanceInformation.helplineNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xxl),

                ElevatedButton.icon(
                  onPressed: () async {
                    final user = ref.read(currentUserProvider);
                    final userId = user?.id ?? 'demo_user_001';
                    final repo = ref.read(applicationsRepositoryProvider);
                    final existingApps = await repo.getApplications(userId);

                    const uniqueness = ScholarshipUniqueness();
                    final conflict = uniqueness.conflictIfApplying(
                      existing: existingApps,
                      userId: userId,
                    );

                    if (conflict != null) {
                      if (context.mounted) {
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

                    if (context.mounted) {
                      context.push(AppRoutes.applySchemePath(scheme.schemeId));
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Apply Now (e-Verification)'),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => _launchUrl(scheme.applicationPortal.portalUrl),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Visit Official Government Portal'),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => AppErrorView(message: err.toString()),
      ),
    );
  }

  Widget _buildDetailBadge({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildCriterionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
