/// How long before a task starts its reminder fires.
///
/// Kept in `domain/` rather than beside the projection in
/// `core/services/task_reminders.dart` because the models validate against it:
/// a model importing a service that imports `ui/strings.dart` would invert the
/// layering for the sake of four constants.
library;

/// The lead times a reminder can be set to, in minutes before the task starts.
///
/// A fixed set rather than a free-text field: nobody wants a 7-minute
/// reminder, and an open number invites a value the notification cannot
/// usefully honour. 0 means "when the task starts", which for time-blocking is
/// defensible in itself — the block *is* the appointment.
const List<int> reminderLeadChoices = [0, 5, 10, 15, 30, 60];

/// Lead time applied to a task that has not chosen one.
const int defaultReminderLeadMinutes = 10;

/// Upper bound on a stored lead time, in minutes (24 hours).
///
/// Enforced here and as a SQL `CHECK` on both task tables, per
/// docs/decisions/0004-invariants-in-both-app-and-schema.md. A reminder more
/// than a day ahead of its task is not a reminder about that task.
const int maxReminderLeadMinutes = 1440;

/// Whether [minutes] is a lead time this app will store.
bool isValidReminderLead(int minutes) =>
    minutes >= 0 && minutes <= maxReminderLeadMinutes;
