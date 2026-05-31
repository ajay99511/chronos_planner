import 'package:chronosky/core/result.dart';

/// Abstract interface for individual user preferences.
abstract class PreferenceRepository {
  /// Get a preference value by key.
  Future<Result<String?>> get(String key);

  /// Set a preference value.
  Future<Result<void>> set(String key, String value);

  /// Remove a preference by key.
  Future<Result<void>> remove(String key);
}

/// Extended interface for bulk preference operations.
abstract class BulkPreferenceRepository extends PreferenceRepository {
  /// Get all preferences.
  Future<Result<Map<String, String>>> getAll();
}
