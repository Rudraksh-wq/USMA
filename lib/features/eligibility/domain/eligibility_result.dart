enum EligibilityStatus {
  eligible,
  conditionallyEligible,
  ineligible,
  needsInfo,
  incompleteProfile,
  blockedByExistingAward,
}

class ExistingAward {
  final String schemeId;
  final String schemeName;
  final String academicYear;
  final String status; // 'Active', 'Sanctioned', 'Disbursed'
  final String sourceSystem; // 'NSP', 'SFMP', 'NOS'

  const ExistingAward({
    required this.schemeId,
    required this.schemeName,
    required this.academicYear,
    required this.status,
    required this.sourceSystem,
  });

  Map<String, dynamic> toMap() => {
        'schemeId': schemeId,
        'schemeName': schemeName,
        'academicYear': academicYear,
        'status': status,
        'sourceSystem': sourceSystem,
      };

  factory ExistingAward.fromMap(Map<String, dynamic> map) => ExistingAward(
        schemeId: map['schemeId']?.toString() ?? '',
        schemeName: map['schemeName']?.toString() ?? '',
        academicYear: map['academicYear']?.toString() ?? '2026-2027',
        status: map['status']?.toString() ?? 'Active',
        sourceSystem: map['sourceSystem']?.toString() ?? 'NSP',
      );
}

class SchemeEligibilityEvaluation {
  final String schemeId;
  final String schemeName;
  final EligibilityStatus status;
  final bool isEligible;
  final List<String> passedCriteria;
  final List<String> failedCriteria;
  final List<String> missingDocuments;
  final List<String> missingProfileFields;
  final List<String> pendingActions;
  final String recommendation;
  final int rulesSatisfied;
  final int rulesTotal;
  final List<String> ruleReasonKeys;
  final ExistingAward? blockedByAward;
  final String? conflictExplanation;

  const SchemeEligibilityEvaluation({
    required this.schemeId,
    required this.schemeName,
    required this.status,
    required this.isEligible,
    required this.passedCriteria,
    required this.failedCriteria,
    required this.missingDocuments,
    this.missingProfileFields = const [],
    required this.pendingActions,
    required this.recommendation,
    this.rulesSatisfied = 0,
    this.rulesTotal = 0,
    this.ruleReasonKeys = const [],
    this.blockedByAward,
    this.conflictExplanation,
  });

  String get statusBadgeText {
    switch (status) {
      case EligibilityStatus.eligible:
        return 'Eligible';
      case EligibilityStatus.conditionallyEligible:
        return 'Conditionally Eligible';
      case EligibilityStatus.ineligible:
        return 'Not Eligible';
      case EligibilityStatus.needsInfo:
      case EligibilityStatus.incompleteProfile:
        return 'Needs Info';
      case EligibilityStatus.blockedByExistingAward:
        return 'Blocked by Existing Award';
    }
  }

  String get ruleScoreText => '$rulesSatisfied/$rulesTotal rules satisfied';
}

class StudentEligibilityProfile {
  final String? userId;
  final bool? isScheduledTribe;
  final String? socialCategory; // 'ST', 'PVTG', 'SC', 'OBC', 'GEN'
  final bool isPvtg;
  final double? familyAnnualIncome;
  final String? educationLevel; // 'Pre-Matric', 'Post-Matric', 'Higher Education', 'Research', 'Overseas'
  final String? currentClassOrDegree; // 'Class 9', 'Class 10', 'B.Tech', 'MBBS', 'M.Phil', 'Ph.D', etc.
  final String? institutionType; // 'PREMIER_NOTIFIED', 'REGULAR_RECOGNIZED', 'FOREIGN_QS500', 'OTHER'
  final double? qualifyingMarksPercentage;
  final int? studentAge;
  final bool hasAadhaar;
  final bool hasAadhaarSeededBank;
  final bool hasNetJrf;
  final bool hasForeignAdmission;
  final bool isDivyang;
  final String? stateDomicile;
  final List<String> availableDocumentTypes; // 'CASTE_CERTIFICATE', 'INCOME_CERTIFICATE', 'AADHAAR', etc.

  const StudentEligibilityProfile({
    this.userId,
    this.isScheduledTribe = true,
    this.socialCategory = 'ST',
    this.isPvtg = false,
    this.familyAnnualIncome,
    this.educationLevel,
    this.currentClassOrDegree,
    this.institutionType,
    this.qualifyingMarksPercentage,
    this.studentAge,
    this.hasAadhaar = true,
    this.hasAadhaarSeededBank = true,
    this.hasNetJrf = false,
    this.hasForeignAdmission = false,
    this.isDivyang = false,
    this.stateDomicile,
    this.availableDocumentTypes = const [],
  });

  bool get hasCompleteBasicProfile =>
      socialCategory != null &&
      familyAnnualIncome != null &&
      educationLevel != null;
}
