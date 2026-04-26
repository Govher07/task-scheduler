import 'package:drift/drift.dart';
import 'goals_table.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get goalId => text().nullable().references(Goals, #id)();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  DateTimeColumn get deadline => dateTime().nullable()();
  IntColumn get estimatedDurationMinutes => integer().nullable()();
  IntColumn get effortLevel => integer().withDefault(const Constant(1))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
