import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';
import 'core/services/notification_service.dart';
import 'features/settings/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;
  final savedDark = prefs.getBool('pref_dark_mode');
  final initialTheme = savedDark == true ? AppTheme.dark : AppTheme.light;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('ja'),
        Locale('zh'),
        Locale('pt'),
        Locale('it'),
        Locale('ko'),
        Locale('ru'),
        Locale('ar'),
        Locale('hi'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: ThemeProvider(
          initTheme: initialTheme,
          duration: const Duration(milliseconds: 600),
          builder: (_, __) => PomodoApp(onboarded: onboarded),
        ),
      ),
    ),
  );
}

class PomodoApp extends ConsumerStatefulWidget {
  const PomodoApp({super.key, required this.onboarded});
  final bool onboarded;

  @override
  ConsumerState<PomodoApp> createState() => _PomodoAppState();
}

class _PomodoAppState extends ConsumerState<PomodoApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(widget.onboarded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WakelockPlus.toggle(enable: ref.read(settingsProvider).keepScreenOn);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      if (prev?.keepScreenOn != next.keepScreenOn) {
        WakelockPlus.toggle(enable: next.keepScreenOn);
      }
    });

    return ThemeSwitcher.withTheme(
      builder: (ctx, switcher, theme) => MaterialApp.router(
        title: 'Volo',
        theme: theme,
        routerConfig: _router,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ThemeSwitchingArea(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
