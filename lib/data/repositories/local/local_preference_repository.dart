import 'package:drift/drift.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/local/daos/preference_dao.dart';
import 'package:chronosky/data/repositories/preference_repository.dart';

/// Drift-backed implementation of [PreferenceRepository] and [BulkPreferenceRepository].
class LocalPreferenceRepository implements BulkPreferenceRepository {
  final PreferenceDao _dao;

  LocalPreferenceRepository(this._dao);

  Future<Result<T>> _wrap<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Success(value);
    } on DriftWrappedException catch (e) {
      return Failure(DatabaseFailure('Database operation failed', e.toString()));
    } on Exception catch (e) {
      return Failure(UnknownFailure('Unexpected error', e.toString()));
    }
  }

  @override
  Future<Result<String?>> get(String key) {
    return _wrap(() => _dao.getValue(key));
  }

  @override
  Future<Result<void>> set(String key, String value) {
    return _wrap(() => _dao.setValue(key, value));
  }

  @override
  Future<Result<void>> remove(String key) {
    return _wrap(() => _dao.deleteValue(key));
  }

  @override
  Future<Result<Map<String, String>>> getAll() {
    return _wrap(() => _dao.getAll());
  }
}
