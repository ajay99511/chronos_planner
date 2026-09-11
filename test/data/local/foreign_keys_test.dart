import 'package:chronosky/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the referential cascades declared in `tables.dart`.
///
/// SQLite defaults `PRAGMA foreign_keys` to OFF per connection, which silently
/// turns every `ON DELETE CASCADE` into a no-op. These tests assert the
/// observable behaviour (children disappear with their parent) rather than the
/// pragma itself, so they keep passing if the enforcement mechanism changes.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
  });

  tearDown(() async {
    await db.close();
  });

  group('foreign key cascades', () {
    test('deleting a template removes its active-day rows', () async {
      await db.into(db.planTemplates).insert(
            PlanTemplatesCompanion.insert(id: 'tmpl-1', name: 'Deep Work'),
          );
      await db.into(db.templateActiveDays).insert(
            TemplateActiveDaysCompanion.insert(
              templateId: 'tmpl-1',
              dayIndex: 4,
            ),
          );

      await (db.delete(db.planTemplates)
            ..where((t) => t.id.equals('tmpl-1')))
          .go();

      final orphans = await db.select(db.templateActiveDays).get();
      expect(
        orphans,
        isEmpty,
        reason: 'active-day rows must not outlive their template',
      );
    });

    test('deleting a template removes its template tasks', () async {
      await db.into(db.planTemplates).insert(
            PlanTemplatesCompanion.insert(id: 'tmpl-2', name: 'Morning'),
          );
      await db.into(db.templateTasks).insert(
            TemplateTasksCompanion.insert(
              id: 'ttask-1',
              templateId: 'tmpl-2',
              title: 'Stretch',
              startTime: '07:00',
              endTime: '07:30',
              type: 'health',
            ),
          );

      await (db.delete(db.planTemplates)
            ..where((t) => t.id.equals('tmpl-2')))
          .go();

      final orphans = await db.select(db.templateTasks).get();
      expect(
        orphans,
        isEmpty,
        reason: 'template tasks must not outlive their template',
      );
    });

    test('deleting a day plan removes its tasks', () async {
      await db.into(db.dayPlans).insert(
            DayPlansCompanion.insert(
              id: 'dp-1',
              date: DateTime(2026, 8, 24),
              weekKey: '2026-W35',
            ),
          );
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 'task-1',
              title: 'Write audit',
              startTime: '09:00',
              endTime: '11:00',
              type: 'work',
              dayPlanId: 'dp-1',
            ),
          );

      await (db.delete(db.dayPlans)..where((d) => d.id.equals('dp-1'))).go();

      final orphans = await db.select(db.tasks).get();
      expect(
        orphans,
        isEmpty,
        reason: 'tasks must not outlive their day plan',
      );
    });

    test('a task cannot reference a day plan that does not exist', () async {
      await expectLater(
        db.into(db.tasks).insert(
              TasksCompanion.insert(
                id: 'task-2',
                title: 'Dangling',
                startTime: '09:00',
                endTime: '10:00',
                type: 'work',
                dayPlanId: 'no-such-day-plan',
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
