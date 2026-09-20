import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failures.dart';
import '../domain/models/user_model.dart';

abstract class IAuthRepository {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<void> sendOtp({required String phoneNumber});
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<void> completeEkyc({
    required String aadhaarNumber,
    required String tribe,
    required double income,
  });
  Future<void> startSimulatedSession();
  Future<void> signOut();
  Future<void> updateProfile(UserModel user);
}

/// SIMULATED session used only when DATA_MODE=demo.
UserModel simulatedDemoStudent({required String phoneNumber}) {
  return UserModel(
    id: 'sim_session_${phoneNumber.hashCode.abs()}',
    name: 'Sunita Marandi',
    email: 'student@example.org',
    phoneNumber: phoneNumber,
    aadhaarLast4: '4829',
    tribe: 'Santhal',
    state: 'Odisha',
    district: 'Mayurbhanj',
    familyAnnualIncome: 180000,
    isAadhaarLinked: true,
    isDigiLockerLinked: true,
    bankAccountLast4: '3819',
    bankIfsc: 'SBIN0001234',
    apaarId: 'APAAR-2026-9938-11',
    educationLevel: 'post_matric',
    isScheduledTribe: true,
  );
}

class MockAuthRepository implements IAuthRepository {
  MockAuthRepository();

  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _cachedUser;
  String? _pendingPhone;

  /// SIMULATED OTP accepted in demo mode only.
  static const simulatedOtp = '123456';

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Future<void> sendOtp({required String phoneNumber}) async {
    if (phoneNumber.replaceAll(RegExp(r'\D'), '').length < 10) {
      throw const ValidationFailure('Enter a valid 10-digit mobile number.');
    }
    _pendingPhone = phoneNumber;
  }

  @override
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    if (smsCode != simulatedOtp) {
      throw const AuthFailure(
        'Invalid OTP. In demo mode use the SIMULATED code 123456.',
      );
    }
    final phone = _pendingPhone ?? '+91';
    _cachedUser = simulatedDemoStudent(phoneNumber: phone);
    _controller.add(_cachedUser);
    return _cachedUser!;
  }

  @override
  Future<void> completeEkyc({
    required String aadhaarNumber,
    required String tribe,
    required double income,
  }) async {
    final user = _cachedUser;
    if (user == null) {
      throw const AuthFailure('Sign in before completing e-KYC.');
    }
    if (aadhaarNumber.replaceAll(RegExp(r'\D'), '').length != 12) {
      throw const ValidationFailure('Aadhaar number must be 12 digits.');
    }
    _cachedUser = user.copyWith(
      aadhaarLast4: aadhaarNumber.substring(aadhaarNumber.length - 4),
      tribe: tribe,
      familyAnnualIncome: income,
      isAadhaarLinked: true,
    );
    _controller.add(_cachedUser);
  }

  @override
  Future<void> startSimulatedSession() async {
    _cachedUser = simulatedDemoStudent(phoneNumber: '+919876543210');
    _controller.add(_cachedUser);
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    _controller.add(null);
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    _cachedUser = user;
    _controller.add(_cachedUser);
  }
}

class LiveAuthRepository implements IAuthRepository {
  LiveAuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  UserModel? _cachedUser;

  @override
  Stream<UserModel?> get authStateChanges async* {
    yield* _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }
      try {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists && doc.data() != null) {
          _cachedUser = UserModel.fromMap(doc.data()!, doc.id);
        } else {
          _cachedUser = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Student',
            email: firebaseUser.email ?? '',
            phoneNumber: firebaseUser.phoneNumber ?? '',
            aadhaarLast4: 'XXXX',
            tribe: '',
            state: '',
            district: '',
            familyAnnualIncome: 0,
          );
        }
        return _cachedUser;
      } catch (e) {
        throw ErrorMapper.map(e);
      }
    });
  }

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Future<void> sendOtp({required String phoneNumber}) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          throw ErrorMapper.map(e);
        },
        codeSent: (_, __) {},
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw const AuthFailure('Sign-in did not return a user.');
      }
      _cachedUser = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Student',
        email: firebaseUser.email ?? '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
        aadhaarLast4: 'XXXX',
        tribe: '',
        state: '',
        district: '',
        familyAnnualIncome: 0,
      );
      return _cachedUser!;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> completeEkyc({
    required String aadhaarNumber,
    required String tribe,
    required double income,
  }) async {
    final user = _cachedUser;
    if (user == null) {
      throw const AuthFailure('Sign in before completing e-KYC.');
    }
    try {
      final updated = user.copyWith(
        aadhaarLast4: aadhaarNumber.length >= 4
            ? aadhaarNumber.substring(aadhaarNumber.length - 4)
            : user.aadhaarLast4,
        tribe: tribe,
        familyAnnualIncome: income,
        isAadhaarLinked: true,
      );
      await updateProfile(updated);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> startSimulatedSession() async {
    throw const IntegrationFailure(
      'Simulated sessions are not available in live mode.',
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _cachedUser = null;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap(), SetOptions(merge: true));
      _cachedUser = user;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  if (AppConfig.isDemo) {
    return MockAuthRepository();
  }
  return LiveAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<UserModel?>((ref) {
  final asyncUser = ref.watch(currentUserStreamProvider);
  return asyncUser.value ?? ref.watch(authRepositoryProvider).currentUser;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// In demo mode, allows toggling the "Demo: view as admin" mode.
final demoAdminModeProvider = StateProvider<bool>((ref) => false);

final isAdminUserProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  if (user.role == UserRole.admin) return true;
  if (AppConfig.isDemo && ref.watch(demoAdminModeProvider)) return true;
  return false;
});
