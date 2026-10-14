import 'dart:async';
import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/seeds/default_plan_templates.dart';
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
    registerFallbackValue(<Task>[]);
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
    when(() => mockPrefRepo.set(any(), any()))
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
      // Operation failures surface transiently (a snackbar) and must NOT set
      // the fatal errorMessage, which would blank the whole schedule screen.
      expect(provider.errorMessage, isNull);
      expect(provider.takeTransientError(), 'Delete failed');
    });

    test('refreshIfDateChanged is a no-op when the date has not changed',
        () async {
      provider = ScheduleStateProvider(
        scheduleRepo: mockScheduleRepo,
        templateRepo: mockTemplateRepo,
        prefRepo: mockPrefRepo,
        logger: mockLogger,
      );
      await provider.loadData();

      clearInteractions(mockScheduleRepo);

      // Same calendar day → must not re-hit the repository.
      await provider.refreshIfDateChanged();

      verifyNever(() => mockScheduleRepo.getUpcomingDays(any()));
    });

    // getSortedTasks is called from a Selector, so before memoization it did
    // an O(n log n) copy-and-sort on every notify and every parent rebuild.
    // The observable contract is that the same instance comes back until
    // something it depends on changes.
    group('getSortedTasks memoization', () {
      late DayPlan day;

      Future<ScheduleStateProvider> loaded() async {
        final now = DateTime.now();
        day = DayPlan(
          id: 'd1',
          date: DateTime(now.year, now.month, now.day),
          tasks: [
            Task(
              id: 'late',
              title: 'Late',
              startTime: '17:00',
              endTime: '18:00',
              type: TaskType.work,
            ),
            Task(
              id: 'early',
              title: 'Early',
              startTime: '08:00',
              endTime: '09:00',
              type: TaskType.work,
            ),
          ],
        );
        when(() => mockScheduleRepo.getUpcomingDays(any()))
            .thenAnswer((_) async => Success([day]));
        when(() => mockPrefRepo.set(any(), any()))
            .thenAnswer((_) async => const Success(null));
        final p = ScheduleStateProvider(
          scheduleRepo: mockScheduleRepo,
          templateRepo: mockTemplateRepo,
          prefRepo: mockPrefRepo,
          logger: mockLogger,
        );
        await p.loadData();
        return p;
      }

      test('sorts ascending by start time', () async {
        provider = await loaded();

        expect(
          provider.getSortedTasks(provider.selectedDay).map((t) => t.id),
          ['early', 'late'],
        );
      });

      test('returns the same instance on a repeat call', () async {
        provider = await loaded();
        final first = provider.getSortedTasks(provider.selectedDay);

        expect(provider.getSortedTasks(provider.selectedDay), same(first));
      });

      test('recomputes when the sort order changes', () async {
        provider = await loaded();
        final ascending = provider.getSortedTasks(provider.selectedDay);

        await provider.toggleSortOrder();
        final descending = provider.getSortedTasks(provider.selectedDay);

        expect(descending, isNot(same(ascending)));
        expect(descending.map((t) => t.id), ['late', 'early']);
      });

      test('recomputes when the day is replaced by a mutation', () async {
        provider = await loaded();
        final before = provider.getSortedTasks(provider.selectedDay);

        when(() => mockScheduleRepo.addTaskToDate(any(), any()))
            .thenAnswer((_) async => const Success(null));
        await provider.addTask(
          Task(
            id: 'midday',
            title: 'Midday',
            startTime: '12:00',
            endTime: '13:00',
            type: TaskType.work,
          ),
        );

        final after = provider.getSortedTasks(provider.selectedDay);
        expect(after, isNot(same(before)));
        expect(after.map((t) => t.id), ['early', 'midday', 'late']);
      });

      test('hands back a list the caller cannot corrupt', () async {
        provider = await loaded();
        final sorted = provider.getSortedTasks(provider.selectedDay);

        // The same instance is returned repeatedly, so an in-place mutation
        // would poison every later reader.
        expect(() => sorted.sort(), throwsUnsupportedError);
      });
    });

    test('applyTemplateToDays maps weekday indices to the correct dates',
        () async {
      // Rolling week starting today — whatever weekday that is.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final week = List.generate(
        7,
        (i) => DayPlan(
          id: 'd$i',
          date: today.add(Duration(days: i)),
          tasks: [],
        ),
      );
      when(() => mockScheduleRepo.getUpcomingDays(any()))
          .thenAnswer((_) async => Success(week));

      final appliedDates = <DateTime>[];
      when(() => mockScheduleRepo.addTasksToDate(any(), any()))
          .thenAnswer((inv) async {
        appliedDates.add(inv.positionalArguments[0] as DateTime);
        return const Success(null);
      });

      provider = ScheduleStateProvider(
        scheduleRepo: mockScheduleRepo,
        templateRepo: mockTemplateRepo,
        prefRepo: mockPrefRepo,
        logger: mockLogger,
      );
      await provider.loadData();

      final template = PlanTemplate(
        id: 'tmpl1',
        name: 'Plan',
        description: '',
        tasks: [
          TemplateTask(
            id: 'tt1',
            templateId: 'tmpl1',
            title: 'Task',
            startTime: '09:00',
            endTime: '10:00',
            type: TaskType.work,
          ),
        ],
      );

      // Select Monday (0) and Wednesday (2) — the dialog's day-chip encoding.
      await provider.applyTemplateToDays(template, [0, 2]);

      expect(appliedDates.length, 2);
      expect(
        appliedDates.map((d) => d.weekday).toSet(),
        {DateTime.monday, DateTime.wednesday},
      );
    });

    test('applying a template carries its reminder settings onto the tasks',
        () async {
      // A plan is the main way tasks get created, so dropping reminder state
      // here would mean the user re-arms every reminder after every apply.
      final added = <Task>[];
      when(() => mockScheduleRepo.addTasksToDate(any(), any()))
          .thenAnswer((inv) async {
        added.addAll(inv.positionalArguments[1] as List<Task>);
        return const Success(null);
      });

      final template = PlanTemplate(
        id: 'tmpl-1',
        name: 'Weekday Essentials',
        description: '',
        tasks: [
          TemplateTask(
            id: 'tt-1',
            templateId: 'tmpl-1',
            title: 'Deep work block',
            startTime: '09:00',
            endTime: '11:00',
            type: TaskType.work,
            reminderEnabled: true,
            reminderLeadMinutes: 30,
          ),
        ],
      );

      provider = ScheduleStateProvider(
        scheduleRepo: mockScheduleRepo,
        templateRepo: mockTemplateRepo,
        prefRepo: mockPrefRepo,
        logger: mockLogger,
      );
      await provider.loadData();

      await provider.applyTemplate(template, 0);

      expect(added, hasLength(1));
      expect(added.single.reminderEnabled, isTrue);
      expect(added.single.reminderLeadMinutes, 30);
    });

    group('starter templates', () {
      test('an empty library on a first run is seeded once', () async {
        final seeded = <PlanTemplate>[];
        when(() => mockTemplateRepo.addTemplate(any())).thenAnswer((inv) async {
          seeded.add(inv.positionalArguments.first as PlanTemplate);
          return const Success(null);
        });

        provider = ScheduleStateProvider(
          scheduleRepo: mockScheduleRepo,
          templateRepo: mockTemplateRepo,
          prefRepo: mockPrefRepo,
          logger: mockLogger,
        );
        await provider.loadData();
        // Seeding is fired without awaiting so the first frame is not held
        // behind it.
        await Future<void>.delayed(Duration.zero);

        expect(seeded.length, defaultPlanTemplates().length);
        // Never recurring: a seeded recurring plan would write itself into the
        // user's week on first launch without being asked.
        expect(seeded.every((t) => t.isRecurring), isFalse);
        verify(() => mockPrefRepo.set('templates_seeded', any())).called(1);
      });

      test('an empty library is not re-seeded once the flag is set', () async {
        when(() => mockPrefRepo.get('templates_seeded'))
            .thenAnswer((_) async => const Success('true'));

        provider = ScheduleStateProvider(
          scheduleRepo: mockScheduleRepo,
          templateRepo: mockTemplateRepo,
          prefRepo: mockPrefRepo,
          logger: mockLogger,
        );
        await provider.loadData();
        await Future<void>.delayed(Duration.zero);

        // Deleting every plan is a decision, not missing data.
        verifyNever(() => mockTemplateRepo.addTemplate(any()));
      });

      test('an unreadable flag is treated as already seeded', () async {
        when(() => mockPrefRepo.get('templates_seeded')).thenAnswer(
          (_) async => const Failure(DatabaseFailure('pref read failed')),
        );

        provider = ScheduleStateProvider(
          scheduleRepo: mockScheduleRepo,
          templateRepo: mockTemplateRepo,
          prefRepo: mockPrefRepo,
          logger: mockLogger,
        );
        await provider.loadData();
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => mockTemplateRepo.addTemplate(any()));
      });
    });
  });
}
