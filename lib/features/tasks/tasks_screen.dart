import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/database.dart';
import '../../data/database/database_provider.dart';
import 'tasks_provider.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _tab = 0; // 0 = active, 1 = completed

  @override
  Widget build(BuildContext context) {
    final activeTasks = ref.watch(activeTasksProvider);
    final completedTasks = ref.watch(completedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('tasks.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            color: AppColors.primary,
            onPressed: () => context.push('/create-task'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _PillTab(
                  label: 'tasks.active'.tr(),
                  count: activeTasks.maybeWhen(
                    data: (l) => l.length,
                    orElse: () => 0,
                  ),
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 8),
                _PillTab(
                  label: 'tasks.completed'.tr(),
                  count: completedTasks.maybeWhen(
                    data: (l) => l.length,
                    orElse: () => 0,
                  ),
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: (_tab == 0 ? activeTasks : completedTasks).when(
              data: (list) => list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tab == 0
                                ? Icons.checklist_rounded
                                : Icons.check_circle_outline,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (_tab == 0
                                    ? 'tasks.no_active'
                                    : 'tasks.no_completed')
                                .tr(),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          if (_tab == 0) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => context.push('/create-task'),
                              icon: const Icon(Icons.add_rounded,
                                  color: AppColors.primary),
                              label: Text(
                                'tasks.add'.tr(),
                                style:
                                    const TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        8 + MediaQuery.of(context).padding.bottom,
                      ),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) =>
                          _TaskCard(task: list[i], ref: ref),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.ref});
  final Task task;
  final WidgetRef ref;

  Color get _priorityColor {
    switch (task.priority) {
      case 2:
        return AppColors.priorityHigh;
      case 1:
        return AppColors.priorityMed;
      default:
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = List<String>.from(
      jsonDecode(task.tags.isEmpty ? '[]' : task.tags) as List,
    );
    final db = ref.read(dbProvider);

    return Dismissible(
      key: ValueKey(task.id),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: task.isCompleted ? AppColors.priorityMed : Colors.green,
        icon: task.isCompleted
            ? Icons.undo_rounded
            : Icons.check_circle_outline_rounded,
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: Colors.red.shade400,
        icon: Icons.delete_outline_rounded,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await db.updateTask(task.copyWith(isCompleted: !task.isCompleted));
          return false; // don't remove from list (stream will update)
        } else {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(task.title),
                  content: Text('tasks.delete_confirm'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('common.cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'tasks.delete'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          db.deleteTask(task.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color:
                  Color(int.parse(task.categoryColor.replaceAll('#', '0xFF'))),
              width: 4,
            ),
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
            right: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => db
                    .updateTask(task.copyWith(isCompleted: !task.isCompleted)),
                child: Container(
                  margin: const EdgeInsets.only(top: 1, right: 10),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted ? Colors.green : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(task.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? AppColors.textSecondary
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: _priorityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    if (task.subtaskTotal > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${task.subtaskDone}/${task.subtaskTotal}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: task.subtaskTotal > 0
                                    ? task.subtaskDone / task.subtaskTotal
                                    : 0,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                color: AppColors.primary,
                                minHeight: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: tags
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
  });
  final Alignment alignment;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });
  final String label;
  final int? count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? Colors.transparent
                : Theme.of(context).dividerColor.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white70 : AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
