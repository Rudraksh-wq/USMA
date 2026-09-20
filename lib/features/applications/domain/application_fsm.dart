/// Roles participating in application state transitions.
enum UserRole {
  student,
  institutionVerifier,
  stateOfficer,
  ministryOfficer,
  admin,
}

/// Strict Canonical States matching firestore.rules
class ApplicationState {
  static const String draft = 'Draft';
  static const String submitted = 'Submitted';
  static const String instituteVerified = 'InstituteVerified';
  static const String stateApproved = 'StateApproved';
  static const String sanctioned = 'Sanctioned';
  static const String returned = 'Returned';
  static const String resubmitted = 'Resubmitted';
  static const String rejected = 'Rejected';

  static const List<String> allStates = [
    draft,
    submitted,
    instituteVerified,
    stateApproved,
    sanctioned,
    returned,
    resubmitted,
    rejected,
  ];
}

/// Result of evaluating a state transition.
class TransitionResult {
  final bool isAllowed;
  final String? errorReason;

  const TransitionResult.allowed()
      : isAllowed = true,
        errorReason = null;

  const TransitionResult.denied(this.errorReason) : isAllowed = false;
}

/// Pure-Dart Finite State Machine matching USMA firestore.rules.
class ApplicationStateMachine {
  /// Check whether a transition from [fromStatus] to [toStatus] is permitted for [role].
  static TransitionResult canTransition({
    required String fromStatus,
    required String toStatus,
    required UserRole role,
  }) {
    if (fromStatus == toStatus) {
      return const TransitionResult.allowed();
    }

    switch (role) {
      case UserRole.student:
        if (fromStatus == ApplicationState.draft &&
            toStatus == ApplicationState.submitted) {
          return const TransitionResult.allowed();
        }
        if (fromStatus == ApplicationState.returned &&
            toStatus == ApplicationState.resubmitted) {
          return const TransitionResult.allowed();
        }
        return TransitionResult.denied(
          'Students can only transition Draft -> Submitted or Returned -> Resubmitted.',
        );

      case UserRole.institutionVerifier:
        if (fromStatus == ApplicationState.submitted ||
            fromStatus == ApplicationState.resubmitted) {
          if (toStatus == ApplicationState.instituteVerified ||
              toStatus == ApplicationState.returned ||
              toStatus == ApplicationState.rejected) {
            return const TransitionResult.allowed();
          }
        }
        return TransitionResult.denied(
          'Institution verifiers can only move Submitted/Resubmitted to InstituteVerified, Returned, or Rejected.',
        );

      case UserRole.stateOfficer:
        if (fromStatus == ApplicationState.instituteVerified) {
          if (toStatus == ApplicationState.stateApproved ||
              toStatus == ApplicationState.returned ||
              toStatus == ApplicationState.rejected) {
            return const TransitionResult.allowed();
          }
        }
        return TransitionResult.denied(
          'State officers can only move InstituteVerified to StateApproved, Returned, or Rejected.',
        );

      case UserRole.ministryOfficer:
        if (fromStatus == ApplicationState.stateApproved) {
          if (toStatus == ApplicationState.sanctioned ||
              toStatus == ApplicationState.rejected) {
            return const TransitionResult.allowed();
          }
        }
        return TransitionResult.denied(
          'Ministry officers can only sanction or reject StateApproved applications.',
        );

      case UserRole.admin:
        // Admins can execute emergency administrative overrides
        return const TransitionResult.allowed();
    }
  }

  /// Returns valid next states for given state and role.
  static List<String> nextValidStates({
    required String currentStatus,
    required UserRole role,
  }) {
    return ApplicationState.allStates.where((candidate) {
      return canTransition(
        fromStatus: currentStatus,
        toStatus: candidate,
        role: role,
      ).isAllowed && candidate != currentStatus;
    }).toList();
  }
}
