import 'package:chronosky/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The database-level backstop for task invariants.
///
/// `Task.create` is the primary guard, but it only covers data this version of
/// the app writes. These constraints catch anything else: a future code path
/// that forgets the factory, a raw SQL insert, or a row arriving from an older
/// build. "Let the database enforce what the database can enforce"
/// (stack-appendices.md §2). Before v10 nothing at this layer objected —
/// asserts were compiled out of release builds, so `startTime: '99:99'`
/// persisted happily.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    await db.into(db.dayPlans).insert(
          DayPlansCompanion.insert(
            id: 'dp-1',
            date: DateTime(2026, 9, 22),
            weekKey: '2026-W39',
          ),
        );
    await db.into(db.planTemplates).insert(
          PlanTemplatesCompanion.insert(id: 'tmpl-1', name: 'Morning'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertTask({
    String id = 'task-1',
    String title = 'Deep work',
    String startTime = '09:00',
    String endTime = '11:00',
    double estimatedCost = 0,
    double actualCost = 0,
  }) =>
      db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: id,
              title: title,
              startTime: startTime,
              endTime: endTime,
              type: 'work',
              dayPlanId: 'dp-1',
              estimatedCost: Value(estimatedCost),
              actualCost: Value(actualCost),
            ),
          );

  group('tasks.title', () {
    test('accepts a title within bounds', () async {
      await insertTask(title: 'x');
      await insertTask(id: 'task-2', title: 'x' * 200);

      expect(await db.select(db.tasks).get(), hasLength(2));
    });

    test('rejects an empty title', () {
      expect(insertTask(title: ''), throwsA(isA<Exception>()));
    });

    test('rejects a title over 200 characters', () {
      expect(insertTask(title: 'x' * 201), throwsA(isA<Exception>()));
    });
  });

  group('tasks clock times', () {
    test('accepts the boundaries of the clock', () async {
      await insertTask(startTime: '00:00', endTime: '23:59');

      expect(await db.select(db.tasks).get(), hasLength(1));
    });

    for (final bad in ['9:00', '24:00', '25:30', '29:59', '12:60', '', 'noon']) {
      test('rejects "$bad" as a start time', () {
        expect(insertTask(startTime: bad), throwsA(isA<Exception>()));
      });

      test('rejects "$bad" as an end time', () {
        expect(insertTask(endTime: bad), throwsA(isA<Exception>()));
      });
    }
  });

  group('tasks costs', () {
    test('accepts zero and positive costs', () async {
      await insertTask(estimatedCost: 0, actualCost: 12.5);

      expect(await db.select(db.tasks).get(), hasLength(1));
    });

    test('rejects a negative estimated cost', () {
      expect(insertTask(estimatedCost: -0.01), throwsA(isA<Exception>()));
    });

    test('rejects a negative actual cost', () {
      expect(insertTask(actualCost: -1), throwsA(isA<Exception>()));
    });

    test('costs still default to zero when omitted', () async {
      // Table-level constraints leave the column definitions untouched, so
      // drift's own defaults still apply. Pinned because an earlier attempt
      // used column-level customConstraint, which does replace the default.
      await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: 'task-defaults',
              title: 'No costs given',
              startTime: '09:00',
              endTime: '10:00',
              type: 'work',
              dayPlanId: 'dp-1',
            ),
          );

      final row = await db.select(db.tasks).getSingle();
      expect(row.estimatedCost, 0.0);
      expect(row.actualCost, 0.0);
    });
  });

  group('template_tasks', () {
    Future<void> insertTemplateTask({
      String title = 'Stretch',
      String startTime = '07:00',
      double estimatedCost = 0,
    }) =>
        db.into(db.templateTasks).insert(
              TemplateTasksCompanion.insert(
                id: 'ttask-1',
                templateId: 'tmpl-1',
                title: title,
                startTime: startTime,
                endTime: '07:30',
                type: 'health',
                estimatedCost: Value(estimatedCost),
              ),
            );

    test('accepts a valid template task', () async {
      await insertTemplateTask();

      expect(await db.select(db.templateTasks).get(), hasLength(1));
    });

    test('is guarded by the same rules as tasks', () {
      // The two tables must not drift apart: a template materialises into
      // tasks, so a template row the tasks table would reject is a future
      // failure waiting to happen.
      expect(insertTemplateTask(title: ''), throwsA(isA<Exception>()));
      expect(insertTemplateTask(startTime: '25:00'), throwsA(isA<Exception>()));
      expect(
        insertTemplateTask(estimatedCost: -1),
        throwsA(isA<Exception>()),
      );
    });
  });
}
