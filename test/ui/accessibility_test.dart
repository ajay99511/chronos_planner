import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:chronosky/ui/screens/schedule_view.dart';
import 'package:chronosky/ui/widgets/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mocks.dart';
import '../helpers/widget_harness.dart';

/// `stack-appendices.md` §3 treats accessibility as a requirement rather than
/// an enhancement. Before this, lib/ui had three Semantics wrappers across
/// ~7,900 lines and no reduce-motion handling despite leaning heavily on
/// animation and blur.
void main() {
  late MockScheduleRepository scheduleRepo;
  late MockTemplateRepository templateRepo;
  late MockPreferenceRepository prefRepo;
  late ScheduleStateProvider provider;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    scheduleRepo = MockScheduleRepository();
    templateRepo = MockTemplateRepository();
    prefRepo = MockPreferenceRepository();
    stubTemplateAndPrefsSuccess(templateRepo, prefRepo);
    stubScheduleRepoSuccess(
      scheduleRepo,
      days: sevenEmptyDays(
        tasksOnFirstDay: [
          taskFixture(id: 't1', title: 'Write the audit'),
          taskFixture(
            id: 't2',
            title: 'Review the diff',
            startTime: '13:00',
            endTime: '14:00',
            completed: true,
          ),
        ],
      ),
    );
  });

  tearDown(() => provider.dispose());

  Future<void> pumpSchedule(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    provider = scheduleProviderWith(
      scheduleRepo: scheduleRepo,
      templateRepo: templateRepo,
      prefRepo: prefRepo,
    );
    await pumpWithProviders(
      tester,
      const ScheduleView(),
      scheduleProvider: provider,
      reduceMotion: reduceMotion,
    );
    await tester.pumpAndSettle();
  }

  group('guidelines', () {
    testWidgets('the schedule meets tap target guidelines', (tester) async {
      await pumpSchedule(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('the schedule meets text contrast guidelines', (tester) async {
      await pumpSchedule(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('every tappable target is labelled for a screen reader',
        (tester) async {
      await pumpSchedule(tester);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  group('task card semantics', () {
    testWidgets('announces title, time, type and completion', (tester) async {
      await pumpSchedule(tester);

      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text('Write the audit'),
          matching: find.byType(TaskCard),
        ),
      );

      expect(semantics.label, contains('Write the audit'));
      expect(semantics.label, contains('09:00 to 11:00'));
      expect(semantics.label, contains('work'));
      expect(semantics.label, contains('not completed'));
    });

    testWidgets('a completed task announces that it is completed',
        (tester) async {
      await pumpSchedule(tester);

      final semantics = tester.getSemantics(
        find.ancestor(
          of: find.text('Review the diff'),
          matching: find.byType(TaskCard),
        ),
      );

      expect(semantics.label, contains('completed'));
      expect(semantics.label, isNot(contains('not completed')));
    });
  });

  group('reduced motion', () {
    testWidgets('drops the hover scale transition when asked', (tester) async {
      await pumpSchedule(tester, reduceMotion: true);

      expect(
        find.descendant(
          of: find.byType(TaskCard),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
        reason: 'a reduce-motion request means no movement, not faster movement',
      );
    });

    testWidgets('keeps the transition when motion is allowed', (tester) async {
      await pumpSchedule(tester);

      expect(
        find.descendant(
          of: find.byType(TaskCard),
          matching: find.byType(ScaleTransition),
        ),
        findsWidgets,
      );
    });

    testWidgets('still renders every task with motion disabled',
        (tester) async {
      await pumpSchedule(tester, reduceMotion: true);

      // Removing the animation must not remove content.
      expect(find.text('Write the audit'), findsOneWidget);
      expect(find.text('Review the diff'), findsOneWidget);
    });
  });
}
