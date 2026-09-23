import 'package:chronosky/core/services/logger.dart';
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/main.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises startup end to end over an in-memory database: schema creation,
/// the SharedPreferences migration and the provider wiring, in one pass.
///
/// main() previously reached for the AppDatabase singleton directly, so this
/// path -- the riskiest in the app, since it both migrates and opens -- had no
/// test at all.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppDatabase memoryDb() =>
      AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

  test('wires a usable schedule over a fresh database', () async {
    final db = memoryDb();
    addTearDown(db.close);

    final deps = await composeDependencies(
      database: db,
      logger: const NoOpLogger(),
    );
    addTearDown(deps.scheduleStateProvider.dispose);

    // The provider loads in its constructor.
    await pumpEventQueue();

    expect(deps.scheduleStateProvider.errorMessage, isNull);
    expect(
      deps.scheduleStateProvider.weekPlan,
      hasLength(7),
      reason: 'startup must produce the full rolling window',
    );

    // The rolling window was persisted, not just held in memory.
    final rows = await db.select(db.dayPlans).get();
    expect(rows, hasLength(7));
  });

  test('carries legacy SharedPreferences data through startup', () async {
    SharedPreferences.setMockInitialValues({
      'chronos-sort-order': 'desc',
    });
    final db = memoryDb();
    addTearDown(db.close);

    final deps = await composeDependencies(
      database: db,
      logger: const NoOpLogger(),
    );
    addTearDown(deps.scheduleStateProvider.dispose);
    await pumpEventQueue();

    // Migrated into Drift and then read back by the provider, which is the
    // whole chain this seam exists to cover.
    expect(deps.scheduleStateProvider.sortOrder, SortOrder.desc);
  });

  test('startup is idempotent across a restart', () async {
    final db = memoryDb();
    addTearDown(db.close);

    final first = await composeDependencies(
      database: db,
      logger: const NoOpLogger(),
    );
    await pumpEventQueue();
    first.scheduleStateProvider.dispose();

    final second = await composeDependencies(
      database: db,
      logger: const NoOpLogger(),
    );
    addTearDown(second.scheduleStateProvider.dispose);
    await pumpEventQueue();

    expect(second.scheduleStateProvider.weekPlan, hasLength(7));
    // Re-running must reuse the existing rows rather than duplicating the
    // window, which is what the v8 uniqueness work was protecting.
    final rows = await db.select(db.dayPlans).get();
    expect(rows, hasLength(7));
  });
}
