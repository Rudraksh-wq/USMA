import 'package:flutter_test/flutter_test.dart';
import 'package:usma/core/localization/app_localization.dart';

void main() {
  group('AppLocalization Multi-Language & Tribal Dialect Tests', () {
    test('provides translations for all supported languages', () {
      for (final lang in AppLocalization.supportedLanguages) {
        final home = AppLocalization.tr('nav_home', lang: lang);
        expect(home, isNotEmpty);
      }
    });

    test('Santali Ol Chiki translation returns Ol Chiki characters', () {
      final homeSantali = AppLocalization.tr('nav_home', lang: AppLocalization.langSantali);
      expect(homeSantali, contains('ᱚᱲᱟᱜ'));
    });

    test('falls back to English when key is missing in target language', () {
      final fallback = AppLocalization.tr('settings_title', lang: 'unknown_lang');
      expect(fallback, 'App Settings');
    });

    test('supported languages match display names mapping', () {
      for (final code in AppLocalization.supportedLanguages) {
        expect(AppLocalization.languageNames.containsKey(code), isTrue);
      }
    });
  });
}
