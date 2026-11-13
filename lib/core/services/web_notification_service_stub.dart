import 'notification_service.dart';

/// Native builds never construct the web implementation; this stub exists so
/// that conditional imports stay analyzable on every platform.
NotificationService createWebNotificationService() {
  return const UnsupportedNotificationService();
}
