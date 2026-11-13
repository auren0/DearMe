import 'package:dearme/app/app.dart';
import 'package:dearme/app/providers.dart';
import 'package:dearme/core/models/app_settings.dart';
import 'package:dearme/core/models/letter.dart';
import 'package:dearme/features/settings/data/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fake_letter_repository.dart';
import 'fake_notification_service.dart';

class TestHarness {
  TestHarness({
    required this.container,
    required this.repository,
    required this.notifications,
    required this.settingsRepository,
  });

  final ProviderContainer container;
  final FakeLetterRepository repository;
  final FakeNotificationService notifications;
  final InMemorySettingsRepository settingsRepository;
}

Future<TestHarness> pumpTestApp(
  WidgetTester tester, {
  List<Letter> letters = const <Letter>[],
  AppSettings settings = const AppSettings.defaults(),
  DateTime? now,
  FakeNotificationService? notifications,
  bool settle = true,
}) async {
  await initializeDateFormatting();
  final fixedNow = now ?? DateTime.utc(2026, 6, 1, 12);
  final repository = FakeLetterRepository(letters);
  final settingsRepository = InMemorySettingsRepository(settings);
  final fakeNotifications = notifications ?? FakeNotificationService();
  final container = ProviderContainer(
    overrides: [
      letterRepositoryProvider.overrideWithValue(repository),
      notificationServiceProvider.overrideWithValue(fakeNotifications),
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      initialSettingsProvider.overrideWithValue(settings),
      clockProvider.overrideWithValue(() => fixedNow),
      tickingNowProvider.overrideWith(
        (ref) => Stream<DateTime>.value(fixedNow),
      ),
      packageInfoProvider.overrideWith(
        (ref) async => PackageInfo(
          appName: 'DearMe',
          packageName: 'dearme',
          version: '1.0.0',
          buildNumber: '1',
        ),
      ),
      storageAvailableProvider.overrideWithValue(true),
    ],
  );
  addTearDown(() {
    container.dispose();
    repository.dispose();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const DearMeApp()),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
  return TestHarness(
    container: container,
    repository: repository,
    notifications: fakeNotifications,
    settingsRepository: settingsRepository,
  );
}

Letter buildLetter({
  required DateTime now,
  String id = 'letter-1',
  String title = 'Hello future',
  String body = 'A private message from the past.',
  DateTime? openAt,
  DateTime? openedAt,
  bool isDraft = false,
  int notificationId = 42,
}) {
  return Letter(
    id: id,
    title: title,
    body: body,
    createdAt: now.subtract(const Duration(days: 10)),
    updatedAt: now.subtract(const Duration(days: 10)),
    openAt: openAt,
    openedAt: openedAt,
    notificationId: notificationId,
    isDraft: isDraft,
  );
}
