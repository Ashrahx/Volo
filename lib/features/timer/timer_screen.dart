import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/database.dart';
import 'timer_provider.dart';
import '../settings/settings_provider.dart';
import '../tasks/tasks_provider.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(timerProvider);
    final tasks = ref.watch(activeTasksProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/volo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Volo'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _TypeSelector(current: timer.type, ref: ref),
            const SizedBox(height: 32),
            _CircularTimer(timer: timer),
            const SizedBox(height: 32),
            _TimerControls(timer: timer, ref: ref),
            const SizedBox(height: 28),
            _StreakRow(sessionsToday: timer.sessionsToday, settings: settings),
            const SizedBox(height: 20),
            _TodayTasks(tasks: tasks, timer: timer, ref: ref),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.current, required this.ref});
  final TimerType current;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: TimerType.values.map((t) {
          final isActive = t == current;
          final label = t == TimerType.focus
              ? 'timer.focus'.tr()
              : t == TimerType.shortBreak
                  ? 'timer.short_break'.tr()
                  : 'timer.long_break'.tr();
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(timerProvider.notifier).setType(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CircularTimer extends StatelessWidget {
  const _CircularTimer({required this.timer});
  final TimerState timer;

  Color get _arcColor {
    switch (timer.type) {
      case TimerType.focus:
        return AppColors.focusRed;
      case TimerType.shortBreak:
        return AppColors.breakGreen;
      case TimerType.longBreak:
        return AppColors.longBreakBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(
          painter: _ArcPainter(
            progress: timer.progress,
            color: _arcColor,
            trackColor: _arcColor.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _arcColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_alarm_rounded,
                        size: 14,
                        color: _arcColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timer.type == TimerType.focus
                            ? 'timer.focus_time'.tr()
                            : timer.type == TimerType.shortBreak
                                ? 'timer.short_break_time'.tr()
                                : 'timer.long_break_time'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _arcColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  timer.formattedTime,
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                )
                    .animate(
                      target: timer.status == TimerStatus.running ? 1 : 0,
                    )
                    .custom(
                      duration: 200.ms,
                      builder: (ctx, val, child) => child,
                    ),
                const SizedBox(height: 4),
                Text(
                  'timer.sessions_completed'.tr(
                    namedArgs: {'count': '${timer.sessionsToday}'},
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });
  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 10.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({required this.timer, required this.ref});
  final TimerState timer;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(timerProvider.notifier);
    final isRunning = timer.status == TimerStatus.running;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlBtn(
          icon: Icons.stop_rounded,
          size: 44,
          onTap: () => notifier.stop(),
          color: AppColors.textSecondary,
          bg: Theme.of(context).cardTheme.color!,
        ),
        const SizedBox(width: 16),
        _ControlBtn(
          icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 56,
          onTap: () => isRunning ? notifier.pause() : notifier.start(),
          color: Colors.white,
          bg: AppColors.primary,
          large: true,
        ),
        const SizedBox(width: 16),
        _ControlBtn(
          icon: Icons.skip_next_rounded,
          size: 44,
          onTap: () => notifier.skip(),
          color: AppColors.textSecondary,
          bg: Theme.of(context).cardTheme.color!,
        ),
      ],
    );
  }
}

class _ControlBtn extends StatefulWidget {
  const _ControlBtn({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.color,
    required this.bg,
    this.large = false,
  });
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color color;
  final Color bg;
  final bool large;

  @override
  State<_ControlBtn> createState() => _ControlBtnState();
}

class _ControlBtnState extends State<_ControlBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.forward();
  void _onTapUp(_) {
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final dim = widget.large ? 72.0 : 52.0;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: dim,
          height: dim,
          decoration: BoxDecoration(
            color: widget.bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.large
                  ? Colors.transparent
                  : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
            boxShadow: widget.large
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              widget.icon,
              key: ValueKey(widget.icon),
              color: widget.color,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.sessionsToday, required this.settings});
  final int sessionsToday;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final days = [
      'common.day_letter_sun'.tr(),
      'common.day_letter_mon'.tr(),
      'common.day_letter_tue'.tr(),
      'common.day_letter_wed'.tr(),
      'common.day_letter_thu'.tr(),
      'common.day_letter_fri'.tr(),
      'common.day_letter_sat'.tr(),
    ];
    final today = DateTime.now().weekday % 7;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'timer.start_today'.tr(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'timer.sessions_progress'.tr(
                    namedArgs: {
                      'done': '$sessionsToday',
                      'total': '${settings.dailyGoalHours * 2}',
                      'mins': '${sessionsToday * 25}',
                    },
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: days.asMap().entries.map((e) {
              final isDone = e.key < today && sessionsToday > 0;
              final isToday = e.key == today;
              return Container(
                margin: const EdgeInsets.only(left: 4),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primaryLight
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isToday
                        ? AppColors.primary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    width: isToday ? 1.5 : 0.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDone
                          ? Colors.white
                          : isToday
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TodayTasks extends StatelessWidget {
  const _TodayTasks({
    required this.tasks,
    required this.timer,
    required this.ref,
  });
  final AsyncValue<List<Task>> tasks;
  final TimerState timer;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.format_list_bulleted_rounded, size: 18),
            const SizedBox(width: 6),
            Text(
              'timer.todays_tasks'.tr(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/create-task'),
              child: Text('timer.plan'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        tasks.when(
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.checklist_rounded,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'timer.no_tasks'.tr(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: list.take(3).map((t) {
                final isActive = t.id == timer.activeTaskId;
                return GestureDetector(
                  onTap: () => ref
                      .read(timerProvider.notifier)
                      .setActiveTask(isActive ? null : t.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primaryLight
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.15),
                        width: isActive ? 1 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(t.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isActive ? AppColors.textPrimary : null,
                                ),
                              ),
                              if (t.subtaskTotal > 0)
                                Text(
                                  'timer.subtasks'.tr(namedArgs: {
                                    'done': '${t.subtaskDone}',
                                    'total': '${t.subtaskTotal}',
                                  }),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'timer.active_label'.tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}
