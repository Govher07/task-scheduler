import 'package:drift/drift.dart';
import 'tables/goals_table.dart';
import 'tables/tasks_table.dart';
import 'tables/events_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Goals, Tasks, Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
