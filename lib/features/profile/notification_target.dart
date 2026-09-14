/// Where a notification leads: the feed row and a tapped push share this one
/// mapping so the two can never send the user to different screens.
///
/// `null` when the notification is informational only, or carries no ref.
String? notificationTarget(String type, String? refId, {required bool teacher}) {
  if (refId == null || refId.isEmpty) return null;
  return switch (type) {
    'test_assigned' || 'test_due_soon' when !teacher => '/student/test/$refId',
    'test_graded' || 'test_failed' when !teacher => '/student/test/$refId/result',
    'test_assigned' || 'test_graded' when teacher => '/teacher/test/$refId',
    _ => null,
  };
}
