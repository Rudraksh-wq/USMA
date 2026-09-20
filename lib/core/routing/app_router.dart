import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/ekyc_screen.dart';
import '../../features/dashboard/presentation/main_scaffold.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/applications/presentation/schemes_screen.dart';
import '../../features/applications/presentation/scheme_detail_screen.dart';
import '../../features/applications/presentation/apply_screen.dart';
import '../../features/applications/presentation/applications_screen.dart';
import '../../features/applications/presentation/application_detail_screen.dart';
import '../../features/documents/presentation/documents_screen.dart';
import '../../features/disbursements/presentation/disbursements_screen.dart';
import '../../features/eligibility/presentation/eligibility_screen.dart';
import '../../features/chatbot/presentation/chatbot_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/verification/presentation/unified_verification_screen.dart';
import '../../features/coverage_gap/presentation/admin_analytics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/verification/presentation/integration_status_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
    _ref.listen(demoAdminModeProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

/// Tracks whether the initial splash screen display has finished.
final splashCompletedProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isLoggedIn = user != null;
      final isAdmin = ref.read(isAdminUserProvider);
      final splashCompleted = ref.read(splashCompletedProvider);
      final location = state.matchedLocation;

      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;
      final isOtp = location == AppRoutes.otp;

      // 1. Unauthenticated users are sent to /login for any route except splash, login, and otp
      if (!isLoggedIn) {
        if (isSplash || isLogin || isOtp) {
          return null;
        }
        return AppRoutes.login;
      }

      // 2. Authenticated users hitting /login or /splash go to /dashboard instead
      // (Splash is allowed on initial launch before branded timer completes)
      if (isLogin || (isSplash && splashCompleted)) {
        return AppRoutes.dashboard;
      }

      // 3. AppRoutes.adminAnalytics: not reachable by a non-admin account
      if (location == AppRoutes.adminAnalytics) {
        if (!isAdmin) {
          return AppRoutes.dashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.ekyc,
        builder: (context, state) => const EkycScreen(),
      ),
      // Shell route for persistent bottom navigation bar
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.applications,
            builder: (context, state) => const ApplicationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.documents,
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.disbursements,
            builder: (context, state) => const DisbursementsScreen(),
          ),
          GoRoute(
            path: AppRoutes.chatbot,
            builder: (context, state) => const ChatbotScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.schemes,
        builder: (context, state) => const SchemesScreen(),
      ),
      GoRoute(
        path: '/schemes/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return SchemeDetailScreen(schemeId: id);
        },
      ),
      GoRoute(
        path: '/apply/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ApplyScreen(schemeId: id);
        },
      ),
      GoRoute(
        path: '/applications/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ApplicationDetailScreen(applicationId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.eligibility,
        builder: (context, state) => const EligibilityScreen(),
      ),
      GoRoute(
        path: AppRoutes.verification,
        builder: (context, state) => const UnifiedVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAnalytics,
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.integrationStatus,
        builder: (context, state) => const IntegrationStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
