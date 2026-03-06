/// Abstract interface for user preferences.
abstract class PreferenceRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
  Future<void> remove(String key);
  Future<Map<String, String>> getAll();
}
