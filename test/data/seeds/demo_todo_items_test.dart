import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:chronosky/data/seeds/demo_todo_items.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Workspace samples are data, and data that misbehaves does so on a
/// first launch, where the user has no idea what they are looking at.
void main() {
  group('demoTodoItems', () {
    test('ships three of each kind', () {
      final items = demoTodoItems();

      expect(items, hasLength(12));
      for (final type in TodoItemType.values) {
        expect(
          items.where((i) => i.itemType == type),
          hasLength(3),
          reason: 'expected three ${type.name} samples',
        );
      }
    });

    test('every item is flagged as demo', () {
      // The switch filters on this; an unflagged sample is indistinguishable
      // from the user's own content and can never be hidden.
      expect(demoTodoItems().every((i) => i.isDemo), isTrue);
    });

    test('ids are unique across a call', () {
      final ids = demoTodoItems().map((i) => i.id).toList();

      expect(ids.toSet().length, ids.length);
    });

    test('alarms are disarmed and in the past', () {
      final alarms = demoTodoItems()
          .where((i) => i.itemType == TodoItemType.alarm)
          .toList();

      for (final alarm in alarms) {
        expect(alarm.enabled, isFalse);
        expect(alarm.scheduledAt!.isBefore(DateTime.now()), isTrue);
      }
    });

    test('timers have a usable duration', () {
      final timers = demoTodoItems()
          .where((i) => i.itemType == TodoItemType.timer)
          .toList();

      for (final timer in timers) {
        expect(timer.durationMinutes, greaterThan(0));
      }
    });

    test('checklists have items, some already ticked', () {
      // So the progress indicator has something to show rather than rendering
      // an empty list and a 0/0.
      final lists = demoTodoItems()
          .where((i) => i.itemType == TodoItemType.list)
          .toList();

      for (final list in lists) {
        expect(list.checklist, isNotEmpty);
      }
      expect(
        lists.any((l) => l.checklist.any((c) => c.done)),
        isTrue,
      );
    });

    test('titles are within the length the schema allows', () {
      for (final item in demoTodoItems()) {
        expect(item.title.length, inInclusiveRange(1, 200));
      }
    });
  });
}
