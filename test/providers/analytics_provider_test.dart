import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/intelligence_service.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/providers/analytics_provider.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

/// AnalyticsProvider had no tests at all, because it hard-constructed
/// IntelligenceService and so could not be exercised without running the real
/// peak calculation and its isolate hop. See L-3 in the audit.
class _StubIntelligence extends IntelligenceService {
  int callCount = 0;
  Map<int, double> peaks = const {};

  @override
  Future<Map<int, double>> getEnergyPeaks(List<Task> history) async {
    callCount++;
    lastHistory = history;
    return peaks;
  }

  List<Task> lastHistory = const [];
}

void main() {
  late MockScheduleRepository scheduleRepo;
  late MockTemplateRepository templateRepo;
  late MockPreferenceRepository prefRepo;
  late ScheduleStateProvider schedule;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    scheduleRepo = MockScheduleRepository();
    templateRepo = MockTemplateRepository();
    prefRepo = MockPreferenceRepository();
    stubTemplateAndPrefsSuccess(templateRepo, prefRepo);
  });

  tearDown(() => schedule.dispose());

  Future<ScheduleStateProvider> loadedSchedule({
    List<Task> tasksToday = const [],
  }) async {
    stubScheduleRepoSuccess(
      scheduleRepo,
      days: sevenEmptyDays(tasksOnFirstDay: tasksToday),
    );
    schedule = ScheduleStateProvider(
      scheduleRepo: scheduleRepo,
      templateRepo: templateRepo,
      prefRepo: prefRepo,
      logger: const NoOpLogger(),
    );
    // ScheduleStateProvider loads in its constructor through several await
    // points; drain the queue rather than guessing a hop count.
    await pumpEventQueue();
    return schedule;
  }

  group('week metrics', () {
    test('counts tasks and completions across the loaded week', () async {
      final provider = AnalyticsProvider(
        await loadedSchedule(
          tasksToday: [
            taskFixture(id: 'a', completed: true),
            taskFixture(id: 'b', startTime: '13:00', endTime: '14:00'),
          ],
        ),
      );
      addTearDown(provider.dispose);

      expect(provider.totalTasks, 2);
      expect(provider.completedTasks, 1);
      expect(provider.efficiency, 50.0);
    });

    test('efficiency is zero rather than NaN for an empty week', () async {
      final provider = AnalyticsProvider(await loadedSchedule());
      addTearDown(provider.dispose);

      expect(provider.totalTasks, 0);
      expect(provider.efficiency, 0);
    });

    test('sums focus hours, treating an overnight task correctly', () async {
      final provider = AnalyticsProvider(
        await loadedSchedule(
          tasksToday: [
            taskFixture(id: 'a', startTime: '09:00', endTime: '11:30'),
            taskFixture(id: 'b', startTime: '23:00', endTime: '01:00'),
          ],
        ),
      );
      addTearDown(provider.dispose);

      expect(provider.totalFocusHours, closeTo(4.5, 1e-9));
    });

    test('distributes duration across task categories', () async {
      final provider = AnalyticsProvider(
        await loadedSchedule(
          tasksToday: [
            taskFixture(id: 'a', endTime: '10:00'),
            taskFixture(
              id: 'b',
              type: TaskType.health,
              startTime: '12:00',
              endTime: '14:00',
            ),
          ],
        ),
      );
      addTearDown(provider.dispose);

      expect(provider.categoryDistribution[TaskType.work], closeTo(1, 1e-9));
      expect(provider.categoryDistribution[TaskType.health], closeTo(2, 1e-9));
      expect(provider.categoryDistribution[TaskType.leisure], 0);
    });
  });

  group('energy peaks', () {
    test('merges persisted history with the live week, keyed by id', () async {
      final intel = _StubIntelligence()..peaks = {9: 3.0};
      // Order matters: loadedSchedule applies the default stubs, so a
      // history override has to come after it.
      final loaded = await loadedSchedule(
        tasksToday: [taskFixture(id: 'live')],
      );
      when(() => scheduleRepo.getTaskHistory(any())).thenAnswer(
        (_) async => Success([taskFixture(id: 'historic', completed: true)]),
      );

      final provider = AnalyticsProvider(loaded, scheduleRepo, intel);
      addTearDown(provider.dispose);
      await pumpEventQueue();

      expect(provider.energyPeaks, {9: 3.0});
      expect(
        intel.lastHistory.map((t) => t.id).toSet(),
        {'historic', 'live'},
        reason: 'history and the live week are both fed to the calculation',
      );
    });

    test('falls back to the live week when history cannot be read', () async {
      final intel = _StubIntelligence()..peaks = {14: 1.0};
      final loaded = await loadedSchedule(
        tasksToday: [taskFixture(id: 'live')],
      );
      when(() => scheduleRepo.getTaskHistory(any())).thenAnswer(
        (_) async => const Failure(DatabaseFailure('history unavailable')),
      );

      final provider = AnalyticsProvider(loaded, scheduleRepo, intel);
      addTearDown(provider.dispose);
      await pumpEventQueue();

      // A failed history read is non-fatal: peaks still compute.
      expect(provider.energyPeaks, {14: 1.0});
      expect(intel.lastHistory.map((t) => t.id), contains('live'));
    });
  });
}
