import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/database_provider.dart';
import 'package:go_router/go_router.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  bool _isWeekly = true;

  String _formatSeconds(int s) {
    if (s < 60) return '${s}s';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('reports.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionLabel(label: 'reports.today_label'.tr()),
          const SizedBox(height: 8),
          FutureBuilder(
            future: Future.wait([
              db.getTodaySessions(),
              db.getHourlyFocusToday(),
            ]),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final todaySessions = snap.data![0] as List;
              final hourly = snap.data![1] as Map<int, int>;

              final totalFocus = todaySessions
                  .where((s) => (s as dynamic).type == 0)
                  .fold<int>(
                    0,
                    (sum, s) => sum + (s as dynamic).durationSeconds as int,
                  );
              final totalBreak = todaySessions
                  .where((s) => (s as dynamic).type != 0)
                  .fold<int>(
                    0,
                    (sum, s) => sum + (s as dynamic).durationSeconds as int,
                  );
              final totalUnfocused = (24 * 3600) - totalFocus - totalBreak;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'reports.today_focus'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSeconds(totalFocus),
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'reports.focused_today'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatChip(
                              label: 'reports.focused'.tr(),
                              value: _formatSeconds(totalFocus),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              label: 'reports.breaks'.tr(),
                              value: _formatSeconds(totalBreak),
                              color: AppColors.priorityMed,
                            ),
                            const SizedBox(width: 12),
                            _StatChip(
                              label: 'reports.unfocused'.tr(),
                              value: _formatSeconds(totalUnfocused),
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'reports.focus_time'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            _TogglePill(
                              options: [
                                'reports.weekly'.tr(),
                                'reports.monthly'.tr(),
                              ],
                              selected: _isWeekly ? 0 : 1,
                              onChanged: (i) =>
                                  setState(() => _isWeekly = i == 0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _BigStat(
                              label: 'reports.total_focus'.tr(),
                              value: _formatSeconds(
                                totalFocus * (_isWeekly ? 7 : 30),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _BigStat(
                              label: 'reports.avg_focus'.tr(),
                              value: _formatSeconds(
                                totalFocus ~/
                                    (todaySessions.isEmpty
                                        ? 1
                                        : todaySessions.length),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _BigStat(
                              label: 'reports.total_sessions'.tr(),
                              value: '${todaySessions.length}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 140,
                          child: _HourlyBarChart(hourly: hourly),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'reports.highlights'.tr()),
          const SizedBox(height: 8),
          FutureBuilder(
            future: Future.wait([
              db.getTotalCompletedSessions(),
              db.getTotalActiveDays(),
              db.getCurrentStreak(),
              db.getHeatmapData(12),
            ]),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final completions = snap.data![0] as int;
              final activeDays = snap.data![1] as int;
              final streak = snap.data![2] as int;
              final heatmap = snap.data![3] as Map<DateTime, int>;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.task_alt_outlined,
                          value: '$completions',
                          label: 'reports.completions'.tr(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_outlined,
                          value: '$activeDays',
                          label: 'reports.active_days'.tr(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'reports.heatmap'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'reports.heatmap_monthly'.tr(),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Heatmap(data: heatmap),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'reports.less'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            ...List.generate(
                              5,
                              (i) => Container(
                                margin: const EdgeInsets.only(right: 3),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: i == 0 ? 0.08 : i * 0.22,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'reports.more'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(context),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 32,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'reports.streak'.tr(
                                namedArgs: {'count': '$streak'},
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'reports.keep_it_up'.tr(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      );
}

class _HourlyBarChart extends StatelessWidget {
  const _HourlyBarChart({required this.hourly});
  final Map<int, int> hourly;

  @override
  Widget build(BuildContext context) {
    final maxVal = hourly.values.isEmpty
        ? 1.0
        : hourly.values.reduce((a, b) => a > b ? a : b).toDouble();

    final bars = List.generate(9, (i) {
      final hour = i + 2;
      final val = (hourly[hour] ?? 0).toDouble();
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: val,
            color: AppColors.primary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.3,
        barGroups: bars,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.data});
  final Map<DateTime, int> data;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weeks = 12;
    final startDate = now.subtract(Duration(days: weeks * 7 + now.weekday - 1));
    final maxVal =
        data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);

    final dayLabels = [
      'reports.day_sun'.tr(),
      'reports.day_mon'.tr(),
      'reports.day_tue'.tr(),
      'reports.day_wed'.tr(),
      'reports.day_thu'.tr(),
      'reports.day_fri'.tr(),
      'reports.day_sat'.tr(),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: dayLabels
              .map(
                (d) => SizedBox(
                  height: 14,
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: List.generate(weeks, (w) {
              return Expanded(
                child: Column(
                  children: List.generate(7, (d) {
                    final date = startDate.add(Duration(days: w * 7 + d));
                    final count =
                        data[DateTime(date.year, date.month, date.day)] ?? 0;
                    final opacity =
                        count == 0 ? 0.08 : (count / maxVal).clamp(0.15, 1.0);
                    return Container(
                      margin: const EdgeInsets.all(1),
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.asMap().entries.map((e) {
          final isSelected = e.key == selected;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
