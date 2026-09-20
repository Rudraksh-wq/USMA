// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// Demo Seeding Script for USMA Smart India Hackathon Presentation.
/// Generates 6 realistic personas:
/// 1. Birsa Munda (Class 9, Pre-Matric ST)
/// 2. Shanti Oraon (B.Tech 2nd Year, Post-Matric ST)
/// 3. Jaipal Singh (IIT Bombay B.Tech CSE, Top Class Education for ST)
/// 4. Anjali Gond (Ph.D. Forestry, NFST Scholar)
/// 5. Rajesh Bhil (M.Sc. Oxford University UK, NOS Scholar)
/// 6. Nodal Officer (State Tribal Welfare Officer, Odisha)
void main() {
  print('========================================================');
  print('USMA Demo Seeding Tool — SIH 2026 PS SIH26238');
  print('Ministry of Tribal Affairs • Scheduled Tribe Beneficiaries');
  print('========================================================\n');

  final personas = [
    {
      'id': 'demo_student_pre_matric',
      'name': 'Birsa Munda',
      'role': 'student',
      'state': 'JH',
      'category': 'ST',
      'annualIncome': 120000.0,
      'targetScheme': 'mota_pre_matric_st',
      'schemeName': 'Pre-Matric Scholarship for ST Students',
      'stage': 'Submitted',
      'status': 'InstituteVerified',
      'disbursementAmount': 3500.0,
      'documents': ['Caste Certificate (ST)', 'Class 8 Marksheet', 'Income Certificate', 'Aadhaar (DigiLocker)'],
    },
    {
      'id': 'demo_student_post_matric',
      'name': 'Shanti Oraon',
      'role': 'student',
      'state': 'OD',
      'category': 'ST',
      'annualIncome': 210000.0,
      'targetScheme': 'mota_post_matric_st',
      'schemeName': 'Post-Matric Scholarship for ST Students',
      'stage': 'StateApproved',
      'status': 'Sanctioned',
      'disbursementAmount': 18000.0,
      'documents': ['Caste Certificate (ST)', 'Class 12 Marksheet', 'College Fee Receipt', 'Aadhaar (DigiLocker)'],
    },
    {
      'id': 'demo_student_top_class',
      'name': 'Jaipal Singh',
      'role': 'student',
      'state': 'JH',
      'category': 'ST',
      'annualIncome': 450000.0,
      'targetScheme': 'mota_top_class_st',
      'schemeName': 'National Fellowship and Scholarship for Higher Education (Top Class)',
      'stage': 'Sanctioned',
      'status': 'Sanctioned',
      'disbursementAmount': 220000.0,
      'documents': ['IIT Bombay Admission Letter', 'Caste Certificate (ST)', 'Income Affidavit', 'DigiLocker Aadhaar'],
    },
    {
      'id': 'demo_student_nfst',
      'name': 'Anjali Gond',
      'role': 'student',
      'state': 'MP',
      'category': 'ST',
      'annualIncome': 300000.0,
      'targetScheme': 'mota_nfst',
      'schemeName': 'National Fellowship for Higher Education of ST Students (NFST)',
      'stage': 'Sanctioned',
      'status': 'Disbursed',
      'disbursementAmount': 372000.0,
      'documents': ['UGC-NET ST Fellowship Award', 'University Ph.D. Joining Report', 'Quarterly Progress Report'],
    },
    {
      'id': 'demo_student_nos',
      'name': 'Rajesh Bhil',
      'role': 'student',
      'state': 'RJ',
      'category': 'ST',
      'annualIncome': 400000.0,
      'targetScheme': 'mota_nos',
      'schemeName': 'National Overseas Scholarship for ST Students (NOS)',
      'stage': 'Sanctioned',
      'status': 'Disbursed',
      'disbursementAmount': 1540000.0,
      'documents': ['Oxford Offer Letter', 'IELTS 7.5 Scorecard', 'Valid Passport', 'Visa Clearance'],
    },
    {
      'id': 'demo_officer_odisha',
      'name': 'Dr. K. Rathore, IAS',
      'role': 'state_officer',
      'state': 'OD',
      'institutionId': null,
      'designation': 'State Nodal Officer, SSD & Tribal Welfare Dept.',
      'jurisdiction': 'Odisha State (All 30 Districts)',
    }
  ];

  final file = File('assets/data/demo_personas.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(personas));

  print('Successfully generated ${personas.length} demo personas in assets/data/demo_personas.json:');
  for (final p in personas) {
    print(' - [${p['role']}] ${p['name']} (${p['state']}) -> ${p['schemeName'] ?? p['designation']}');
  }
  print('\nSeeding complete.');
}
