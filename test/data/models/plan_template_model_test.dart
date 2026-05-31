import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanTemplate Active Days Logic', () {
    // Feature: chronos-planner-tsd, Property 2: PlanTemplate Active Days Round-Trip
    
    String encodeDays(List<int> days) {
      return days.join(',');
    }

    List<int> parseActiveDays(String activeDaysStr) {
      if (activeDaysStr.isEmpty) return [];
      return activeDaysStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .where((d) => d >= 0 && d <= 6)
          .toList();
    }

    test('Active Days Round-Trip', () {
      final random = Random();
      final allDays = [0, 1, 2, 3, 4, 5, 6];

      for (int i = 0; i < 100; i++) {
        // Generate a random subset of days
        final subset = <int>[];
        for (final day in allDays) {
          if (random.nextBool()) {
            subset.add(day);
          }
        }

        final encoded = encodeDays(subset);
        final parsed = parseActiveDays(encoded);

        expect(parsed.toSet(), equals(subset.toSet()), reason: 'Iteration $i failed for subset $subset');
      }
    });

    test('Parse handles malformed strings', () {
      expect(parseActiveDays('0, 2, 8, abc, 4'), [0, 2, 4]);
      expect(parseActiveDays('  1,2,  3  '), [1, 2, 3]);
      expect(parseActiveDays(''), []);
    });
  });
}
