import '../router/app_router.dart';

/// Routes the user to the screen that matches a notification row or FCM payload.
///
/// When [pushOntoStack] is true (in-app inbox), bin routes use [GoRouter.push]
/// so Back returns to the inbox. When false (opened from a push), [go] is used.
void navigateFromNotificationPayload({
  required String? type,
  String? binId,
  bool pushOntoStack = false,
}) {
  final r = AppRouter.router;
  final t = (type ?? '').trim();
  final b = (binId ?? '').trim();

  void binPath(String path) {
    if (pushOntoStack) {
      r.push(path);
    } else {
      r.go(path);
    }
  }

  switch (t) {
    case 'message':
      if (b.isNotEmpty) {
        binPath('/bin/$b/chat');
        return;
      }
      break;
    case 'join_request':
      if (b.isNotEmpty) {
        binPath('/bin/$b?manage=requests');
        return;
      }
      break;
    case 'activity':
    case 'bin_health':
      if (b.isNotEmpty) {
        binPath('/bin/$b');
        return;
      }
      break;
    case 'help_request':
    case 'task_completed':
    case 'task_accepted':
    case 'task_reverted':
      final refreshToken = DateTime.now().millisecondsSinceEpoch;
      r.go('/main?tab=tasks&refresh=$refreshToken');
      return;
  }
  r.go('/main');
}
