import 'package:flutter/material.dart';

/// Animation timing that respects the platform's reduce-motion setting.
///
/// The app leans heavily on movement — scale-on-hover cards, animated day
/// chips, fades, and large blurred backdrops. For users who have asked their OS
/// to reduce motion, that is at best distracting and at worst nauseating, and
/// `stack-appendices.md` §3 requires honouring the preference.
extension MotionPreference on BuildContext {
  /// Whether the user has asked the platform to minimise animation.
  bool get prefersReducedMotion => MediaQuery.of(this).disableAnimations;

  /// [preferred], or zero when the user prefers reduced motion.
  ///
  /// Zero rather than "shorter": a reduced-motion request means no movement,
  /// not faster movement. Widgets still rebuild and still land in their final
  /// state, so nothing is lost but the transition.
  Duration motion(Duration preferred) =>
      prefersReducedMotion ? Duration.zero : preferred;
}
