import '../../applications/domain/models/mota_scheme_model.dart';
import 'eligibility_result.dart';

class MoTAEligibilityEngine {
  static const double prePostMatricIncomeCeiling = 250000.0;
  static const double higherEduResearchOverseasIncomeCeiling = 600000.0;

  /// Main entry point: evaluates a student profile and existing awards across schemes
  static List<SchemeEligibilityEvaluation> evaluate(
    StudentEligibilityProfile profile,
    List<ExistingAward> existingAwards, {
    List<MotaSchemeModel> schemes = const [],
  }) {
    return schemes
        .map((s) => evaluateScheme(
              profile: profile,
              scheme: s,
              existingAwards: existingAwards,
            ))
        .toList();
  }

  /// Backward compatible helper
  static List<SchemeEligibilityEvaluation> evaluateAllSchemes({
    required StudentEligibilityProfile profile,
    required List<MotaSchemeModel> schemes,
    List<ExistingAward> existingAwards = const [],
  }) {
    return evaluate(profile, existingAwards, schemes: schemes);
  }

  /// Evaluates student profile against a single MoTA scheme based on authentic government rules.
  static SchemeEligibilityEvaluation evaluateScheme({
    required StudentEligibilityProfile profile,
    required MotaSchemeModel scheme,
    List<ExistingAward> existingAwards = const [],
  }) {
    final passed = <String>[];
    final failed = <String>[];
    final missingDocs = <String>[];
    final missingFields = <String>[];
    final reasonKeys = <String>[];
    final pendingActions = <String>[];

    int satisfiedCount = 0;
    int totalCount = 0;

    // -------------------------------------------------------------------------
    // 0. Profile Completeness Verification
    // -------------------------------------------------------------------------
    if (profile.socialCategory == null) {
      missingFields.add('Social Category (ST/PVTG)');
    }
    if (profile.familyAnnualIncome == null) {
      missingFields.add('Family Annual Income');
    }
    if (profile.educationLevel == null) {
      missingFields.add('Education Level / Class');
    }

    if (missingFields.isNotEmpty) {
      return SchemeEligibilityEvaluation(
        schemeId: scheme.schemeId,
        schemeName: scheme.schemeName,
        status: EligibilityStatus.incompleteProfile,
        isEligible: false,
        passedCriteria: const [],
        failedCriteria: [
          'Incomplete profile details (${missingFields.join(', ')} missing)',
        ],
        missingDocuments: const [],
        missingProfileFields: missingFields,
        pendingActions: const ['Complete your student profile to evaluate eligibility.'],
        recommendation: 'Please provide complete income, category, and education details in your profile.',
        rulesSatisfied: 0,
        rulesTotal: 4,
        ruleReasonKeys: const ['rule_incomplete_profile'],
      );
    }

    // -------------------------------------------------------------------------
    // 1. One-Scholarship-at-a-Time Verification
    // -------------------------------------------------------------------------
    // A student cannot avail more than one centrally funded scholarship at once.
    ExistingAward? conflictingAward;
    for (final award in existingAwards) {
      final isCurrentOrActive = award.status.toLowerCase() == 'active' ||
          award.status.toLowerCase() == 'sanctioned' ||
          award.status.toLowerCase() == 'disbursed';
      if (isCurrentOrActive && award.schemeId != scheme.schemeId) {
        conflictingAward = award;
        break;
      }
    }

    // -------------------------------------------------------------------------
    // 2. ST / PVTG Community Verification
    // -------------------------------------------------------------------------
    totalCount++;
    final isSt = (profile.socialCategory == 'ST' ||
        profile.socialCategory == 'PVTG' ||
        profile.isScheduledTribe == true);
    if (!isSt) {
      failed.add('Only candidates belonging to recognized Scheduled Tribe (ST) communities are eligible for MoTA schemes.');
      reasonKeys.add('rule_failed_st_community');
    } else {
      satisfiedCount++;
      passed.add('Belongs to recognized Scheduled Tribe (ST) community.');
      reasonKeys.add('rule_passed_st_community');
    }

    // -------------------------------------------------------------------------
    // 3. Income Ceiling Rule
    // -------------------------------------------------------------------------
    totalCount++;
    final double schemeMaxIncome = scheme.incomeLimit.maxFamilyIncome;
    final double income = profile.familyAnnualIncome!;
    if (income > schemeMaxIncome) {
      failed.add(
        'Annual family income (₹${income.toStringAsFixed(0)}) exceeds scheme ceiling of ₹${schemeMaxIncome.toStringAsFixed(0)} (${scheme.incomeLimit.formattedLimit}).',
      );
      reasonKeys.add('rule_failed_income_ceiling');
    } else {
      satisfiedCount++;
      passed.add(
        'Family annual income (₹${income.toStringAsFixed(0)}) is within the eligible limit of ${scheme.incomeLimit.formattedLimit}.',
      );
      reasonKeys.add('rule_passed_income_ceiling');
    }

    // -------------------------------------------------------------------------
    // 4. Scheme-Specific Education Level and Institutional Rules
    // -------------------------------------------------------------------------
    totalCount++;
    final eduLevel = (profile.educationLevel ?? '').trim().toLowerCase();
    final course = (profile.currentClassOrDegree ?? '').trim().toLowerCase();
    final instType = profile.institutionType ?? 'REGULAR_RECOGNIZED';

    switch (scheme.schemeId) {
      case 'pre_matric_st':
      case 'pre_matric':
        final isPreMatric = eduLevel.contains('pre-matric') ||
            eduLevel.contains('pre_matric') ||
            eduLevel.contains('class 9') ||
            eduLevel.contains('class 10') ||
            course.contains('class 9') ||
            course.contains('class 10') ||
            course.contains('ix') ||
            course.contains('x');
        if (!isPreMatric) {
          failed.add('Pre-Matric scholarship is strictly applicable for Class IX and Class X students only.');
          reasonKeys.add('rule_failed_pre_matric_level');
        } else {
          satisfiedCount++;
          passed.add('Enrolled in regular Class IX or Class X.');
          reasonKeys.add('rule_passed_pre_matric_level');
        }
        break;

      case 'post_matric_st':
      case 'post_matric':
        final isPostMatric = eduLevel.contains('post-matric') ||
            eduLevel.contains('post_matric') ||
            eduLevel.contains('higher education') ||
            eduLevel.contains('class 11') ||
            eduLevel.contains('class 12') ||
            eduLevel.contains('college') ||
            eduLevel.contains('degree') ||
            eduLevel.contains('graduation') ||
            eduLevel.contains('polytechnic') ||
            eduLevel.contains('diploma') ||
            eduLevel.contains('iti') ||
            course.contains('b.tech') ||
            course.contains('b.sc') ||
            course.contains('ba') ||
            course.contains('m.tech') ||
            course.contains('ph.d');
        if (!isPostMatric || eduLevel.contains('pre-matric')) {
          failed.add('Post-Matric scholarship is applicable for students pursuing Class XI up to Ph.D in recognized institutions.');
          reasonKeys.add('rule_failed_post_matric_level');
        } else {
          satisfiedCount++;
          passed.add('Enrolled in recognized Post-Matric / Post-Secondary course.');
          reasonKeys.add('rule_passed_post_matric_level');
        }
        break;

      case 'top_class_st':
      case 'top_class':
        final isHigherEdu = eduLevel.contains('higher education') ||
            eduLevel.contains('degree') ||
            eduLevel.contains('post-matric') ||
            course.contains('b.tech') ||
            course.contains('mbbs') ||
            course.contains('mba') ||
            course.contains('ll.b');
        final isPremierInst = instType == 'PREMIER_NOTIFIED' ||
            course.contains('iit') ||
            course.contains('nit') ||
            course.contains('iim') ||
            course.contains('aiims') ||
            course.contains('nlu');
        if (!isHigherEdu) {
          failed.add('Top Class scholarship requires enrollment in notified undergraduate or postgraduate professional degree courses.');
          reasonKeys.add('rule_failed_top_class_course');
        } else {
          passed.add('Enrolled in recognized professional higher education degree.');
          reasonKeys.add('rule_passed_top_class_course');
        }
        if (!isPremierInst && instType != 'PREMIER_NOTIFIED') {
          failed.add('Top Class scheme requires admission in one of the 265 MoTA-notified premier institutions (IITs, NITs, IIMs, AIIMS, NLUs, etc.).');
          reasonKeys.add('rule_failed_premier_inst');
        } else {
          passed.add('Admitted in MoTA-notified Premier Higher Education Institution.');
          reasonKeys.add('rule_passed_premier_inst');
        }
        if (isHigherEdu && (isPremierInst || instType == 'PREMIER_NOTIFIED')) {
          satisfiedCount++;
        }
        break;

      case 'nfst':
        final isResearch = eduLevel.contains('research') ||
            eduLevel.contains('m.phil') ||
            eduLevel.contains('ph.d') ||
            eduLevel.contains('phd') ||
            course.contains('ph.d') ||
            course.contains('mphil') ||
            course.contains('doctorate');
        if (!isResearch) {
          failed.add('National Fellowship (NFST) is strictly for full-time regular M.Phil and Ph.D research scholars.');
          reasonKeys.add('rule_failed_research_enrolment');
        } else {
          passed.add('Registered for regular full-time M.Phil / Ph.D research.');
          reasonKeys.add('rule_passed_research_enrolment');
        }

        // Check NET/JRF qualification if required
        if (scheme.netJrfRequired && !profile.hasNetJrf) {
          failed.add('NFST requires qualification in UGC-NET / CSIR-NET or national level entrance examination.');
          reasonKeys.add('rule_failed_net_jrf');
        } else if (scheme.netJrfRequired) {
          passed.add('UGC/CSIR-NET research qualification confirmed.');
          reasonKeys.add('rule_passed_net_jrf');
        }

        if (isResearch && (!scheme.netJrfRequired || profile.hasNetJrf)) {
          satisfiedCount++;
        }
        break;

      case 'nos':
        final isOverseas = eduLevel.contains('overseas') ||
            eduLevel.contains('abroad') ||
            instType == 'FOREIGN_QS500' ||
            course.contains('abroad') ||
            course.contains('overseas') ||
            profile.hasForeignAdmission;
        if (!isOverseas) {
          failed.add('National Overseas Scholarship (NOS) requires unconditional admission into top 500 QS-ranked foreign universities.');
          reasonKeys.add('rule_failed_foreign_admission');
        } else {
          passed.add('Enrolled / Admitted for Master\'s / Ph.D in Top 500 QS foreign university.');
          reasonKeys.add('rule_passed_foreign_admission');
        }

        // Min qualifying marks
        final minMarks = scheme.minMarksPercentage ?? 55.0;
        if (profile.qualifyingMarksPercentage != null &&
            profile.qualifyingMarksPercentage! < minMarks) {
          failed.add('NOS requires minimum ${minMarks.toStringAsFixed(0)}% marks in qualifying degree.');
          reasonKeys.add('rule_failed_min_marks');
        } else if (profile.qualifyingMarksPercentage != null) {
          passed.add('Qualifying marks criteria satisfied (≥ ${minMarks.toStringAsFixed(0)}%).');
          reasonKeys.add('rule_passed_min_marks');
        }

        // Age restriction
        final maxAge = scheme.maxAge ?? 35;
        if (profile.studentAge != null && profile.studentAge! >= maxAge) {
          failed.add('NOS requires candidate to be below $maxAge years of age on 1st July of application year.');
          reasonKeys.add('rule_failed_age_limit');
        } else if (profile.studentAge != null) {
          passed.add('Age criteria satisfied (< $maxAge years).');
          reasonKeys.add('rule_passed_age_limit');
        }

        final marksOk = profile.qualifyingMarksPercentage == null || profile.qualifyingMarksPercentage! >= minMarks;
        final ageOk = profile.studentAge == null || profile.studentAge! < maxAge;
        if (isOverseas && marksOk && ageOk) {
          satisfiedCount++;
        }
        break;

      default:
        satisfiedCount++;
        break;
    }

    // -------------------------------------------------------------------------
    // 5. Mandatory Document Verification
    // -------------------------------------------------------------------------
    totalCount++;
    final availableDocs = profile.availableDocumentTypes.map((d) => d.toUpperCase()).toSet();
    if (!availableDocs.contains('CASTE_CERTIFICATE') && !availableDocs.contains('ST_CERTIFICATE')) {
      missingDocs.add('Scheduled Tribe (ST) Certificate');
    }
    if (!availableDocs.contains('INCOME_CERTIFICATE')) {
      missingDocs.add('Annual Income Certificate for current financial year');
    }
    if (!availableDocs.contains('AADHAAR') && !profile.hasAadhaar) {
      missingDocs.add('Aadhaar Card (Aadhaar-seeded bank account)');
    }
    if (scheme.schemeId == 'nos' && !availableDocs.contains('PASSPORT')) {
      missingDocs.add('Valid Indian Passport');
    }

    if (missingDocs.isEmpty) {
      satisfiedCount++;
      passed.add('All mandatory verification documents uploaded.');
      reasonKeys.add('rule_passed_documents');
    } else {
      reasonKeys.add('rule_pending_documents');
    }

    // -------------------------------------------------------------------------
    // 6. Conflicting Award Handling (Precedence Rule)
    // -------------------------------------------------------------------------
    if (conflictingAward != null) {
      final conflictMsg =
          'You have an active scholarship award under ${conflictingAward.schemeName} (${conflictingAward.sourceSystem}). Under Ministry of Tribal Affairs rules, a student can avail only one government scholarship at a time. To apply for ${scheme.shortName}, you must first surrender or complete your current award.';
      return SchemeEligibilityEvaluation(
        schemeId: scheme.schemeId,
        schemeName: scheme.schemeName,
        status: EligibilityStatus.blockedByExistingAward,
        isEligible: false,
        passedCriteria: passed,
        failedCriteria: failed,
        missingDocuments: missingDocs,
        missingProfileFields: missingFields,
        pendingActions: [
          'Surrender active award under ${conflictingAward.schemeName}',
          'Obtain No-Objection / Release Certificate from nodal officer'
        ],
        recommendation: conflictMsg,
        rulesSatisfied: satisfiedCount,
        rulesTotal: totalCount,
        ruleReasonKeys: ['rule_blocked_existing_award', ...reasonKeys],
        blockedByAward: conflictingAward,
        conflictExplanation: conflictMsg,
      );
    }

    // -------------------------------------------------------------------------
    // 7. Determine Resulting Status
    // -------------------------------------------------------------------------
    if (failed.isNotEmpty) {
      return SchemeEligibilityEvaluation(
        schemeId: scheme.schemeId,
        schemeName: scheme.schemeName,
        status: EligibilityStatus.ineligible,
        isEligible: false,
        passedCriteria: passed,
        failedCriteria: failed,
        missingDocuments: missingDocs,
        missingProfileFields: missingFields,
        pendingActions: failed,
        recommendation: 'Criteria not met for ${scheme.shortName}. Explore other MoTA schemes.',
        rulesSatisfied: satisfiedCount,
        rulesTotal: totalCount,
        ruleReasonKeys: reasonKeys,
      );
    } else if (missingDocs.isNotEmpty) {
      pendingActions.add('Upload missing documents: ${missingDocs.join(', ')}');
      return SchemeEligibilityEvaluation(
        schemeId: scheme.schemeId,
        schemeName: scheme.schemeName,
        status: EligibilityStatus.conditionallyEligible,
        isEligible: true,
        passedCriteria: passed,
        failedCriteria: const [],
        missingDocuments: missingDocs,
        missingProfileFields: missingFields,
        pendingActions: pendingActions,
        recommendation: 'Eligible! Upload required documents to complete verification.',
        rulesSatisfied: satisfiedCount,
        rulesTotal: totalCount,
        ruleReasonKeys: reasonKeys,
      );
    } else {
      return SchemeEligibilityEvaluation(
        schemeId: scheme.schemeId,
        schemeName: scheme.schemeName,
        status: EligibilityStatus.eligible,
        isEligible: true,
        passedCriteria: passed,
        failedCriteria: const [],
        missingDocuments: const [],
        missingProfileFields: const [],
        pendingActions: ['Proceed to apply via ${scheme.applicationPortal.portalName}'],
        recommendation: 'Fully eligible. You can proceed with the application.',
        rulesSatisfied: satisfiedCount,
        rulesTotal: totalCount,
        ruleReasonKeys: reasonKeys,
      );
    }
  }
}
