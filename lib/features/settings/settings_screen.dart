import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../../data/database/database_provider.dart';
import 'settings_provider.dart';

BoxDecoration _cardDeco(BuildContext context) => BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        width: 0.5,
      ),
    );

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          _GreetingCard(settings: settings, notifier: notifier),
          const SizedBox(height: 8),
          _StatsRow(),
          const SizedBox(height: 20),
          _SectionHeader(label: 'settings.timer_settings'.tr()),
          const SizedBox(height: 8),
          Container(
            decoration: _cardDeco(context),
            child: Column(
              children: [
                _TimerRow(
                  label: 'settings.focus_label'.tr(),
                  color: AppColors.focusRed,
                  current: settings.focusDuration,
                  options: const [5, 10, 25],
                  onChanged: notifier.setFocusDuration,
                  context: context,
                  customLabel: 'settings.focus_label'.tr(),
                ),
                Divider(
                  height: 0.5,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
                _TimerRow(
                  label: 'settings.break_label'.tr(),
                  color: AppColors.breakGreen,
                  current: settings.shortBreak,
                  options: const [5, 10, 15],
                  onChanged: notifier.setShortBreak,
                  context: context,
                  customLabel: 'settings.break_label'.tr(),
                ),
                Divider(
                  height: 0.5,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
                _TimerRow(
                  label: 'settings.long_label'.tr(),
                  color: AppColors.longBreakBlue,
                  current: settings.longBreak,
                  options: const [15, 20, 30],
                  onChanged: notifier.setLongBreak,
                  context: context,
                  customLabel: 'settings.long_label'.tr(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(label: 'settings.preferences'.tr()),
          const SizedBox(height: 8),
          Container(
            decoration: _cardDeco(context),
            child: Column(
              children: [
                _PrefsRow(
                  icon: Icons.notifications_outlined,
                  label: 'settings.notifications'.tr(),
                  trailing: Text(
                    settings.notificationsEnabled
                        ? 'settings.notifs_enabled'.tr()
                        : 'settings.notifs_disabled'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: settings.notificationsEnabled
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  onTap: () => _showNotificationsDialog(context, ref),
                ),
                _divider(context),
                _PrefsRow(
                  icon: Icons.language_outlined,
                  label: 'settings.language'.tr(),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _localeName(settings.locale),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () => context.push('/language'),
                ),
                _divider(context),
                _PrefsRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'settings.dark_mode'.tr(),
                  trailing: ThemeSwitcher.withTheme(
                    builder: (ctx, switcher, theme) => Switch(
                      value: theme.brightness == Brightness.dark,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) {
                        switcher.changeTheme(
                          theme: v ? AppTheme.dark : AppTheme.light,
                          isReversed: !v,
                        );
                        notifier.setDarkMode(v);
                      },
                    ),
                  ),
                  onTap: null,
                ),
                _divider(context),
                _PrefsRow(
                  icon: Icons.screen_lock_portrait_outlined,
                  label: 'settings.keep_screen_on'.tr(),
                  trailing: Switch(
                    value: settings.keepScreenOn,
                    activeThumbColor: AppColors.primary,
                    onChanged: notifier.setKeepScreenOn,
                  ),
                  onTap: null,
                ),
                _divider(context),
                _PrefsRow(
                  icon: Icons.access_time_outlined,
                  label: 'settings.daily_hours'.tr(),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.dailyGoalHours}h',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () => _showDailyGoalPicker(context, ref, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(label: 'settings.focus_mode'.tr()),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(context),
            child: Row(
              children: [
                const Icon(Icons.do_not_disturb_on_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings.dnd'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'settings.dnd_desc'.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.doNotDisturb,
                  activeThumbColor: AppColors.primary,
                  onChanged: notifier.setDoNotDisturb,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showNotificationsDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, sheetRef, _) {
          final liveSettings = sheetRef.watch(settingsProvider);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.notifications_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'settings.notifications'.tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      liveSettings.notificationsEnabled
                          ? 'settings.notifs_enabled'.tr()
                          : 'settings.notifs_disabled'.tr(),
                      style: const TextStyle(fontSize: 15),
                    ),
                    Switch(
                      value: liveSettings.notificationsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) async {
                        if (v) {
                          await NotificationService.requestPermission();
                          sheetRef
                              .read(settingsProvider.notifier)
                              .setNotificationsEnabled(true);
                        } else {
                          sheetRef
                              .read(settingsProvider.notifier)
                              .setNotificationsEnabled(false);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDailyGoalPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          int hours = settings.dailyGoalHours;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'settings.daily_goal'.tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (hours > 1) setState(() => hours--);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 32,
                      color: AppColors.primary,
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${hours}h',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (hours < 16) setState(() => hours++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 32,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setDailyGoalHours(hours);
                    Navigator.pop(ctx);
                  },
                  child: Text('settings.save'.tr()),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  String _localeName(String code) {
    const map = {
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'ja': '日本語',
      'zh': '中文',
      'pt': 'Português',
      'it': 'Italiano',
      'ko': '한국어',
    };
    return map[code] ?? code.toUpperCase();
  }

  Widget _divider(BuildContext context) => Divider(
        height: 0.5,
        color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        indent: 50,
      );
}

class _TimerRow extends StatelessWidget {
  const _TimerRow({
    required this.label,
    required this.color,
    required this.current,
    required this.options,
    required this.onChanged,
    required this.context,
    required this.customLabel,
  });
  final String label;
  final Color color;
  final int current;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final BuildContext context;
  final String customLabel;

  bool get _isCustom => !options.contains(current);

  void _openCustomDialog() {
    final ctrl = TextEditingController(text: _isCustom ? '$current' : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(customLabel),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            suffixText: 'settings.minutes_suffix'.tr(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim());
              if (v != null && v >= 1 && v <= 180) {
                onChanged(v);
              }
              Navigator.pop(ctx);
            },
            child: Text('settings.save'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          ...options.map((opt) {
            final isSelected = opt == current;
            return GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(left: 6),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Theme.of(ctx).dividerColor.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$opt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: _openCustomDialog,
            child: _isCustom
                ? Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$current',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(left: 6),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Theme.of(ctx).dividerColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: Theme.of(ctx).dividerColor.withValues(alpha: 0.7),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PrefsRow extends StatelessWidget {
  const _PrefsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: trailing,
      onTap: onTap,
      dense: true,
    );
  }
}

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return FutureBuilder<List<int>>(
      future: Future.wait([
        db.countActiveTasks(),
        db.getTotalCompletedSessions(),
        db.getTotalFocusMinutes(),
      ]),
      builder: (context, snap) {
        final tasks = snap.data?[0] ?? 0;
        final sessions = snap.data?[1] ?? 0;
        final minutes = snap.data?[2] ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: _cardDeco(context),
          child: Row(
            children: [
              _StatCell(value: '$tasks', label: 'settings.tasks_label'.tr()),
              _Divider(),
              _StatCell(
                  value: '$sessions', label: 'settings.sessions_label'.tr()),
              _Divider(),
              _StatCell(
                  value: '$minutes', label: 'settings.minutes_label'.tr()),
            ],
          ),
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 32, color: AppColors.border);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _GreetingCard extends StatefulWidget {
  const _GreetingCard({required this.settings, required this.notifier});
  final AppSettings settings;
  final SettingsNotifier notifier;

  @override
  State<_GreetingCard> createState() => _GreetingCardState();
}

class _GreetingCardState extends State<_GreetingCard> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.settings.userName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.notifier.setUserName(_ctrl.text);
    setState(() => _editing = false);
  }

  String _greetingText() {
    final name = widget.settings.userName.trim();
    if (name.isEmpty) return 'settings.greeting'.tr();
    return 'settings.greeting_name'.tr(namedArgs: {'name': name});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                size: 24,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _editing
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'settings.name_hint'.tr(),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _save(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _save,
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'settings.customize'.tr(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
          ),
          if (!_editing)
            GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
