import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  static const String _channelPrefix = 'dearme_letters';
  static const String _legacyChannelId = 'dearme_letters';
  static const int _testNotificationId = 2147483000;
  static const int _maxIosPending = 60;

  final FlutterLocalNotificationsPlugin _plugin;
  final Map<int, Timer> _linuxTimers = <int, Timer>{};

  ValueChanged<String>? _onTap;
  NotificationAppLaunchDetails? _launchDetails;
  String? _launchPayload;
  bool _initialized = false;
  Future<void>? _initialization;
  bool _timeZonesInitialized = false;
  bool _legacyChannelRemoved = false;

  String _activeLocaleCode = 'ru';
  String _channelName = 'DearMe';
  String _channelDescription = '';

  String get _activeChannelId => '${_channelPrefix}_$_activeLocaleCode';

  @override
  NotificationPlatformInfo get platformInfo {
    final isLinux = !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;
    return NotificationPlatformInfo(
      isWeb: false,
      supportsNativeScheduling: !isLinux,
      requiresRunningApp: isLinux,
      // Windows opens its own Settings app; the plugin has no deep link there.
      supportsSystemSettings: !isLinux && !isWindows,
      // Windows and Linux have no in-app permission prompt.
      supportsPermissionRequest: !isLinux && !isWindows,
      supportsWebPush: false,
      webPushConfigured: false,
      platformName: defaultTargetPlatform.name,
    );
  }

  @override
  Future<void> initialize({
    required ValueChanged<String> onTap,
    VoidCallback? onSubscriptionChanged,
  }) {
    _onTap = onTap;
    if (_initialized) {
      return Future<void>.value();
    }

    final pending = _initialization;
    if (pending != null) {
      return pending;
    }

    final future = _initializeInternal().whenComplete(() {
      // A failed initialization must be retryable. Keeping a rejected future
      // cached would make every later schedule call fail with the same stale
      // error for the rest of the process lifetime.
      if (!_initialized) {
        _initialization = null;
      }
    });
    _initialization = future;
    return future;
  }

  Future<void> _initializeInternal() async {
    try {
      await _configureTimeZones();

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

      void handleResponse(NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onTap?.call(payload);
        }
      }

      if (defaultTargetPlatform == TargetPlatform.windows) {
        // The Windows implementation reports initialization success with a
        // bool. The cross-platform wrapper discards it, so resolve it directly
        // to avoid pretending that notifications are ready when they are not.
        final windows = _plugin
            .resolvePlatformSpecificImplementation<
              FlutterLocalNotificationsWindows
            >();
        final initialized =
            await windows?.initialize(
              settings: settings.windows!,
              onDidReceiveNotificationResponse: handleResponse,
            ) ??
            false;
        if (!initialized) {
          throw const NotificationException(
            'Windows notification initialization failed.',
            null,
            'Check the Windows AUMID, toast activator CLSID and notification '
                'settings.',
          );
        }
      } else {
        await _plugin.initialize(
          settings: settings,
          onDidReceiveNotificationResponse: handleResponse,
        );
      }

      try {
        _launchDetails = await _plugin.getNotificationAppLaunchDetails();
        if (_launchDetails?.didNotificationLaunchApp ?? false) {
          final payload = _launchDetails?.notificationResponse?.payload;
          if (payload != null && payload.isNotEmpty) {
            _launchPayload = payload;
          }
        }
      } on Object catch (error, stackTrace) {
        // Launch details are unavailable on some desktop configurations, but
        // this is worth recording because it also covers a broken plugin
        // registration.
        developer.log(
          'Could not read notification launch details.',
          name: 'dearme.notifications',
          error: error,
          stackTrace: stackTrace,
        );
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _removeLegacyAndroidChannel();
        developer.log(
          'Notification service initialized on Android '
          '(time zone: ${tz.local.name}, '
          'exact alarms: ${await _canScheduleExactAlarms()}).',
          name: 'dearme.notifications',
        );
      } else {
        developer.log(
          'Notification service initialized on '
          '${defaultTargetPlatform.name}.',
          name: 'dearme.notifications',
        );
      }

      _initialized = true;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Notification initialization failed on ${defaultTargetPlatform.name}.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _configureTimeZones() async {
    if (!_timeZonesInitialized) {
      tz_data.initializeTimeZones();
      _timeZonesInitialized = true;
    }

    try {
      final local = await FlutterTimezone.getLocalTimezone();
      final identifier = local.identifier;
      try {
        tz.setLocalLocation(tz.getLocation(identifier));
        developer.log(
          'Local time zone resolved to $identifier.',
          name: 'dearme.notifications',
        );
      } on Object catch (error, stackTrace) {
        // A missing or unusual time-zone identifier must not prevent the app
        // from starting. UTC scheduling still preserves the absolute instant.
        tz.setLocalLocation(tz.UTC);
        developer.log(
          'Unknown time zone "$identifier"; falling back to UTC.',
          name: 'dearme.notifications',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } on Object catch (error, stackTrace) {
      tz.setLocalLocation(tz.UTC);
      developer.log(
        'Could not read the device time zone; falling back to UTC.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Scheduling may be requested before the post-frame startup coordinator has
  /// finished initializing the plugin. Waiting (and retrying a failed
  /// initialization) removes that race instead of reporting a scheduling error.
  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    final pending = _initialization;
    if (pending != null) {
      try {
        await pending;
        return;
      } on Object {
        // The initialization that was already running failed. Fall through and
        // try once more; a transient platform error should not permanently
        // disable reminders for this process.
        if (_initialized) {
          return;
        }
      }
    }
    await initialize(onTap: _onTap ?? (_) {});
  }

  @override
  Future<NotificationPermissionStatus> permissionStatus() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _android;
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
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not query notification permission.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
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
        final android = _android;
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
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not request notification permission.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
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
    try {
      await _ensureInitialized();
    } on Object catch (error, stackTrace) {
      developer.log(
        'Notification initialization failed while preparing the schedule.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      throw NotificationException(
        'Notification service could not be initialized.',
        error,
        'Platform: ${defaultTargetPlatform.name}.',
      );
    }

    _activeLocaleCode = localeCode.isEmpty ? 'en' : localeCode;
    _channelName = channelName;
    _channelDescription = channelDescription;

    await cancelAllScheduled();
    try {
      await _ensureAndroidChannel();
    } on Object catch (error, stackTrace) {
      developer.log(
        'The Android notification channel could not be created.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      throw NotificationException(
        'The Android notification channel could not be created.',
        error,
        'Channel: $_activeChannelId, platform: ${defaultTargetPlatform.name}.',
      );
    }

    final now = DateTime.now().toUtc();
    final future =
        letters.where((letter) => letter.openAt.toUtc().isAfter(now)).toList()
          ..sort((a, b) => a.openAt.compareTo(b.openAt));

    // iOS keeps at most 64 pending notifications. Scheduling the closest 60
    // leaves room for the test notification and future app launches.
    final limited = defaultTargetPlatform == TargetPlatform.iOS
        ? future.take(_maxIosPending)
        : future;

    _ScheduleFailure? firstFailure;
    for (final letter in limited) {
      try {
        await _scheduleOne(letter: letter, title: title, body: body);
      } on Object catch (error, stackTrace) {
        firstFailure ??= _ScheduleFailure(letter: letter, error: error);
        developer.log(
          'Notification ${letter.notificationId} for letter '
          '"${letter.letterId}" could not be scheduled '
          '(opens ${letter.openAt.toUtc().toIso8601String()}).',
          name: 'dearme.notifications',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (firstFailure != null) {
      final failure = firstFailure;
      throw NotificationException(
        'Some notifications could not be scheduled.',
        failure.error,
        'First failure: letter ${failure.letter.letterId}, '
            'notification id ${failure.letter.notificationId}, '
            'opens ${failure.letter.openAt.toUtc().toIso8601String()}, '
            'time zone ${tz.local.name}, platform '
            '${defaultTargetPlatform.name}.',
      );
    }

    developer.log(
      'Scheduled ${limited.length} notification(s) '
      '(locale $_activeLocaleCode, channel $_activeChannelId).',
      name: 'dearme.notifications',
    );
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
          _plugin
              .show(
                id: letter.notificationId,
                title: title,
                body: body,
                notificationDetails: details,
                payload: payload,
              )
              .catchError((Object error, StackTrace stackTrace) {
                developer.log(
                  'Linux notification ${letter.notificationId} could not be '
                  'shown.',
                  name: 'dearme.notifications',
                  error: error,
                  stackTrace: stackTrace,
                );
              }),
        );
      });
      return;
    }

    final scheduledDate = tz.TZDateTime.from(letter.openAt.toUtc(), tz.local);
    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      // A letter may become openable while the loop is running. Skipping is
      // correct: the app already treats it as ready and there is nothing left
      // to remind the user about.
      developer.log(
        'Skipped notification ${letter.notificationId}: opening instant '
        '${letter.openAt.toUtc().toIso8601String()} is no longer in the future.',
        name: 'dearme.notifications',
      );
      return;
    }

    final scheduleMode = await _androidScheduleMode();
    try {
      await _plugin.zonedSchedule(
        id: letter.notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    } on PlatformException catch (error, stackTrace) {
      if (error.code == 'exact_alarms_not_permitted' &&
          scheduleMode != AndroidScheduleMode.inexactAllowWhileIdle) {
        // Android 12+ may block exact alarms even if the capability check
        // reported success (for example after the user revokes the permission
        // while the app is running). Falling back preserves the reminder; the
        // system may deliver it a little later.
        developer.log(
          'Exact alarms are not permitted; retrying notification '
          '${letter.notificationId} with an inexact alarm.',
          name: 'dearme.notifications',
          error: error,
          stackTrace: stackTrace,
        );
        await _plugin.zonedSchedule(
          id: letter.notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
        return;
      }
      developer.log(
        'Android rejected notification ${letter.notificationId} '
        '(code: ${error.code}, details: ${error.details}).',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on ArgumentError catch (error, stackTrace) {
      // The plugin validates the trigger again. If the chosen instant elapsed
      // while this loop was running there is nothing left to schedule.
      if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
        developer.log(
          'Notification ${letter.notificationId} became due before it could '
          'be scheduled; treating the letter as ready instead of failing.',
          name: 'dearme.notifications',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
      rethrow;
    }
  }

  /// Uses an exact alarm only when the OS already permits it. DearMe does not
  /// request the restricted `SCHEDULE_EXACT_ALARM` permission, so on most
  /// Android 12+ devices this returns an inexact mode. The UI explains that
  /// reminders can therefore arrive slightly late.
  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    if (await _canScheduleExactAlarms()) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<bool> _canScheduleExactAlarms() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not query exact-alarm capability.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  NotificationDetails _notificationDetails({
    required String title,
    required String body,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _activeChannelId,
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
    try {
      await _android?.createNotificationChannel(
        AndroidNotificationChannel(
          _activeChannelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          showBadge: true,
        ),
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not create the Android notification channel '
        '$_activeChannelId.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Older DearMe versions used a single, non-localized channel. Removing it
  /// once avoids a stale channel permanently showing the old language name.
  Future<void> _removeLegacyAndroidChannel() async {
    if (_legacyChannelRemoved ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _legacyChannelRemoved = true;
    try {
      await _android?.deleteNotificationChannel(channelId: _legacyChannelId);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not delete the legacy Android notification channel.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
    } on UnimplementedError catch (error, stackTrace) {
      developer.log(
        'Pending-notification cancellation is not implemented on this '
        'platform.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    } on UnsupportedError catch (error, stackTrace) {
      developer.log(
        'Pending-notification cancellation is unsupported on this platform.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    } on Object catch (error, stackTrace) {
      // Cancelling stale reminders must not break saving or deleting letters.
      // The next successful sync replaces the schedule.
      developer.log(
        'Could not cancel all pending notifications.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<bool> showTest({
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
    required String localeCode,
  }) async {
    _activeLocaleCode = localeCode.isEmpty ? 'en' : localeCode;
    _channelName = channelName;
    _channelDescription = channelDescription;
    try {
      await _ensureInitialized();
      final permission = await permissionStatus();
      if (!permission.isGranted) {
        return false;
      }
      await _ensureAndroidChannel();
      await _plugin.show(
        id: _testNotificationId,
        title: title,
        body: body,
        notificationDetails: _notificationDetails(title: title, body: body),
        payload: 'test',
      );
      return true;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not show the test notification.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> openSystemSettings() async {
    try {
      return await _plugin.openAppNotificationSettings() ?? false;
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not open the system notification settings.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
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

class _ScheduleFailure {
  const _ScheduleFailure({required this.letter, required this.error});

  final ScheduledLetter letter;
  final Object error;
}
