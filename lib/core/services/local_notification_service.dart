import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

/// Native notification implementation for Android, iOS, macOS, Windows and
/// Linux.
///
/// Android, iOS, macOS and Windows use the OS scheduler, so delivery works when
/// the Dart process is closed. Linux has no scheduler API in the desktop
/// notification specification; for that platform DearMe keeps a timer while the
/// app is running and shows a real system notification when it fires. The
/// limitation is surfaced in Settings.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'dearme_letters';
  static const int _testNotificationId = 2147483000;
  static const int _maxIosPending = 60;

  final FlutterLocalNotificationsPlugin _plugin;
  final Map<int, Timer> _linuxTimers = <int, Timer>{};

  ValueChanged<String>? _onTap;
  NotificationAppLaunchDetails? _launchDetails;
  String? _launchPayload;
  bool _initialized = false;
  String _channelName = 'DearMe';
  String _channelDescription = '';

  @override
  NotificationPlatformInfo get platformInfo {
    final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    return NotificationPlatformInfo(
      isWeb: false,
      supportsNativeScheduling: !isLinux,
      requiresRunningApp: isLinux,
      supportsSystemSettings: !isLinux,
      supportsWebPush: false,
      webPushConfigured: false,
      platformName: defaultTargetPlatform.name,
    );
  }

  @override
  Future<void> initialize({
    required ValueChanged<String> onTap,
    VoidCallback? onSubscriptionChanged,
  }) async {
    if (_initialized) {
      _onTap = onTap;
      return;
    }
    _onTap = onTap;

    try {
      tz_data.initializeTimeZones();
      try {
        final local = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(local.identifier));
      } on Object {
        // A missing or unusual time zone identifier must not prevent the app
        // from starting. UTC scheduling still preserves the absolute instant.
        tz.setLocalLocation(tz.UTC);
      }
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('ic_stat_dearme'),
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: const LinuxInitializationSettings(defaultActionName: 'DearMe'),
      windows: const WindowsInitializationSettings(
        appName: 'DearMe',
        appUserModelId: 'DearMe.App',
        guid: 'f7d9a3c2-6c1e-4d7a-9f2b-8e4a1c5b7d30',
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onTap?.call(payload);
        }
      },
    );

    try {
      _launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (_launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = _launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          _launchPayload = payload;
        }
      }
    } on Object {
      // Launch details are unavailable on some desktop configurations.
    }

    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final enabled = await android?.areNotificationsEnabled();
        if (enabled == null) {
          return NotificationPermissionStatus.notDetermined;
        }
        return enabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final options = await ios?.checkPermissions();
        return _mapDarwinOptions(options?.isEnabled);
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macos = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final options = await macos?.checkPermissions();
        return _mapDarwinOptions(options?.isEnabled);
      }
      // Windows and Linux have no cross-platform permission query. Their
      // system notification servers accept notifications when available.
      return NotificationPermissionStatus.granted;
    } on Object {
      return NotificationPermissionStatus.unsupported;
    }
  }

  NotificationPermissionStatus _mapDarwinOptions(bool? enabled) {
    if (enabled == null) {
      return NotificationPermissionStatus.notDetermined;
    }
    return enabled
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        return (granted ?? false)
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await ios?.requestPermissions(alert: true, sound: true);
        return (granted ?? false)
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macos = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final granted = await macos?.requestPermissions(
          alert: true,
          sound: true,
        );
        return (granted ?? false)
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
      return NotificationPermissionStatus.granted;
    } on Object {
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<void> synchronize({
    required List<ScheduledLetter> letters,
    required String localeCode,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    if (!_initialized) {
      throw const NotificationException(
        'Notification service is not initialized.',
      );
    }

    _channelName = channelName;
    _channelDescription = channelDescription;

    await cancelAllScheduled();
    await _ensureAndroidChannel();

    final now = DateTime.now().toUtc();
    final future =
        letters.where((letter) => letter.openAt.toUtc().isAfter(now)).toList()
          ..sort((a, b) => a.openAt.compareTo(b.openAt));

    // iOS keeps at most 64 pending notifications. Scheduling the closest 60
    // leaves room for the test notification and future app launches.
    final limited = defaultTargetPlatform == TargetPlatform.iOS
        ? future.take(_maxIosPending)
        : future;

    Object? firstError;
    for (final letter in limited) {
      try {
        await _scheduleOne(letter: letter, title: title, body: body);
      } on Object catch (error) {
        firstError ??= error;
      }
    }

    if (firstError != null) {
      throw NotificationException(
        'Some notifications could not be scheduled.',
        firstError,
      );
    }
  }

  Future<void> _scheduleOne({
    required ScheduledLetter letter,
    required String title,
    required String body,
  }) async {
    final payload = 'letter:${letter.letterId}';
    final details = _notificationDetails(title: title, body: body);

    if (defaultTargetPlatform == TargetPlatform.linux) {
      _linuxTimers.remove(letter.notificationId)?.cancel();
      final delay = letter.openAt.toUtc().difference(DateTime.now().toUtc());
      if (delay.isNegative) {
        return;
      }
      _linuxTimers[letter.notificationId] = Timer(delay, () {
        _linuxTimers.remove(letter.notificationId);
        // A system notification is shown, not an in-app banner. Delivery while
        // the app is closed is not possible on Linux; Settings explains this.
        unawaited(
          _plugin.show(
            id: letter.notificationId,
            title: title,
            body: body,
            notificationDetails: details,
            payload: payload,
          ),
        );
      });
      return;
    }

    await _plugin.zonedSchedule(
      id: letter.notificationId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(letter.openAt.toUtc(), tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  NotificationDetails _notificationDetails({
    required String title,
    required String body,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.email,
        styleInformation: BigTextStyleInformation(body),
        ticker: title,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
        presentBanner: true,
        presentList: true,
        interruptionLevel: InterruptionLevel.active,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: false,
        presentBanner: true,
        presentList: true,
      ),
      linux: const LinuxNotificationDetails(
        category: LinuxNotificationCategory.email,
        urgency: LinuxNotificationUrgency.normal,
      ),
      windows: const WindowsNotificationDetails(
        duration: WindowsNotificationDuration.long,
      ),
    );
  }

  Future<void> _ensureAndroidChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        showBadge: true,
      ),
    );
  }

  @override
  Future<void> cancelAllScheduled() async {
    for (final timer in _linuxTimers.values) {
      timer.cancel();
    }
    _linuxTimers.clear();

    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        // Windows' cancelAllPendingNotifications is not implemented by the
        // plugin. Cancelling the known pending IDs is reliable for scheduled
        // toasts created by this app.
        final pending = await _plugin.pendingNotificationRequests();
        for (final request in pending) {
          await _plugin.cancel(id: request.id);
        }
      } else if (defaultTargetPlatform != TargetPlatform.linux) {
        await _plugin.cancelAllPendingNotifications();
      }
    } on UnimplementedError {
      // The platform has no pending-notification API (Linux).
    } on UnsupportedError {
      // Same as above, depending on the plugin version.
    }
  }

  @override
  Future<bool> showTest({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    _channelName = channelName;
    _channelDescription = channelDescription;
    final permission = await permissionStatus();
    if (!permission.isGranted) {
      return false;
    }
    try {
      await _ensureAndroidChannel();
      await _plugin.show(
        id: _testNotificationId,
        title: title,
        body: body,
        notificationDetails: _notificationDetails(title: title, body: body),
        payload: 'test',
      );
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openSystemSettings() async {
    try {
      return await _plugin.openAppNotificationSettings() ?? false;
    } on Object {
      return false;
    }
  }

  @override
  Future<PushServerStatus> pushServerStatus() async =>
      PushServerStatus.notApplicable;

  @override
  Future<String?> takeLaunchPayload() async {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  @override
  Future<void> dispose() async {
    for (final timer in _linuxTimers.values) {
      timer.cancel();
    }
    _linuxTimers.clear();
    _onTap = null;
  }
}
