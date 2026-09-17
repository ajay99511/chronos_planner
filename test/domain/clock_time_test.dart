import 'package:chronosky/domain/clock_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClockTime.tryParse', () {
    test('parses a zero-padded 24-hour time', () {
      expect(ClockTime.tryParse('09:30')!.minutesSinceMidnight, 9 * 60 + 30);
      expect(ClockTime.tryParse('00:00')!.minutesSinceMidnight, 0);
      expect(ClockTime.tryParse('23:59')!.minutesSinceMidnight, 23 * 60 + 59);
    });

    test('rejects everything that is not HH:mm in range', () {
      for (final bad in [
        '',
        '9:00', // not zero-padded
        '24:00', // hour out of range
        '12:60', // minute out of range
        '99:99',
        'noon',
        '09:30:00',
        ' 09:30',
      ]) {
        expect(ClockTime.tryParse(bad), isNull, reason: '"$bad"');
      }
    });

    test('round-trips through formatted', () {
      for (final raw in ['00:00', '07:05', '13:45', '23:59']) {
        expect(ClockTime.tryParse(raw)!.formatted, raw);
      }
    });

    test('orders chronologically', () {
      final early = ClockTime.tryParse('08:00')!;
      final late = ClockTime.tryParse('17:30')!;

      expect(early.compareTo(late), isNegative);
      expect(([late, early]..sort()).first, early);
    });

    test('equal times are equal and hash alike', () {
      expect(ClockTime.tryParse('10:15'), ClockTime.tryParse('10:15'));
      expect(
        ClockTime.tryParse('10:15').hashCode,
        ClockTime.tryParse('10:15').hashCode,
      );
    });
  });

  group('TimeRange.duration', () {
    Duration durationOf(String from, String to) =>
        TimeRange.tryParse(from, to)!.duration;

    test('measures a same-day range', () {
      expect(durationOf('09:00', '11:30'), const Duration(hours: 2, minutes: 30));
    });

    test('treats an overnight range as running into the next day', () {
      expect(durationOf('23:00', '01:00'), const Duration(hours: 2));
      expect(durationOf('22:30', '06:00'), const Duration(hours: 7, minutes: 30));
    });

    test('treats an identical start and end as a full day', () {
      // Preserves the prior behaviour of the schedule and analytics screens,
      // which both normalised end <= start by adding 24h.
      expect(durationOf('09:00', '09:00'), const Duration(hours: 24));
    });

    test('is null for a malformed pair rather than silently zero', () {
      expect(TimeRange.tryParse('99:99', '10:00'), isNull);
      expect(TimeRange.tryParse('09:00', 'later'), isNull);
    });
  });

  group('TimeRange.overlaps', () {
    TimeRange range(String from, String to) => TimeRange.tryParse(from, to)!;

    test('detects a partial overlap in both directions', () {
      final morning = range('09:00', '11:00');
      final late = range('10:30', '12:00');

      expect(morning.overlaps(late), isTrue);
      expect(late.overlaps(morning), isTrue);
    });

    test('detects containment', () {
      expect(range('09:00', '17:00').overlaps(range('12:00', '13:00')), isTrue);
      expect(range('12:00', '13:00').overlaps(range('09:00', '17:00')), isTrue);
    });

    test('does not flag back-to-back ranges', () {
      // Half-open: a task ending at 11:00 and one starting at 11:00 are not
      // double-booked, which is the common case for a packed schedule.
      expect(range('09:00', '11:00').overlaps(range('11:00', '12:00')), isFalse);
    });

    test('does not flag disjoint ranges', () {
      expect(range('09:00', '10:00').overlaps(range('14:00', '15:00')), isFalse);
    });

    test('detects an overnight range overlapping an early-morning one', () {
      expect(range('22:00', '02:00').overlaps(range('23:00', '23:30')), isTrue);
    });

    test('a range always overlaps itself', () {
      final r = range('09:00', '11:00');
      expect(r.overlaps(r), isTrue);
    });
  });

  group('TimeRange.minutesInHour', () {
    TimeRange range(String from, String to) => TimeRange.tryParse(from, to)!;

    test('attributes a whole hour fully', () {
      expect(range('09:00', '12:00').minutesInHour(10), 60);
    });

    test('attributes a partial hour proportionally', () {
      expect(range('09:30', '10:15').minutesInHour(9), 30);
      expect(range('09:30', '10:15').minutesInHour(10), 15);
    });

    test('attributes nothing to an untouched hour', () {
      expect(range('09:00', '11:00').minutesInHour(14), 0);
    });

    test('spreads an overnight range across both sides of midnight', () {
      final overnight = range('23:00', '01:00');

      expect(overnight.minutesInHour(23), 60);
      expect(overnight.minutesInHour(0), 60);
      expect(overnight.minutesInHour(1), 0);
    });

    test('sums to the range duration across all hours', () {
      final r = range('09:30', '13:45');
      var total = 0;
      for (var hour = 0; hour < 24; hour++) {
        total += r.minutesInHour(hour);
      }
      expect(total, r.duration.inMinutes);
    });
  });
}
