import 'dart:io';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/daos/day_plan_dao.dart';
import 'package:chronosky/data/local/daos/task_dao.dart';
import 'package:chronosky/data/models/day_plan_model.dart' as domain;
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
    when(() => mockTaskDao.getTasksForDay(any())).thenAnswer((_) async => []);
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
      when(() => mockTaskDao.getTasksForDay(any())).thenAnswer((_) async => []);

      final result = await repository.getUpcomingDays(1);

      expect(result, isA<Success>());
      expect(failures, 2);
    });

    test('DriftWrappedException returns Failure(DatabaseFailure)', () async {
      when(() => mockDayPlanDao.getDayPlansFrom(any(), any()))
          .thenThrow(DriftWrappedException(message: 'Error', cause: 'SQL Error'));

      final result = await repository.getUpcomingDays(1);

      expect(result, isA<Failure>());
      expect((result as Failure).failure, isA<DatabaseFailure>());
    });
  });
}
