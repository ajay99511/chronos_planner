import 'dart:async';
import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

void main() {
  late TodoProvider provider;
  late MockTodoRepository mockTodoRepo;
  late MockPreferenceRepository mockPrefRepo;
  late StreamController<List<TodoItem>> notesController;
  late StreamController<List<TodoItem>> timersController;
  late StreamController<List<TodoItem>> listsController;
  late StreamController<List<TodoItem>> alarmsController;

  setUp(() {
    mockTodoRepo = MockTodoRepository();
    mockPrefRepo = MockPreferenceRepository();
    when(() => mockPrefRepo.get(any()))
        .thenAnswer((_) async => const Success(null));
    when(() => mockPrefRepo.set(any(), any()))
        .thenAnswer((_) async => const Success(null));
    // Broadcast so a stream can be listened to again after a retry, matching
    // Drift's watch(), which hands out an independently-listenable stream on
    // every call. A single-subscription controller would throw on resubscribe
    // and misattribute that to the provider.
    notesController = StreamController<List<TodoItem>>.broadcast();
    timersController = StreamController<List<TodoItem>>.broadcast();
    listsController = StreamController<List<TodoItem>>.broadcast();
    alarmsController = StreamController<List<TodoItem>>.broadcast();

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
      provider = TodoProvider(mockTodoRepo, prefRepo: mockPrefRepo);

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

    test('a stream error after dispose does not resubscribe', () async {
      provider = TodoProvider(
        mockTodoRepo,
        prefRepo: mockPrefRepo,
        retryBaseDelay: const Duration(milliseconds: 10),
      );

      notesController.addError(Exception('database went away'));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      provider.dispose();

      // The retry was previously an uncancellable Future.delayed, so it fired
      // after dispose, re-listened to all four streams (leaking them, since
      // dispose had already run) and called notifyListeners on a disposed
      // ChangeNotifier. See H-3 in the audit.
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(notesController.hasListener, isFalse);
      expect(timersController.hasListener, isFalse);
      expect(listsController.hasListener, isFalse);
      expect(alarmsController.hasListener, isFalse);
    });

    test('a stream error while mounted resubscribes', () async {
      provider = TodoProvider(
        mockTodoRepo,
        prefRepo: mockPrefRepo,
        retryBaseDelay: const Duration(milliseconds: 10),
      );

      notesController.addError(Exception('transient failure'));
      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(provider.errorMessage, contains('transient failure'));

      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(
        notesController.hasListener,
        isTrue,
        reason: 'recovery must still work for a live provider',
      );

      provider.dispose();
    });

    test('retries are bounded rather than looping forever', () async {
      provider = TodoProvider(
        mockTodoRepo,
        prefRepo: mockPrefRepo,
        retryBaseDelay: const Duration(milliseconds: 5),
      );

      // Each error schedules the next attempt; after the cap the provider
      // stops rather than retrying every few seconds indefinitely.
      for (var i = 0; i < TodoProvider.maxSubscribeRetries + 2; i++) {
        notesController.addError(Exception('still down'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      expect(provider.retryAttempts, TodoProvider.maxSubscribeRetries);

      provider.dispose();
    });

    test('alarms getter sorts by the selected sort order', () async {
      provider = TodoProvider(mockTodoRepo, prefRepo: mockPrefRepo);
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
