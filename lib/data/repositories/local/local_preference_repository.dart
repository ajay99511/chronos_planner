import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/repositories/local/db_guard.dart';
import 'package:chronosky/data/local/daos/preference_dao.dart';
import 'package:chronosky/data/repositories/preference_repository.dart';

/// Drift-backed implementation of [PreferenceRepository].
class LocalPreferenceRepository implements PreferenceRepository {
  final PreferenceDao _dao;

  LocalPreferenceRepository(this._dao);

  @override
  Future<Result<String?>> get(String key) {
    return guardDb(() => _dao.getValue(key));
  }

  @override
  Future<Result<void>> set(String key, String value) {
    return guardDb(() => _dao.setValue(key, value));
  }

  @override
  Future<Result<void>> remove(String key) {
    return guardDb(() => _dao.deleteValue(key));
  }
}
