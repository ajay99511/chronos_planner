import 'package:chronosky/ui/navigation/feature_tabs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the registry's invariants.
///
/// Adding a destination previously meant four separate edits — the screen
/// list, the sidebar items, the bottom-bar items, and keeping their order in
/// agreement. Both navigation surfaces now derive from [appFeatureTabs], so
/// these are the properties that keep that true.
void main() {
  test('every tab carries both a full and a compact label', () {
    for (final tab in appFeatureTabs) {
      expect(tab.label, isNotEmpty, reason: 'sidebar label');
      expect(tab.compactLabel, isNotEmpty, reason: 'bottom bar label');
    }
  });

  test('labels are unique, so a destination is unambiguous', () {
    expect(
      appFeatureTabs.map((t) => t.label).toSet(),
      hasLength(appFeatureTabs.length),
    );
    expect(
      appFeatureTabs.map((t) => t.compactLabel).toSet(),
      hasLength(appFeatureTabs.length),
    );
  });

  test('icons are distinct, so tabs are visually distinguishable', () {
    expect(
      appFeatureTabs.map((t) => t.icon).toSet(),
      hasLength(appFeatureTabs.length),
    );
  });

  test('screens are distinct instances', () {
    expect(
      appFeatureTabs.map((t) => t.screen.runtimeType).toSet(),
      hasLength(appFeatureTabs.length),
    );
  });

  test('a bottom navigation bar can render the registry', () {
    // BottomNavigationBar asserts on fewer than two items, which is the one
    // way a future edit to this list could break the shell at runtime.
    expect(appFeatureTabs.length, greaterThanOrEqualTo(2));
  });
}
