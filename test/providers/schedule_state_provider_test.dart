import 'dart:async';
import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/repositories/schedule_repository.dart';
import 'package:chronosky/data/repositories/template_repository.dart';
import 'package:chronosky/data/repositories/preference_repository.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduleRepo extends Mock implements ScheduleRepository {}
class MockTemplateRepo extends Mock implements TemplateRepository {}
class MockPrefRepo extends Mock implements PreferenceRepository {}
class MockLogger extends Mock implements Logger {}

class FakeTask extends Fake implements Task {}
class FakeTemplate extends Fake implements PlanTemplate {}

void main() {
  late ScheduleStateProvider provider;
  late MockScheduleRepo mockScheduleRepo;
  late MockTemplateRepo mockTemplateRepo;
  late MockPrefRepo mockPrefRepo;
  late MockLogger mockLogger;

  setUpAll(() {
    registerFallbackValue(FakeTask());
    registerFallbackValue(FakeTemplate());
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockScheduleRepo = MockScheduleRepo();
    mockTemplateRepo = MockTemplateRepo();
    mockPrefRepo = MockPrefRepo();
    mockLogger = MockLogger();

    // Default successes
    when(() => mockScheduleRepo.getUpcomingDays(any()))
        .thenAnswer((_) async => Success([DayPlan(id: 'd1', date: DateTime.now(), tasks: [])]));
    when(() => mockTemplateRepo.getAllTemplates())
        .thenAnswer((_) async => const Success(<PlanTemplate>[])); // Non-const for mutability
    when(() => mockPrefRepo.get(any()))
        .thenAnswer((_) async => const Success(null));
    when(() => mockTemplateRepo.addTemplate(any()))
        .thenAnswer((_) async => const Success(null));
  });

  group('ScheduleStateProvider', () {
    test('initial data load populates weekPlan', () async {
      provider = ScheduleStateProvider(
        scheduleRepo: mockScheduleRepo,
        templateRepo: mockTemplateRepo,
        prefRepo: mockPrefRepo,
        logger: mockLogger,
      );
      
      await provider.loadData();
      
      expect(provider.weekPlan.length, 1);
      expect(provider.weekPlan[0].id, 'd1');
    });

    test('addTask optimistically updates UI', () async {
      final now = DateTime.now();
      final day = DayPlan(id: 'd1', date: now, tasks: []);
      when(() => mockScheduleRepo.getUpcomingDays(any()))
          .thenAnswer((_) async => Success([day]));
      
      final completer = Completer<Result<void>>();
      when(() => mockScheduleRepo.addTaskToDate(any(), any()))
          .thenAnswer((_) => completer.future);

      provider = ScheduleStateProvider(
        scheduleRepo: mockScheduleRepo,
        templateRepo: mockTemplateRepo,
        prefRepo: mockPrefRepo,
        logger: mockLogger,
      );
      await provider.loadData();

      final task = Task(id: 't1', title: 'New Task', startTime: '09:00', endTime: '10:00', type: TaskType.work);
      
      final future = provider.addTask(task);
      
      expect(provider.weekPlan[0].tasks.length, 1);
      expect(provider.weekPlan[0].tasks[0].id, 't1');

      completer.complete(const Success(null));
      await future;
    });

    test('deleteTask triggers rollback on repository failure', () async {
      final now = DateTime.now();
      final task = Task(id: 't1', title: 'T1', startTime: '09:00', endTime: '10:00', type: TaskType.work);
      final day = DayPlan(id: 'd1', date: now, tasks: [task]);
      
      when(() => mockScheduleRepo.getUpcomingDays(any()))
          .thenAnswer((_) async => Success([day]));
      when(() => mockScheduleRepo.deleteTask(any(), any()))
          .thenAnswer((_) async => const Failure(DatabaseFailure('Delete failed')));

      provider = ScheduleStateProvider(
        scheduleRepo: mockScheduleRepo,
        templateRepo: mockTemplateRepo,
        prefRepo: mockPrefRepo,
        logger: mockLogger,
      );
      await provider.loadData();

      await provider.deleteTask('t1');
      
      expect(provider.weekPlan[0].tasks.length, 1);
      expect(provider.errorMessage, 'Delete failed');
    });
  });
}
