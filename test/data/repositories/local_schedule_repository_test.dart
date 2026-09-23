import 'dart:io';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/daos/day_plan_dao.dart';
import 'package:chronosky/data/local/daos/task_dao.dart';
import 'package:chronosky/data/models/day_plan_model.dart' as domain;
import 'package:chronosky/data/models/task_model.dart' as domain;
import 'package:chronosky/data/repositories/local/local_schedule_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Runs transactions inline so repository logic can be tested against mocks.
class _FakeDb extends Fake implements AppDatabase {
  @override
  Future<T> transaction<T>(Future<T> Function() action,
      {bool requireNew = false,}) =>
      action();
}

class MockDayPlanDao extends Mock implements DayPlanDao {
  @override
  AppDatabase get attachedDatabase => _FakeDb();
}

class MockTaskDao extends Mock implements TaskDao {}

/// A generated `Task` row, as the DAO would return it.
Task _taskRow({
  required String id,
  required String dayPlanId,
  String startTime = '09:00',
}) =>
    Task(
      id: id,
      title: 'Row $id',
      description: '',
      startTime: startTime,
      endTime: '23:00',
      type: 'work',
      priority: 'medium',
      energyLevel: 'medium',
      estimatedCost: 0,
      actualCost: 0,
      completed: false,
      dayPlanId: dayPlanId,
      sourceTemplateId: '',
    );

