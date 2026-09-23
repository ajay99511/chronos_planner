import 'dart:async';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/alarm_output.dart';
import 'package:chronosky/core/services/alarm_scheduler_service.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

/// Records what a firing alarm asked of the outside world.
class _FakeAlarmOutput implements AlarmOutput {
  final List<String> played = [];
  int stopCount = 0;
  int bringToFrontCount = 0;
  bool disposed = false;

  /// When set, [playLooping] throws it — the moved-or-deleted sound file case.
  Object? playError;

  @override
  Future<void> playLooping(String path) async {
    if (playError != null) throw playError!;
    played.add(path);
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> bringToFront() async => bringToFrontCount++;

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  late MockTodoRepository repo;
  late StreamController<List<TodoItem>> alarms;
  late _FakeAlarmOutput output;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    repo = MockTodoRepository();
    output = _FakeAlarmOutput();
    // Broadcast so a retry can resubscribe, matching Drift's watch().
    alarms = StreamController<List<TodoItem>>.broadcast();
    when(() => repo.watchByType(TodoItemType.alarm))
        .thenAnswer((_) => alarms.stream);
    when(() => repo.updateTodo(any()))
        .thenAnswer((_) async => const Success(null));
  });

  tearDown(() => alarms.close());

  AlarmSchedulerService service({
    Duration retryBaseDelay = const Duration(milliseconds: 10),
  }) =>
      AlarmSchedulerService(
        repo,
        const NoOpLogger(),
        output: output,
        retryBaseDelay: retryBaseDelay,
      );

  TodoItem alarm({
    String id = 'alarm-1',
    required DateTime at,
    bool enabled = true,
    String audioFilePath = 'C:/sounds/wake.mp3',
  }) =>
      TodoItem(
        id: id,
        title: 'Wake up',
        createdAt: DateTime(2026, 1, 1),
        itemType: TodoItemType.alarm,
        scheduledAt: at,
        enabled: enabled,
        audioFilePath: audioFilePath,
      );

  group('firing', () {
    test('an alarm already due rings and plays its sound', () async {
      final subject = service();
      addTearDown(subject.dispose);

      alarms.add([
        alarm(at: DateTime.now().subtract(const Duration(seconds: 1))),
      ]);
      await pumpEventQueue();

      expect(subject.ringing?.id, 'alarm-1');
      expect(output.played, ['C:/sounds/wake.mp3']);
      expect(subject.audioUnavailable, isFalse);
    });

    test('firing disarms the alarm so it is one-shot', () async {
      final subject = service();
      addTearDown(subject.dispose);

      alarms.add([alarm(at: DateTime.now())]);
      await pumpEventQueue();

      final written = verify(() => repo.updateTodo(captureAny()))
          .captured
          .cast<TodoItem>();
      expect(written.any((t) => t.enabled == false), isTrue);
    });

    test('a missing sound file still rings, and says the sound failed',
        () async {
      output.playError = Exception('file not found');
      final subject = service();
      addTearDown(subject.dispose);

      alarms.add([alarm(at: DateTime.now())]);
      await pumpEventQueue();

      expect(
        subject.ringing?.id,
        'alarm-1',
        reason: 'the alarm must still ring without its sound',
      );
      expect(
        subject.audioUnavailable,
        isTrue,
        reason: 'a silent alarm is otherwise indistinguishable from a mute',
      );
    });

    test('an alarm with no sound configured is not reported as failed',
        () async {
      final subject = service();
      addTearDown(subject.dispose);

      alarms.add([alarm(at: DateTime.now(), audioFilePath: '')]);
      await pumpEventQueue();

      expect(subject.ringing, isNotNull);
      expect(output.played, isEmpty);
      expect(subject.audioUnavailable, isFalse);
    });

    test('a disabled alarm never fires', () async {
      final subject = service();
      addTearDown(subject.dispose);

      alarms.add([alarm(at: DateTime.now(), enabled: false)]);
      await pumpEventQueue();

      expect(subject.ringing, isNull);
      expect(output.played, isEmpty);
    });

    test('a long-missed alarm is disarmed rather than rung', () async {
      final subject = service();
      addTearDown(subject.dispose);

      alarms.add([
        alarm(at: DateTime.now().subtract(const Duration(hours: 3))),
      ]);
      await pumpEventQueue();

      expect(
        subject.ringing,
        isNull,
        reason: 'an alarm missed while the app was closed must not ambush',
      );
      verify(() => repo.updateTodo(any())).called(1);
    });

    test('the soonest of several alarms is the one armed', () async {
      final subject = service();
      addTearDown(subject.dispose);
      final now = DateTime.now();

      alarms.add([
        alarm(id: 'later', at: now.add(const Duration(hours: 2))),
        alarm(id: 'soonest', at: now),
        alarm(id: 'middle', at: now.add(const Duration(hours: 1))),
      ]);
      await pumpEventQueue();

      expect(subject.ringing?.id, 'soonest');
    });
  });

  group('dismissal', () {
    test('dismiss stops the sound and clears the overlay', () async {
      final subject = service();
      addTearDown(subject.dispose);
      alarms.add([alarm(at: DateTime.now())]);
      await pumpEventQueue();

      await subject.dismiss();

      expect(subject.ringing, isNull);
      expect(subject.audioUnavailable, isFalse);
      expect(output.stopCount, 1);
    });

    test('dismiss clears the overlay even when stopping audio throws',
        () async {
      final subject = service();
      addTearDown(subject.dispose);
      alarms.add([alarm(at: DateTime.now())]);
      await pumpEventQueue();

      // The user must never be trapped behind the overlay by the audio layer.
      final failing = _ThrowingStopOutput();
      final trapped = AlarmSchedulerService(
        repo,
        const NoOpLogger(),
        output: failing,
      );
      addTearDown(trapped.dispose);
      await trapped.dismiss();

      expect(trapped.ringing, isNull);
    });
  });

  group('lifecycle', () {
    test('dispose releases the output and stops listening', () async {
      final subject = service();

      subject.dispose();
      await pumpEventQueue();

      expect(output.disposed, isTrue);
      expect(alarms.hasListener, isFalse);
    });

    test('a stream error after dispose does not resubscribe', () async {
      final subject = service();
      alarms.addError(Exception('database went away'));
      await Future<void>.delayed(const Duration(milliseconds: 1));

      subject.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(alarms.hasListener, isFalse);
    });

    test('a stream error while alive resubscribes, so alarms keep working',
        () async {
      final subject = service();
      addTearDown(subject.dispose);

      alarms.addError(Exception('transient failure'));
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(
        alarms.hasListener,
        isTrue,
        reason: 'losing the stream silently stops every future alarm',
      );
    });

    test('resubscribe attempts are bounded', () async {
      final subject = service(retryBaseDelay: const Duration(milliseconds: 5));
      addTearDown(subject.dispose);

      for (var i = 0; i < AlarmSchedulerService.maxSubscribeRetries + 2; i++) {
        alarms.addError(Exception('still down'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }

      expect(
        subject.retryAttempts,
        AlarmSchedulerService.maxSubscribeRetries,
      );
    });
  });
}

class _ThrowingStopOutput extends _FakeAlarmOutput {
  @override
  Future<void> stop() async => throw Exception('audio device gone');
}
