import 'package:flutter/foundation.dart';

import 'local_notification_service.dart';
import 'notification_service.dart';
import 'web_notification_service_stub.dart'
    if (dart.library.js_interop) 'web_notification_service_web.dart'
    as web;

/// Chooses the notification transport for the current platform.
///
/// There is deliberately no single-plugin assumption: native platforms use
/// OS scheduling, while web uses a real Web Push subscription and a service
/// worker delivered by the DearMe backend.
NotificationService createNotificationService() {
  if (kIsWeb) {
    return web.createWebNotificationService();
  }
  return LocalNotificationService();
}
