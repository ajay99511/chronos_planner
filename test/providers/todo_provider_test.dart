import 'dart:async';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:chronosky/data/repositories/todo_repository.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTodoRepo extends Mock implements TodoRepository {}

void main() {
  late TodoProvider provider;
  late MockTodoRepo mockTodoRepo;
  late StreamController<List<TodoItem>> notesController;
  late StreamController<List<TodoItem>> timersController;
  late StreamController<List<TodoItem>> listsController;
  late StreamController<List<TodoItem>> alarmsController;

  setUp(() {
    mockTodoRepo = MockTodoRepo();
    notesController = StreamController<List<TodoItem>>();
    timersController = StreamController<List<TodoItem>>();
    listsController = StreamController<List<TodoItem>>();
    alarmsController = StreamController<List<TodoItem>>();

    when(() => mockTodoRepo.watchByType(TodoItemType.note)).thenAnswer((_) => notesController.stream);
    when(() => mockTodoRepo.watchByType(TodoItemType.timer)).thenAnswer((_) => timersController.stream);
    when(() => mockTodoRepo.watchByType(TodoItemType.list)).thenAnswer((_) => listsController.stream);
    when(() => mockTodoRepo.watchByType(TodoItemType.alarm)).thenAnswer((_) => alarmsController.stream);
  });

  tearDown(() {
    notesController.close();
    timersController.close();
    listsController.close();
    alarmsController.close();
  });

  group('TodoProvider', () {
    test('dispose cancels all stream subscriptions', () async {
      provider = TodoProvider(mockTodoRepo);

      expect(notesController.hasListener, isTrue);
      expect(timersController.hasListener, isTrue);
      expect(listsController.hasListener, isTrue);
      expect(alarmsController.hasListener, isTrue);

      provider.dispose();

      // StreamControllers might take a microtask to update hasListener
      await Future.microtask(() {});

      expect(notesController.hasListener, isFalse);
      expect(timersController.hasListener, isFalse);
      expect(listsController.hasListener, isFalse);
      expect(alarmsController.hasListener, isFalse);
    });

    test('alarms getter sorts by the selected sort order', () async {
      provider = TodoProvider(mockTodoRepo);
      final now = DateTime.now();

      TodoItem alarm(String id, Duration inFuture, DateTime created) =>
          TodoItem(
            id: id,
            title: id,
            createdAt: created,
            itemType: TodoItemType.alarm,
            scheduledAt: now.add(inFuture),
          );

      final a = alarm('a', const Duration(hours: 3), now);
      final b = alarm('b', const Duration(hours: 1),
          now.subtract(const Duration(days: 1)),);
      final c = alarm('c', const Duration(hours: 2),
          now.subtract(const Duration(days: 2)),);

      alarmsController.add([a, b, c]);
      await Future.microtask(() {});

      // Default: soonest first.
      expect(provider.alarms.map((x) => x.id).toList(), ['b', 'c', 'a']);

      await provider.setAlarmSort(AlarmSort.upcomingDesc);
      expect(provider.alarms.map((x) => x.id).toList(), ['a', 'c', 'b']);

      await provider.setAlarmSort(AlarmSort.addedDesc);
      expect(provider.alarms.map((x) => x.id).toList(), ['a', 'b', 'c']);

      await provider.setAlarmSort(AlarmSort.addedAsc);
      expect(provider.alarms.map((x) => x.id).toList(), ['c', 'b', 'a']);

      provider.dispose();
    });
  });
}
