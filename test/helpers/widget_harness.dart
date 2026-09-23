import 'package:chronosky/core/services/logger.dart';
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
