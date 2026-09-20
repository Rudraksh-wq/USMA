enum UserRole {
  student,
  admin,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String aadhaarLast4;
  final String tribe;
  final String state;
  final String district;
  final double familyAnnualIncome;
  final bool isAadhaarLinked;
  final bool isDigiLockerLinked;
  final String? bankAccountLast4;
  final String? bankIfsc;
  final String? apaarId;
  final String educationLevel;
  final bool isScheduledTribe;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.aadhaarLast4,
    required this.tribe,
    required this.state,
    required this.district,
    required this.familyAnnualIncome,
    this.isAadhaarLinked = false,
    this.isDigiLockerLinked = false,
    this.bankAccountLast4,
    this.bankIfsc,
    this.apaarId,
    this.educationLevel = 'post_matric',
    this.isScheduledTribe = true,
    this.role = UserRole.student,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      aadhaarLast4: map['aadhaarLast4']?.toString() ?? 'XXXX',
      tribe: map['tribe']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      district: map['district']?.toString() ?? '',
      familyAnnualIncome: (map['familyAnnualIncome'] as num?)?.toDouble() ?? 0,
      isAadhaarLinked: map['isAadhaarLinked'] == true,
      isDigiLockerLinked: map['isDigiLockerLinked'] == true,
      bankAccountLast4: map['bankAccountLast4']?.toString(),
      bankIfsc: map['bankIfsc']?.toString(),
      apaarId: map['apaarId']?.toString(),
      educationLevel: map['educationLevel']?.toString() ?? 'post_matric',
      isScheduledTribe: map['isScheduledTribe'] != false,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.student,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'aadhaarLast4': aadhaarLast4,
      'tribe': tribe,
      'state': state,
      'district': district,
      'familyAnnualIncome': familyAnnualIncome,
      'isAadhaarLinked': isAadhaarLinked,
      'isDigiLockerLinked': isDigiLockerLinked,
      'bankAccountLast4': bankAccountLast4,
      'bankIfsc': bankIfsc,
      'apaarId': apaarId,
      'educationLevel': educationLevel,
      'isScheduledTribe': isScheduledTribe,
      'role': role.name,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? aadhaarLast4,
    String? tribe,
    String? state,
    String? district,
    double? familyAnnualIncome,
    bool? isAadhaarLinked,
    bool? isDigiLockerLinked,
    String? bankAccountLast4,
    String? bankIfsc,
    String? apaarId,
    String? educationLevel,
    bool? isScheduledTribe,
    UserRole? role,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      aadhaarLast4: aadhaarLast4 ?? this.aadhaarLast4,
      tribe: tribe ?? this.tribe,
      state: state ?? this.state,
      district: district ?? this.district,
      familyAnnualIncome: familyAnnualIncome ?? this.familyAnnualIncome,
      isAadhaarLinked: isAadhaarLinked ?? this.isAadhaarLinked,
      isDigiLockerLinked: isDigiLockerLinked ?? this.isDigiLockerLinked,
      bankAccountLast4: bankAccountLast4 ?? this.bankAccountLast4,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      apaarId: apaarId ?? this.apaarId,
      educationLevel: educationLevel ?? this.educationLevel,
      isScheduledTribe: isScheduledTribe ?? this.isScheduledTribe,
      role: role ?? this.role,
    );
  }
}
