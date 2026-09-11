import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/plan_template_model.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// `operator ==` compares collection fields structurally with [listEquals],
/// so `hashCode` must hash their contents too. `List.hashCode` is
/// identity-based, which produced different hashes for objects that compare
/// equal and quietly broke Set/Map membership. See H-1 in the audit.
void main() {
  Task task(String id) => Task(
        id: id,
        title: 'Deep work',
        startTime: '09:00',
        endTime: '11:00',
        type: TaskType.work,
      );

  group('DayPlan', () {
    test('equal plans built from separate task lists share a hash code', () {
      final a = DayPlan(
        id: 'dp-1',
        date: DateTime(2026, 8, 24),
        tasks: [task('t-1')],
      );
      final b = DayPlan(
        id: 'dp-1',
        date: DateTime(2026, 8, 24),
        tasks: [task('t-1')],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equal plans collapse to a single set entry', () {
      // Every mutation path rebuilds the task list, so structurally equal
      // plans backed by distinct List objects are the normal case.
      final a = DayPlan(
        id: 'dp-1',
        date: DateTime(2026, 8, 24),
        tasks: [task('t-1')],
      );
      final b = DayPlan(
        id: 'dp-1',
        date: DateTime(2026, 8, 24),
        tasks: [task('t-1')],
      );

      expect({a, b}, hasLength(1));
    });

    test('plans differing only in their tasks hash differently', () {
      final a = DayPlan(
        id: 'dp-1',
        date: DateTime(2026, 8, 24),
        tasks: [task('t-1')],
      );
      final b = DayPlan(
        id: 'dp-1',
        date: DateTime(2026, 8, 24),
        tasks: [task('t-2')],
      );

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('PlanTemplate', () {
    PlanTemplate template({List<int> activeDays = const [4]}) => PlanTemplate(
          id: 'tmpl-1',
          name: 'Deep Work Friday',
          description: 'Focused coding schedule',
          tasks: [
            TemplateTask(
              id: 'ttask-1',
              templateId: 'tmpl-1',
              title: 'Deep Work Block',
              startTime: '09:00',
              endTime: '12:00',
              type: TaskType.work,
            ),
          ],
          activeDays: activeDays,
        );

    test('equal templates built from separate lists share a hash code', () {
      expect(template(), equals(template()));
      expect(template().hashCode, equals(template().hashCode));
      expect({template(), template()}, hasLength(1));
    });

    test('templates differing only in active days hash differently', () {
      expect(template(activeDays: const [4]),
          isNot(equals(template(activeDays: const [1]))),);
      expect(template(activeDays: const [4]).hashCode,
          isNot(equals(template(activeDays: const [1]).hashCode)),);
    });
  });

  group('TodoItem', () {
    TodoItem item(List<ChecklistItem> checklist) => TodoItem(
          id: 'todo-1',
          title: 'Groceries',
          createdAt: DateTime(2026, 8, 24),
          itemType: TodoItemType.list,
          checklist: checklist,
        );

    test('equal items built from separate checklists share a hash code', () {
      final a = item([const ChecklistItem(text: 'Milk')]);
      final b = item([const ChecklistItem(text: 'Milk')]);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect({a, b}, hasLength(1));
    });

    test('items differing only in their checklist hash differently', () {
      final a = item([const ChecklistItem(text: 'Milk')]);
      final b = item([const ChecklistItem(text: 'Bread')]);

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
