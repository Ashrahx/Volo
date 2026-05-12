import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

class AppSettings {
  const AppSettings({
    this.focusDuration = 25,
    this.shortBreak = 5,
    this.longBreak = 15,
    this.darkModeOverride,
    this.locale = 'en',
    this.keepScreenOn = false,
    this.dailyGoalHours = 8,
    this.doNotDisturb = false,
    this.notificationsEnabled = true,
    this.userName = '',
  });

  final int focusDuration;
  final int shortBreak;
  final int longBreak;
  final bool? darkModeOverride;
  final String locale;
  final bool keepScreenOn;
  final int dailyGoalHours;
  final bool doNotDisturb;
  final bool notificationsEnabled;
  final String userName;

  AppSettings copyWith({
    int? focusDuration,
    int? shortBreak,
    int? longBreak,
    Object? darkModeOverride = _kSentinel,
    String? locale,
    bool? keepScreenOn,
    int? dailyGoalHours,
    bool? doNotDisturb,
    bool? notificationsEnabled,
    String? userName,
  }) {
    return AppSettings(
      focusDuration: focusDuration ?? this.focusDuration,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      darkModeOverride: identical(darkModeOverride, _kSentinel)
          ? this.darkModeOverride
          : darkModeOverride as bool?,
      locale: locale ?? this.locale,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      userName: userName ?? this.userName,
    );
  }
}

const _kSentinel = Object();

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kFocus = 'pref_focus_mins';
  static const _kShort = 'pref_short_mins';
  static const _kLong = 'pref_long_mins';
  static const _kDark = 'pref_dark_mode';
  static const _kLocale = 'pref_locale';
  static const _kScreen = 'pref_keep_screen';
  static const _kGoal = 'pref_daily_goal_hours';
  static const _kDnd = 'pref_do_not_disturb';
  static const _kNotifs = 'pref_notifications_enabled';
  static const _kUserName = 'pref_user_name';

  void _load() {
    state = AppSettings(
      focusDuration: _prefs.getInt(_kFocus) ?? 25,
      shortBreak: _prefs.getInt(_kShort) ?? 5,
      longBreak: _prefs.getInt(_kLong) ?? 15,
      darkModeOverride: _prefs.getBool(_kDark),
      locale: _prefs.getString(_kLocale) ?? 'en',
      keepScreenOn: _prefs.getBool(_kScreen) ?? false,
      dailyGoalHours: _prefs.getInt(_kGoal) ?? 8,
      doNotDisturb: _prefs.getBool(_kDnd) ?? false,
      notificationsEnabled: _prefs.getBool(_kNotifs) ?? true,
      userName: _prefs.getString(_kUserName) ?? '',
    );
  }

  void setFocusDuration(int v) {
    _prefs.setInt(_kFocus, v);
    state = state.copyWith(focusDuration: v);
  }

  void setShortBreak(int v) {
    _prefs.setInt(_kShort, v);
    state = state.copyWith(shortBreak: v);
  }

  void setLongBreak(int v) {
    _prefs.setInt(_kLong, v);
    state = state.copyWith(longBreak: v);
  }

  void setDarkMode(bool v) {
    _prefs.setBool(_kDark, v);
    state = state.copyWith(darkModeOverride: v);
  }

  void setLanguage(String code) {
    _prefs.setString(_kLocale, code);
    state = state.copyWith(locale: code);
  }

  void setKeepScreenOn(bool v) {
    _prefs.setBool(_kScreen, v);
    state = state.copyWith(keepScreenOn: v);
  }

  void setDailyGoalHours(int v) {
    _prefs.setInt(_kGoal, v);
    state = state.copyWith(dailyGoalHours: v);
  }

  void setDoNotDisturb(bool v) {
    _prefs.setBool(_kDnd, v);
    state = state.copyWith(doNotDisturb: v);
  }

  void setNotificationsEnabled(bool v) {
    _prefs.setBool(_kNotifs, v);
    state = state.copyWith(notificationsEnabled: v);
  }

  void setUserName(String v) {
    _prefs.setString(_kUserName, v.trim());
    state = state.copyWith(userName: v.trim());
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(sharedPrefsProvider)),
);
