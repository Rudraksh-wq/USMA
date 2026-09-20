import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/data/auth_repository.dart';
import '../../documents/data/documents_repository.dart';
import '../data/schemes_repository.dart';
import '../domain/models/mota_scheme_model.dart';
import '../../eligibility/domain/eligibility_engine.dart';
import '../../eligibility/domain/eligibility_result.dart';

class SchemesScreen extends ConsumerStatefulWidget {
  const SchemesScreen({super.key});

  @override
  ConsumerState<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends ConsumerState<SchemesScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Pre-Matric',
    'Post-Matric',
    'Higher Education',
    'Research',
    'Overseas',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showQuickEligibilitySheet(BuildContext context, MotaSchemeModel scheme, StudentEligibilityProfile profile) {
    final eval = MoTAEligibilityEngine.evaluateScheme(profile: profile, scheme: scheme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheme.schemeName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ministry of Tribal Affairs',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(eval.status),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Evaluation Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (eval.passedCriteria.isNotEmpty) ...[
                for (final p in eval.passedCriteria)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                      ],
                    ),
                  ),
              ],
              if (eval.failedCriteria.isNotEmpty) ...[
                for (final f in eval.failedCriteria)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f, style: const TextStyle(fontSize: 12, color: AppColors.error))),
                      ],
                    ),
                  ),
              ],
              if (eval.missingDocuments.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                          SizedBox(width: 6),
                          Text('Required Documents Needed:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      for (final doc in eval.missingDocuments)
                        Text('• $doc', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(AppRoutes.schemeDetailPath(scheme.schemeId));
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(EligibilityStatus status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case EligibilityStatus.eligible:
        bg = AppColors.successBg;
        text = AppColors.success;
        label = 'Eligible';
        icon = Icons.check_circle_outline_rounded;
        break;
      case EligibilityStatus.conditionallyEligible:
        bg = AppColors.warningBg;
        text = AppColors.warning;
        label = 'Conditional';
        icon = Icons.info_outline_rounded;
        break;
      case EligibilityStatus.ineligible:
        bg = AppColors.errorBg;
        text = AppColors.error;
        label = 'Ineligible';
        icon = Icons.highlight_off_rounded;
        break;
      case EligibilityStatus.incompleteProfile:
      case EligibilityStatus.needsInfo:
        bg = AppColors.surfaceVariant;
        text = AppColors.textSecondary;
        label = 'Check Needed';
        icon = Icons.help_outline_rounded;
        break;
      case EligibilityStatus.blockedByExistingAward:
        bg = AppColors.warningBg;
        text = AppColors.warning;
        label = 'Active Award';
        icon = Icons.block_flipped;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schemesAsync = ref.watch(motaSchemesListProvider);
    final user = ref.watch(currentUserProvider);
    final docs = ref.watch(userDocumentsProvider).asData?.value ?? const [];

    final studentProfile = StudentEligibilityProfile(
      userId: user?.id,
      isScheduledTribe: user?.isScheduledTribe ?? true,
      socialCategory: user?.isScheduledTribe == true ? 'ST' : 'GEN',
      familyAnnualIncome: user?.familyAnnualIncome,
      educationLevel: user?.educationLevel ?? 'Post-Matric',
      currentClassOrDegree: user?.educationLevel,
      institutionType: 'PREMIER_NOTIFIED',
      hasAadhaar: user?.isAadhaarLinked ?? true,
      hasAadhaarSeededBank: user?.bankAccountLast4 != null,
      availableDocumentTypes: docs.map((d) => d.type).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoTA Scholarships'),
      ),
      body: Column(
        children: [
          // Statutory rule educational banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
            color: AppColors.surfaceVariant,
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can receive one government scholarship at a time. All 5 MoTA schemes are listed below.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search scholarships (Pre-Matric, Post-Matric, Top Class)...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.surface : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: schemesAsync.when(
              data: (schemes) {
                final query = _searchController.text.toLowerCase().trim();
                final filtered = schemes.where((s) {
                  final matchesCat = _selectedCategory == 'All' ||
                      s.targetEducationLevels.any((l) => l.toLowerCase().contains(_selectedCategory.toLowerCase())) ||
                      s.targetEducationLevel.toLowerCase().contains(_selectedCategory.toLowerCase());
                  final matchesQuery = query.isEmpty ||
                      s.schemeName.toLowerCase().contains(query) ||
                      s.shortName.toLowerCase().contains(query) ||
                      s.description.toLowerCase().contains(query) ||
                      s.whoCanApply.toLowerCase().contains(query);
                  return matchesCat && matchesQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching scholarship schemes found.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, idx) {
                    final scheme = filtered[idx];
                    final eval = MoTAEligibilityEngine.evaluateScheme(profile: studentProfile, scheme: scheme);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Title and Eligibility Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scheme.schemeName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Ministry of Tribal Affairs',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildStatusChip(eval.status),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Who can apply info
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    scheme.whoCanApply,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Grid specs: Income limit, Education level, Main benefits
                          Row(
                            children: [
                              _buildSpecBox(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Income Limit',
                                value: scheme.incomeLimit.formattedLimit,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildSpecBox(
                                icon: Icons.school_outlined,
                                label: 'Education Level',
                                value: scheme.targetEducationLevel,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              _buildSpecBox(
                                icon: Icons.card_giftcard_outlined,
                                label: 'Main Benefits',
                                value: scheme.scholarshipBenefits.maintenanceAllowance.isNotEmpty
                                    ? 'Stipend + Fee Waiver'
                                    : 'Full Financial Grant',
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildSpecBox(
                                icon: Icons.public_outlined,
                                label: 'Application Route',
                                value: scheme.applicationPortal.portalName,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Actions: Check Eligibility & View Details
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showQuickEligibilitySheet(context, scheme, studentProfile),
                                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                                  label: const Text('Eligibility', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => context.push(AppRoutes.schemeDetailPath(scheme.schemeId)),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: const Text('View Scheme', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoadingIndicator(message: 'Loading MoTA schemes...'),
              error: (err, _) => AppErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(motaSchemesListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
