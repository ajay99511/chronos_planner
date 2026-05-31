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

class MockDayPlanDao extends Mock implements DayPlanDao {}
class MockTaskDao extends Mock implements TaskDao {}

void main() {
  late LocalScheduleRepository repository;
  late MockDayPlanDao mockDayPlanDao;
  late MockTaskDao mockTaskDao;

  setUp(() {
    mockDayPlanDao = MockDayPlanDao();
    mockTaskDao = MockTaskDao();
    repository = LocalScheduleRepository(mockDayPlanDao, mockTaskDao);
    
    registerFallbackValue(const DayPlansCompanion());
    registerFallbackValue(const TasksCompanion());
  });

  group('LocalScheduleRepository', () {
    test('getUpcomingDays(7) returns exactly 7 DayPlan objects', () async {
      when(() => mockDayPlanDao.getDayPlansFrom(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockDayPlanDao.insertDayPlans(any()))
          .thenAnswer((_) async => []);

      final result = await repository.getUpcomingDays(7);

      expect(result, isA<Success<List<domain.DayPlan>>>());
      final list = (result as Success<List<domain.DayPlan>>).value;
      expect(list.length, 7);
    });

    test('retry logic fires on FileSystemException', () async {
      int calls = 0;
      when(() => mockDayPlanDao.getDayPlansFrom(any(), any())).thenAnswer((_) async {
        calls++;
        if (calls < 3) {
          throw const FileSystemException('Busy');
        }
        return [];
      });
      when(() => mockDayPlanDao.insertDayPlans(any()))
          .thenAnswer((_) async => []);

      final result = await repository.getUpcomingDays(1);

      expect(result, isA<Success>());
      expect(calls, 3);
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
