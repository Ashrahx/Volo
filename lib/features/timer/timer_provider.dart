import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/notification_service.dart';
import '../../data/database/database.dart';
import '../../data/database/database_provider.dart';
import '../settings/settings_provider.dart';

enum TimerType { focus, shortBreak, longBreak }

enum TimerStatus { stopped, running, paused }

class TimerState {
  const TimerState({
    required this.type,
    required this.status,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.sessionsToday,
    this.activeTaskId,
  });

  final TimerType type;
  final TimerStatus status;
  final int totalSeconds;
  final int remainingSeconds;
  final int sessionsToday;
  final int? activeTaskId;

  double get progress =>
      totalSeconds > 0 ? remainingSeconds / totalSeconds : 1.0;

  String get formattedTime {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TimerState copyWith({
    TimerType? type,
    TimerStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
    int? sessionsToday,
    Object? activeTaskId = _kSentinel,
  }) {
    return TimerState(
      type: type ?? this.type,
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      sessionsToday: sessionsToday ?? this.sessionsToday,
      activeTaskId: identical(activeTaskId, _kSentinel)
          ? this.activeTaskId
          : activeTaskId as int?,
    );
  }
}

const _kSentinel = Object();

class TimerNotifier extends StateNotifier<TimerState>
    with WidgetsBindingObserver {
  TimerNotifier(this._ref) : super(_buildInitialState(_ref)) {
    WidgetsBinding.instance.addObserver(this);
    _initAsync();
  }

  final Ref _ref;
  Timer? _ticker;

  static const _kEndTimestamp = 'timer_end_ts';
  static const _kTimerType = 'timer_type_idx';

  static TimerState _buildInitialState(Ref ref) {
    final settings = ref.read(settingsProvider);
    final total = settings.focusDuration * 60;
    return TimerState(
      type: TimerType.focus,
      status: TimerStatus.stopped,
      totalSeconds: total,
      remainingSeconds: total,
      sessionsToday: 0,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (this.state.status == TimerStatus.running) {
        _showBackgroundNotification();
      }
    } else if (state == AppLifecycleState.resumed) {
      NotificationService.cancelTimerProgress();
    }
  }

  Future<void> _showBackgroundNotification() async {
    final settings = _ref.read(settingsProvider);
    if (!settings.notificationsEnabled) return;
    final m = state.remainingSeconds ~/ 60;
    final s = state.remainingSeconds % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final isBreak = state.type != TimerType.focus;
    await NotificationService.showTimerProgress(
      title: isBreak
          ? 'notifications.break_progress'.tr()
          : 'notifications.focus_progress'.tr(),
      body: 'notifications.remaining'.tr(namedArgs: {'time': timeStr}),
    );
  }

  SharedPreferences get _prefs => _ref.read(sharedPrefsProvider);

  int _durationFor(TimerType type) {
    final s = _ref.read(settingsProvider);
    return switch (type) {
      TimerType.focus => s.focusDuration * 60,
      TimerType.shortBreak => s.shortBreak * 60,
      TimerType.longBreak => s.longBreak * 60,
    };
  }

  Future<void> _initAsync() async {
    if (!mounted) return;
    final db = _ref.read(dbProvider);
    final sessionsToday = await db.countTodaySessions();
    if (!mounted) return;

    final prefs = _prefs;
    final endTs = prefs.getInt(_kEndTimestamp);
    final typeIdx = prefs.getInt(_kTimerType);

    if (endTs == null || typeIdx == null) {
      state = state.copyWith(sessionsToday: sessionsToday);
      return;
    }

    final type =
        TimerType.values[typeIdx.clamp(0, TimerType.values.length - 1)];
    final remaining = DateTime.fromMillisecondsSinceEpoch(
      endTs,
    ).difference(DateTime.now()).inSeconds;

    if (remaining <= 0) {
      await prefs.remove(_kEndTimestamp);
      await prefs.remove(_kTimerType);
      state = state.copyWith(sessionsToday: sessionsToday);
      return;
    }

    state = TimerState(
      type: type,
      status: TimerStatus.running,
      totalSeconds: _durationFor(type),
      remainingSeconds: remaining,
      sessionsToday: sessionsToday,
      activeTaskId: state.activeTaskId,
    );
    _startTicker();
  }

  void start() {
    if (state.status == TimerStatus.running) return;
    final endTime = DateTime.now().add(
      Duration(seconds: state.remainingSeconds),
    );
    _prefs.setInt(_kEndTimestamp, endTime.millisecondsSinceEpoch);
    _prefs.setInt(_kTimerType, state.type.index);
    state = state.copyWith(status: TimerStatus.running);
    _startTicker();
  }

  void pause() {
    _ticker?.cancel();
    _prefs.remove(_kEndTimestamp);
    _prefs.remove(_kTimerType);
    state = state.copyWith(status: TimerStatus.paused);
  }

  void stop() {
    _ticker?.cancel();
    _prefs.remove(_kEndTimestamp);
    _prefs.remove(_kTimerType);
    final total = _durationFor(state.type);
    state = TimerState(
      type: state.type,
      status: TimerStatus.stopped,
      totalSeconds: total,
      remainingSeconds: total,
      sessionsToday: state.sessionsToday,
      activeTaskId: state.activeTaskId,
    );
  }

  void skip() {
    _ticker?.cancel();
    _prefs.remove(_kEndTimestamp);
    _prefs.remove(_kTimerType);
    _onCompleted(state.type);
  }

  void setType(TimerType t) {
    _ticker?.cancel();
    _prefs.remove(_kEndTimestamp);
    _prefs.remove(_kTimerType);
    final total = _durationFor(t);
    state = TimerState(
      type: t,
      status: TimerStatus.stopped,
      totalSeconds: total,
      remainingSeconds: total,
      sessionsToday: state.sessionsToday,
      activeTaskId: state.activeTaskId,
    );
  }

  void setActiveTask(int? id) {
    state = state.copyWith(activeTaskId: id);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final endTs = _prefs.getInt(_kEndTimestamp);
    if (endTs == null) {
      _ticker?.cancel();
      return;
    }
    final remaining = DateTime.fromMillisecondsSinceEpoch(
      endTs,
    ).difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _ticker?.cancel();
      _onCompleted(state.type);
    } else {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  Future<void> _onCompleted(TimerType completedType) async {
    if (!mounted) return;
    final db = _ref.read(dbProvider);
    if (completedType == TimerType.focus) {
      await db.insertSession(
        SessionsCompanion.insert(
          type: const drift.Value(0),
          durationSeconds: _durationFor(completedType),
          completed: const drift.Value(true),
          taskId: drift.Value(state.activeTaskId),
          endedAt: drift.Value(DateTime.now()),
        ),
      );
    }
    if (!mounted) return;

    final settings = _ref.read(settingsProvider);
    final isFocusDnd =
        completedType == TimerType.focus && settings.doNotDisturb;
    if (settings.notificationsEnabled && !isFocusDnd) {
      await NotificationService.showTimerComplete(
        title: completedType == TimerType.focus
            ? 'timer.timer_complete_focus'.tr()
            : 'timer.timer_complete_break'.tr(),
        body: completedType == TimerType.focus
            ? 'timer.timer_complete_focus_body'.tr()
            : 'timer.timer_complete_break_body'.tr(),
      );
    }
    if (!mounted) return;
    final sessionsToday = await db.countTodaySessions();
    if (!mounted) return;

    final nextType = completedType == TimerType.focus
        ? (sessionsToday % 4 == 0 ? TimerType.longBreak : TimerType.shortBreak)
        : TimerType.focus;

    final total = _durationFor(nextType);
    state = TimerState(
      type: nextType,
      status: TimerStatus.stopped,
      totalSeconds: total,
      remainingSeconds: total,
      sessionsToday: sessionsToday,
      activeTaskId: state.activeTaskId,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(ref),
);
