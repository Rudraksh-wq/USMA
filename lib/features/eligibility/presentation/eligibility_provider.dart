import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../applications/data/schemes_repository.dart';
import '../../documents/data/documents_repository.dart';
import '../domain/eligibility_engine.dart';
import '../domain/eligibility_result.dart';

class StudentProfileNotifier extends StateNotifier<StudentEligibilityProfile> {
  StudentProfileNotifier()
      : super(const StudentEligibilityProfile(
          socialCategory: 'ST',
          educationLevel: 'Post-Matric',
          currentClassOrDegree: 'Class 12',
          institutionType: 'PREMIER_NOTIFIED',
          familyAnnualIncome: 200000.0,
          hasAadhaar: true,
          hasAadhaarSeededBank: true,
        ));

  void updateSocialCategory(String category) {
    state = StudentEligibilityProfile(
      userId: state.userId,
      isScheduledTribe: category == 'ST' || category == 'PVTG',
      socialCategory: category,
      isPvtg: category == 'PVTG',
      familyAnnualIncome: state.familyAnnualIncome,
      educationLevel: state.educationLevel,
      currentClassOrDegree: state.currentClassOrDegree,
      institutionType: state.institutionType,
      qualifyingMarksPercentage: state.qualifyingMarksPercentage,
      studentAge: state.studentAge,
      hasAadhaar: state.hasAadhaar,
      hasAadhaarSeededBank: state.hasAadhaarSeededBank,
      hasNetJrf: state.hasNetJrf,
      hasForeignAdmission: state.hasForeignAdmission,
      isDivyang: state.isDivyang,
      stateDomicile: state.stateDomicile,
      availableDocumentTypes: state.availableDocumentTypes,
    );
  }

  void updateEducationLevel(String level) {
    state = StudentEligibilityProfile(
      userId: state.userId,
      isScheduledTribe: state.isScheduledTribe,
      socialCategory: state.socialCategory,
      isPvtg: state.isPvtg,
      familyAnnualIncome: state.familyAnnualIncome,
      educationLevel: level,
      currentClassOrDegree: level,
      institutionType: state.institutionType,
      qualifyingMarksPercentage: state.qualifyingMarksPercentage,
      studentAge: state.studentAge,
      hasAadhaar: state.hasAadhaar,
      hasAadhaarSeededBank: state.hasAadhaarSeededBank,
      hasNetJrf: state.hasNetJrf,
      hasForeignAdmission: state.hasForeignAdmission,
      isDivyang: state.isDivyang,
      stateDomicile: state.stateDomicile,
      availableDocumentTypes: state.availableDocumentTypes,
    );
  }

  void updateInstitutionType(String instType) {
    state = StudentEligibilityProfile(
      userId: state.userId,
      isScheduledTribe: state.isScheduledTribe,
      socialCategory: state.socialCategory,
      isPvtg: state.isPvtg,
      familyAnnualIncome: state.familyAnnualIncome,
      educationLevel: state.educationLevel,
      currentClassOrDegree: state.currentClassOrDegree,
      institutionType: instType,
      qualifyingMarksPercentage: state.qualifyingMarksPercentage,
      studentAge: state.studentAge,
      hasAadhaar: state.hasAadhaar,
      hasAadhaarSeededBank: state.hasAadhaarSeededBank,
      hasNetJrf: state.hasNetJrf,
      hasForeignAdmission: state.hasForeignAdmission,
      isDivyang: state.isDivyang,
      stateDomicile: state.stateDomicile,
      availableDocumentTypes: state.availableDocumentTypes,
    );
  }

  void updateIncome(double income) {
    state = StudentEligibilityProfile(
      userId: state.userId,
      isScheduledTribe: state.isScheduledTribe,
      socialCategory: state.socialCategory,
      isPvtg: state.isPvtg,
      familyAnnualIncome: income,
      educationLevel: state.educationLevel,
      currentClassOrDegree: state.currentClassOrDegree,
      institutionType: state.institutionType,
      qualifyingMarksPercentage: state.qualifyingMarksPercentage,
      studentAge: state.studentAge,
      hasAadhaar: state.hasAadhaar,
      hasAadhaarSeededBank: state.hasAadhaarSeededBank,
      hasNetJrf: state.hasNetJrf,
      hasForeignAdmission: state.hasForeignAdmission,
      isDivyang: state.isDivyang,
      stateDomicile: state.stateDomicile,
      availableDocumentTypes: state.availableDocumentTypes,
    );
  }

  void syncUploadedDocuments(List<String> docTypes) {
    state = StudentEligibilityProfile(
      userId: state.userId,
      isScheduledTribe: state.isScheduledTribe,
      socialCategory: state.socialCategory,
      isPvtg: state.isPvtg,
      familyAnnualIncome: state.familyAnnualIncome,
      educationLevel: state.educationLevel,
      currentClassOrDegree: state.currentClassOrDegree,
      institutionType: state.institutionType,
      qualifyingMarksPercentage: state.qualifyingMarksPercentage,
      studentAge: state.studentAge,
      hasAadhaar: state.hasAadhaar,
      hasAadhaarSeededBank: state.hasAadhaarSeededBank,
      hasNetJrf: state.hasNetJrf,
      hasForeignAdmission: state.hasForeignAdmission,
      isDivyang: state.isDivyang,
      stateDomicile: state.stateDomicile,
      availableDocumentTypes: docTypes,
    );
  }
}

final studentProfileProvider =
    StateNotifierProvider<StudentProfileNotifier, StudentEligibilityProfile>(
        (ref) => StudentProfileNotifier());

final existingAwardsProvider =
    StateProvider<List<ExistingAward>>((ref) => const <ExistingAward>[]);

final eligibilityEvaluationsProvider =
    Provider<List<SchemeEligibilityEvaluation>>((ref) {
  final profile = ref.watch(studentProfileProvider);
  final awards = ref.watch(existingAwardsProvider);
  final schemesAsync = ref.watch(motaSchemesListProvider);
  final docsAsync = ref.watch(userDocumentsProvider);

  // Sync available docs into profile if available
  final docs = docsAsync.asData?.value ?? const [];
  final docTypes = docs.map((d) => d.type).toList();
  final effectiveProfile = StudentEligibilityProfile(
    userId: profile.userId,
    isScheduledTribe: profile.isScheduledTribe,
    socialCategory: profile.socialCategory,
    isPvtg: profile.isPvtg,
    familyAnnualIncome: profile.familyAnnualIncome,
    educationLevel: profile.educationLevel,
    currentClassOrDegree: profile.currentClassOrDegree,
    institutionType: profile.institutionType,
    qualifyingMarksPercentage: profile.qualifyingMarksPercentage,
    studentAge: profile.studentAge,
    hasAadhaar: profile.hasAadhaar,
    hasAadhaarSeededBank: profile.hasAadhaarSeededBank,
    hasNetJrf: profile.hasNetJrf,
    hasForeignAdmission: profile.hasForeignAdmission,
    isDivyang: profile.isDivyang,
    stateDomicile: profile.stateDomicile,
    availableDocumentTypes: docTypes.isNotEmpty ? docTypes : profile.availableDocumentTypes,
  );

  final schemes = schemesAsync.value ?? const [];
  if (schemes.isEmpty) return const [];

  return MoTAEligibilityEngine.evaluate(
    effectiveProfile,
    awards,
    schemes: schemes,
  );
});
