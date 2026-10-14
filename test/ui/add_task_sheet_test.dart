import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/providers/analytics_provider.dart';
import 'package:chronosky/ui/widgets/add_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mocks.dart';
import '../helpers/widget_harness.dart';

void main() {
  late MockScheduleRepository scheduleRepo;
  late MockTemplateRepository templateRepo;
  late MockPreferenceRepository prefRepo;

  setUpAll(registerCommonFallbacks);

  setUp(() {
    scheduleRepo = MockScheduleRepository();
    templateRepo = MockTemplateRepository();
    prefRepo = MockPreferenceRepository();
    stubScheduleRepoSuccess(scheduleRepo);
    stubTemplateAndPrefsSuccess(templateRepo, prefRepo);
  });

  Future<void> pumpSheet(WidgetTester tester, {required Task editing}) async {
    final provider = scheduleProviderWith(
      scheduleRepo: scheduleRepo,
      templateRepo: templateRepo,
      prefRepo: prefRepo,
    );
    addTearDown(provider.dispose);

    await pumpWithProviders(
      tester,
      AddTaskSheet(
        editingTask: editing,
        showDateControls: false,
        onAdd: (_, __) {},
        onUpdate: (_) {},
      ),
      scheduleProvider: provider,
      analyticsProvider: AnalyticsProvider(provider),
      surfaceSize: const Size(500, 1400),
    );
    await tester.pumpAndSettle();
  }

  group('editing a task', () {
    testWidgets('shows the task\'s own start and end time', (tester) async {
      await pumpSheet(
        tester,
        editing: taskFixture(startTime: '14:30', endTime: '16:45'),
      );

      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('16:45'), findsOneWidget);
    });

    testWidgets('the time picker opens on the task\'s time, not a default',
        (tester) async {
      // The defect: initialTime was a hardcoded 09:00, so every edit opened
      // the dial on a time the task did not have — which reads as the time
      // having been lost, and invites confirming 09:00 over it.
      await pumpSheet(
        tester,
        editing: taskFixture(startTime: '14:30', endTime: '16:45'),
      );

      await tester.tap(find.text('14:30'));
      await tester.pumpAndSettle();
      // Confirm without touching the dial. Asserting the outcome rather than
      // the dial's own labels keeps this independent of 12- vs 24-hour
      // rendering, and it is the consequence that actually bites: accepting
      // the picker unchanged used to silently rewrite 14:30 to 09:00.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('14:30'), findsOneWidget);
      expect(find.text('09:00'), findsNothing);
    });
  });
}
