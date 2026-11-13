import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/database/app_database.dart';
import '../core/models/app_locale_option.dart';
import '../core/models/app_settings.dart';
import '../core/models/app_theme_option.dart';
import '../core/models/letter.dart';
import '../core/models/letter_status.dart';
import '../core/services/notification_service.dart';
import '../core/services/notification_service_factory.dart';
import '../core/services/time_zone_service.dart';
import '../features/letters/application/letter_service.dart';
import '../features/letters/data/letter_transfer_service.dart';
import '../features/letters/data/sembast_letter_repository.dart';
import '../features/settings/data/settings_repository.dart';
import 'startup_coordinator.dart';

/// Overridden in `main()` with the opened database.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden.');
});

final letterRepositoryProvider = Provider<LetterRepository>((ref) {
  return SembastLetterRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be overridden.');
});

/// False when the persistent database could not be opened and the app fell
/// back to in-memory storage. The home screen shows an honest warning.
final storageAvailableProvider = Provider<bool>((ref) => true);

/// Loaded before `runApp` so the first frame already has the right theme and
/// locale (no flash of the wrong language or a white screen).
final initialSettingsProvider = Provider<AppSettings>((ref) {
  return const AppSettings.defaults();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = createNotificationService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final clockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});

final timeZoneServiceProvider = Provider<TimeZoneService>((ref) {
  return const TimeZoneService();
});

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final letterServiceProvider = Provider<LetterService>((ref) {
  return LetterService(
    ref.watch(letterRepositoryProvider),
    ref.watch(notificationServiceProvider),
    () => ref.read(settingsControllerProvider),
    ref.watch(clockProvider),
  );
});

final lettersControllerProvider =
    AsyncNotifierProvider<LettersController, List<Letter>>(
      LettersController.new,
    );

final transferFileGatewayProvider = Provider<TransferFileGateway>((ref) {
  return const FilePickerTransferGateway();
});

final letterTransferServiceProvider = Provider<LetterTransferService>((ref) {
  return LetterTransferService(ref.watch(transferFileGatewayProvider));
});

/// A shared 20-second tick so every countdown updates without creating one
/// timer per card.
final tickingNowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream<DateTime>.periodic(const Duration(seconds: 20), (_) => clock());
});

final startupCoordinatorProvider = Provider<StartupCoordinator>((ref) {
  return StartupCoordinator(ref);
});

final notificationPermissionProvider =
    FutureProvider<NotificationPermissionStatus>((ref) async {
      final status = await ref.watch(letterServiceProvider).permissionStatus();
      final requested = ref
          .watch(settingsControllerProvider)
          .notificationPermissionRequested;
      if (!requested && status == NotificationPermissionStatus.denied) {
        // Android cannot distinguish "never asked" from "blocked"; use the
        // persisted request flag to avoid a misleading label.
        return NotificationPermissionStatus.notDetermined;
      }
      return status;
    });

final pushServerStatusProvider = FutureProvider<PushServerStatus>((ref) {
  return ref.watch(letterServiceProvider).pushServerStatus();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final letterByIdProvider = Provider.family<AsyncValue<Letter?>, String>((
  ref,
  id,
) {
  final letters = ref.watch(lettersControllerProvider);
  return letters.whenData((items) {
    for (final letter in items) {
      if (letter.id == id) {
        return letter;
      }
    }
    return null;
  });
});

class LetterStatistics {
  const LetterStatistics({
    required this.total,
    required this.sealed,
    required this.ready,
    required this.opened,
    required this.drafts,
  });

  final int total;
  final int sealed;
  final int ready;
  final int opened;
  final int drafts;
}

final letterStatisticsProvider = Provider<LetterStatistics>((ref) {
  final letters = ref.watch(lettersControllerProvider).value ?? const [];
  final clock = ref.watch(clockProvider);
  final tick = ref.watch(tickingNowProvider).value;
  final now = tick ?? clock();

  var sealed = 0;
  var ready = 0;
  var opened = 0;
  var drafts = 0;
  for (final letter in letters) {
    switch (letter.statusAt(now)) {
      case LetterStatus.sealed:
        sealed++;
      case LetterStatus.ready:
        ready++;
      case LetterStatus.opened:
        opened++;
      case LetterStatus.draft:
        drafts++;
    }
  }

  return LetterStatistics(
    total: letters.length,
    sealed: sealed,
    ready: ready,
    opened: opened,
    drafts: drafts,
  );
});

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.watch(initialSettingsProvider);
  }

  Future<void> setTheme(AppThemeOption theme) async {
    await _persist(state.copyWith(theme: theme));
  }

  Future<void> setLocale(AppLocaleOption locale) async {
    await _persist(state.copyWith(locale: locale));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _persist(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setNotificationPermissionRequested(bool requested) async {
    await _persist(state.copyWith(notificationPermissionRequested: requested));
  }

  Future<void> setLastKnownTimeZone(String? identifier) async {
    await _persist(state.copyWith(lastKnownTimeZone: identifier));
  }

  Future<void> resetToDefaults() async {
    await _persist(const AppSettings.defaults());
  }

  Future<void> _persist(AppSettings next) async {
    final previous = state;
    state = next;
    try {
      await ref.read(settingsRepositoryProvider).save(next);
    } on Object {
      // Restore the old UI state so it never lies about what was persisted.
      state = previous;
      rethrow;
    }
  }
}

class LettersController extends AsyncNotifier<List<Letter>> {
  LetterService get _service => ref.read(letterServiceProvider);
  LetterRepository get _repository => ref.read(letterRepositoryProvider);

  @override
  Future<List<Letter>> build() async {
    final repository = ref.watch(letterRepositoryProvider);
    final subscription = repository.watchAll().listen(
      (letters) {
        state = AsyncData(letters);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
    ref.onDispose(() {
      unawaited(subscription.cancel());
    });
    return repository.getAll();
  }

  Future<Letter> saveDraft(Letter letter) async {
    final result = await _service.saveDraft(letter);
    await _refresh();
    return result.letter;
  }

  Future<LetterSaveResult> seal({
    required Letter letter,
    required DateTime openAt,
  }) async {
    final now = ref.read(clockProvider)();
    if (!openAt.toUtc().isAfter(now)) {
      throw ArgumentError.value(openAt, 'openAt', 'Must be in the future.');
    }
    final result = await _service.seal(letter: letter, openAt: openAt);
    await _refresh();
    return result;
  }

  Future<LetterSaveResult> updateSealed({
    required Letter letter,
    required String title,
    required String body,
    required DateTime openAt,
  }) async {
    final now = ref.read(clockProvider)();
    if (!openAt.toUtc().isAfter(now)) {
      throw ArgumentError.value(openAt, 'openAt', 'Must be in the future.');
    }
    final result = await _service.updateSealed(
      letter: letter,
      title: title,
      body: body,
      openAt: openAt,
    );
    await _refresh();
    return result;
  }

  Future<LetterSaveResult> markOpened(Letter letter) async {
    final result = await _service.markOpened(letter);
    await _refresh();
    return result;
  }

  Future<LetterDeleteResult> deleteLetter(Letter letter) async {
    final result = await _service.delete(letter);
    await _refresh();
    return result;
  }

  Future<LetterDeleteResult> deleteAllLetters() async {
    final result = await _service.deleteAll();
    await _refresh();
    return result;
  }

  Future<ImportSummary> importLetters(List<Letter> letters) async {
    final summary = await _service.importLetters(letters);
    await _refresh();
    return summary;
  }

  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    final letters = await _repository.getAll();
    state = AsyncData(letters);
  }
}
