class IncomeLimitInfo {
  final double maxFamilyIncome;
  final String formattedLimit;
  final String description;
  final String relaxationNote;

  const IncomeLimitInfo({
    required this.maxFamilyIncome,
    required this.formattedLimit,
    required this.description,
    required this.relaxationNote,
  });

  factory IncomeLimitInfo.fromMap(Map<String, dynamic> map) {
    return IncomeLimitInfo(
      maxFamilyIncome: (map['maxFamilyIncome'] as num?)?.toDouble() ?? 0.0,
      formattedLimit: map['formattedLimit']?.toString() ?? '₹0',
      description: map['description']?.toString() ?? '',
      relaxationNote: map['relaxationNote']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'maxFamilyIncome': maxFamilyIncome,
        'formattedLimit': formattedLimit,
        'description': description,
        'relaxationNote': relaxationNote,
      };
}

class ApplicationPortalInfo {
  final String portalName;
  final String portalUrl;
  final String routingType;
  final String routingInstructions;

  const ApplicationPortalInfo({
    required this.portalName,
    required this.portalUrl,
    required this.routingType,
    required this.routingInstructions,
  });

  factory ApplicationPortalInfo.fromMap(Map<String, dynamic> map) {
    return ApplicationPortalInfo(
      portalName: map['portalName']?.toString() ?? '',
      portalUrl: map['portalUrl']?.toString() ?? '',
      routingType: map['routingType']?.toString() ?? 'PORTAL',
      routingInstructions: map['routingInstructions']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'portalName': portalName,
        'portalUrl': portalUrl,
        'routingType': routingType,
        'routingInstructions': routingInstructions,
      };
}

class VerificationStageInfo {
  final int order;
  final String stageName;
  final String authority;
  final int slaDays;
  final String description;

  const VerificationStageInfo({
    required this.order,
    required this.stageName,
    required this.authority,
    required this.slaDays,
    required this.description,
  });

