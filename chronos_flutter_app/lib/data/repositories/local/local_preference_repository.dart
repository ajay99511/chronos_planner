import '../../local/daos/preference_dao.dart';
import '../preference_repository.dart';

/// Drift-backed implementation of [PreferenceRepository].
class LocalPreferenceRepository implements PreferenceRepository {
  final PreferenceDao _dao;

  LocalPreferenceRepository(this._dao);

  @override
  Future<String?> get(String key) => _dao.getValue(key);

  @override
  Future<void> set(String key, String value) => _dao.setValue(key, value);

  @override
  Future<void> remove(String key) => _dao.deleteValue(key);

  @override
  Future<Map<String, String>> getAll() => _dao.getAll();
}
