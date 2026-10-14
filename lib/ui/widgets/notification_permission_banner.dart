import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chronosky/core/services/notification_coordinator.dart';
import 'package:chronosky/core/theme/app_theme.dart';

/// Warns that the OS will not deliver, and offers the fix inline.
///
/// Without notification permission every scheduled alarm and reminder is
/// silently useless, so a screen that lets the user arm one must not also let
/// them believe it is set. Reporting the problem without the remedy would just
/// relocate the dead end, hence the button.
///
/// One widget rather than a copy per screen: the Tasks tab and the Schedule
/// tab show the same banner about the same permission, and two copies would
/// drift in wording the moment either is touched.
///
/// Renders nothing when delivery is permitted, so callers can place it
/// unconditionally.
class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({super.key, required this.message});

  /// What the user loses while permission is denied, in their terms.
  ///
  /// Passed in rather than fixed because the stakes differ by screen: an alarm
  /// that will not go off is a different sentence from a reminder that will
  /// not arrive.
  final String message;

  @override
  Widget build(BuildContext context) {
    final coordinator = context.watch<NotificationCoordinator>();
    if (!coordinator.notificationsBlocked) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.pagePadding(context),
        0,
        AppResponsive.pagePadding(context),
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_off_rounded,
              color: Colors.orangeAccent,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              // Bounded: this is a prompt competing for height with the list
              // it sits above, and on a 320x568 phone at 1.3 text scale an
              // unbounded three-line message pushed the whole screen over.
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.bodySmall.copyWith(color: Colors.orangeAccent),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              // Explicit, not the theme's accent: the theme's indigo over
              // this orange tint measures 2.18:1, which the accessibility
              // suite fails and a user in sunlight cannot read. Matching the
              // banner's own orange gives 7.6:1 against the same composited
              // background.
              style: TextButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
              ),
              onPressed: coordinator.requestNotificationPermission,
              child: const Text('ALLOW'),
            ),
          ],
        ),
      ),
    );
  }
}
