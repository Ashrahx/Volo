import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/database/database_provider.dart';

final activeTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(dbProvider).watchActiveTasks();
});

final completedTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(dbProvider).watchCompletedTasks();
});

final isProProvider = StateProvider<bool>((ref) => false);
