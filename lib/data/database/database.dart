import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get category => text().withDefault(const Constant('default'))();
  TextColumn get categoryColor =>
      text().withDefault(const Constant('#E24B4A'))();
  TextColumn get icon => text().withDefault(const Constant('📋'))();
  TextColumn get description => text().nullable()();
  IntColumn get priority =>
      integer().withDefault(const Constant(1))(); // 0=low 1=med 2=high
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurringDays => text().nullable()(); // JSON: [1,3,5]
  TextColumn get tags =>
      text().withDefault(const Constant('[]'))(); // JSON array
  IntColumn get subtaskTotal => integer().withDefault(const Constant(0))();
  IntColumn get subtaskDone => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().nullable().references(Tasks, #id)();
  IntColumn get type =>
      integer().withDefault(const Constant(0))(); // 0=focus 1=short 2=long
  IntColumn get durationSeconds => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Tasks, Sessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pomodo.db');
  }

  Stream<List<Task>> watchActiveTasks() => (select(tasks)
        ..where((t) => t.isCompleted.equals(false))
        ..orderBy([
          (t) => OrderingTerm.desc(t.priority),
          (t) => OrderingTerm.desc(t.createdAt)
        ]))
      .watch();

  Stream<List<Task>> watchCompletedTasks() => (select(tasks)
        ..where((t) => t.isCompleted.equals(true))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
      .watch();

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(Task task) => update(tasks).replace(task);

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<int> countActiveTasks() async {
    final count = tasks.id.count();
    final query = selectOnly(tasks)
      ..addColumns([count])
      ..where(tasks.isCompleted.equals(false));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertSession(SessionsCompanion session) =>
      into(sessions).insert(session);

  Future<bool> updateSession(Session session) =>
      update(sessions).replace(session);

  Future<List<Session>> getTodaySessions() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return (select(sessions)
          ..where((s) =>
              s.startedAt.isBiggerOrEqualValue(start) &
              s.startedAt.isSmallerThanValue(end) &
              s.completed.equals(true)))
        .get();
  }

  Future<int> countTodaySessions() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final count = sessions.id.count();
    final query = selectOnly(sessions)
      ..addColumns([count])
      ..where(sessions.startedAt.isBiggerOrEqualValue(start) &
          sessions.startedAt.isSmallerThanValue(end) &
          sessions.completed.equals(true));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<Map<DateTime, int>> getHeatmapData(int weeks) async {
    final cutoff = DateTime.now().subtract(Duration(days: weeks * 7));
    final rows = await (select(sessions)
          ..where((s) =>
              s.startedAt.isBiggerOrEqualValue(cutoff) &
              s.completed.equals(true)))
        .get();

    final map = <DateTime, int>{};
    for (final s in rows) {
      final day =
          DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  Future<int> getTotalCompletedSessions() async {
    final count = sessions.id.count();
    final query = selectOnly(sessions)
      ..addColumns([count])
      ..where(sessions.completed.equals(true));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> getTotalActiveDays() async {
    final rows =
        await (select(sessions)..where((s) => s.completed.equals(true))).get();
    final days = <String>{};
    for (final s in rows) {
      days.add('${s.startedAt.year}-${s.startedAt.month}-${s.startedAt.day}');
    }
    return days.length;
  }

  Future<int> getCurrentStreak() async {
    final rows = await (select(sessions)
          ..where((s) => s.completed.equals(true))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();

    final days = <DateTime>{};
    for (final s in rows) {
      days.add(DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day));
    }
    if (days.isEmpty) return 0;

    final sorted = days.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime expected = DateTime.now();
    expected = DateTime(expected.year, expected.month, expected.day);

    for (final day in sorted) {
      if (day == expected ||
          day == expected.subtract(const Duration(days: 1))) {
        streak++;
        expected = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<Map<int, int>> getHourlyFocusToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final rows = await (select(sessions)
          ..where((s) =>
              s.startedAt.isBiggerOrEqualValue(start) &
              s.startedAt.isSmallerThanValue(end) &
              s.type.equals(0) &
              s.completed.equals(true)))
        .get();

    final map = <int, int>{};
    for (final s in rows) {
      final hour = s.startedAt.hour;
      map[hour] = (map[hour] ?? 0) + s.durationSeconds;
    }
    return map;
  }

  Future<int> getTotalFocusMinutes() async {
    final rows = await (select(sessions)
          ..where((s) => s.completed.equals(true) & s.type.equals(0)))
        .get();
    final totalSecs = rows.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    return totalSecs ~/ 60;
  }
}
