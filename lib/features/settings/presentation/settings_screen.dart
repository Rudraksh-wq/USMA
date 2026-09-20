import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/theme/tokens.dart';
import '../data/language_provider.dart';

export '../data/language_provider.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<String> _languages = [
    'English',
    'हिन्दी (Hindi)',
    'ଓଡ଼ିଆ (Odia)',
    'ᱥᱟᱱᱛﺎᱲᱤ (Santhali)',
    'తెలుగు (Telugu)',
    'বাংলা (Bengali)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final currentLang = ref.watch(languageProvider);
    final langCode = ref.watch(languageCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalization.tr('settings_title', lang: langCode)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            AppLocalization.tr('settings_accessibility', lang: langCode),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: AppColors.primary),
              title: Text(AppLocalization.tr('settings_display_language', lang: langCode)),
              subtitle: Text(currentLang),
              trailing: DropdownButton<String>(
                key: const Key('language_dropdown'),
                value: currentLang,
                underline: const SizedBox.shrink(),
                items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(languageCodeProvider.notifier).setLanguageByDisplayName(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Explicit Language Translation Coverage Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.translate_rounded, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalization.tr('settings_coverage_notice', lang: langCode),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalization.tr('settings_coverage_desc', lang: langCode),
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
              title: Text(AppLocalization.tr('settings_dark_mode', lang: langCode)),
              subtitle: Text(AppLocalization.tr('settings_dark_mode_sub', lang: langCode)),
              value: currentTheme == ThemeMode.dark,
              onChanged: (isDark) {
                ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            AppLocalization.tr('settings_about', lang: langCode),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                  title: Text(AppLocalization.tr('settings_version', lang: langCode)),
                  subtitle: Text(AppLocalization.tr('settings_version_val', lang: langCode)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded, color: AppColors.textSecondary),
                  title: Text(AppLocalization.tr('settings_terms', lang: langCode)),
                  subtitle: Text(AppLocalization.tr('settings_terms_val', lang: langCode)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
