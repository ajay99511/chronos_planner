import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/models/day_plan_model.dart' as domain;
import 'package:chronosky/data/models/task_model.dart' as domain;
import 'package:chronosky/data/repositories/local/local_schedule_repository.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the repository against a real SQLite database rather than mocked
/// DAOs. The batched task read groups rows by `dayPlanId` and relies on the
/// query's ordering holding within each group — properties a mock cannot
/// confirm, since the mock is what returns the rows.
void main() {
  late AppDatabase db;
  late LocalScheduleRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = LocalScheduleRepository(db.dayPlanDao, db.taskDao);
  });

  tearDown(() async {
    await db.close();
  });

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<domain.DayPlan> unwrap(Result<List<domain.DayPlan>> result) =>
      (result as Success<List<domain.DayPlan>>).value;

  domain.Task task(String id, String start, String end) => domain.Task(
        id: id,
        title: 'Task $id',
        startTime: start,
        endTime: end,
        type: domain.TaskType.work,
      );

  test('creates the rolling window and reads it back', () async {
    final days = unwrap(await repository.getUpcomingDays(7));

    expect(days, hasLength(7));
    expect(days.first.date, today());
    expect(days.last.date, today().add(const Duration(days: 6)));
    expect(days.every((d) => d.tasks.isEmpty), isTrue);
  });

  test('groups tasks onto the correct day and orders them by start time',
      () async {
    final start = today();
    await repository.addTaskToDate(start, task('t-late', '16:00', '17:00'));
    await repository.addTaskToDate(start, task('t-early', '08:00', '09:00'));
    await repository.addTaskToDate(
      start.add(const Duration(days: 2)),
      task('t-later-day', '10:00', '11:00'),
    );

    final days = unwrap(await repository.getUpcomingDays(7));

    expect(
      days[0].tasks.map((t) => t.id),
      ['t-early', 't-late'],
      reason: 'the batched query orders by start time within each day',
    );
    expect(days[1].tasks, isEmpty);
    expect(days[2].tasks.map((t) => t.id), ['t-later-day']);
  });

  test('a second read reuses the same day rows', () async {
    final first = unwrap(await repository.getUpcomingDays(7));
    final second = unwrap(await repository.getUpcomingDays(7));

    expect(
      second.map((d) => d.id),
      first.map((d) => d.id),
      reason: 'the window must not be recreated on every load',
    );
    final rows = await db.select(db.dayPlans).get();
    expect(rows, hasLength(7));
  });

  test('deleting a task removes it from the next read', () async {
    final start = today();
    await repository.addTaskToDate(start, task('t-1', '09:00', '10:00'));
    final dayId = unwrap(await repository.getUpcomingDays(1)).single.id;

    await repository.deleteTask(dayId, 't-1');

    expect(unwrap(await repository.getUpcomingDays(1)).single.tasks, isEmpty);
  });

  test('task history spans days and excludes earlier dates', () async {
    final start = today();
    await repository.addTaskToDate(start, task('t-today', '09:00', '10:00'));
    await repository.addTaskToDate(
      start.add(const Duration(days: 1)),
      task('t-tomorrow', '09:00', '10:00'),
    );
    // Materialise the window so both day rows exist.
    await repository.getUpcomingDays(7);

    final fromToday = await repository.getTaskHistory(start);
    final fromTomorrow = await repository.getTaskHistory(
      start.add(const Duration(days: 1)),
    );

    expect(
      (fromToday as Success<List<domain.Task>>).value.map((t) => t.id),
      containsAll(['t-today', 't-tomorrow']),
    );
    expect(
      (fromTomorrow as Success<List<domain.Task>>).value.map((t) => t.id),
      ['t-tomorrow'],
    );
  });
}
