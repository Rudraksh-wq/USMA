import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localization.dart';

const String _kLanguagePrefKey = 'selected_language_code';

class LanguageNotifier extends Notifier<String> {
  @override
  String build() {
    _loadPersistedLanguage();
    return AppLocalization.langEnglish;
  }

  Future<void> _loadPersistedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_kLanguagePrefKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        state = savedCode;
      }
    } catch (_) {
      // In tests or mock environments where SharedPreferences isn't initialized yet,
      // state remains default English.
    }
  }

  Future<void> setLanguageCode(String code) async {
    state = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLanguagePrefKey, code);
    } catch (_) {}
  }

  Future<void> setLanguageByDisplayName(String displayName) async {
    final code = AppLocalization.languageCodeFromDisplay[displayName] ?? AppLocalization.langEnglish;
    await setLanguageCode(code);
  }
}

/// Provider for the active language code ('en', 'hi', 'or', etc.).
final languageCodeProvider = NotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);

/// Display name provider for settings dropdown backward compatibility.
final languageProvider = Provider<String>((ref) {
  final code = ref.watch(languageCodeProvider);
  return AppLocalization.languageNames[code] ?? 'English';
});

/// Drives MaterialApp's active Locale.
final currentLocaleProvider = Provider<Locale>((ref) {
  final code = ref.watch(languageCodeProvider);
  return Locale(code, 'IN');
});
