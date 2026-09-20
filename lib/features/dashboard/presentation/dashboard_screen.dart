import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../settings/data/language_provider.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../../applications/data/applications_repository.dart';
import '../../applications/data/schemes_repository.dart';
import '../../disbursements/data/disbursements_repository.dart';
import '../../documents/data/documents_repository.dart';
import '../data/command_center_repository.dart';
import '../domain/models/command_center_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showFamilyView = false;

  void _showDeficiencyFixSheet(BuildContext context, DeficiencyItem def) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Action Required (Deficiency)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                def.issue,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Source: ${def.source} • Raised: ${def.date.day}/${def.date.month}/${def.date.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningBg.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resolution Guidance:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warning),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.actionRequired,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deadline: ${def.deadline.day}/${def.deadline.month}/${def.deadline.year}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Resolve Now'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(commandCenterRepositoryProvider).resolveDeficiency(def.id);
                        ref.invalidate(userDeficienciesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Document uploaded and deficiency resolved!')),
                          );
                          context.push(AppRoutes.documents);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final langCode = ref.watch(languageCodeProvider);
    final applicationsAsync = ref.watch(userApplicationsProvider);
    final disbursementsAsync = ref.watch(userDisbursementsProvider);
    final deficienciesAsync = ref.watch(userDeficienciesProvider);
    final familyAsync = ref.watch(familyScholarshipsProvider);

    final apps = applicationsAsync.asData?.value ?? const [];
    final disbursements = disbursementsAsync.asData?.value ?? const [];
    final deficiencies = deficienciesAsync.asData?.value ?? const [];

    final activeAppsCount = apps.where((a) => a.isActive).length;
    final totalSanctioned = apps.fold<double>(0, (sum, a) => sum + a.sanctionedAmount);
    final totalDisbursed = disbursements.where((d) => d.pfmsStatus == 'SUCCESS').fold<double>(0, (sum, d) => sum + d.amount);
    final latestDisbursement = disbursements.isNotEmpty ? disbursements.first : null;
    final unresolvedDeficiencies = deficiencies.where((d) => !d.isResolved).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USMA Command Center',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                Text(
                  'Ministry of Tribal Affairs • DBT Portal',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: AppColors.primary),
            tooltip: 'Dynamic Eligibility Checker',
            onPressed: () => context.push(AppRoutes.eligibility),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userApplicationsProvider);
          ref.invalidate(motaSchemesListProvider);
          ref.invalidate(userDisbursementsProvider);
          ref.invalidate(userDeficienciesProvider);
          ref.invalidate(familyScholarshipsProvider);
          ref.invalidate(userDocumentsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Synchronization status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'Last synchronized: Today, 15:20 IST (Offline-ready)',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Text('Demo Data', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown)),
                    ),
                  ],
                ),
              ),

              // 1. STUDENT OVERVIEW & COMMAND HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Johar, ${user?.name ?? "Sunita Marandi"}! 🙏',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${user?.tribe ?? "Santhal"} Tribe • ${user?.district ?? "Mayurbhanj"}, ${user?.state ?? "Odisha"}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.amberAccent, size: 14),
                              SizedBox(width: 4),
                              Text('ST Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Profile Completion Bar
                    Row(
                      children: [
                        const Text('Profile Completion: 90%', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const Spacer(),
                        const Text('Aadhaar & DigiLocker Linked', style: TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.90,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // KPI stats row
                    Row(
                      children: [
                        _buildStatTile('Active Applications', '$activeAppsCount', Icons.assignment_turned_in_outlined),
                        const SizedBox(width: AppSpacing.sm),
                        _buildStatTile('Total Sanctioned', '₹${totalSanctioned.toStringAsFixed(0)}', Icons.account_balance_wallet_outlined),
                        const SizedBox(width: AppSpacing.sm),
                        _buildStatTile('Disbursed (DBT)', '₹${totalDisbursed.toStringAsFixed(0)}', Icons.check_circle_outline),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action shortcuts
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.explore_outlined,
                      title: 'Scholarship Explorer',
                      subtitle: '5 MoTA Schemes',
                      color: AppColors.primary,
                      onTap: () => context.push(AppRoutes.schemes),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.checklist_rtl_rounded,
                      title: AppLocalization.tr('dash_eligibility_engine', lang: langCode),
                      subtitle: AppLocalization.tr('dash_statutory_check', lang: langCode),
                      color: AppColors.secondary,
                      onTap: () => context.push(AppRoutes.eligibility),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.hub_outlined,
                      title: AppLocalization.tr('dash_unified_verification', lang: langCode),
                      subtitle: AppLocalization.tr('dash_unified_verification_sub', lang: langCode),
                      color: AppColors.info,
                      onTap: () => context.push(AppRoutes.verification),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.analytics_outlined,
                      title: AppLocalization.tr('dash_officer_analytics', lang: langCode),
                      subtitle: AppLocalization.tr('dash_officer_analytics_sub', lang: langCode),
                      color: AppColors.gold,
                      onTap: () => context.push(AppRoutes.adminAnalytics),
                    ),
                  ),
                ],
              ),
              if (AppConfig.isDemo) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 20, color: Colors.purple.shade700),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${AppConfig.simulatedLabel}: View as Admin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        key: const Key('demo_admin_toggle'),
                        value: ref.watch(demoAdminModeProvider),
                        activeColor: Colors.purple.shade700,
                        onChanged: (val) {
                          ref.read(demoAdminModeProvider.notifier).state = val;
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // 2. DEFICIENCY CENTER (ACTION REQUIRED)
              if (unresolvedDeficiencies.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Deficiency Center (${unresolvedDeficiencies.length} Actions)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Text('Action Required', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final def in unresolvedDeficiencies)
                  Card(
                    color: AppColors.errorBg.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  def.issue,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: def.severity == DeficiencySeverity.critical ? AppColors.error : AppColors.warning,
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  def.severity.name.toUpperCase(),
                                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Source: ${def.source} • Scheme: ${def.schemeTitle}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          const SizedBox(height: 4),
                          Text(
                            'Action: ${def.actionRequired}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Deadline: ${def.deadline.day}/${def.deadline.month}/${def.deadline.year}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  minimumSize: const Size(80, 28),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onPressed: () => _showDeficiencyFixSheet(context, def),
                                child: const Text('Fix Now', style: TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // 3. UNIFIED APPLICATION TIMELINE & SCHEME TRACKER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Application Tracking',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.applications),
                    child: const Text('View All'),
                  ),
                ],
              ),
              if (apps.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text('No active applications currently submitted.'),
                  ),
                )
              else
                ...apps.take(2).map((app) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                app.id,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textTertiary),
                              ),
                              StatusBadge(status: app.status),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            app.schemeTitle,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${app.instituteName} • AY ${app.academicYear}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(),
                          const SizedBox(height: AppSpacing.xs),

                          // Visual multi-stage timeline
                          const Text('Verification & Disbursement Pipeline:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.sm),
                          _buildVisualTimeline(app.timeline),

                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sanctioned: ₹${app.sanctionedAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              TextButton.icon(
                                onPressed: () => context.push(AppRoutes.applicationDetailPath(app.id)),
                                icon: const Icon(Icons.arrow_forward, size: 14),
                                label: const Text('Detailed Lifecycle', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.xl),

              // 4. DBT PAYMENT TRACKER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DBT Payment & PFMS Tracker',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.disbursements),
                    child: const Text('All Transactions'),
                  ),
                ],
              ),
              if (latestDisbursement != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.successBg,
                                  child: Icon(Icons.currency_rupee, color: AppColors.success, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${latestDisbursement.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ],
                            ),
                            const StatusBadge(status: 'SUCCESS', isSmall: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${latestDisbursement.schemeTitle} (${latestDisbursement.academicInstallment})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'UTR: ${latestDisbursement.utrNumber} • ${latestDisbursement.bankName} (..${latestDisbursement.accountLast4})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Credited Date: ${latestDisbursement.disbursementDate.day}/${latestDisbursement.disbursementDate.month}/${latestDisbursement.disbursementDate.year}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              // 5. FAMILY SCHOLARSHIP VIEW (OPTIONAL)
              Card(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.family_restroom, color: AppColors.primary, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Family Scholarship Overview',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Switch(
                            value: _showFamilyView,
                            onChanged: (val) => setState(() => _showFamilyView = val),
                          ),
                        ],
                      ),
                      const Text(
                        'Securely track applications across children under the same verified ration / family ID.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (_showFamilyView) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xs),
                        familyAsync.when(
                          data: (members) {
                            return Column(
                              children: members.map((m) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                        child: Text(m.memberName[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${m.memberName} (${m.relationship})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            Text(m.schemeName, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      StatusBadge(status: m.currentStatus, isSmall: true),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualTimeline(List<dynamic> timeline) {
    if (timeline.isEmpty) return const SizedBox.shrink();
    return Row(
      children: timeline.asMap().entries.map((entry) {
        final idx = entry.key;
        final event = entry.value;
        final isCompleted = event.isCompleted == true;
        final isLast = idx == timeline.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: isCompleted ? AppColors.success : AppColors.surfaceVariant,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 10,
                      color: isCompleted ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.title.toString().split(' ').first,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.success : AppColors.border,
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
