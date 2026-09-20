import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:usma/core/routing/app_router.dart';
import 'package:usma/core/routing/app_routes.dart';
import 'package:usma/features/auth/data/auth_repository.dart';
import 'package:usma/features/auth/domain/models/user_model.dart';

void main() {
  const studentUser = UserModel(
    id: 'student_001',
    name: 'Sunita Marandi',
    email: 'student@example.org',
    phoneNumber: '+919876543210',
    aadhaarLast4: '4829',
    tribe: 'Santhal',
    state: 'Odisha',
    district: 'Mayurbhanj',
    familyAnnualIncome: 180000,
    role: UserRole.student,
  );

  const adminUser = UserModel(
    id: 'admin_001',
    name: 'Officer Rajesh Soren',
    email: 'officer@mota.gov.in',
    phoneNumber: '+919876543211',
    aadhaarLast4: '9988',
    tribe: 'Santhal',
    state: 'Odisha',
    district: 'Bhubaneswar',
    familyAnnualIncome: 800000,
    role: UserRole.admin,
  );

  group('GoRouter Redirect Tests', () {
    testWidgets('Signed-out user hitting protected route (/dashboard) is redirected to /login', (tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Attempt navigating to protected route
      router.go(AppRoutes.dashboard);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.login));
      expect(find.text('Welcome to USMA'), findsOneWidget);
    });

    testWidgets('Signed-out user can access public auth routes (/login, /otp, /splash)', (tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      router.go(AppRoutes.login);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.login));

      router.go(AppRoutes.otp);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.otp));
    });

    testWidgets('Signed-in user hitting /login is redirected to /dashboard', (tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(studentUser),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Explicitly hit /login as a signed-in user
      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.dashboard));
    });

    testWidgets('Non-admin student hitting /admin-analytics is blocked and redirected to /dashboard', (tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(studentUser),
            demoAdminModeProvider.overrideWith((ref) => false),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      // Student attempts to reach admin analytics
      router.go(AppRoutes.adminAnalytics);
      await tester.pumpAndSettle();

      // Blocked and redirected to dashboard
      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.dashboard));
    });

    testWidgets('Officer with UserRole.admin hitting /admin-analytics is granted access', (tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(adminUser),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      router.go(AppRoutes.adminAnalytics);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.adminAnalytics));
      expect(find.text('MoTA Officer & Admin Analytics'), findsOneWidget);
    });

    testWidgets('Demo mode allows access to /admin-analytics when demoAdminMode toggle is enabled', (tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(studentUser),
            demoAdminModeProvider.overrideWith((ref) => true),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      router.go(AppRoutes.adminAnalytics);
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.adminAnalytics));
      expect(find.text('MoTA Officer & Admin Analytics'), findsOneWidget);
    });

    testWidgets('SplashScreen navigates unauthenticated user to /login after timer', (tester) async {
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );

      expect(find.text('USMA'), findsOneWidget);

      // Advance through the 1400ms splash branded delay
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, equals(AppRoutes.login));
    });
  });
}
