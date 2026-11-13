import 'package:flutter/foundation.dart';

enum NotificationPermissionStatus {
  granted,
  denied,
  notDetermined,
  unsupported;

  bool get isGranted => this == NotificationPermissionStatus.granted;
}

enum PushServerStatus { notApplicable, notConfigured, connected, unreachable }

/// What the current platform can actually do. The UI uses this to explain
/// limitations instead of promising behaviour the OS cannot deliver.
@immutable
class NotificationPlatformInfo {
  const NotificationPlatformInfo({
    required this.isWeb,
    required this.supportsNativeScheduling,
    required this.requiresRunningApp,
    required this.supportsSystemSettings,
    required this.supportsWebPush,
    required this.webPushConfigured,
    required this.platformName,
  });

  final bool isWeb;
  final bool supportsNativeScheduling;
  final bool requiresRunningApp;
  final bool supportsSystemSettings;
  final bool supportsWebPush;
  final bool webPushConfigured;
  final String platformName;
}

/// A sealed letter that should produce a notification when it opens.
@immutable
class ScheduledLetter {
  const ScheduledLetter({
    required this.letterId,
    required this.notificationId,
    required this.openAt,
  });

  final String letterId;
  final int notificationId;
  final DateTime openAt;
}

class NotificationException implements Exception {
  const NotificationException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'NotificationException: $message';
}

/// Platform-agnostic notification contract.
///
/// Implementations must never expose letter contents to a remote server. The
/// web implementation only sends ids, delivery instants and locale information.
abstract interface class NotificationService {
  Future<void> initialize({
    required ValueChanged<String> onTap,
    VoidCallback? onSubscriptionChanged,
  });

  NotificationPlatformInfo get platformInfo;

  Future<NotificationPermissionStatus> permissionStatus();

  Future<NotificationPermissionStatus> requestPermission();

  /// Replaces the entire pending schedule. This makes edits, deletions and
  /// locale changes deterministic and prevents duplicate notifications.
  Future<void> synchronize({
    required List<ScheduledLetter> letters,
    required String localeCode,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });

  Future<void> cancelAllScheduled();

  Future<bool> showTest({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  });

  Future<bool> openSystemSettings();

  Future<PushServerStatus> pushServerStatus();

  /// Returns a payload once if the application was launched from a
  /// notification. Subsequent calls return null.
  Future<String?> takeLaunchPayload();

  Future<void> dispose();
}

/// Safe fallback used only when a feature is genuinely unavailable.
class UnsupportedNotificationService implements NotificationService {
  const UnsupportedNotificationService();

  @override
  Future<void> initialize({
    required ValueChanged<String> onTap,
    VoidCallback? onSubscriptionChanged,
  }) async {}

  @override
  NotificationPlatformInfo get platformInfo => const NotificationPlatformInfo(
    isWeb: false,
    supportsNativeScheduling: false,
    requiresRunningApp: false,
    supportsSystemSettings: false,
    supportsWebPush: false,
    webPushConfigured: false,
    platformName: 'unsupported',
  );

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.unsupported;

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.unsupported;

  @override
  Future<void> synchronize({
    required List<ScheduledLetter> letters,
    required String localeCode,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<void> cancelAllScheduled() async {}

  @override
  Future<bool> showTest({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async => false;

  @override
  Future<bool> openSystemSettings() async => false;

  @override
  Future<PushServerStatus> pushServerStatus() async =>
      PushServerStatus.notApplicable;

  @override
  Future<String?> takeLaunchPayload() async => null;

  @override
  Future<void> dispose() async {}
}
