import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/applications_repository.dart';

class ApplicationDetailScreen extends ConsumerWidget {
  final String applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appAsync = ref.watch(applicationDetailProvider(applicationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Timeline'),
      ),
      body: appAsync.when(
        data: (app) {
          if (app == null) return const Center(child: Text('Application not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(app.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                          StatusBadge(status: app.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(app.schemeTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('${app.instituteName} • ${app.academicYear}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sanctioned Scholarship Amount', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('₹${app.sanctionedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                const Text('What Happens Next (5-Stage Timeline)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.md),

                // Timeline List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: app.timeline.length,
                  itemBuilder: (context, idx) {
                    final item = app.timeline[idx];
                    final isLast = idx == app.timeline.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: item.isCompleted ? AppColors.success : AppColors.surfaceVariant,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: item.isCompleted ? AppColors.success : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  item.isCompleted ? Icons.check : Icons.circle,
                                  size: 13,
                                  color: item.isCompleted ? AppColors.surface : AppColors.textTertiary,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 48,
                                color: item.isCompleted ? AppColors.success : AppColors.border,
                              ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: item.isCompleted ? AppColors.textPrimary : AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.timestamp.day}/${item.timestamp.month}/${item.timestamp.year}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                if (app.status == 'MINISTRY_APPROVED' || app.status == 'DISBURSED')
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.disbursements),
                    icon: const Icon(Icons.currency_rupee_rounded),
                    label: const Text('View Payment & DBT Details'),
                  ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
