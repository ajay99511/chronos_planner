import 'package:drift/drift.dart';

/// Stores individual tasks belonging to a [DayPlans] entry.
@TableIndex(name: 'idx_tasks_day_plan_id', columns: {#dayPlanId})
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

  // v5: Added ON DELETE CASCADE
  TextColumn get dayPlanId =>
      text().references(DayPlans, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceTemplateId => text().withDefault(const Constant(''))();

  /// SQL-level guards on task data (schema v10).
  ///
  /// `Task.create` is the primary validation, but it only covers data this
  /// version of the app writes. These catch everything else: a code path that
  /// forgets the factory, a raw SQL insert, a row from an older build. "Let the
  /// database enforce what the database can enforce" (stack-appendices.md §2).
  ///
  /// Written as inline literals rather than shared constants because drift's
  /// generator reads the source AST: a reference to a `const` string is
  /// silently emitted as no constraint at all. [TemplateTasks] repeats these
  /// deliberately — the duplication is visible and checked by a test, which is
  /// better than an abstraction the code generator ignores.
  ///
  /// The clock check fixes the shape with GLOB and caps minutes at 59; the
  /// upper-bound comparison rejects hours 24-29, which the character class
  /// alone would admit. Lexical comparison is exact because values are
  /// zero-padded.
  @override
  List<String> get customConstraints => [
        'CHECK (length(title) BETWEEN 1 AND 200)',
        "CHECK (start_time GLOB '[0-2][0-9]:[0-5][0-9]' "
            "AND start_time <= '23:59')",
        "CHECK (end_time GLOB '[0-2][0-9]:[0-5][0-9]' "
            "AND end_time <= '23:59')",
        'CHECK (estimated_cost >= 0.0)',
        'CHECK (actual_cost >= 0.0)',
      ];

  @override
  Set<Column> get primaryKey => {id};
}

/// Represents one day in the weekly schedule.
///
/// v8: `date` is unique — exactly one plan may exist per calendar day.
/// Duplicate rows (a historic source of "lost" tasks) are merged on upgrade.
@TableIndex(name: 'idx_day_plans_week_key', columns: {#weekKey})
@TableIndex(name: 'idx_day_plans_date', columns: {#date}, unique: true)
class DayPlans extends Table {
  TextColumn get id => text()();
  // v5: Removed dateStr and dayOfWeek (now computed)
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
  // v5: Removed activeDays (moved to TemplateActiveDays table)

  @override
  Set<Column> get primaryKey => {id};
}

/// Junction table for template active days.
/// v5: Added
class TemplateActiveDays extends Table {
  TextColumn get templateId =>
      text().references(PlanTemplates, #id, onDelete: KeyAction.cascade)();
  IntColumn get dayIndex => integer()(); // 0-6

  @override
  Set<Column> get primaryKey => {templateId, dayIndex};
}

/// Tasks belonging to a [PlanTemplates] entry.
@TableIndex(name: 'idx_template_tasks_template_id', columns: {#templateId})
class TemplateTasks extends Table {
  TextColumn get id => text()();

  // v5: Added ON DELETE CASCADE
  TextColumn get templateId =>
      text().references(PlanTemplates, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get type => text()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  TextColumn get energyLevel => text().withDefault(const Constant('medium'))();
  RealColumn get estimatedCost => real().withDefault(const Constant(0.0))();

  /// Mirrors [Tasks.customConstraints], minus `actual_cost`, which this table
  /// does not have. A template materialises into tasks, so a template row the
  /// tasks table would reject is a deferred failure.
  @override
  List<String> get customConstraints => [
        'CHECK (length(title) BETWEEN 1 AND 200)',
        "CHECK (start_time GLOB '[0-2][0-9]:[0-5][0-9]' "
            "AND start_time <= '23:59')",
        "CHECK (end_time GLOB '[0-2][0-9]:[0-5][0-9]' "
            "AND end_time <= '23:59')",
        'CHECK (estimated_cost >= 0.0)',
      ];

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
class TodoItems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // v7: Added — tracks last modification for display/sorting
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get itemType => text().withDefault(const Constant('note'))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get checklistJson => text().withDefault(const Constant(''))();
  TextColumn get audioFilePath => text().withDefault(const Constant(''))();
  // v8: Added — wall-clock trigger moment for alarm items (null otherwise)
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  // v8: Added — whether an alarm is armed; one-shot alarms flip to false on fire
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
