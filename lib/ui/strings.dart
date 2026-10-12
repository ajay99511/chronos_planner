/// The boundary between user-facing text and the widgets that show it.
///
/// ## Why this exists, and what it deliberately does not do
///
/// `design-judgment.md` puts i18n under *"defer, but leave a seam — do not
/// build; do place the boundary so the future change is local"*. The app
/// declares one supported locale and there is no committed plan for a second,
/// so extracting all ~170 literals in `lib/ui` would be building the thing
/// rather than seaming it.
///
/// What *is* expensive to retrofit is text where English grammar has been
/// compiled into the widget tree: a ternary that appends "s" for a plural, a
/// count spliced into a sentence, a message assembled from fragments. Those
/// are wrong in most languages and, worse, they are invisible — they read as
/// ordinary string interpolation. `stack-appendices.md` §3 is explicit: *"never
/// concatenate translated fragments"*.
///
/// So this holds the messages that carry grammar, and only those. Fixed labels
/// ("Cancel", "Save", "CHRONOS") stay at their call sites: each is a single
/// token, a lookup would gain nothing today, and moving them later is a
/// mechanical find-and-replace against this same class.
///
/// When a second locale is actually committed, every message below becomes an
/// ARB entry with a proper `plural` clause, and the call sites do not change.
class AppStrings {
  const AppStrings._();

  // ── Overlap warnings ──────────────────────────

  /// Warns that a task collides with one existing task.
  static String overlapsWithTask(String title, String start, String end) =>
      'Heads up: overlaps with "$title" ($start–$end)';

  /// Warns that a task collides with [count] others.
  ///
  /// A separate message rather than a fragment appended to the singular: the
  /// two differ by more than an "s" in most languages.
  static String overlapsWithCount(int count) =>
      'Heads up: overlaps with $count other tasks';

  /// Confirms a task was added to several days, with any collisions noted.
  ///
  /// The count and its noun are formatted together so a translation can agree
  /// them; previously the plural "s" was appended by a ternary at the call
  /// site and the clause was concatenated onto the sentence.
  static String addedToDays({
    required String title,
    required int dayCount,
    required int overlapCount,
    String? firstOverlapTitle,
  }) {
    final base = 'Added "$title" to $dayCount days';
    if (overlapCount == 0) return base;
    final overlaps = overlapCount == 1
        ? '1 overlap found'
        : '$overlapCount overlaps found';
    final including =
        firstOverlapTitle == null ? '' : ' including "$firstOverlapTitle"';
    return '$base; $overlaps$including';
  }

  // ── Task and schedule messages ────────────────

  static String deletedTask(String title) => 'Deleted "$title"';

  static String templateSaved(String name) => 'Template "$name" saved';

  static String noPlansFor(String dayLabel) => 'No plans for $dayLabel';

  /// Screen-reader description of a day in the selector strip.
  static String daySummary({
    required String dayOfWeek,
    required String dateLabel,
    required int completed,
    required int total,
  }) =>
      '$dayOfWeek, $dateLabel, $completed of $total tasks completed';

  /// Screen-reader description of a task card.
  static String taskSummary({
    required String title,
    required String start,
    required String end,
    required String type,
    String description = '',
    required bool completed,
  }) =>
      [
        title,
        '$start to $end',
        type,
        if (description.isNotEmpty) description,
        completed ? 'completed' : 'not completed',
      ].join(', ');

  // ── Todo and timer messages ───────────────────

  static String timerDuration(int minutes) =>
      minutes == 1 ? '1 minute' : '$minutes minutes';

  static String checklistProgress(int done, int total) =>
      '$done / $total items completed';

  /// Spoken form of a countdown, so a screen reader does not read "12:34" as
  /// individual digits.
  static String timeRemaining(int totalSeconds) {
    if (totalSeconds <= 0) return 'Timer finished';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minutePart = minutes == 1 ? '1 minute' : '$minutes minutes';
    final secondPart = seconds == 1 ? '1 second' : '$seconds seconds';
    if (minutes == 0) return '$secondPart remaining';
    if (seconds == 0) return '$minutePart remaining';
    return '$minutePart $secondPart remaining';
  }

  /// Tells the user which alarms passed while the app was not running.
  ///
  /// Names them rather than giving a bare count: "1 alarm was missed" leaves
  /// the user guessing which, and the whole point is to restore trust.
  static String missedAlarms(Iterable<String> titles) {
    final names = titles.toList();
    if (names.isEmpty) return '';
    if (names.length == 1) {
      return 'Missed alarm while the app was closed: "${names.first}"';
    }
    if (names.length == 2) {
      return 'Missed 2 alarms while the app was closed: '
          '"${names[0]}" and "${names[1]}"';
    }
    return 'Missed ${names.length} alarms while the app was closed, '
        'including "${names.first}"';
  }

  static String planTaskCount(int count) =>
      count == 1 ? '1 task' : '$count tasks';

  // ── Reminder messages ─────────────────────────

  /// How a lead time reads in a chooser: "At start", "10 minutes before".
  ///
  /// Here rather than at the call site because it inflects a noun by a count
  /// *and* pairs it with a preposition, and because zero is a different
  /// sentence rather than "0 minutes before".
  static String reminderLeadLabel(int minutes) {
    if (minutes == 0) return 'At start';
    if (minutes == 1) return '1 minute before';
    if (minutes == 60) return '1 hour before';
    return '$minutes minutes before';
  }

  /// Body of the notification itself.
  ///
  /// Says when the task starts, because the reminder arrives minutes earlier
  /// and "Deep work block" alone does not tell the user whether to move now.
  static String reminderBody({
    required String start,
    required int leadMinutes,
  }) {
    if (leadMinutes == 0) return 'Starting now ($start)';
    if (leadMinutes == 1) return 'Starts in 1 minute, at $start';
    if (leadMinutes == 60) return 'Starts in 1 hour, at $start';
    return 'Starts in $leadMinutes minutes, at $start';
  }

  /// Screen-reader label for a task's reminder switch.
  ///
  /// Names the task and the lead time: a bare "switch" leaves a
  /// screen-reader user with no idea which of a day's blocks it belongs to.
  static String reminderToggleLabel({
    required String taskTitle,
    required bool enabled,
    required int leadMinutes,
  }) =>
      enabled
          ? 'Reminder on, ${reminderLeadLabel(leadMinutes).toLowerCase()}, '
              'for $taskTitle'
          : 'Reminder off for $taskTitle';
}
