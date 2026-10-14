import 'package:chronosky/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/responsive_matrix.dart';

/// The text-scale ceiling, and the thing that keeps it honest.
///
/// `responsive_layout_test.dart` proves every screen survives the scales in
/// `responsiveProbeScales`. That proof is only worth something while the app
/// actually refuses to exceed the largest of them — otherwise raising
/// `AppResponsive.maxTextScale` would silently let layouts reach a scale
/// nothing has ever checked, and the layout suite would still be green.
///
/// So this file asserts the two halves agree, and that the clamp does what it
/// claims at runtime.
void main() {
  test('the probed scales never exceed what the app allows', () {
    // If this fails, the fix is to add the new scale to the matrix and make
    // the screens pass at it — not to trim the matrix.
    expect(
      responsiveProbeScales.reduce((a, b) => a > b ? a : b),
      AppResponsive.maxTextScale,
      reason: 'The responsive layout matrix must probe right up to the '
          'ceiling the app clamps to, or the ceiling is untested.',
    );
  });

  testWidgets('a request above the ceiling is clamped down', (tester) async {
    late TextScaler effective;

    await tester.pumpWidget(
      MediaQuery(
        // Far above the cap, as a platform setting of 2.0+ would be.
        data: const MediaQueryData(textScaler: TextScaler.linear(3)),
        child: Builder(
          builder: (context) {
            effective = AppResponsive.clampedTextScaler(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(effective.scale(10), 10 * AppResponsive.maxTextScale);
  });

  testWidgets('a request below 1.0 is left alone', (tester) async {
    // Only the upper bound is clamped: someone who asks for smaller text is
    // asking for something every layout can honour.
    late TextScaler effective;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
        child: Builder(
          builder: (context) {
            effective = AppResponsive.clampedTextScaler(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(effective.scale(10), closeTo(8, 0.001));
  });

  testWidgets('scaled() grows a fixed dimension with the text', (tester) async {
    late double atOne;
    late double atCeiling;

    Future<void> measure(double scale, void Function(double) sink) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Builder(
            builder: (context) {
              sink(AppResponsive.scaled(context, 100));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    await measure(1, (v) => atOne = v);
    await measure(3, (v) => atCeiling = v);

    expect(atOne, 100);
    // Clamped, so a 3x request still only grows the box to the ceiling.
    expect(atCeiling, 100 * AppResponsive.maxTextScale);
  });
}
