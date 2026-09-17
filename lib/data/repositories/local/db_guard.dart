import 'package:drift/drift.dart';

import 'package:chronosky/core/result.dart';

/// Runs [action], mapping anything it throws into the [Result] taxonomy.
///
/// Catches `Object` rather than `Exception` deliberately. Dart's `Error`
/// hierarchy — `StateError`, `RangeError`, cast failures — does not implement
/// `Exception`, so an `on Exception` clause lets those escape the envelope
/// entirely. When that happens the caller's `Result.fold` never runs: its
/// optimistic UI update is never rolled back, no transient error is recorded,
/// and the user is shown a write that silently did not happen.
///
/// Shared by every local repository so the error taxonomy has one definition
/// rather than four copies that drift apart.
Future<Result<T>> guardDb<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } on DriftWrappedException catch (e) {
    return Failure(DatabaseFailure('Database operation failed', e.toString()));
  } catch (e) {
    return Failure(UnknownFailure('Unexpected error', e.toString()));
  }
}
