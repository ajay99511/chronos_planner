import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/providers/analytics_provider.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'mocks.dart';

/// Mounts a widget inside the providers and Material ancestors the real app
/// supplies, so screens can be pumped without reproducing `main.dart`.
///
/// A [Scaffold] wrapper is deliberate: several screens call
/// `ScaffoldMessenger.of(context).showSnackBar`, which needs somewhere to
/// render, and the snackbar is the surface under test for error reporting.
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  required ScheduleStateProvider scheduleProvider,
  AnalyticsProvider? analyticsProvider,
  Size surfaceSize = const Size(1200, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ScheduleStateProvider>.value(
          value: scheduleProvider,
        ),
        ChangeNotifierProvider<AnalyticsProvider>.value(
          value: analyticsProvider ?? AnalyticsProvider(scheduleProvider),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Builds a [ScheduleStateProvider] over mocks, already stubbed to succeed.
///
/// The provider loads in its constructor, so callers normally follow this with
/// `await tester.pumpAndSettle()` to reach the loaded state.
ScheduleStateProvider scheduleProviderWith({
  required MockScheduleRepository scheduleRepo,
  required MockTemplateRepository templateRepo,
  required MockPreferenceRepository prefRepo,
  Logger? logger,
}) {
  return ScheduleStateProvider(
    scheduleRepo: scheduleRepo,
    templateRepo: templateRepo,
    prefRepo: prefRepo,
    logger: logger ?? const NoOpLogger(),
  );
}
