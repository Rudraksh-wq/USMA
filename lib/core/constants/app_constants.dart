class AppConstants {
  AppConstants._();

  static const List<String> schemes = ['pre_matric', 'post_matric', 'top_class', 'nfst', 'nos'];
  
  static const Map<String, String> schemeDisplayNames = {
    'pre_matric': 'Pre-Matric Scholarship',
    'post_matric': 'Post-Matric Scholarship',
    'top_class': 'Top Class Education',
    'nfst': 'National Fellowship for ST',
    'nos': 'National Overseas Scholarship',
  };

  static const List<String> sourceSystems = ['nsp', 'sfmp', 'nos_portal'];
  
  static const Map<String, String> sourceSystemDisplayNames = {
    'nsp': 'National Scholarship Portal (NSP)',
    'sfmp': 'Scholarship Fund Management Portal (Canara Bank)',
    'nos_portal': 'NOS Portal',
  };

  static const List<String> applicationStages = [
    'draft', 'submitted', 'under_verification', 'deficiency_raised', 'sanctioned', 'disbursed', 'rejected'
  ];

  static const Map<String, String> stageDisplayNames = {
    'draft': 'Draft',
    'submitted': 'Submitted',
    'under_verification': 'Under Verification',
    'deficiency_raised': 'Deficiency Raised',
    'sanctioned': 'Sanctioned',
    'disbursed': 'Disbursed',
    'rejected': 'Rejected',
  };

  static const List<String> documentTypes = ['identity', 'st_certificate', 'income', 'academic', 'institution', 'other'];

  static const Map<String, String> documentTypeDisplayNames = {
    'identity': 'Identity Proof',
    'st_certificate': 'ST Certificate',
    'income': 'Income Certificate',
    'academic': 'Academic Document',
    'institution': 'Institution Certificate',
    'other': 'Other',
  };

  static const String notifStatusChange = 'status_change';
  static const String notifDeficiency = 'deficiency';
  static const String notifDisbursement = 'disbursement';
  static const String notifSystem = 'system';

  static const String settingsBox = 'settings_box';
  static const String chatCacheBox = 'chat_cache_box';

  static const String usersCollection = 'users';
  static const String schemesCollection = 'schemes';

  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2 MB

  /// File types accepted for manual document uploads.
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const List<String> allowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
  ];
}
