import 'package:drift/drift.dart';

/// Stores individual tasks belonging to a [DayPlans] entry.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get startTime => text()(); // "HH:mm"
  TextColumn get endTime => text()(); // "HH:mm"
  TextColumn get type => text()(); // TaskType enum name
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get dayPlanId => text().references(DayPlans, #id)();
  TextColumn get sourceTemplateId => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Represents one day in the weekly schedule.
class DayPlans extends Table {
  TextColumn get id => text()();
  TextColumn get dateStr => text()(); // "Feb 10"
  TextColumn get dayOfWeek => text()(); // "Monday"
  DateTimeColumn get date => dateTime()();
  TextColumn get weekKey => text()(); // "2026-W07"

  @override
  Set<Column> get primaryKey => {id};
}

/// Metadata for a reusable plan template.
class PlanTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get activeDays => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tasks belonging to a [PlanTemplates] entry.
class TemplateTasks extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text().references(PlanTemplates, #id)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get type => text()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Simple key-value store for user preferences.
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
