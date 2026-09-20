/// Central PII Redactor for USMA.
/// Sanitizes sensitive fields before logging, analytics, or caching.
class PiiRedactor {
  static final RegExp _aadhaarRegex = RegExp(r'\b\d{4}\s\d{4}\s(\d{4})\b');
  static final RegExp _aadhaarContinuousRegex = RegExp(r'(?<=aadhaar[:\s=]+)(\d{8})(\d{4})\b', caseSensitive: false);
  static final RegExp _phoneRegex = RegExp(r'\b(?:\+?91)?[6-9]\d{5}(\d{4})\b');
  static final RegExp _accountRegex = RegExp(r'(?<=account[:\s=]+|bank[:\s=]+)(\d{5,14})(\d{4})\b', caseSensitive: false);
  static final RegExp _generic12Digits = RegExp(r'\b\d{8}(\d{4})\b');

  /// Masks Aadhaar number to display only last 4 digits (e.g. XXXX-XXXX-1234).
  static String maskAadhaar(String input) {
    var out = input.replaceAllMapped(_aadhaarRegex, (m) => 'XXXX-XXXX-${m[1]}');
    out = out.replaceAllMapped(_aadhaarContinuousRegex, (m) => 'XXXX-XXXX-${m[2]}');
    return out;
  }

  /// Masks 10-digit Indian Mobile Numbers (e.g. XXXXXX1234).
  static String maskPhone(String input) {
    return input.replaceAllMapped(_phoneRegex, (m) => 'XXXXXX${m[1]}');
  }

  /// Masks Bank Account Numbers (e.g. XXXXXX1234).
  static String maskBankAccount(String input) {
    return input.replaceAllMapped(_accountRegex, (m) => 'XXXXXX${m[2]}');
  }

  /// Redacts all recognized PII patterns from a log message.
  static String redactLogMessage(String message) {
    var result = maskPhone(message);
    result = maskBankAccount(result);
    result = maskAadhaar(result);
    return result;
  }
}
