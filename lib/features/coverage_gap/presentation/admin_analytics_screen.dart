import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/data/auth_repository.dart';
import '../data/coverage_gap_analytics_repository.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  String _selectedState = 'All States';
  String _selectedScheme = 'All MoTA Schemes';

  final List<String> _states = [
    'All States',
    'Odisha',
    'Jharkhand',
    'Madhya Pradesh',
    'Chhattisgarh',
    'Assam',
    'Rajasthan',
  ];

  final List<String> _schemes = [
    'All MoTA Schemes',
    'Pre-Matric ST',
    'Post-Matric ST (PMS-ST)',
    'Top Class Higher Education',
    'National Fellowship (NFST)',
    'National Overseas (NOS)',
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminUserProvider);
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Admin Access Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'This section is restricted to Ministry Officers and System Administrators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                if (AppConfig.isDemo) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(demoAdminModeProvider.notifier).state = true;
                    },
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Demo: View as Admin'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final summaryAsync = ref.watch(adminAnalyticsSummaryProvider);
    final recordsAsync = ref.watch(coverageGapRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoTA Officer & Admin Analytics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 6),
            child: const Text(
              'Coverage Gap & Direct Benefit Transfer Analytics (Demo)',
              style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedState,
                    decoration: const InputDecoration(
                      labelText: 'State / UT',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedState = val);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedScheme,
                    decoration: const InputDecoration(
                      labelText: 'Scheme Filter',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: _schemes.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedScheme = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Summary KPI Matrix
            summaryAsync.when(
              data: (summary) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildKpiCard(
                          title: 'Total Enrolled STs',
                          value: '${(summary.totalEnrolledST / 1000).toStringAsFixed(1)}k',
                          subtitle: 'UDISE+ / AISHE Database',
                          icon: Icons.people_outline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildKpiCard(
                          title: 'Active Beneficiaries',
                          value: '${(summary.activeBeneficiaries / 1000).toStringAsFixed(1)}k',
                          subtitle: 'Direct DBT Recipients',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _buildKpiCard(
                          title: 'Coverage Gap (Unreached)',
                          value: '${(summary.potentiallyEligibleNonBeneficiaries / 1000).toStringAsFixed(1)}k',
                          subtitle: 'Eligible but Not Applied',
                          icon: Icons.explore_off_outlined,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        _buildKpiCard(
                          title: 'Pending Verification',
                          value: '${(summary.verificationPending / 1000).toStringAsFixed(1)}k',
                          subtitle: 'Institute / SNO Pipeline',
                          icon: Icons.hourglass_top,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const AppLoadingIndicator(),
              error: (e, _) => AppErrorView(message: e.toString()),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Coverage Gap Breakdown Section
            const Text(
              'Unreached Beneficiary Detection (Sample Records)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Identifies tribal students enrolled in schools/universities who are missing out on statutory MoTA entitlements.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),

            recordsAsync.when(
              data: (records) {
                return Column(
                  children: records.map((rec) {
                    final isGap = rec.statusCategory == 'POTENTIALLY_ELIGIBLE_NOT_APPLIED';
                    final isMismatch = rec.statusCategory == 'DATA_MISMATCH';

                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(
                          color: isGap
                              ? AppColors.error.withValues(alpha: 0.4)
                              : (isMismatch ? AppColors.warning.withValues(alpha: 0.4) : AppColors.border),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isGap
                              ? AppColors.errorBg
                              : (isMismatch ? AppColors.warningBg : AppColors.successBg),
                          child: Icon(
                            isGap
                                ? Icons.person_add_disabled
                                : (isMismatch ? Icons.sync_problem : Icons.verified_user),
                            size: 18,
                            color: isGap
                                ? AppColors.error
                                : (isMismatch ? AppColors.warning : AppColors.success),
                          ),
                        ),
                        title: Text(rec.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${rec.institutionName} • ${rec.district}, ${rec.state}', style: const TextStyle(fontSize: 11)),
                            if (rec.mismatchDescription != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  rec.mismatchDescription!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isGap ? AppColors.error : AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isGap
                                ? AppColors.errorBg
                                : (isMismatch ? AppColors.warningBg : AppColors.successBg),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            isGap ? 'UNREACHED' : (isMismatch ? 'MISMATCH' : 'ACTIVE'),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isGap
                                  ? AppColors.error
                                  : (isMismatch ? AppColors.warning : AppColors.success),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading records: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: color),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'MoTA Stats',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
