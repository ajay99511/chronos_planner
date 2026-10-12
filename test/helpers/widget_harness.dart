import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/core/services/notification_coordinator.dart';
import 'package:chronosky/core/services/scheduled_notifier.dart';
import 'package:chronosky/core/theme/app_theme.dart';
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
  NotificationCoordinator? notificationCoordinator,
  Size surfaceSize = const Size(1200, 900),
  bool reduceMotion = false,
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
        // The schedule and task screens read notification permission from
        // here, so it has to be present even for tests about something else.
        // The default is backed by a no-op notifier, which reports no
        // permission — so the banner shows, which is the honest default for a
        // test that has not said otherwise.
        ChangeNotifierProvider<NotificationCoordinator>.value(
          value: notificationCoordinator ?? _inertCoordinator(),
        ),
      ],
      child: MaterialApp(
        // The app's real theme, so colour-dependent assertions (contrast in
        // particular) measure what ships rather than a default light Scaffold.
        theme: AppTheme.dark,
        home: Scaffold(
          body: reduceMotion
              // copyWith, not a fresh MediaQueryData: constructing one would
              // also reset size, padding and text scale, laying the tree out
              // against a zero-sized window and measuring something other
              // than the app. The Builder sits under MaterialApp so there is
              // data to copy.
              ? Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: true),
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    ),
  );
}

/// A coordinator that reaches no platform and no database.
///
/// Built over fresh mocks rather than the caller's, because nothing in a
/// widget test should depend on what the notification schedule happens to
/// contain; tests that care construct their own and pass it in.
NotificationCoordinator _inertCoordinator() {
  final todoRepo = MockTodoRepository();
  final scheduleRepo = MockScheduleRepository();
  stubTodoRepoEmpty(todoRepo);
  stubScheduleRepoSuccess(scheduleRepo);
  final coordinator = NotificationCoordinator(
    todoRepo: todoRepo,
    scheduleRepo: scheduleRepo,
    logger: const NoOpLogger(),
    notifier: const NoOpScheduledNotifier(),
  );
  addTearDown(coordinator.dispose);
  return coordinator;
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
