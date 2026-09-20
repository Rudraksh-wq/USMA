import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0] : 'S',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.surface),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    user?.name ?? 'Sunita Marandi',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ST Community • ${user?.tribe ?? "Santhal"}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Profile info card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildInfoTile('Aadhaar Number', 'XXXX-XXXX-${user?.aadhaarLast4 ?? "4829"}', Icons.fingerprint_rounded, true),
                  const Divider(),
                  _buildInfoTile('APAAR Student ID', user?.apaarId ?? 'APAAR-2026-9938-11', Icons.badge_outlined, true),
                  const Divider(),
                  _buildInfoTile('Seeded Bank Account', 'State Bank of India (..${user?.bankAccountLast4 ?? "3819"})', Icons.account_balance_outlined, true),
                  const Divider(),
                  _buildInfoTile('State & District', '${user?.state ?? "Odisha"}, ${user?.district ?? "Mayurbhanj"}', Icons.location_on_outlined, false),
                  const Divider(),
                  _buildInfoTile('Annual Family Income', '₹${(user?.familyAnnualIncome ?? 180000).toStringAsFixed(0)}', Icons.currency_rupee_rounded, false),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Government Verification Transparency Section
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.hub_outlined, color: AppColors.primary),
                title: const Text('How We Verify Your Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Multi-source verification with UIDAI, DigiLocker & State DB', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: AppConfig.isDemo
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Demo data', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push(AppRoutes.verification),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Officer Analytics (Access moved here from student quick actions)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.analytics_outlined, color: AppColors.primary),
                title: const Text('Officer Analytics & Coverage Gap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('State & District saturation matrix for nodal officers', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push(AppRoutes.adminAnalytics),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.ekyc),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Update e-KYC Verification'),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) {
                  context.go(AppRoutes.login);
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
          if (isVerified)
            const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                SizedBox(width: 4),
                Text('Verified', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
        ],
      ),
    );
  }
}
