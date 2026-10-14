/// The sound a task reminder makes.
///
/// ## Why a fixed set, and why each one owns a channel
/// On Android a notification's sound belongs to its **channel**, and a channel
/// is immutable once created — the user owns its settings, and
/// `createNotificationChannel` on an existing id silently updates only the
/// name and description. So "let the user change the reminder sound" cannot be
/// done by mutating one channel; each sound needs a channel of its own, and
/// switching means creating the new one and deleting the old.
///
/// That is why this is a closed enum rather than a file path: every possible
/// value has to correspond to a channel the app can create and tear down, and
/// an arbitrary user-supplied file would mean an unbounded set of channels
/// accumulating in the user's system settings.
///
/// ## Why the duration lives in the file
/// A reminder is meant to ring for about ten seconds and then stop. Nothing in
/// Dart can stop a notification's sound once the OS starts it, so the duration
/// *is* the file's length. The bundled tones are each exactly 10 seconds.
/// See docs/decisions/0013-reminder-tones.md.
enum ReminderTone {
  /// Warm two-note bell. The default: audible without being an alarm.
  chime(
    label: 'Chime',
    description: 'A warm bell, repeating for ten seconds.',
    resource: 'reminder_chime',
    channelSuffix: 'chime',
  ),

  /// Plainer repeating beeps.
  pulse(
    label: 'Pulse',
    description: 'Soft repeating beeps, for ten seconds.',
    resource: 'reminder_pulse',
    channelSuffix: 'pulse',
  ),

  /// Plucky and short — the least intrusive of the bundled tones.
  marimba(
    label: 'Marimba',
    description: 'Short plucked notes, for ten seconds.',
    resource: 'reminder_marimba',
    channelSuffix: 'marimba',
  ),

  /// The device's own notification sound.
  ///
  /// Short — usually under two seconds — so it does **not** give the
  /// ten-second behaviour. Offered because some people want their phone to
  /// sound like their phone, and because it is the only option that keeps
  /// working if a bundled file is ever removed.
  deviceDefault(
    label: 'Device default',
    description: 'Your phone\'s own notification sound. Brief, not ten '
        'seconds.',
    resource: null,
    channelSuffix: 'system',
  );

  const ReminderTone({
    required this.label,
    required this.description,
    required this.resource,
    required this.channelSuffix,
  });

  /// Name shown in the picker.
  final String label;

  /// One line under the label, so the trade-off is visible before choosing.
  final String description;

  /// Android raw-resource name, without extension, or null for the system
  /// sound. Must match a file in `android/app/src/main/res/raw/`.
  final String? resource;

  /// Appended to the reminder channel id, so each tone gets its own channel.
  ///
  /// Part of the channel id rather than derived from [name] so that renaming
  /// an enum value cannot silently orphan a channel on a user's device.
  final String channelSuffix;

  /// Whether this tone gives the ten-second behaviour.
  bool get ringsForTenSeconds => resource != null;

  /// The tone used when nothing has been chosen, or a stored value cannot be
  /// read back.
  static const ReminderTone fallback = ReminderTone.chime;

  /// Resolves a persisted [name], falling back rather than throwing.
  ///
  /// A preference written by a build that offered a tone this one does not is
  /// an expected outcome, not a crash: the user downgraded, or the tone was
  /// retired. Falling back silently is right because the alternative is a user
  /// whose reminders stop making any sound at all.
  static ReminderTone fromName(String? stored) {
    if (stored == null) return fallback;
    for (final tone in ReminderTone.values) {
      if (tone.name == stored) return tone;
    }
    return fallback;
  }
}

/// Bumped when a bundled tone's audio file changes.
///
/// A channel's sound is fixed at creation, so replacing `reminder_chime.wav`
/// with a different recording would leave every existing install playing the
/// old one forever. Incrementing this changes every channel id, which makes
/// Android treat them as new channels and pick up the new audio.
///
/// The cost of bumping it is that the user's own per-channel tweaks (volume,
/// vibration, importance) reset, so do it only when the audio actually
/// changed — not for a label or description edit, which Android *does* let the
/// app update in place.
const String reminderChannelVersion = 'v1';

/// The Android channel id for [tone].
String reminderChannelId(ReminderTone tone) =>
    'chronos_reminders_${tone.channelSuffix}_$reminderChannelVersion';
