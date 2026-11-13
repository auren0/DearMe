import 'package:dearme/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.permission = NotificationPermissionStatus.granted,
    this.syncError,
    this.pushStatus = PushServerStatus.notApplicable,
    this.isWeb = false,
  });

  NotificationPermissionStatus permission;
  Object? syncError;
  PushServerStatus pushStatus;
  bool isWeb;

  ValueChanged<String>? onTap;
  VoidCallback? onSubscriptionChanged;
  String? launchPayload;
  bool initialized = false;
  int cancelAllCount = 0;
  int synchronizeCount = 0;
  int testNotificationCount = 0;
  bool testResult = true;
  List<ScheduledLetter> scheduled = <ScheduledLetter>[];
  String? lastLocaleCode;
  String? lastTitle;
  String? lastBody;
  String? lastChannelName;

  @override
  Future<void> initialize({
    required ValueChanged<String> onTap,
    VoidCallback? onSubscriptionChanged,
  }) async {
    initialized = true;
    this.onTap = onTap;
    this.onSubscriptionChanged = onSubscriptionChanged;
  }

  @override
  NotificationPlatformInfo get platformInfo => NotificationPlatformInfo(
    isWeb: isWeb,
    supportsNativeScheduling: !isWeb,
    requiresRunningApp: false,
    supportsSystemSettings: !isWeb,
    supportsWebPush: isWeb,
    webPushConfigured: isWeb,
    platformName: isWeb ? 'web' : 'test',
  );

  @override
  Future<NotificationPermissionStatus> permissionStatus() async => permission;

  @override
  Future<NotificationPermissionStatus> requestPermission() async => permission;

  @override
  Future<void> synchronize({
    required List<ScheduledLetter> letters,
    required String localeCode,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    synchronizeCount++;
    lastLocaleCode = localeCode;
    lastTitle = title;
    lastBody = body;
    lastChannelName = channelName;
    if (syncError != null) {
      throw syncError!;
    }
    scheduled = List<ScheduledLetter>.of(letters);
  }

  @override
  Future<void> cancelAllScheduled() async {
    cancelAllCount++;
    scheduled = <ScheduledLetter>[];
  }

  @override
  Future<bool> showTest({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    testNotificationCount++;
    return testResult;
  }

  @override
  Future<bool> openSystemSettings() async => true;

  @override
  Future<PushServerStatus> pushServerStatus() async => pushStatus;

  @override
  Future<String?> takeLaunchPayload() async {
    final value = launchPayload;
    launchPayload = null;
    return value;
  }

  @override
  Future<void> dispose() async {}
}