  factory VerificationStageInfo.fromMap(Map<String, dynamic> map) {
    return VerificationStageInfo(
      order: (map['order'] as num?)?.toInt() ?? 1,
      stageName: map['stageName']?.toString() ?? '',
      authority: map['authority']?.toString() ?? '',
      slaDays: (map['slaDays'] as num?)?.toInt() ?? 15,
      description: map['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'order': order,
        'stageName': stageName,
        'authority': authority,
        'slaDays': slaDays,
        'description': description,
      };
}

class ScholarshipBenefitsInfo {
  final double annualMaxEstimatedAmount;
  final String feeCoverage;
  final String maintenanceAllowance;
  final String otherAllowances;
  final String frequency;
  final String fundSharingRatio;

  const ScholarshipBenefitsInfo({
    required this.annualMaxEstimatedAmount,
    required this.feeCoverage,
    required this.maintenanceAllowance,
    required this.otherAllowances,
    required this.frequency,
    required this.fundSharingRatio,
  });

  factory ScholarshipBenefitsInfo.fromMap(Map<String, dynamic> map) {
    return ScholarshipBenefitsInfo(
      annualMaxEstimatedAmount:
          (map['annualMaxEstimatedAmount'] as num?)?.toDouble() ?? 0.0,
      feeCoverage: map['feeCoverage']?.toString() ?? '',
      maintenanceAllowance: map['maintenanceAllowance']?.toString() ?? '',
      otherAllowances: map['otherAllowances']?.toString() ?? '',
      frequency: map['frequency']?.toString() ?? 'Per Annum',
      fundSharingRatio: map['fundSharingRatio']?.toString() ?? '100% Central',
    );
  }

  Map<String, dynamic> toMap() => {
        'annualMaxEstimatedAmount': annualMaxEstimatedAmount,
        'feeCoverage': feeCoverage,
        'maintenanceAllowance': maintenanceAllowance,
        'otherAllowances': otherAllowances,
        'frequency': frequency,
        'fundSharingRatio': fundSharingRatio,
      };
}

class ImportantDatesInfo {
  final String academicYear;
  final String applicationOpenDate;
  final String applicationClosingDate;
  final String verificationDeadline;

  const ImportantDatesInfo({
    required this.academicYear,
    required this.applicationOpenDate,
    required this.applicationClosingDate,
    required this.verificationDeadline,
  });

  factory ImportantDatesInfo.fromMap(Map<String, dynamic> map) {
    return ImportantDatesInfo(
      academicYear: map['academicYear']?.toString() ?? '2026-2027',
      applicationOpenDate: map['applicationOpenDate']?.toString() ??
          'Information not available / requires verification',
      applicationClosingDate: map['applicationClosingDate']?.toString() ??
          'Information not available / requires verification',
      verificationDeadline: map['verificationDeadline']?.toString() ??
          'Information not available / requires verification',
    );
  }

  Map<String, dynamic> toMap() => {
        'academicYear': academicYear,
        'applicationOpenDate': applicationOpenDate,
        'applicationClosingDate': applicationClosingDate,
        'verificationDeadline': verificationDeadline,
      };
}

class OfficialGuidelinesInfo {
  final String officialSource;
  final String sourceUrl;
  final String guidelineDocumentName;
  final String lastVerifiedDate;

  const OfficialGuidelinesInfo({
    this.officialSource = 'Source: Ministry of Tribal Affairs',
    this.sourceUrl = 'https://tribal.nic.in/ScholarshiP.aspx',
    required this.guidelineDocumentName,
    required this.lastVerifiedDate,
  });

  factory OfficialGuidelinesInfo.fromMap(Map<String, dynamic> map) {
    return OfficialGuidelinesInfo(
      officialSource: map['officialSource']?.toString() ??
          'Source: Ministry of Tribal Affairs',
      sourceUrl: map['sourceUrl']?.toString() ??
          'https://tribal.nic.in/ScholarshiP.aspx',
      guidelineDocumentName: map['guidelineDocumentName']?.toString() ?? '',
      lastVerifiedDate: map['lastVerifiedDate']?.toString() ?? '2026-03-20',
    );
  }

  Map<String, dynamic> toMap() => {
        'officialSource': officialSource,
        'sourceUrl': sourceUrl,
        'guidelineDocumentName': guidelineDocumentName,
        'lastVerifiedDate': lastVerifiedDate,
      };
}

class SchemeFaqItem {
  final String question;
  final String answer;

  const SchemeFaqItem({required this.question, required this.answer});

  factory SchemeFaqItem.fromMap(Map<String, dynamic> map) {
    return SchemeFaqItem(
      question: map['question']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'question': question,
        'answer': answer,
      };
}

class GrievanceInformation {
  final String portalUrl;
  final String nodalEmail;
  final String helplineNumber;
  final String division;

  const GrievanceInformation({
    required this.portalUrl,
    required this.nodalEmail,
    required this.helplineNumber,
    required this.division,
  });

  factory GrievanceInformation.fromMap(Map<String, dynamic> map) {
    return GrievanceInformation(
      portalUrl: map['portalUrl']?.toString() ?? 'https://tribal.nic.in/Grievance/',
      nodalEmail: map['nodalEmail']?.toString() ?? 'tribal-scholarship@gov.in',
      helplineNumber: map['helplineNumber']?.toString() ?? '0120-6619540',
      division: map['division']?.toString() ?? 'Ministry of Tribal Affairs',
    );
  }

  Map<String, dynamic> toMap() => {
        'portalUrl': portalUrl,
        'nodalEmail': nodalEmail,
        'helplineNumber': helplineNumber,
        'division': division,
      };
}

class MotaSchemeModel {
  final String schemeId;
  final String schemeName;
  final String shortName;
  final String description;
  final String targetEducationLevel;
  final List<String> targetEducationLevels;
  final String whoCanApply;
  final List<String> eligibilityCriteria;
  final IncomeLimitInfo incomeLimit;
  final List<String> requiredDocuments;
  final ApplicationPortalInfo applicationPortal;
  final List<VerificationStageInfo> verificationStages;
  final ScholarshipBenefitsInfo scholarshipBenefits;
  final ImportantDatesInfo importantDates;
  final OfficialGuidelinesInfo officialGuidelines;
  final List<SchemeFaqItem> faq;
  final GrievanceInformation grievanceInformation;
  final String sourceSystem; // 'NSP', 'SFMP', 'NOS'
  final String domicileRequirement;
  final String disabilityProvisions;
  final String pvtgProvisions;
  final double? minMarksPercentage;
  final int? maxAge;
  final bool netJrfRequired;
  final bool admissionAbroadRequired;

  const MotaSchemeModel({
    required this.schemeId,
    required this.schemeName,
    required this.shortName,
    required this.description,
    required this.targetEducationLevel,
    required this.targetEducationLevels,
    required this.whoCanApply,
    required this.eligibilityCriteria,
    required this.incomeLimit,
    required this.requiredDocuments,
    required this.applicationPortal,
    required this.verificationStages,
    required this.scholarshipBenefits,
    required this.importantDates,
    required this.officialGuidelines,
    required this.faq,
    required this.grievanceInformation,
    this.sourceSystem = 'NSP',
    this.domicileRequirement = 'VERIFY: Resident ST of respective State/UT',
    this.disabilityProvisions = 'VERIFY: Provisions as per MoTA guidelines',
    this.pvtgProvisions = 'VERIFY: Priority coverage for PVTG students',
    this.minMarksPercentage,
    this.maxAge,
    this.netJrfRequired = false,
    this.admissionAbroadRequired = false,
  });

  factory MotaSchemeModel.fromMap(Map<String, dynamic> map) {
    final levels = List<String>.from(
      map['targetEducationLevels'] ??
          (map['educationLevels'] is List ? map['educationLevels'] : const <String>[]),
    );
    final primaryLevel = map['targetEducationLevel']?.toString() ??
        map['educationLevel']?.toString() ??
        (levels.isNotEmpty ? levels.first : 'Post-Matric');

    final incomeMap = map['incomeLimit'] is Map
        ? Map<String, dynamic>.from(map['incomeLimit'] as Map)
        : <String, dynamic>{
            'maxFamilyIncome': (map['maxFamilyIncome'] as num?)?.toDouble() ?? 250000.0,
            'formattedLimit':
                '₹${((map['maxFamilyIncome'] as num?)?.toDouble() ?? 250000.0).toStringAsFixed(0)}',
            'description': 'Family income ceiling',
            'relaxationNote': '',
          };

    final portalMap = map['applicationPortal'] is Map
        ? Map<String, dynamic>.from(map['applicationPortal'] as Map)
        : <String, dynamic>{
            'portalName': 'MoTA / State Portal',
            'portalUrl': 'https://tribal.nic.in',
            'routingType': 'PORTAL',
            'routingInstructions': 'Apply via official portal',
          };

    final benefitsMap = map['scholarshipBenefits'] is Map
        ? Map<String, dynamic>.from(map['scholarshipBenefits'] as Map)
        : <String, dynamic>{
            'annualMaxEstimatedAmount':
                (map['maxAmount'] as num?)?.toDouble() ?? 0.0,
            'feeCoverage': 'As per norms',
            'maintenanceAllowance': 'As per norms',
            'otherAllowances': '',
            'frequency': map['frequency']?.toString() ?? 'Per Annum',
            'fundSharingRatio': '100% Central / Shared',
          };

    final datesMap = map['importantDates'] is Map
        ? Map<String, dynamic>.from(map['importantDates'] as Map)
        : <String, dynamic>{
            'academicYear': '2026-2027',
            'applicationOpenDate': 'Information not available / requires verification',
            'applicationClosingDate': 'Information not available / requires verification',
            'verificationDeadline': 'Information not available / requires verification',
          };

    final guidelinesMap = map['officialGuidelines'] is Map
        ? Map<String, dynamic>.from(map['officialGuidelines'] as Map)
        : <String, dynamic>{
            'officialSource': 'Source: Ministry of Tribal Affairs',
            'sourceUrl': 'https://tribal.nic.in/ScholarshiP.aspx',
            'guidelineDocumentName': map['schemeName'] ?? map['title'] ?? '',
            'lastVerifiedDate': '2026-03-20',
          };

    final stagesList = map['verificationStages'] is List
        ? (map['verificationStages'] as List)
            .map((e) => VerificationStageInfo.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <VerificationStageInfo>[];

    final faqList = map['faq'] is List
        ? (map['faq'] as List)
            .map((e) => SchemeFaqItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <SchemeFaqItem>[];

    final grievanceMap = map['grievanceInformation'] is Map
        ? Map<String, dynamic>.from(map['grievanceInformation'] as Map)
        : <String, dynamic>{
            'portalUrl': 'https://tribal.nic.in/Grievance/',
            'nodalEmail': 'tribal-scholarship@gov.in',
            'helplineNumber': '0120-6619540',
            'division': 'Ministry of Tribal Affairs',
          };

    return MotaSchemeModel(
      schemeId: map['schemeId']?.toString() ?? map['id']?.toString() ?? '',
      schemeName: map['schemeName']?.toString() ?? map['title']?.toString() ?? '',
      shortName: map['shortName']?.toString() ?? map['shortTitle']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      targetEducationLevel: primaryLevel,
      targetEducationLevels: levels.isEmpty ? [primaryLevel] : levels,
      whoCanApply: map['whoCanApply']?.toString() ??
          'Scheduled Tribe (ST) students meeting specified academic requirements.',
      eligibilityCriteria: List<String>.from(
        map['eligibilityCriteria'] ?? const <String>[],
      ),
      incomeLimit: IncomeLimitInfo.fromMap(incomeMap),
      requiredDocuments: List<String>.from(
        map['requiredDocuments'] ?? const <String>[],
      ),
      applicationPortal: ApplicationPortalInfo.fromMap(portalMap),
      verificationStages: stagesList,
      scholarshipBenefits: ScholarshipBenefitsInfo.fromMap(benefitsMap),
      importantDates: ImportantDatesInfo.fromMap(datesMap),
      officialGuidelines: OfficialGuidelinesInfo.fromMap(guidelinesMap),
      faq: faqList,
      grievanceInformation: GrievanceInformation.fromMap(grievanceMap),
      sourceSystem: map['sourceSystem']?.toString() ?? 'NSP',
      domicileRequirement: map['domicileRequirement']?.toString() ??
          'VERIFY: Resident ST of respective State/UT',
      disabilityProvisions: map['disabilityProvisions']?.toString() ??
          'VERIFY: Provisions as per MoTA guidelines',
      pvtgProvisions: map['pvtgProvisions']?.toString() ??
          'VERIFY: Priority coverage for PVTG students',
      minMarksPercentage: (map['minMarksPercentage'] as num?)?.toDouble(),
      maxAge: (map['maxAge'] as num?)?.toInt(),
      netJrfRequired: map['netJrfRequired'] == true,
      admissionAbroadRequired: map['admissionAbroadRequired'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'schemeId': schemeId,
        'schemeName': schemeName,
        'shortName': shortName,
        'description': description,
        'targetEducationLevel': targetEducationLevel,
        'targetEducationLevels': targetEducationLevels,
        'whoCanApply': whoCanApply,
        'eligibilityCriteria': eligibilityCriteria,
        'incomeLimit': incomeLimit.toMap(),
        'requiredDocuments': requiredDocuments,
        'applicationPortal': applicationPortal.toMap(),
        'verificationStages': verificationStages.map((e) => e.toMap()).toList(),
        'scholarshipBenefits': scholarshipBenefits.toMap(),
        'importantDates': importantDates.toMap(),
        'officialGuidelines': officialGuidelines.toMap(),
        'faq': faq.map((e) => e.toMap()).toList(),
        'grievanceInformation': grievanceInformation.toMap(),
        'sourceSystem': sourceSystem,
        'domicileRequirement': domicileRequirement,
        'disabilityProvisions': disabilityProvisions,
        'pvtgProvisions': pvtgProvisions,
        'minMarksPercentage': minMarksPercentage,
        'maxAge': maxAge,
        'netJrfRequired': netJrfRequired,
        'admissionAbroadRequired': admissionAbroadRequired,
      };
}
