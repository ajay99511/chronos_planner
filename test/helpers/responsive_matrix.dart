import 'dart:ui';

/// The window sizes every screen is expected to lay out in without overflowing.
///
/// Chosen because each one is a real device class rather than a round number:
///
/// - **320×568** — the narrowest width still in use (small Androids, iPhone SE
///   1st gen) and, more commonly now, what any phone becomes in split-screen.
///   This is the width that was broken on every screen.
/// - **360×640** — the single most common Android width in the field.
/// - **411×731** — a modern mid-size phone (Pixel class).
/// - **600×900** — the compact/medium breakpoint, i.e. a small tablet or a
///   phone in landscape. Sits exactly on `AppResponsive.isMedium`.
/// - **900×600** — the medium/expanded breakpoint, landscape. Short *and* wide,
///   which is the shape that catches vertical layouts assuming phone height.
/// - **1200×900** — the desktop default from `main.dart`.
const List<Size> responsiveProbeSizes = [
  Size(320, 568),
  Size(360, 640),
  Size(411, 731),
  Size(600, 900),
  Size(900, 600),
  Size(1200, 900),
];

/// Text scales every screen is expected to survive.
///
/// 1.3 is an ordinary accessibility setting that a great many people use
/// without thinking of it as one. 1.5 is the ceiling the app clamps to (see
/// `AppResponsive.clampedTextScaler`), so nothing above it can reach a layout
/// and there is no point probing it.
const List<double> responsiveProbeScales = [1.0, 1.3, 1.5];
