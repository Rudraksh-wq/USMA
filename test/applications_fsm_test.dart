import 'package:flutter_test/flutter_test.dart';
import 'package:usma/features/applications/domain/application_fsm.dart';

void main() {
  group('Application Finite State Machine Tests', () {
    test('Student can submit Draft and resubmit Returned', () {
      final sub = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.draft,
        toStatus: ApplicationState.submitted,
        role: UserRole.student,
      );
      expect(sub.isAllowed, isTrue);

      final resub = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.returned,
        toStatus: ApplicationState.resubmitted,
        role: UserRole.student,
      );
      expect(resub.isAllowed, isTrue);
    });

    test('Student cannot self-sanction or self-verify (Security check)', () {
      final sanctionAttack = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.submitted,
        toStatus: ApplicationState.sanctioned,
        role: UserRole.student,
      );
      expect(sanctionAttack.isAllowed, isFalse);
      expect(sanctionAttack.errorReason, contains('Students can only'));

      final verifyAttack = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.submitted,
        toStatus: ApplicationState.instituteVerified,
        role: UserRole.student,
      );
      expect(verifyAttack.isAllowed, isFalse);
    });

    test('Institution Verifier can verify, return, or reject Submitted application', () {
      final verify = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.submitted,
        toStatus: ApplicationState.instituteVerified,
        role: UserRole.institutionVerifier,
      );
      expect(verify.isAllowed, isTrue);

      final ret = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.submitted,
        toStatus: ApplicationState.returned,
        role: UserRole.institutionVerifier,
      );
      expect(ret.isAllowed, isTrue);
    });

    test('Institution Verifier cannot sanction directly', () {
      final sanction = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.submitted,
        toStatus: ApplicationState.sanctioned,
        role: UserRole.institutionVerifier,
      );
      expect(sanction.isAllowed, isFalse);
    });

    test('State Officer transitions InstituteVerified to StateApproved', () {
      final approve = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.instituteVerified,
        toStatus: ApplicationState.stateApproved,
        role: UserRole.stateOfficer,
      );
      expect(approve.isAllowed, isTrue);
    });

    test('Ministry Officer can sanction StateApproved application', () {
      final sanction = ApplicationStateMachine.canTransition(
        fromStatus: ApplicationState.stateApproved,
        toStatus: ApplicationState.sanctioned,
        role: UserRole.ministryOfficer,
      );
      expect(sanction.isAllowed, isTrue);
    });

    test('nextValidStates returns accurate options for each role', () {
      final studentOptions = ApplicationStateMachine.nextValidStates(
        currentStatus: ApplicationState.draft,
        role: UserRole.student,
      );
      expect(studentOptions, equals([ApplicationState.submitted]));

      final verifierOptions = ApplicationStateMachine.nextValidStates(
        currentStatus: ApplicationState.submitted,
        role: UserRole.institutionVerifier,
      );
      expect(
        verifierOptions,
        containsAll([
          ApplicationState.instituteVerified,
          ApplicationState.returned,
          ApplicationState.rejected,
        ]),
      );
    });
  });
}
