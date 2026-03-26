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
  TextColumn get energyLevel => text().withDefault(const Constant('medium'))();
  RealColumn get estimatedCost => real().withDefault(const Constant(0.0))();
  RealColumn get actualCost => real().withDefault(const Constant(0.0))();
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
  TextColumn get energyLevel => text().withDefault(const Constant('medium'))();
  RealColumn get estimatedCost => real().withDefault(const Constant(0.0))();

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

/// Standalone tasks not connected to calendar.
/// Supports three item types: note, timer, list.
class TodoItems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Discriminator: 'note', 'timer', or 'list'
  TextColumn get itemType => text().withDefault(const Constant('note'))();

  /// Timer-only: duration in minutes
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();

  /// List-only: JSON-encoded array of checklist items
  /// e.g. [{"text":"Buy milk","done":false},{"text":"Walk dog","done":true}]
  TextColumn get checklistJson => text().withDefault(const Constant(''))();

  /// Timer-only: path to local audio file played on completion
  TextColumn get audioFilePath => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