void main() {
  late LocalScheduleRepository repository;
  late MockDayPlanDao mockDayPlanDao;
  late MockTaskDao mockTaskDao;

  /// In-memory day plan rows; insertDayPlans appends so the re-read after
  /// insert (id re-resolution) sees the created rows, as the real DB would.
  late List<DayPlan> stored;

  void stubStatefulDao() {
    when(() => mockDayPlanDao.getDayPlansFrom(any(), any()))
        .thenAnswer((_) async => List.of(stored));
    when(() => mockDayPlanDao.insertDayPlans(any())).thenAnswer((inv) async {
      final plans = inv.positionalArguments[0] as List<DayPlansCompanion>;
      for (final p in plans) {
        stored.add(
          DayPlan(id: p.id.value, date: p.date.value, weekKey: p.weekKey.value),
        );
      }
    });
    when(() => mockTaskDao.getTasksForDays(any())).thenAnswer((_) async => []);
  }

  setUp(() {
    mockDayPlanDao = MockDayPlanDao();
    mockTaskDao = MockTaskDao();
    repository = LocalScheduleRepository(mockDayPlanDao, mockTaskDao);
    stored = [];

    registerFallbackValue(const DayPlansCompanion());
    registerFallbackValue(const TasksCompanion());
  });

  group('LocalScheduleRepository', () {
    test('getUpcomingDays(7) returns exactly 7 DayPlan objects', () async {
      stubStatefulDao();

      final result = await repository.getUpcomingDays(7);

      expect(result, isA<Success<List<domain.DayPlan>>>());
      final list = (result as Success<List<domain.DayPlan>>).value;
      expect(list.length, 7);
      // Every returned id must correspond to a persisted row.
      final storedIds = stored.map((p) => p.id).toSet();
      expect(list.every((p) => storedIds.contains(p.id)), isTrue);
    });

    test('getUpcomingDays reuses existing rows instead of duplicating',
        () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      stored = [DayPlan(id: 'existing-id', date: today, weekKey: 'w')];
      stubStatefulDao();

      final result = await repository.getUpcomingDays(1);

      final list = (result as Success<List<domain.DayPlan>>).value;
      expect(list.single.id, 'existing-id');
      expect(stored.length, 1);
    });

    test('retry logic fires on FileSystemException', () async {
      int failures = 0;
      when(() => mockDayPlanDao.getDayPlansFrom(any(), any()))
          .thenAnswer((_) async {
        if (failures < 2) {
          failures++;
          throw const FileSystemException('Busy');
        }
        return List.of(stored);
      });
      when(() => mockDayPlanDao.insertDayPlans(any())).thenAnswer((inv) async {
        final plans = inv.positionalArguments[0] as List<DayPlansCompanion>;
        for (final p in plans) {
          stored.add(
            DayPlan(
                id: p.id.value, date: p.date.value, weekKey: p.weekKey.value,),
          );
        }
      });
      when(() => mockTaskDao.getTasksForDays(any()))
          .thenAnswer((_) async => []);

      final result = await repository.getUpcomingDays(1);

      expect(result, isA<Success>());
      expect(failures, 2);
    });

    // performance-efficiency.md lists N+1 as the most frequent suspect: the
    // schedule loads seven days at once and previously issued one task query
    // per day inside the loop.
    test('getUpcomingDays reads every day\'s tasks in a single query',
        () async {
      stubStatefulDao();

      final result = await repository.getUpcomingDays(7);

      expect(result, isA<Success>());
      verify(() => mockTaskDao.getTasksForDays(any())).called(1);
    });

    test('getUpcomingDays attaches each task to its own day', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      stored = [
        DayPlan(id: 'day-0', date: today, weekKey: 'w'),
        DayPlan(
          id: 'day-1',
          date: today.add(const Duration(days: 1)),
          weekKey: 'w',
        ),
      ];
      stubStatefulDao();
      when(() => mockTaskDao.getTasksForDays(any())).thenAnswer(
        (_) async => [
          _taskRow(id: 't-today', dayPlanId: 'day-0', startTime: '09:00'),
          _taskRow(id: 't-tomorrow', dayPlanId: 'day-1', startTime: '10:00'),
          _taskRow(id: 't-today-2', dayPlanId: 'day-0', startTime: '14:00'),
        ],
      );

      final result = await repository.getUpcomingDays(2);
      final days = (result as Success<List<domain.DayPlan>>).value;

      expect(
        days[0].tasks.map((t) => t.id),
        ['t-today', 't-today-2'],
        reason: 'grouping must keep the query order within a day',
      );
      expect(days[1].tasks.map((t) => t.id), ['t-tomorrow']);
    });

    test('DriftWrappedException returns Failure(DatabaseFailure)', () async {
      when(() => mockDayPlanDao.getDayPlansFrom(any(), any()))
          .thenThrow(DriftWrappedException(message: 'Error', cause: 'SQL Error'));

      final result = await repository.getUpcomingDays(1);

      expect(result, isA<Failure>());
      expect((result as Failure).failure, isA<DatabaseFailure>());
    });

    // `Error` does not implement `Exception`, so a catch clause written as
    // `on Exception` lets StateError/RangeError escape the Result envelope
    // entirely. The caller's rollback never runs and the write is lost with
    // no trace. See C-3 in AUDIT_AND_STANDARDS_ANALYSIS.md.
    test('an Error thrown by a DAO is captured as Failure, not rethrown',
        () async {
      when(() => mockDayPlanDao.getDayPlansFrom(any(), any()))
          .thenThrow(StateError('database in an impossible state'));

      final result = await repository.getUpcomingDays(1);

      expect(result, isA<Failure>());
      expect((result as Failure).failure, isA<UnknownFailure>());
    });

    test('addTaskToDate reports a Failure when the day plan cannot be resolved',
        () async {
      // Reproduces the real path: the INSERT OR IGNORE is ignored because
      // another row already claims the date, so the id re-read returns null
      // and _ensureDayPlanId throws StateError.
      when(() => mockDayPlanDao.getDayPlanId(any()))
          .thenAnswer((_) async => null);
      when(() => mockDayPlanDao.insertDayPlan(any())).thenAnswer((_) async {});

      final result = await repository.addTaskToDate(
        DateTime(2026, 8, 24),
        domain.Task(
          id: 'task-1',
          title: 'Write the audit',
          startTime: '09:00',
          endTime: '11:00',
          type: domain.TaskType.work,
        ),
      );

      expect(
        result,
        isA<Failure>(),
        reason: 'the caller must be able to roll back its optimistic update',
      );
    });
  });
}
