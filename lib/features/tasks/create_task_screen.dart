import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../data/database/database.dart';
import '../../data/database/database_provider.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _titleFocus = FocusNode();

  int _priority = 1; // 0=low 1=med 2=high
  String _icon = '📋';
  String _color = '#E24B4A';
  bool _isRecurring = false;
  final List<bool> _recurringDays = List.filled(7, false);
  final List<String> _tags = [];
  final _tagCtrl = TextEditingController();

  static List<_Template> get _templates => [
        _Template('tasks.tpl_meeting'.tr(), '👥', '#5C6BC0'),
        _Template('tasks.tpl_email'.tr(), '📧', '#26A69A'),
        _Template('tasks.tpl_coding'.tr(), '💻', '#E24B4A'),
        _Template('tasks.tpl_code_review'.tr(), '🔍', '#F59E0B'),
        _Template('tasks.tpl_deep_work'.tr(), '🎯', '#8B5CF6'),
      ];

  static const _icons = [
    '📋',
    '🎯',
    '💡',
    '🔥',
    '⚡',
    '📚',
    '💻',
    '✉️',
    '📊',
    '🎨',
    '🏃',
    '🍎',
    '👥',
    '🔍',
    '📝',
    '🛠️',
    '🧪',
    '🚀',
    '💰',
    '📱',
    '🌍',
    '🎵',
    '🏋️',
    '☕',
    '📧',
    '🔔',
    '📌',
    '🗂️',
    '📅',
    '⭐',
    '🎓',
    '💪',
    '🌱',
    '🦁',
    '🦉',
    '🐉',
    '🏆',
    '🎖️',
    '🧠',
    '❤️',
    '🔑',
    '🌈',
    '🕐',
    '🔒',
    '📦',
    '🛡️',
    '🌙',
    '☀️',
  ];

  static const _colors = [
    '#E24B4A',
    '#F59E0B',
    '#10B981',
    '#3B82F6',
    '#8B5CF6',
    '#EC4899',
    '#06B6D4',
    '#F97316',
    '#84CC16',
    '#6366F1',
  ];

  static List<String> get _dayLabels => [
        'common.day_letter_sun'.tr(),
        'common.day_letter_mon'.tr(),
        'common.day_letter_tue'.tr(),
        'common.day_letter_wed'.tr(),
        'common.day_letter_thu'.tr(),
        'common.day_letter_fri'.tr(),
        'common.day_letter_sat'.tr(),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _titleFocus.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(_Template t) {
    setState(() {
      _titleCtrl.text = t.name;
      _icon = t.icon;
      _color = t.color;
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _titleFocus.requestFocus();
      return;
    }
    final db = ref.read(dbProvider);
    await db.insertTask(
      TasksCompanion.insert(
        title: _titleCtrl.text.trim(),
        description: drift.Value(
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        ),
        priority: drift.Value(_priority),
        icon: drift.Value(_icon),
        categoryColor: drift.Value(_color),
        isRecurring: drift.Value(_isRecurring),
        recurringDays: drift.Value(
          _isRecurring
              ? jsonEncode(
                  _recurringDays
                      .asMap()
                      .entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList(),
                )
              : null,
        ),
        tags: drift.Value(jsonEncode(_tags)),
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.92,
      maxChildSize: 0.97,
      snap: true,
      snapSizes: const [0.92, 0.97],
      expand: false,
      builder: (ctx, scrollCtrl) => Scaffold(
        backgroundColor: Theme.of(context).cardTheme.color,
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardTheme.color,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'tasks.new_task'.tr(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text(
                'tasks.save'.tr(),
                style: TextStyle(
                  color: _titleCtrl.text.trim().isEmpty
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: scrollCtrl,
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            32 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Section(label: 'tasks.templates'.tr()),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _templates
                      .map(
                        (t) => GestureDetector(
                          onTap: () => _applyTemplate(t),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            width: 72,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(t.color.replaceAll('#', '0xFF')),
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(
                                  int.parse(t.color.replaceAll('#', '0xFF')),
                                ).withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  t.icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              _Section(label: 'tasks.title_section'.tr()),
              TextField(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'tasks.title_hint'.tr(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              _Section(label: 'tasks.appearance'.tr()),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showIconPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(_icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'tasks.icon_label'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showColorPicker(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(_color.replaceAll('#', '0xFF')),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'tasks.color_label'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(label: 'tasks.desc_section'.tr()),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'tasks.desc_hint'.tr(),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              _Section(label: 'tasks.priority'.tr()),
              Row(
                children: [
                  _PriorityBtn(
                    label: 'tasks.priority_high'.tr(),
                    color: AppColors.priorityHigh,
                    selected: _priority == 2,
                    onTap: () => setState(() => _priority = 2),
                    icon: Icons.keyboard_double_arrow_up_rounded,
                  ),
                  const SizedBox(width: 8),
                  _PriorityBtn(
                    label: 'tasks.priority_med'.tr(),
                    color: AppColors.priorityMed,
                    selected: _priority == 1,
                    onTap: () => setState(() => _priority = 1),
                    icon: Icons.remove_rounded,
                  ),
                  const SizedBox(width: 8),
                  _PriorityBtn(
                    label: 'tasks.priority_low'.tr(),
                    color: AppColors.priorityLow,
                    selected: _priority == 0,
                    onTap: () => setState(() => _priority = 0),
                    icon: Icons.keyboard_double_arrow_down_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.repeat_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'tasks.recurring'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isRecurring,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _isRecurring = v),
                        ),
                      ],
                    ),
                    if (_isRecurring) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final selected = _recurringDays[i];
                          return GestureDetector(
                            onTap: () => setState(
                              () => _recurringDays[i] = !_recurringDays[i],
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _dayLabels[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _Section(label: 'tasks.tags'.tr()),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._tags.map(
                    (tag) => GestureDetector(
                      onTap: () => setState(() => _tags.remove(tag)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tag,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addTag,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'tasks.add_tag'.tr(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text('tasks.create'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('tasks.add_tag_title'.tr()),
        content: TextField(
          controller: _tagCtrl,
          autofocus: true,
          decoration: InputDecoration(hintText: 'tasks.add_tag_hint'.tr()),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              setState(() => _tags.add(v.trim()));
            }
            _tagCtrl.clear();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (_tagCtrl.text.trim().isNotEmpty) {
                setState(() => _tags.add(_tagCtrl.text.trim()));
              }
              _tagCtrl.clear();
              Navigator.pop(ctx);
            },
            child: Text('common.add'.tr()),
          ),
        ],
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'tasks.choose_icon'.tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _icons.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () {
                  setState(() => _icon = _icons[i]);
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _icon == _icons[i]
                        ? AppColors.primaryLight
                        : Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _icon == _icons[i]
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _icons[i],
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'tasks.choose_color'.tr(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((c) {
                final isSelected = c == _color;
                return GestureDetector(
                  onTap: () {
                    setState(() => _color = c);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(int.parse(c.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(
                                  int.parse(c.replaceAll('#', '0xFF')),
                                ).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 22,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Template {
  const _Template(this.name, this.icon, this.color);
  final String name;
  final String icon;
  final String color;
}

class _Section extends StatelessWidget {
  const _Section({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PriorityBtn extends StatelessWidget {
  const _PriorityBtn({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.icon,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
