import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:chronosky/data/repositories/preference_repository.dart';
import 'package:chronosky/data/repositories/schedule_repository.dart';
import 'package:chronosky/data/repositories/template_repository.dart';
import 'package:chronosky/data/repositories/todo_repository.dart';
import 'package:mocktail/mocktail.dart';

/// Shared repository doubles and domain fixtures.
///
/// Every test file previously declared its own mocks, so a signature change
/// meant editing each one. Keeping them here also keeps the default stubs
/// consistent: a test that cares about a failure stubs that one call and
/// inherits working behaviour for everything else.

class MockScheduleRepository extends Mock implements ScheduleRepository {}

class MockTemplateRepository extends Mock implements TemplateRepository {}

class MockPreferenceRepository extends Mock implements PreferenceRepository {}

class MockTodoRepository extends Mock implements TodoRepository {}

class MockLogger extends Mock implements Logger {}

class _FakeTask extends Fake implements Task {}

class _FakeTemplate extends Fake implements PlanTemplate {}

class _FakeTemplateTask extends Fake implements TemplateTask {}

class _FakeTodoItem extends Fake implements TodoItem {}

class _FakeDayPlan extends Fake implements DayPlan {}

/// Registers the fallback values mocktail needs for `any()` on typed
/// arguments. Call once from `setUpAll`.
void registerCommonFallbacks() {
  registerFallbackValue(_FakeTask());
  registerFallbackValue(_FakeTemplate());
  registerFallbackValue(_FakeTemplateTask());
  registerFallbackValue(_FakeTodoItem());
  registerFallbackValue(_FakeDayPlan());
  registerFallbackValue(<Task>[]);
  registerFallbackValue(<int>[]);
  registerFallbackValue(DateTime(2026, 1, 1));
}

// ── Fixtures ────────────────────────────────────

/// A valid task. Override only what the test is actually about.
Task taskFixture({
  String id = 'task-1',
  String title = 'Deep work',
  String startTime = '09:00',
  String endTime = '11:00',
  TaskType type = TaskType.work,
  bool completed = false,
  String sourceTemplateId = '',
}) =>
    Task(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      type: type,
      completed: completed,
      sourceTemplateId: sourceTemplateId,
    );

/// A day plan for [date], defaulting to today so it lands inside the rolling
/// window the schedule screen renders.
DayPlan dayPlanFixture({
  String id = 'day-1',
  DateTime? date,
  List<Task> tasks = const [],
}) =>
    DayPlan(id: id, date: date ?? _today(), tasks: tasks);

/// Seven consecutive empty days starting today — the shape
/// `getUpcomingDays(7)` returns on a fresh install.
List<DayPlan> sevenEmptyDays({List<Task> tasksOnFirstDay = const []}) {
  final today = _today();
  return [
    for (var i = 0; i < 7; i++)
      DayPlan(
        id: 'day-$i',
        date: today.add(Duration(days: i)),
        tasks: i == 0 ? tasksOnFirstDay : const [],
      ),
  ];
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Stubs every [MockScheduleRepository] call to succeed.
///
/// Call this **first**: it stubs every method, so any per-test override must
/// be applied afterwards or it will be silently replaced by the default.
void stubScheduleRepoSuccess(
  MockScheduleRepository repo, {
  List<DayPlan>? days,
}) {
  when(() => repo.getUpcomingDays(any()))
      .thenAnswer((_) async => Success(days ?? sevenEmptyDays()));
  when(() => repo.addTaskToDate(any(), any()))
      .thenAnswer((_) async => const Success(null));
  when(() => repo.addTasksToDate(any(), any()))
      .thenAnswer((_) async => const Success(null));
  when(() => repo.updateTask(any(), any(), any()))
      .thenAnswer((_) async => const Success(null));
  when(() => repo.deleteTask(any(), any()))
      .thenAnswer((_) async => const Success(null));
  when(() => repo.getTaskHistory(any()))
      .thenAnswer((_) async => const Success(<Task>[]));
}

/// Stubs the template and preference repositories to succeed with empty data.
void stubTemplateAndPrefsSuccess(
  MockTemplateRepository templateRepo,
  MockPreferenceRepository prefRepo,
) {
  when(() => templateRepo.getAllTemplates())
      .thenAnswer((_) async => const Success(<PlanTemplate>[]));
  when(() => templateRepo.addTemplate(any()))
      .thenAnswer((_) async => const Success(null));
  when(() => prefRepo.get(any())).thenAnswer((_) async => const Success(null));
  when(() => prefRepo.set(any(), any()))
      .thenAnswer((_) async => const Success(null));
}
