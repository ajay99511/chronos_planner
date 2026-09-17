import 'package:flutter/foundation.dart';

/// A wall-clock time of day, stored as minutes since midnight.
///
/// The app persists times as `"HH:mm"` strings and relies on lexical order
/// matching chronological order, which only holds while every value is
/// zero-padded and within range. Parsing goes through here so that assumption
/// is checked in exactly one place.
@immutable
class ClockTime implements Comparable<ClockTime> {
  const ClockTime._(this.minutesSinceMidnight);

  /// Minutes elapsed since 00:00, in `0..1439`.
  final int minutesSinceMidnight;

  static final RegExp _format = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// Whether [raw] is a zero-padded 24-hour `HH:mm` value.
  static bool isValid(String raw) => _format.hasMatch(raw);

  /// Parses [raw], or returns null if it is not a valid `HH:mm` value.
  ///
  /// Returns null rather than a fallback because the three call sites this
  /// replaced each invented a different fallback — 0, null and 0-via-catch —
  /// and a silent 0 turns a corrupt record into a midnight event that looks
  /// legitimate.
  static ClockTime? tryParse(String raw) {
    if (!isValid(raw)) return null;
    final hours = int.parse(raw.substring(0, 2));
    final minutes = int.parse(raw.substring(3, 5));
    return ClockTime._(hours * 60 + minutes);
  }

  /// Hour component, `0..23`.
  int get hour => minutesSinceMidnight ~/ 60;

  /// Zero-padded `HH:mm` representation.
  String get formatted {
    final h = hour.toString().padLeft(2, '0');
    final m = (minutesSinceMidnight % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  int compareTo(ClockTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockTime &&
          minutesSinceMidnight == other.minutesSinceMidnight;

  @override
  int get hashCode => minutesSinceMidnight.hashCode;

  @override
  String toString() => formatted;
}

/// A span between two clock times, which may cross midnight.
///
/// An end at or before the start is read as running into the next day, which
/// is how the app has always treated overnight tasks — a 23:00–01:00 block is
/// two hours, not negative.
@immutable
class TimeRange {
  const TimeRange({required this.start, required this.end});

  final ClockTime start;
  final ClockTime end;

  /// Parses a `"HH:mm"` pair, or returns null if either side is malformed.
  static TimeRange? tryParse(String start, String end) {
    final from = ClockTime.tryParse(start);
    final to = ClockTime.tryParse(end);
    if (from == null || to == null) return null;
    return TimeRange(start: from, end: to);
  }

  static const int _minutesPerDay = 24 * 60;

  /// Whether the range runs past midnight into the following day.
  bool get crossesMidnight =>
      end.minutesSinceMidnight <= start.minutesSinceMidnight;

  /// End expressed as minutes from the start's midnight, so an overnight
  /// range reads as a value above 1440 rather than wrapping.
  int get _normalizedEndMinutes =>
      crossesMidnight
          ? end.minutesSinceMidnight + _minutesPerDay
          : end.minutesSinceMidnight;

  /// Elapsed time, treating an overnight range as continuing into the next
  /// day. A range starting and ending at the same minute is a full day, which
  /// preserves the behaviour the schedule and analytics screens relied on.
  Duration get duration => Duration(
        minutes: _normalizedEndMinutes - start.minutesSinceMidnight,
      );

  /// Whether this range and [other] share any time.
  ///
  /// Half-open: a range ending exactly when another starts does not overlap,
  /// so back-to-back tasks are not flagged as double-booked.
  bool overlaps(TimeRange other) =>
      start.minutesSinceMidnight < other._normalizedEndMinutes &&
      other.start.minutesSinceMidnight < _normalizedEndMinutes;

  /// The fraction of this range falling inside clock hour [hour], in minutes.
  ///
  /// Used to spread a task's weight across the hours it spans.
  int minutesInHour(int hour) {
    final hourStart = hour * 60;
    var overlapMinutes = 0;
    // Check the hour in this day and the next, since the range may cross
    // midnight and land on the same clock hour again.
    for (final offset in [0, _minutesPerDay]) {
      final from = hourStart + offset;
      final to = from + 60;
      final lower = from > start.minutesSinceMidnight
          ? from
          : start.minutesSinceMidnight;
      final upper = to < _normalizedEndMinutes ? to : _normalizedEndMinutes;
      if (upper > lower) overlapMinutes += upper - lower;
    }
    return overlapMinutes;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '${start.formatted}-${end.formatted}';
}
