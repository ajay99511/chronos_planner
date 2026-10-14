import 'package:chronosky/core/result.dart';
import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/models/todo_item_model.dart';
import 'package:chronosky/domain/reminder_lead.dart';
import 'package:chronosky/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

void main() {
  late MockPreferenceRepository prefRepo;
  late MockTodoRepository todoRepo;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    prefRepo = MockPreferenceRepository();
    todoRepo = MockTodoRepository();
    stubTodoRepoEmpty(todoRepo);
    when(() => prefRepo.get(any())).thenAnswer((_) async => const Success(null));
    when(() => prefRepo.set(any(), any()))
        .thenAnswer((_) async => const Success(null));
  });

  SettingsProvider build() {
    final provider = SettingsProvider(
      prefRepo: prefRepo,
      todoRepo: todoRepo,
      logger: const NoOpLogger(),
    );
    addTearDown(provider.dispose);
    return provider;
  }

  group('demo visibility', () {
    test('defaults to visible on a fresh install', () async {
      // The samples exist to show what the four workspace kinds and the plan
      // library are for, which they cannot do while hidden.
      final subject = build();
      await pumpEventQueue();

      expect(subject.demoVisible, isTrue);
      expect(subject.loaded, isTrue);
    });

    test('restores a stored "off"', () async {
      when(() => prefRepo.get(SettingsProvider.demoVisiblePrefKey))
          .thenAnswer((_) async => const Success('false'));

      final subject = build();
      await pumpEventQueue();

      expect(subject.demoVisible, isFalse);
    });

    test('switching off persists it', () async {
      final subject = build();
      await pumpEventQueue();

      await subject.setDemoVisible(false);

      expect(subject.demoVisible, isFalse);
      verify(() => prefRepo.set(SettingsProvider.demoVisiblePrefKey, 'false'))
          .called(1);
    });

    test('setting the value it already has writes nothing', () async {
      final subject = build();
      await pumpEventQueue();
      clearInteractions(prefRepo);

      await subject.setDemoVisible(true);

      verifyNever(() => prefRepo.set(any(), any()));
    });

    test('an unreadable preference leaves samples visible', () async {
      when(() => prefRepo.get(any())).thenAnswer(
        (_) async => const Failure(DatabaseFailure('pref read failed')),
      );

      final subject = build();
      await pumpEventQueue();

      expect(subject.demoVisible, isTrue);
    });
  });

  group('default reminder lead', () {
    test('defaults to the documented constant', () async {
      final subject = build();
      await pumpEventQueue();

      expect(subject.defaultLeadMinutes, defaultReminderLeadMinutes);
    });

    test('restores a stored value', () async {
      when(() => prefRepo.get(SettingsProvider.defaultLeadPrefKey))
          .thenAnswer((_) async => const Success('30'));

      final subject = build();
      await pumpEventQueue();

      expect(subject.defaultLeadMinutes, 30);
    });

    test('a stored value outside the allowed range is ignored', () async {
      // Can only come from a build with different limits; honouring it would
      // write a lead time the schema's CHECK rejects.
      when(() => prefRepo.get(SettingsProvider.defaultLeadPrefKey))
          .thenAnswer((_) async => const Success('99999'));

      final subject = build();
      await pumpEventQueue();

      expect(subject.defaultLeadMinutes, defaultReminderLeadMinutes);
    });

    test('unparseable stored text is ignored', () async {
      when(() => prefRepo.get(SettingsProvider.defaultLeadPrefKey))
          .thenAnswer((_) async => const Success('soon'));

      final subject = build();
      await pumpEventQueue();

      expect(subject.defaultLeadMinutes, defaultReminderLeadMinutes);
    });

    test('an out-of-range value is refused rather than stored', () async {
      final subject = build();
      await pumpEventQueue();

      await subject.setDefaultLeadMinutes(maxReminderLeadMinutes + 1);

      expect(subject.defaultLeadMinutes, defaultReminderLeadMinutes);
      verifyNever(
        () => prefRepo.set(SettingsProvider.defaultLeadPrefKey, any()),
      );
    });

    test('a valid change persists', () async {
      final subject = build();
      await pumpEventQueue();

      await subject.setDefaultLeadMinutes(0);

      expect(subject.defaultLeadMinutes, 0);
      verify(() => prefRepo.set(SettingsProvider.defaultLeadPrefKey, '0'))
          .called(1);
    });
  });

  group('seeding the workspace samples', () {
    test('writes twelve items once, and flags them as demo', () async {
      final written = <TodoItem>[];
      when(() => todoRepo.addTodo(any())).thenAnswer((inv) async {
        written.add(inv.positionalArguments.first as TodoItem);
        return const Success(null);
      });

      final subject = build();
      await subject.seedDemoItemsIfNeeded();

      // Three of each of the four kinds.
      expect(written, hasLength(12));
      for (final type in TodoItemType.values) {
        expect(
          written.where((i) => i.itemType == type),
          hasLength(3),
          reason: 'expected three ${type.name} samples',
        );
      }
      expect(written.every((i) => i.isDemo), isTrue);
      verify(() => prefRepo.set(SettingsProvider.demoSeededPrefKey, 'true'))
          .called(1);
    });

    test('does not seed again once the flag is set', () async {
      when(() => prefRepo.get(SettingsProvider.demoSeededPrefKey))
          .thenAnswer((_) async => const Success('true'));

      final subject = build();
      await subject.seedDemoItemsIfNeeded();

      // Deleting every sample is a decision, not missing data.
      verifyNever(() => todoRepo.addTodo(any()));
    });

    test('sample alarms are disarmed and dated in the past', () async {
      // A sample alarm that actually rings is indefensible for content the
      // user did not create. Two independent guards: disarmed, and past.
      final written = <TodoItem>[];
      when(() => todoRepo.addTodo(any())).thenAnswer((inv) async {
        written.add(inv.positionalArguments.first as TodoItem);
        return const Success(null);
      });

      final subject = build();
      await subject.seedDemoItemsIfNeeded();

      final alarms =
          written.where((i) => i.itemType == TodoItemType.alarm).toList();
      expect(alarms, hasLength(3));
      for (final alarm in alarms) {
        expect(alarm.enabled, isFalse, reason: '${alarm.title} is armed');
        expect(alarm.scheduledAt, isNotNull);
        expect(
          alarm.scheduledAt!.isBefore(DateTime.now()),
          isTrue,
          reason: '${alarm.title} is scheduled in the future',
        );
      }
    });

    test('the flag is still set when a write fails', () async {
      // A partial seed is still a seed; retrying would duplicate whatever
      // did land.
      when(() => todoRepo.addTodo(any())).thenAnswer(
        (_) async => const Failure(DatabaseFailure('disk full')),
      );

      final subject = build();
      await subject.seedDemoItemsIfNeeded();

      verify(() => prefRepo.set(SettingsProvider.demoSeededPrefKey, 'true'))
          .called(1);
    });
  });
}
