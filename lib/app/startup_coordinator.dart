import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Initializes notifications, restores the launch deep link, and keeps the
/// schedule in sync across launches, time-zone changes and permission changes.
class StartupCoordinator {
  StartupCoordinator(this._ref);

  final Ref _ref;

  bool _started = false;
  bool _starting = false;

  Future<void> start({
    required void Function(String letterId) onOpenLetter,
  }) async {
    if (_started || _starting) {
      return;
    }
    _starting = true;
    final service = _ref.read(letterServiceProvider);

    try {
      await service.initializeNotifications(
        (payload) {
          final id = service.letterIdFromPayload(payload);
          if (id != null) {
            onOpenLetter(id);
          }
        },
        onSubscriptionChanged: () {
          // A browser rotated the push subscription. Re-register and replace
          // the server schedule while the tab is alive.
          unawaited(service.synchronizeSchedules());
        },
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'Notification initialization failed.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await _refreshTimeZone();
    await service.synchronizeSchedules();

    try {
      final launchPayload = await service.takeLaunchPayload();
      final id = service.letterIdFromPayload(launchPayload);
      if (id != null) {
        onOpenLetter(id);
      }
    } on Object catch (error, stackTrace) {
      developer.log(
        'Could not read a notification launch payload.',
        name: 'dearme.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _started = true;
    _starting = false;
  }

  Future<void> onResume() async {
    if (!_started) {
      return;
    }
    await _refreshTimeZone();
    final error = await _ref.read(letterServiceProvider).synchronizeSchedules();
    _ref.invalidate(notificationPermissionProvider);
    if (error != null) {
      developer.log(
        'Notification resync failed.',
        name: 'dearme.notifications',
        error: error,
      );
    }
  }

  Future<void> _refreshTimeZone() async {
    try {
      final identifier = await _ref
          .read(timeZoneServiceProvider)
          .currentIdentifier();
      final settings = _ref.read(settingsControllerProvider);
      if (settings.lastKnownTimeZone != identifier) {
        await _ref
            .read(settingsControllerProvider.notifier)
            .setLastKnownTimeZone(identifier);
      }
    } on Object catch (error) {
      developer.log(
        'Could not refresh the local time zone.',
        name: 'dearme.notifications',
        error: error,
      );
    }
  }
}
