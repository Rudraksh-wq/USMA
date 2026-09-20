import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../domain/eligibility_result.dart';
import 'eligibility_provider.dart';

class EligibilityScreen extends ConsumerWidget {
  const EligibilityScreen({super.key});

  static const List<String> educationLevels = [
    'Pre-Matric',
    'Post-Matric',
    'Higher Education',
    'Research',
    'Overseas',
  ];

  static const List<String> institutionTypes = [
    'PREMIER_NOTIFIED',
    'REGULAR_RECOGNIZED',
    'FOREIGN_QS500',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);
    final evaluations = ref.watch(eligibilityEvaluationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoTA Dynamic Eligibility Engine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Official Scheme Eligibility Check',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Evaluates against official Ministry of Tribal Affairs (MoTA) statutory norms across Pre-Matric, Post-Matric, Top Class, NFST, and NOS.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),

            // Profile Criteria Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Candidate Profile & Enrolment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Social Category
                    const Text('Social Category', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    DropdownButtonFormField<String>(
                      initialValue: profile.socialCategory ?? 'ST',
                      items: const [
                        DropdownMenuItem(value: 'ST', child: Text('Scheduled Tribe (ST)')),
                        DropdownMenuItem(value: 'PVTG', child: Text('Particularly Vulnerable Tribal Group (PVTG)')),
                        DropdownMenuItem(value: 'SC', child: Text('Scheduled Caste (SC) — Other Ministry')),
                        DropdownMenuItem(value: 'GEN', child: Text('General / Unreserved')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(studentProfileProvider.notifier).updateSocialCategory(val);
                        }
                      },
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Education Level
                    const Text('Education Level', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    DropdownButtonFormField<String>(
                      initialValue: profile.educationLevel ?? 'Post-Matric',
                      items: const [
                        DropdownMenuItem(value: 'Pre-Matric', child: Text('Pre-Matric (Class IX & X)')),
                        DropdownMenuItem(value: 'Post-Matric', child: Text('Post-Matric (Class XI - Degree)')),
                        DropdownMenuItem(value: 'Higher Education', child: Text('Higher Education (Premier Institutes)')),
                        DropdownMenuItem(value: 'Research', child: Text('Research (M.Phil & Ph.D)')),
                        DropdownMenuItem(value: 'Overseas', child: Text('Overseas Studies (Top 500 QS)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(studentProfileProvider.notifier).updateEducationLevel(val);
                        }
                      },
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Institution Type
                    const Text('Institution Type', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    DropdownButtonFormField<String>(
                      initialValue: profile.institutionType ?? 'PREMIER_NOTIFIED',
                      items: const [
                        DropdownMenuItem(value: 'PREMIER_NOTIFIED', child: Text('265 MoTA Notified Premier Institute')),
                        DropdownMenuItem(value: 'REGULAR_RECOGNIZED', child: Text('Regular Recognized School / College')),
                        DropdownMenuItem(value: 'FOREIGN_QS500', child: Text('Foreign University (Top 500 QS)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(studentProfileProvider.notifier).updateInstitutionType(val);
                        }
                      },
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Family Income Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Annual Family Income', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(
                          '₹${(profile.familyAnnualIncome ?? 200000.0).toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: profile.familyAnnualIncome ?? 200000.0,
                      min: 50000,
                      max: 1000000,
                      divisions: 19,
                      activeColor: AppColors.primary,
                      label: '₹${(profile.familyAnnualIncome ?? 200000.0).toStringAsFixed(0)}',
                      onChanged: (val) {
                        ref.read(studentProfileProvider.notifier).updateIncome(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Evaluations Header
            const Text(
              'Scheme Evaluation Results',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (evaluations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...evaluations.map((eval) => _SchemeEvaluationCard(evaluation: eval)),
          ],
        ),
      ),
    );
  }
}

class _SchemeEvaluationCard extends StatelessWidget {
  final SchemeEligibilityEvaluation evaluation;

  const _SchemeEvaluationCard({required this.evaluation});

  Color _getStatusColor() {
    switch (evaluation.status) {
      case EligibilityStatus.eligible:
        return AppColors.success;
      case EligibilityStatus.conditionallyEligible:
        return AppColors.warning;
      case EligibilityStatus.ineligible:
        return AppColors.error;
      case EligibilityStatus.needsInfo:
      case EligibilityStatus.incompleteProfile:
        return AppColors.info;
      case EligibilityStatus.blockedByExistingAward:
        return Colors.deepOrange;
    }
  }

  IconData _getStatusIcon() {
    switch (evaluation.status) {
      case EligibilityStatus.eligible:
        return Icons.check_circle;
      case EligibilityStatus.conditionallyEligible:
        return Icons.pending_actions;
      case EligibilityStatus.ineligible:
        return Icons.cancel;
      case EligibilityStatus.needsInfo:
      case EligibilityStatus.incompleteProfile:
        return Icons.help_outline;
      case EligibilityStatus.blockedByExistingAward:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_getStatusIcon(), color: statusColor, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evaluation.schemeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          evaluation.statusBadgeText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rule score display: rulesSatisfied / rulesTotal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    evaluation.ruleScoreText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Blocked State Explanation Banner
            if (evaluation.status == EligibilityStatus.blockedByExistingAward) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.deepOrange, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'One-Scholarship-at-a-Time Rule',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evaluation.conflictExplanation ?? evaluation.recommendation,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // "What's Missing" Checklist
            if (evaluation.missingProfileFields.isNotEmpty || evaluation.missingDocuments.isNotEmpty) ...[
              const Text(
                "What's Missing Checklist:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.warning),
              ),
              const SizedBox(height: 4),
              ...evaluation.missingProfileFields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Profile field: $f', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              ...evaluation.missingDocuments.map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Document: $doc', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Failed Criteria
            if (evaluation.failedCriteria.isNotEmpty && evaluation.status != EligibilityStatus.blockedByExistingAward) ...[
              const Text(
                'Ineligible Reasons:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error),
              ),
              const SizedBox(height: 4),
              ...evaluation.failedCriteria.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (evaluation.isEligible)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('Apply Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      context.push(AppRoutes.applySchemePath(evaluation.schemeId));
                    },
                  )
                else if (evaluation.missingDocuments.isNotEmpty)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Upload Documents'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () {
                      context.push(AppRoutes.documents);
                    },
                  )
                else
                  Text(
                    evaluation.recommendation,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
