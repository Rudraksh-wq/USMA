import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/applications/domain/models/mota_scheme_model.dart';
import 'package:usma/features/eligibility/domain/eligibility_engine.dart';
import 'package:usma/features/eligibility/domain/eligibility_result.dart';

void main() {
  late List<MotaSchemeModel> schemes;
  late MotaSchemeModel preMatric;
  late MotaSchemeModel postMatric;
  late MotaSchemeModel topClass;
  late MotaSchemeModel nfst;
  late MotaSchemeModel nos;

  setUpAll(() {
    final file = File('assets/data/schemes.json');
    final jsonStr = file.readAsStringSync();
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final rawSchemes = data['schemes'] as List<dynamic>;
    schemes = rawSchemes
        .map((s) => MotaSchemeModel.fromMap(s as Map<String, dynamic>))
        .toList();

    preMatric = schemes.firstWhere((s) => s.schemeId == 'pre_matric_st');
    postMatric = schemes.firstWhere((s) => s.schemeId == 'post_matric_st');
    topClass = schemes.firstWhere((s) => s.schemeId == 'top_class_st');
    nfst = schemes.firstWhere((s) => s.schemeId == 'nfst');
    nos = schemes.firstWhere((s) => s.schemeId == 'nos');
  });

  group('MoTA Five-Scheme Catalog JSON & Model Integrity', () {
    test('1. schemes.json loads all 5 MoTA schemes', () {
      expect(schemes.length, 5);
      final ids = schemes.map((s) => s.schemeId).toSet();
      expect(ids, containsAll(['pre_matric_st', 'post_matric_st', 'top_class_st', 'nfst', 'nos']));
    });

    test('2. Source systems are mapped correctly (NSP, SFMP, NOS)', () {
      expect(preMatric.sourceSystem, 'NSP');
      expect(postMatric.sourceSystem, 'NSP');
      expect(topClass.sourceSystem, 'NSP');
      expect(nfst.sourceSystem, 'SFMP');
      expect(nos.sourceSystem, 'NOS');
    });

    test('3. Income ceilings match statutory guidelines', () {
      expect(preMatric.incomeLimit.maxFamilyIncome, 250000.0);
      expect(postMatric.incomeLimit.maxFamilyIncome, 250000.0);
      expect(topClass.incomeLimit.maxFamilyIncome, 600000.0);
      expect(nfst.incomeLimit.maxFamilyIncome, 600000.0);
      expect(nos.incomeLimit.maxFamilyIncome, 600000.0);
    });

    test('4. Special scheme criteria defined (NET for NFST, Abroad for NOS)', () {
      expect(nfst.netJrfRequired, isTrue);
      expect(nos.admissionAbroadRequired, isTrue);
      expect(nos.maxAge, 35);
      expect(nos.minMarksPercentage, 55.0);
    });
  });

  group('Income Boundary Unit Tests', () {
    const baseDocs = ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR'];

    test('5. Pre-Matric: income exactly at ₹2,50,000 ceiling is eligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Pre-Matric',
        currentClassOrDegree: 'Class 9',
        familyAnnualIncome: 250000.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.isEligible, isTrue);
    });

    test('6. Pre-Matric: income at ₹2,50,001 ceiling is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Pre-Matric',
        currentClassOrDegree: 'Class 9',
        familyAnnualIncome: 250001.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.isEligible, isFalse);
      expect(r.status, EligibilityStatus.ineligible);
    });

    test('7. Post-Matric: income exactly at ₹2,50,000 ceiling is eligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        familyAnnualIncome: 250000.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.isEligible, isTrue);
    });

    test('8. Post-Matric: income at ₹2,50,001 ceiling is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        familyAnnualIncome: 250001.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.isEligible, isFalse);
    });

    test('9. Top Class: income exactly at ₹6,00,000 ceiling is eligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Higher Education',
        currentClassOrDegree: 'B.Tech',
        institutionType: 'PREMIER_NOTIFIED',
        familyAnnualIncome: 600000.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: topClass);
      expect(r.isEligible, isTrue);
    });

    test('10. Top Class: income at ₹6,00,001 is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Higher Education',
        currentClassOrDegree: 'B.Tech',
        institutionType: 'PREMIER_NOTIFIED',
        familyAnnualIncome: 600001.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: topClass);
      expect(r.isEligible, isFalse);
    });

    test('11. NFST: income exactly at ₹6,00,000 ceiling is eligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Research',
        currentClassOrDegree: 'Ph.D',
        hasNetJrf: true,
        familyAnnualIncome: 600000.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nfst);
      expect(r.isEligible, isTrue);
    });

    test('12. NFST: income at ₹6,00,001 is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Research',
        currentClassOrDegree: 'Ph.D',
        hasNetJrf: true,
        familyAnnualIncome: 600001.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nfst);
      expect(r.isEligible, isFalse);
    });

    test('13. NOS: income exactly at ₹6,00,000 is eligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Overseas',
        institutionType: 'FOREIGN_QS500',
        hasForeignAdmission: true,
        qualifyingMarksPercentage: 60.0,
        studentAge: 25,
        familyAnnualIncome: 600000.0,
        availableDocumentTypes: [...baseDocs, 'PASSPORT'],
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nos);
      expect(r.isEligible, isTrue);
    });

    test('14. NOS: income at ₹6,00,001 is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Overseas',
        institutionType: 'FOREIGN_QS500',
        hasForeignAdmission: true,
        qualifyingMarksPercentage: 60.0,
        studentAge: 25,
        familyAnnualIncome: 600001.0,
        availableDocumentTypes: [...baseDocs, 'PASSPORT'],
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nos);
      expect(r.isEligible, isFalse);
    });

    test('15. Zero income student passes income ceiling check', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Pre-Matric',
        currentClassOrDegree: 'Class 9',
        familyAnnualIncome: 0.0,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.isEligible, isTrue);
    });
  });

  group('Incomplete Profile & Missing Fields Tests', () {
    test('16. Missing income yields incompleteProfile status', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        educationLevel: 'Pre-Matric',
        familyAnnualIncome: null,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.status, EligibilityStatus.incompleteProfile);
      expect(r.missingProfileFields, contains('Family Annual Income'));
    });

    test('17. Missing education level yields incompleteProfile status', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: null,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.status, EligibilityStatus.incompleteProfile);
      expect(r.missingProfileFields, contains('Education Level / Class'));
    });

    test('18. Missing social category yields incompleteProfile status', () {
      const p = StudentEligibilityProfile(
        socialCategory: null,
        familyAnnualIncome: 100000.0,
        educationLevel: 'Post-Matric',
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.status, EligibilityStatus.incompleteProfile);
      expect(r.missingProfileFields, contains('Social Category (ST/PVTG)'));
    });

    test('19. All fields missing lists all 3 missing fields', () {
      const p = StudentEligibilityProfile(
        socialCategory: null,
        familyAnnualIncome: null,
        educationLevel: null,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.missingProfileFields.length, 3);
    });
  });

  group('ST & PVTG Community Tests', () {
    const baseDocs = ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR'];

    test('20. ST category student passes community check', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 150000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.isEligible, isTrue);
    });

    test('21. PVTG category student passes community check with priority', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'PVTG',
        isPvtg: true,
        familyAnnualIncome: 150000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.isEligible, isTrue);
    });

    test('22. General category student is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'GEN',
        isScheduledTribe: false,
        familyAnnualIncome: 150000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.isEligible, isFalse);
      expect(r.failedCriteria.any((c) => c.contains('Scheduled Tribe')), isTrue);
    });

    test('23. SC category student is ineligible for MoTA schemes', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'SC',
        isScheduledTribe: false,
        familyAnnualIncome: 150000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.isEligible, isFalse);
    });
  });

  group('One-Scholarship-at-a-Time Rule Tests', () {
    const baseDocs = ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR'];

    test('24. Active Pre-Matric award blocks applying for Post-Matric', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'Class 11',
        availableDocumentTypes: baseDocs,
      );
      const awards = [
        ExistingAward(
          schemeId: 'pre_matric_st',
          schemeName: 'Pre-Matric Scholarship for ST Students',
          academicYear: '2026-2027',
          status: 'Active',
          sourceSystem: 'NSP',
        ),
      ];
      final r = MoTAEligibilityEngine.evaluateScheme(
        profile: p,
        scheme: postMatric,
        existingAwards: awards,
      );
      expect(r.status, EligibilityStatus.blockedByExistingAward);
      expect(r.blockedByAward, isNotNull);
      expect(r.blockedByAward!.schemeId, 'pre_matric_st');
      expect(r.conflictExplanation, contains('Pre-Matric'));
    });

    test('25. Active Post-Matric award blocks applying for Top Class', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 200000.0,
        educationLevel: 'Higher Education',
        institutionType: 'PREMIER_NOTIFIED',
        availableDocumentTypes: baseDocs,
      );
      const awards = [
        ExistingAward(
          schemeId: 'post_matric_st',
          schemeName: 'Post-Matric Scholarship for ST Students',
          academicYear: '2026-2027',
          status: 'Sanctioned',
          sourceSystem: 'NSP',
        ),
      ];
      final r = MoTAEligibilityEngine.evaluateScheme(
        profile: p,
        scheme: topClass,
        existingAwards: awards,
      );
      expect(r.status, EligibilityStatus.blockedByExistingAward);
    });

    test('26. Active NFST award blocks applying for NOS', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 300000.0,
        educationLevel: 'Overseas',
        hasForeignAdmission: true,
        qualifyingMarksPercentage: 65.0,
        studentAge: 28,
        availableDocumentTypes: [...baseDocs, 'PASSPORT'],
      );
      const awards = [
        ExistingAward(
          schemeId: 'nfst',
          schemeName: 'National Fellowship for ST Students',
          academicYear: '2026-2027',
          status: 'Disbursed',
          sourceSystem: 'SFMP',
        ),
      ];
      final r = MoTAEligibilityEngine.evaluateScheme(
        profile: p,
        scheme: nos,
        existingAwards: awards,
      );
      expect(r.status, EligibilityStatus.blockedByExistingAward);
    });

    test('27. Evaluating same scheme as active award is not cross-conflict blocked', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        availableDocumentTypes: baseDocs,
      );
      const awards = [
        ExistingAward(
          schemeId: 'post_matric_st',
          schemeName: 'Post-Matric Scholarship for ST Students',
          academicYear: '2026-2027',
          status: 'Active',
          sourceSystem: 'NSP',
        ),
      ];
      final r = MoTAEligibilityEngine.evaluateScheme(
        profile: p,
        scheme: postMatric,
        existingAwards: awards,
      );
      expect(r.status, isNot(EligibilityStatus.blockedByExistingAward));
    });

    test('28. Expired / Inactive award does NOT block new application', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        availableDocumentTypes: baseDocs,
      );
      const awards = [
        ExistingAward(
          schemeId: 'pre_matric_st',
          schemeName: 'Pre-Matric ST',
          academicYear: '2024-2025',
          status: 'Completed',
          sourceSystem: 'NSP',
        ),
      ];
      final r = MoTAEligibilityEngine.evaluateScheme(
        profile: p,
        scheme: postMatric,
        existingAwards: awards,
      );
      expect(r.status, isNot(EligibilityStatus.blockedByExistingAward));
      expect(r.isEligible, isTrue);
    });
  });

  group('Education Level & Institution Type Tests', () {
    const baseDocs = ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR'];

    test('29. Class 9 student is eligible for Pre-Matric', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Pre-Matric',
        currentClassOrDegree: 'Class 9',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.isEligible, isTrue);
    });

    test('30. Class 11 student is ineligible for Pre-Matric', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'Class 11',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.isEligible, isFalse);
    });

    test('31. Class 12 student is eligible for Post-Matric', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'Class 12',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: postMatric);
      expect(r.isEligible, isTrue);
    });

    test('32. Premier Notified institute student is eligible for Top Class', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 400000.0,
        educationLevel: 'Higher Education',
        currentClassOrDegree: 'B.Tech',
        institutionType: 'PREMIER_NOTIFIED',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: topClass);
      expect(r.isEligible, isTrue);
    });

    test('33. Regular college student is ineligible for Top Class (Requires Premier)', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 400000.0,
        educationLevel: 'Higher Education',
        currentClassOrDegree: 'B.A.',
        institutionType: 'REGULAR_RECOGNIZED',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: topClass);
      expect(r.isEligible, isFalse);
      expect(r.failedCriteria.any((c) => c.contains('265 MoTA-notified')), isTrue);
    });

    test('34. Ph.D researcher with NET/JRF is eligible for NFST', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 350000.0,
        educationLevel: 'Research',
        currentClassOrDegree: 'Ph.D',
        hasNetJrf: true,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nfst);
      expect(r.isEligible, isTrue);
    });

    test('35. Ph.D researcher without NET/JRF is ineligible for NFST', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 350000.0,
        educationLevel: 'Research',
        currentClassOrDegree: 'Ph.D',
        hasNetJrf: false,
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nfst);
      expect(r.isEligible, isFalse);
      expect(r.failedCriteria.any((c) => c.contains('NET')), isTrue);
    });

    test('36. Undergrad student applying for NFST is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 200000.0,
        educationLevel: 'Higher Education',
        currentClassOrDegree: 'B.Tech',
        availableDocumentTypes: baseDocs,
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nfst);
      expect(r.isEligible, isFalse);
    });
  });

  group('NOS Overseas Rules Tests (Marks, Age, Documents)', () {
    const baseDocs = ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR'];

    test('37. NOS candidate with marks < 55% is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 300000.0,
        educationLevel: 'Overseas',
        hasForeignAdmission: true,
        qualifyingMarksPercentage: 54.0, // Below 55%
        studentAge: 26,
        availableDocumentTypes: [...baseDocs, 'PASSPORT'],
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nos);
      expect(r.isEligible, isFalse);
      expect(r.failedCriteria.any((c) => c.contains('minimum 55% marks')), isTrue);
    });

    test('38. NOS candidate aged >= 35 is ineligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 300000.0,
        educationLevel: 'Overseas',
        hasForeignAdmission: true,
        qualifyingMarksPercentage: 65.0,
        studentAge: 35, // Age limit is strictly below 35
        availableDocumentTypes: [...baseDocs, 'PASSPORT'],
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nos);
      expect(r.isEligible, isFalse);
      expect(r.failedCriteria.any((c) => c.contains('below 35 years')), isTrue);
    });

    test('39. NOS candidate missing passport yields conditionallyEligible', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 300000.0,
        educationLevel: 'Overseas',
        hasForeignAdmission: true,
        qualifyingMarksPercentage: 65.0,
        studentAge: 28,
        availableDocumentTypes: baseDocs, // Missing PASSPORT
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: nos);
      expect(r.status, EligibilityStatus.conditionallyEligible);
      expect(r.missingDocuments, contains('Valid Indian Passport'));
    });
  });

  group('Document Requirements & Rules Satisfied Scoring', () {
    test('40. Missing income document yields conditionallyEligible with checklist', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Pre-Matric',
        currentClassOrDegree: 'Class 9',
        availableDocumentTypes: ['CASTE_CERTIFICATE', 'AADHAAR'], // Missing income
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.status, EligibilityStatus.conditionallyEligible);
      expect(r.missingDocuments, contains('Annual Income Certificate for current financial year'));
    });

    test('41. Missing caste document yields conditionallyEligible with checklist', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Pre-Matric',
        currentClassOrDegree: 'Class 9',
        availableDocumentTypes: ['INCOME_CERTIFICATE', 'AADHAAR'], // Missing caste
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.status, EligibilityStatus.conditionallyEligible);
      expect(r.missingDocuments, contains('Scheduled Tribe (ST) Certificate'));
    });

    test('42. Rules satisfied count reflects actual rules (rulesSatisfied / rulesTotal)', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 100000.0,
        educationLevel: 'Pre-Matric',
        currentClassOrDegree: 'Class 9',
        availableDocumentTypes: ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR'],
      );
      final r = MoTAEligibilityEngine.evaluateScheme(profile: p, scheme: preMatric);
      expect(r.rulesSatisfied, r.rulesTotal);
      expect(r.ruleScoreText, '${r.rulesTotal}/${r.rulesTotal} rules satisfied');
    });

    test('43. Evaluates all 5 schemes simultaneously via evaluate() entry point', () {
      const p = StudentEligibilityProfile(
        socialCategory: 'ST',
        familyAnnualIncome: 150000.0,
        educationLevel: 'Post-Matric',
        currentClassOrDegree: 'B.Tech',
        institutionType: 'PREMIER_NOTIFIED',
        availableDocumentTypes: ['CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR'],
      );
      final evals = MoTAEligibilityEngine.evaluate(p, const [], schemes: schemes);
      expect(evals.length, 5);
      final postMatricEval = evals.firstWhere((e) => e.schemeId == 'post_matric_st');
      expect(postMatricEval.isEligible, isTrue);
      final preMatricEval = evals.firstWhere((e) => e.schemeId == 'pre_matric_st');
      expect(preMatricEval.isEligible, isFalse);
    });
  });
}
