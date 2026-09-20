// ============================================================
// USMA — Scholarship Uniqueness & Conflict Pre-check Tests
// scholarship_uniqueness_test.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/applications/data/applications_repository.dart';
import 'package:usma/features/applications/data/schemes_repository.dart';
import 'package:usma/features/applications/domain/models/application_model.dart';
import 'package:usma/features/applications/domain/models/scheme_model.dart';
import 'package:usma/features/applications/domain/scholarship_uniqueness.dart';
import 'package:usma/features/applications/presentation/apply_screen.dart';
import 'package:usma/features/auth/data/auth_repository.dart';
import 'package:usma/features/auth/domain/models/user_model.dart';

class FakeApplicationsRepo implements IApplicationsRepository {
  List<ApplicationModel> apps;
  FakeApplicationsRepo(this.apps);

  @override
  Future<List<ApplicationModel>> getApplications(String userId) async {
    return apps.where((a) => a.userId == userId).toList();
  }

  @override
  Future<ApplicationModel> getApplicationById(String applicationId) async {
    return apps.firstWhere((a) => a.id == applicationId);
  }

  @override
  Future<ApplicationModel> submitApplication(ApplicationModel application) async {
    const uniqueness = ScholarshipUniqueness();
    final conflict = uniqueness.conflictIfApplying(
      existing: apps,
      userId: application.userId,
    );
    if (conflict != null) throw conflict;
    apps.add(application);
    return application;
  }
}

void main() {
  group('ScholarshipUniqueness Domain Logic Tests', () {
    const uniqueness = ScholarshipUniqueness();
    final now = DateTime.now();

    final activeApp = ApplicationModel(
      id: 'APP-2026-ST-8821',
      userId: 'user_st_01',
      schemeId: 'post_matric',
      schemeTitle: 'Post-Matric Scholarship for ST Students',
      academicYear: '2026-2027',
      instituteName: 'NIT Rourkela',
      courseName: 'B.Tech CSE',
      sanctionedAmount: 85000,
      status: 'sanctioned',
      submittedAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 1)),
      timeline: const [],
    );

    final disbursedApp = ApplicationModel(
      id: 'APP-2025-ST-1100',
      userId: 'user_st_01',
      schemeId: 'pre_matric',
      schemeTitle: 'Pre-Matric Scholarship for ST Students',
      academicYear: '2025-2026',
      instituteName: 'Govt High School',
      courseName: 'Class X',
      sanctionedAmount: 10000,
      status: 'disbursed',
      submittedAt: now.subtract(const Duration(days: 200)),
      updatedAt: now.subtract(const Duration(days: 150)),
      timeline: const [],
    );

    final rejectedApp = ApplicationModel(
      id: 'APP-2025-ST-1200',
      userId: 'user_st_01',
      schemeId: 'top_class',
      schemeTitle: 'Top Class Scholarship',
      academicYear: '2025-2026',
      instituteName: 'IIT Delhi',
      courseName: 'B.Tech',
      sanctionedAmount: 200000,
      status: 'rejected',
      submittedAt: now.subtract(const Duration(days: 180)),
      updatedAt: now.subtract(const Duration(days: 170)),
      timeline: const [],
    );

    test('1. No active application (allowed - returns null)', () {
      final conflict = uniqueness.conflictIfApplying(
        existing: [],
        userId: 'user_st_01',
      );
      expect(conflict, isNull);

      final conflictWithClosed = uniqueness.conflictIfApplying(
        existing: [disbursedApp, rejectedApp],
        userId: 'user_st_01',
      );
      expect(conflictWithClosed, isNull);
    });

    test('2. One active application (blocked with specific ID and scheme title message)', () {
      final conflict = uniqueness.conflictIfApplying(
        existing: [activeApp],
        userId: 'user_st_01',
      );
      expect(conflict, isNotNull);
      expect(conflict!.message, contains('APP-2026-ST-8821'));
      expect(conflict.message, contains('Post-Matric Scholarship for ST Students'));
      expect(conflict.message, contains('A student may hold only one scholarship or fellowship at a time.'));
    });

    test('3. Other users active application does not block current user', () {
      final conflict = uniqueness.conflictIfApplying(
        existing: [activeApp],
        userId: 'user_st_99', // Different user
      );
      expect(conflict, isNull);
    });

    test('4. Applying to replace existing application (replacingApplicationId) is allowed', () {
      final conflict = uniqueness.conflictIfApplying(
        existing: [activeApp],
        userId: 'user_st_01',
        replacingApplicationId: 'APP-2026-ST-8821',
      );
      expect(conflict, isNull);
    });
  });

  group('ApplyScreen Uniqueness Widget Tests', () {
    const testUser = UserModel(
      id: 'user_test_01',
      name: 'Sunita Marandi',
      email: 'sunita@example.com',
      phoneNumber: '9876543210',
      aadhaarLast4: '4829',
      tribe: 'Santhal',
      state: 'Odisha',
      district: 'Mayurbhanj',
      familyAnnualIncome: 180000,
      isScheduledTribe: true,
    );

    final testScheme = SchemeModel(
      id: 'top_class',
      code: 'TOP_CLASS_ST',
      title: 'Top Class Scholarship for ST Students',
      shortTitle: 'Top Class ST',
      description: 'Scholarship for premier institutes',
      educationLevel: 'Degree',
      educationLevels: const ['Degree', 'Higher Education'],
      classes: const ['Undergraduate', 'Postgraduate'],
      sourceSystems: const ['NSP'],
      maxAmount: 200000,
      maxFamilyIncome: 600000,
      deadline: DateTime(2026, 11, 30),
      requiredDocuments: const ['Aadhaar', 'Income Certificate', 'ST Certificate'],
    );

    testWidgets('Submitting when active application exists shows specific blocked dialog', (tester) async {
      final now = DateTime.now();
      final existingActive = ApplicationModel(
        id: 'APP-ACTIVE-999',
        userId: 'user_test_01',
        schemeId: 'post_matric',
        schemeTitle: 'Post-Matric ST Scheme',
        academicYear: '2026-2027',
        instituteName: 'NIT Rourkela',
        courseName: 'B.Tech',
        sanctionedAmount: 85000,
        status: 'submitted',
        submittedAt: now,
        updatedAt: now,
        timeline: const [],
      );

      final fakeRepo = FakeApplicationsRepo([existingActive]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            applicationsRepositoryProvider.overrideWithValue(fakeRepo),
            schemeDetailProvider('top_class').overrideWith((ref) async => testScheme),
          ],
          child: const MaterialApp(
            home: ApplyScreen(schemeId: 'top_class'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find submit button and scroll into view
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Application with DigiLocker');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Check dialog appears
      expect(find.text('Application Blocked'), findsOneWidget);
      expect(find.textContaining('APP-ACTIVE-999 — Post-Matric ST Scheme'), findsOneWidget);
      expect(find.textContaining('A student may hold only one scholarship or fellowship at a time.'), findsOneWidget);
      expect(find.text('View Active Application'), findsOneWidget);
    });

    testWidgets('Submitting when no active application exists proceeds to submit', (tester) async {
      final fakeRepo = FakeApplicationsRepo([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            applicationsRepositoryProvider.overrideWithValue(fakeRepo),
            schemeDetailProvider('top_class').overrideWith((ref) async => testScheme),
          ],
          child: const MaterialApp(
            home: ApplyScreen(schemeId: 'top_class'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(ElevatedButton, 'Submit Application with DigiLocker');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verification of success dialog
      expect(find.text('Application Submitted!'), findsOneWidget);
      expect(find.text('Application Blocked'), findsNothing);
    });
  });
}
