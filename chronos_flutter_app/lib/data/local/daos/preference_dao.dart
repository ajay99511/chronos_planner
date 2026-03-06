import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'preference_dao.g.dart';

@DriftAccessor(tables: [Preferences])
class PreferenceDao extends DatabaseAccessor<AppDatabase>
    with _$PreferenceDaoMixin {
  PreferenceDao(super.db);

  /// Get a preference value by key, or null if not set.
  Future<String?> getValue(String key) async {
    final row = await (select(preferences)..where((p) => p.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Set a preference value (insert or update).
  Future<void> setValue(String key, String value) {
    return into(preferences).insertOnConflictUpdate(
      PreferencesCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  /// Delete a preference by key.
  Future<int> deleteValue(String key) {
    return (delete(preferences)..where((p) => p.key.equals(key))).go();
  }

  /// Get all preferences as a map.
  Future<Map<String, String>> getAll() async {
    final rows = await select(preferences).get();
    return {for (final r in rows) r.key: r.value};
  }
}
