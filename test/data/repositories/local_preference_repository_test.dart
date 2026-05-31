import 'dart:math';
import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/repositories/local/local_preference_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late LocalPreferenceRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    repository = LocalPreferenceRepository(database.preferenceDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('LocalPreferenceRepository', () {
    test('Preference Round-Trip', () async {
      // Feature: chronos-planner-tsd, Property 10: Preference Round-Trip
      final random = Random();
      const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

      String randomString(int length) {
        return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
      }

      for (int i = 0; i < 100; i++) {
        final key = randomString(random.nextInt(20) + 1);
        final value = randomString(random.nextInt(50) + 1);

        final setResult = await repository.set(key, value);
        expect(setResult, isA<Success>());

        final getResult = await repository.get(key);
        expect(getResult, isA<Success>());
        expect((getResult as Success).value, equals(value), reason: 'Iteration $i failed for key $key');
      }
    });

    test('get returns null for missing key', () async {
      final result = await repository.get('non-existent');
      expect(result, isA<Success>());
      expect((result as Success).value, equals(null));
    });

    test('remove deletes key', () async {
      await repository.set('key', 'value');
      await repository.remove('key');
      final result = await repository.get('key');
      expect((result as Success).value, equals(null));
    });
  });
}
