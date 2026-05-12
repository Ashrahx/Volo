import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_theme.dart';
import 'settings_provider.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const _languages = [
    _Language('en', 'English', 'EN'),
    _Language('es', 'Español', 'ES'),
    _Language('fr', 'Français', 'FR'),
    _Language('de', 'Deutsch', 'DE'),
    _Language('ja', '日本語', 'JA'),
    _Language('zh', '中文', 'ZH'),
    _Language('pt', 'Português', 'PT'),
    _Language('it', 'Italiano', 'IT'),
    _Language('ko', '한국어', 'KO'),
    _Language('ru', 'Русский', 'RU'),
    _Language('ar', 'العربية', 'AR'),
    _Language('hi', 'हिन्दी', 'HI'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('language.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final lang = _languages[i];
          final isSelected = lang.code == settings.locale;

          return GestureDetector(
            onTap: () async {
              notifier.setLanguage(lang.code);
              await context.setLocale(Locale(lang.code));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Language {
  const _Language(this.code, this.name, this.shortCode);
  final String code;
  final String name;
  final String shortCode;
}
