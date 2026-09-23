import 'package:chronosky/ui/strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// These messages exist because they carry grammar. A count spliced into a
/// sentence, or a plural produced by appending "s", is wrong in most languages
/// and invisible at the call site — it reads as ordinary interpolation.
/// stack-appendices.md §3: "never concatenate translated fragments".
void main() {
  group('overlap warnings', () {
    test('names the single colliding task and its slot', () {
      expect(
        AppStrings.overlapsWithTask('Deep work', '09:00', '11:00'),
        'Heads up: overlaps with "Deep work" (09:00–11:00)',
      );
    });

    test('a multi-collision warning is its own message, not a suffix', () {
      // Kept separate rather than appending to the singular: the two differ by
      // more than an "s" in most languages.
      expect(
        AppStrings.overlapsWithCount(3),
        'Heads up: overlaps with 3 other tasks',
      );
    });
  });

  group('addedToDays', () {
    test('omits the overlap clause when there are none', () {
      expect(
        AppStrings.addedToDays(title: 'Standup', dayCount: 3, overlapCount: 0),
        'Added "Standup" to 3 days',
      );
    });

    test('agrees the overlap count with its noun', () {
      expect(
        AppStrings.addedToDays(title: 'Standup', dayCount: 3, overlapCount: 1),
        contains('1 overlap found'),
      );
      expect(
        AppStrings.addedToDays(title: 'Standup', dayCount: 3, overlapCount: 2),
        contains('2 overlaps found'),
      );
    });

    test('names the first overlap when one is known', () {
      expect(
        AppStrings.addedToDays(
          title: 'Standup',
          dayCount: 2,
          overlapCount: 1,
          firstOverlapTitle: 'Deep work',
        ),
        'Added "Standup" to 2 days; 1 overlap found including "Deep work"',
      );
    });

    test('omits the "including" clause when no title is known', () {
      expect(
        AppStrings.addedToDays(title: 'Standup', dayCount: 2, overlapCount: 4),
        isNot(contains('including')),
      );
    });
  });

  group('counts that must agree with their noun', () {
    test('timerDuration', () {
      expect(AppStrings.timerDuration(1), '1 minute');
      expect(AppStrings.timerDuration(25), '25 minutes');
      expect(AppStrings.timerDuration(0), '0 minutes');
    });

    test('planTaskCount', () {
      expect(AppStrings.planTaskCount(1), '1 task');
      expect(AppStrings.planTaskCount(0), '0 tasks');
      expect(AppStrings.planTaskCount(7), '7 tasks');
    });

    test('checklistProgress', () {
      expect(AppStrings.checklistProgress(2, 5), '2 / 5 items completed');
    });
  });

  group('timeRemaining', () {
    test('reports both units when both are non-zero', () {
      expect(AppStrings.timeRemaining(754), '12 minutes 34 seconds remaining');
    });

    test('drops the zero unit rather than saying "0 seconds"', () {
      expect(AppStrings.timeRemaining(600), '10 minutes remaining');
      expect(AppStrings.timeRemaining(45), '45 seconds remaining');
    });

    test('agrees singular units', () {
      expect(AppStrings.timeRemaining(61), '1 minute 1 second remaining');
    });

    test('announces completion rather than "0 seconds remaining"', () {
      expect(AppStrings.timeRemaining(0), 'Timer finished');
      expect(AppStrings.timeRemaining(-5), 'Timer finished');
    });
  });

  group('missedAlarms', () {
    test('names a single missed alarm', () {
      expect(
        AppStrings.missedAlarms(['Wake up']),
        'Missed alarm while the app was closed: "Wake up"',
      );
    });

    test('names both when two were missed', () {
      expect(
        AppStrings.missedAlarms(['Wake up', 'Standup']),
        'Missed 2 alarms while the app was closed: "Wake up" and "Standup"',
      );
    });

    test('summarises with an example beyond two', () {
      final message = AppStrings.missedAlarms(['A', 'B', 'C']);
      expect(message, contains('Missed 3 alarms'));
      expect(message, contains('including "A"'));
    });

    test('is empty when nothing was missed', () {
      expect(AppStrings.missedAlarms(const []), isEmpty);
    });
  });

  group('accessibility summaries', () {
    test('daySummary reads as a sentence', () {
      expect(
        AppStrings.daySummary(
          dayOfWeek: 'Tuesday',
          dateLabel: 'Sep 22',
          completed: 1,
          total: 3,
        ),
        'Tuesday, Sep 22, 1 of 3 tasks completed',
      );
    });

    test('taskSummary includes the description only when present', () {
      expect(
        AppStrings.taskSummary(
          title: 'Deep work',
          start: '09:00',
          end: '11:00',
          type: 'work',
          completed: false,
        ),
        'Deep work, 09:00 to 11:00, work, not completed',
      );
      expect(
        AppStrings.taskSummary(
          title: 'Deep work',
          start: '09:00',
          end: '11:00',
          type: 'work',
          description: 'Finish the audit',
          completed: true,
        ),
        'Deep work, 09:00 to 11:00, work, Finish the audit, completed',
      );
    });
  });
}
