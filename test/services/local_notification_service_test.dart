import 'package:dearme/core/services/local_notification_service.dart';
import 'package:dearme/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

/// Minimal Android platform implementation used to exercise the real
/// LocalNotificationService scheduling path without a device.
class _FakeAndroidNotifications extends AndroidFlutterLocalNotificationsPlugin {
  int initializeCount = 0;
  int cancelAllCount = 0;
  bool canScheduleExact = false;
  bool failInitialize = false;
  bool throwWhenExact = false;

  final List<AndroidScheduleMode> scheduledModes = <AndroidScheduleMode>[];
  final List<int> scheduledIds = <int>[];
  final List<String> createdChannels = <String>[];

  @override
  Future<bool> initialize({
    required AndroidInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCount++;
    if (failInitialize) {
      throw PlatformException(
        code: 'plugin_initialization_failed',
        message: 'Simulated initialization failure',
      );
    }
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    return null;
  }

  @override
  Future<void> cancelAllPendingNotifications() async {
    cancelAllCount++;
  }

  @override
  Future<bool?> areNotificationsEnabled() async => true;

  @override
  Future<bool?> canScheduleExactNotifications() async => canScheduleExact;

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {
    createdChannels.add(notificationChannel.id);
  }

  @override
  Future<void> deleteNotificationChannel({required String channelId}) async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    AndroidNotificationDetails? notificationDetails,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exact,
  }) async {
    scheduledModes.add(scheduleMode);
    scheduledIds.add(id);
    if (throwWhenExact &&
        scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
      throw PlatformException(
        code: 'exact_alarms_not_permitted',
        message: 'Exact alarms are not permitted',
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAndroidNotifications fake;

  setUp(() {
    fake = _FakeAndroidNotifications();
    FlutterLocalNotificationsPlatform.instance = fake;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  ScheduledLetter buildLetter() {
    return ScheduledLetter(
      letterId: 'letter-1',
      notificationId: 42,
      openAt: DateTime.now().toUtc().add(const Duration(days: 2)),
    );
  }

  Future<void> synchronizeWith(LocalNotificationService service) {
    return service.synchronize(
      letters: <ScheduledLetter>[buildLetter()],
      localeCode: 'en',
      title: 'A letter from your past',
      body: 'Your letter is ready to open.',
      channelName: 'DearMe letters',
      channelDescription: 'Reminders when letters open',
    );
  }

  test(
    'scheduling before explicit initialization waits and uses inexact alarms',
    () async {
      final service = LocalNotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
      );
      addTearDown(service.dispose);

      // Deliberately do not call initialize() first: this is the cold-start
      // race that used to surface as "Failed to schedule notification".
      await synchronizeWith(service);

      expect(fake.initializeCount, 1);
      expect(fake.cancelAllCount, 1);
      expect(fake.createdChannels, contains('dearme_letters_en'));
      expect(fake.scheduledIds, <int>[42]);
      expect(fake.scheduledModes, <AndroidScheduleMode>[
        AndroidScheduleMode.inexactAllowWhileIdle,
      ]);
    },
  );

  test('exact-alarm rejection falls back to an inexact alarm', () async {
    fake.canScheduleExact = true;
    fake.throwWhenExact = true;
    final service = LocalNotificationService(
      plugin: FlutterLocalNotificationsPlugin(),
    );
    addTearDown(service.dispose);

    await synchronizeWith(service);

    expect(fake.scheduledModes, <AndroidScheduleMode>[
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]);
  });

  test(
    'an initialization failure is reported as a NotificationException',
    () async {
      fake.failInitialize = true;
      final service = LocalNotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
      );
      addTearDown(service.dispose);

      await expectLater(
        synchronizeWith(service),
        throwsA(
          isA<NotificationException>().having(
            (error) => error.technicalDetails,
            'technicalDetails',
            contains('android'),
          ),
        ),
      );
      expect(fake.scheduledIds, isEmpty);
    },
  );

  test(
    'Windows advertises no runtime permission prompt or settings deeplink',
    () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final service = LocalNotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
      );

      expect(service.platformInfo.supportsPermissionRequest, isFalse);
      expect(service.platformInfo.supportsSystemSettings, isFalse);
    },
  );
}
