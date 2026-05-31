import 'package:flutter/foundation.dart';

/// A sealed class representing the result of an operation.
/// It can be either a [Success] containing a value of type [T],
/// or a [Failure] containing an [AppFailure].
@immutable
sealed class Result<T> {
  const Result();

  /// Executes [onSuccess] if this is a [Success], or [onFailure] if this is a [Failure].
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    return switch (this) {
      Success(value: final v) => onSuccess(v),
      Failure(failure: final f) => onFailure(f),
    };
  }
}

/// Represents a successful result containing [value].
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

/// Represents a failed result containing [failure].
final class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

/// A sealed class representing the hierarchy of application failures.
@immutable
sealed class AppFailure {
  final String message;
  final dynamic originalError;

  const AppFailure(this.message, [this.originalError]);

  @override
  String toString() => '$runtimeType: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Represents a failure related to database operations.
final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, [super.originalError]);
}

/// Represents a failure related to data validation.
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, [super.originalError]);
}

/// Represents a failure related to network operations.
final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, [super.originalError]);
}

/// Represents an unknown or unexpected failure.
final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, [super.originalError]);
}
