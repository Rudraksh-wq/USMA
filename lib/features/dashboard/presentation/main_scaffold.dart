import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../settings/data/language_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.schemes) || location.startsWith(AppRoutes.applications)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.documents)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.disbursements)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.chatbot)) {
      return 4;
    }
    return 0; // Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
        break;
      case 1:
        context.go(AppRoutes.applications);
        break;
      case 2:
        context.go(AppRoutes.documents);
        break;
      case 3:
        context.go(AppRoutes.disbursements);
        break;
      case 4:
        context.go(AppRoutes.chatbot);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final langCode = ref.watch(languageCodeProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: AppLocalization.tr('nav_home', lang: langCode),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.school_outlined),
            activeIcon: const Icon(Icons.school_rounded),
            label: AppLocalization.tr('nav_schemes', lang: langCode),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_shared_outlined),
            activeIcon: const Icon(Icons.folder_shared_rounded),
            label: AppLocalization.tr('nav_wallet', lang: langCode),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.currency_rupee_rounded),
            activeIcon: const Icon(Icons.currency_rupee_rounded),
            label: AppLocalization.tr('nav_dbt', lang: langCode),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy_outlined),
            activeIcon: const Icon(Icons.smart_toy_rounded),
            label: AppLocalization.tr('nav_saathi', lang: langCode),
          ),
        ],
      ),
    );
  }
}
