import 'package:chronosky/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success should contain value', () {
      const result = Success<int>(42);
      expect(result.value, 42);
    });

    test('Failure should contain AppFailure', () {
      const failure = DatabaseFailure('DB error');
      const result = Failure<int>(failure);
      expect(result.failure, isA<DatabaseFailure>());
      expect(result.failure.message, 'DB error');
    });

    test('fold should call onSuccess when result is Success', () {
      const result = Success<int>(42);
      final folded = result.fold(
        onSuccess: (value) => value * 2,
        onFailure: (failure) => 0,
      );
      expect(folded, 84);
    });

    test('fold should call onFailure when result is Failure', () {
      const failure = ValidationFailure('Invalid data');
      const result = Failure<int>(failure);
      final folded = result.fold(
        onSuccess: (value) => value * 2,
        onFailure: (failure) => failure.message,
      );
      expect(folded, 'Invalid data');
    });

    test('pattern matching should work with switch expression', () {
      const Result<int> result = Success(42);
      final value = switch (result) {
        Success(value: final v) => v,
        Failure() => 0,
      };
      expect(value, 42);
    });
  });

  group('AppFailure', () {
    test('DatabaseFailure should have correct message and toString', () {
      const failure = DatabaseFailure('DB error', 'Internal exception');
      expect(failure.message, 'DB error');
      expect(failure.originalError, 'Internal exception');
      expect(failure.toString(), contains('DatabaseFailure: DB error (Internal exception)'));
    });

    test('ValidationFailure should have correct message', () {
      const failure = ValidationFailure('Invalid title');
      expect(failure.message, 'Invalid title');
      expect(failure.toString(), contains('ValidationFailure: Invalid title'));
    });

    test('NetworkFailure should have correct message', () {
      const failure = NetworkFailure('No internet');
      expect(failure.message, 'No internet');
      expect(failure.toString(), contains('NetworkFailure: No internet'));
    });

    test('UnknownFailure should have correct message', () {
      const failure = UnknownFailure('Unexpected error');
      expect(failure.message, 'Unexpected error');
      expect(failure.toString(), contains('UnknownFailure: Unexpected error'));
    });
  });
}
