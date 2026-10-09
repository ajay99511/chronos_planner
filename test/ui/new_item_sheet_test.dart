import 'dart:async';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/alarm_notifier.dart';
import 'package:chronosky/core/services/alarm_output.dart';
import 'package:chronosky/core/services/alarm_scheduler_service.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/theme/app_theme.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:chronosky/providers/todo_provider.dart';
import 'package:chronosky/ui/widgets/new_item_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../helpers/mocks.dart';

/// Records whether the sheet asked the OS for anything.
class _FakeAlarmNotifier implements AlarmNotifier {
  int requestCount = 0;
  bool permitted = true;
  bool grantOnRequest = true;

  @override
  Future<void> initialise() async {}

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<bool> requestPermission() async {
    requestCount++;
    permitted = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<void> sync(List<TodoItem> alarms) async {}

  @override
  Future<void> cancelAll() async {}
}

/// Keeps `just_audio` and `window_manager` out of a widget test.
class _SilentAlarmOutput implements AlarmOutput {
  @override
  Future<void> playLooping(String path) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> bringToFront() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  late MockTodoRepository repo;
  late MockPreferenceRepository prefRepo;
  late _FakeAlarmNotifier notifier;
  late StreamController<List<TodoItem>> alarmStream;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    repo = MockTodoRepository();
    prefRepo = MockPreferenceRepository();
    notifier = _FakeAlarmNotifier();
    alarmStream = StreamController<List<TodoItem>>.broadcast();

    for (final type in TodoItemType.values) {
      when(() => repo.watchByType(type)).thenAnswer(
        (_) => type == TodoItemType.alarm
            ? alarmStream.stream
            : const Stream<List<TodoItem>>.empty(),
      );
    }
    when(() => repo.addTodo(any())).thenAnswer(
      (_) async => const Success(null),
    );
    when(() => prefRepo.get(any())).thenAnswer(
      (_) async => const Success(null),
    );
  });

  tearDown(() => alarmStream.close());

  /// Mounts the sheet over the providers the real app supplies, already open
  /// on [tab]. Opened through [NewItemSheet.show] rather than pumped directly,
  /// because whether the sheet closes is part of what is under test.
  Future<AlarmSchedulerService> openSheet(
    WidgetTester tester, {
    required int tab,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final todoProvider = TodoProvider(repo, prefRepo: prefRepo);
    final alarmService = AlarmSchedulerService(
      repo,
      const NoOpLogger(),
      output: _SilentAlarmOutput(),
      notifier: notifier,
    );
    addTearDown(todoProvider.dispose);
    addTearDown(alarmService.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
          ChangeNotifierProvider<AlarmSchedulerService>.value(
            value: alarmService,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => NewItemSheet.show(context, initialTab: tab),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return alarmService;
  }

  group('saving', () {
    testWidgets('a rejected write keeps the sheet open and says why',
        (tester) async {
      when(() => repo.addTodo(any())).thenAnswer(
        (_) async => const Failure<void>(DatabaseFailure('Disk is full')),
      );
      await openSheet(tester, tab: 0);

      await tester.enterText(find.byType(TextField).first, 'Groceries');
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      // The sheet used to close over the top of the failure, so a save that
      // did not happen looked exactly like one that did.
      expect(find.text('Disk is full'), findsOneWidget);
      expect(find.byType(NewItemSheet), findsOneWidget);
    });

    testWidgets('a successful write closes the sheet', (tester) async {
      await openSheet(tester, tab: 0);

      await tester.enterText(find.byType(TextField).first, 'Groceries');
      await tester.tap(find.text('Save Note'));
      await tester.pumpAndSettle();

      expect(find.byType(NewItemSheet), findsNothing);
      verify(() => repo.addTodo(any())).called(1);
    });
  });

  group('alarm delivery permission', () {
    testWidgets('is asked for when an alarm is created', (tester) async {
      notifier.permitted = false;
      final service = await openSheet(tester, tab: 2);

      await fillAlarmForm(tester);

      // Asked here, not at launch: this is the first moment the request has a
      // reason the user can see.
      expect(notifier.requestCount, 1);
      expect(service.notificationsBlocked, isFalse);
      expect(find.byType(NewItemSheet), findsNothing);
    });

    testWidgets('is not asked for again once granted', (tester) async {
      await openSheet(tester, tab: 2);

      await fillAlarmForm(tester);

      verify(() => repo.addTodo(any())).called(1);
      expect(notifier.requestCount, 0);
    });

    testWidgets('a refusal says the alarm will not go off', (tester) async {
      notifier.permitted = false;
      notifier.grantOnRequest = false;
      await openSheet(tester, tab: 2);

      await fillAlarmForm(tester);

      // The alarm is saved either way. What the user must not be left with is
      // the belief that it is armed.
      verify(() => repo.addTodo(any())).called(1);
      expect(find.textContaining('notifications are off'), findsOneWidget);
    });
  });

  group('alarm sound', () {
    testWidgets('is only offered where the platform can play it',
        (tester) async {
      await openSheet(tester, tab: 2);

      if (audioSupportedOnThisPlatform) {
        expect(find.text('Select Local Audio'), findsOneWidget);
      } else {
        // just_audio has no Windows or Linux implementation, so offering a
        // picker there advertises something the app cannot deliver.
        expect(find.text('Select Local Audio'), findsNothing);
        expect(
          find.textContaining('not supported on this platform'),
          findsOneWidget,
        );
      }
    });
  });
}

/// Fills in a title and a date/time 30 days out, then taps save.
///
/// Both pickers are driven in keyboard-entry mode, and the date is a fixed
/// offset from today rather than a tap on the calendar grid, so the test does
/// not depend on where the grid happens to land in the month or on what time
/// of day it runs.
Future<void> fillAlarmForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Wake up');

  final target = DateTime.now().add(const Duration(days: 30));
  await tester.tap(find.text('Pick date'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.edit_outlined));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextField),
    ),
    '${target.month}/${target.day}/${target.year}',
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Pick time'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final timeFields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(timeFields.first, '8');
  await tester.enterText(timeFields.last, '30');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Save Alarm'));
  await tester.pumpAndSettle();
}
