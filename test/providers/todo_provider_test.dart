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

  setUp(() {
    mockTodoRepo = MockTodoRepo();
    notesController = StreamController<List<TodoItem>>();
    timersController = StreamController<List<TodoItem>>();
    listsController = StreamController<List<TodoItem>>();

    when(() => mockTodoRepo.watchByType(TodoItemType.note)).thenAnswer((_) => notesController.stream);
    when(() => mockTodoRepo.watchByType(TodoItemType.timer)).thenAnswer((_) => timersController.stream);
    when(() => mockTodoRepo.watchByType(TodoItemType.list)).thenAnswer((_) => listsController.stream);
  });

  tearDown(() {
    notesController.close();
    timersController.close();
    listsController.close();
  });

  group('TodoProvider', () {
    test('dispose cancels all stream subscriptions', () async {
      provider = TodoProvider(mockTodoRepo);

      expect(notesController.hasListener, isTrue);
      expect(timersController.hasListener, isTrue);
      expect(listsController.hasListener, isTrue);

      provider.dispose();

      // StreamControllers might take a microtask to update hasListener
      await Future.microtask(() {});

      expect(notesController.hasListener, isFalse);
      expect(timersController.hasListener, isFalse);
      expect(listsController.hasListener, isFalse);
    });
  });
}
