import 'package:dearme/core/models/app_locale_option.dart';
import 'package:dearme/core/models/app_settings.dart';
import 'package:dearme/core/models/app_theme_option.dart';
import 'package:dearme/core/models/letter.dart';
import 'package:dearme/core/services/notification_service.dart';
import 'package:dearme/features/letters/application/letter_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_letter_repository.dart';
import '../support/fake_notification_service.dart';

void main() {
  final now = DateTime.utc(2026, 6, 1, 12);

  LetterService buildService({
    required FakeLetterRepository repository,
    required FakeNotificationService notifications,
    AppSettings settings = const AppSettings.defaults(),
  }) {
    return LetterService(repository, notifications, () => settings, () => now);
  }

  group('drafts and sealing', () {
    test('saving a draft does not touch the notification schedule', () async {
      final repository = FakeLetterRepository();
      final notifications = FakeNotificationService();
      final service = buildService(
        repository: repository,
        notifications: notifications,
      );
      final draft = Letter.create(now: now, title: 'Draft', body: 'Body');

      final result = await service.saveDraft(draft);

      expect(result.letter.isDraft, isTrue);
      expect(notifications.synchronizeCount, 0);
      expect(notifications.cancelAllCount, 0);
      expect((await repository.getAll()).single.id, draft.id);
    });

    test(
      'sealing persists the letter and schedules exactly one future alert',
      () async {
        final draft = Letter.create(now: now, title: 'Draft', body: 'Body');
        final openAt = now.add(const Duration(days: 10));
        final repository = FakeLetterRepository(<Letter>[draft]);
        final notifications = FakeNotificationService();
        final service = buildService(
          repository: repository,
          notifications: notifications,
        );

        final result = await service.seal(letter: draft, openAt: openAt);

        expect(result.letter.isDraft, isFalse);
        expect(result.letter.openAt, openAt);
        expect(result.notificationError, isNull);
        expect(notifications.scheduled.length, 1);
        expect(notifications.scheduled.single.letterId, draft.id);
        expect(notifications.scheduled.single.openAt, openAt);
        expect(notifications.lastTitle, contains('письмо из прошлого'));
        expect((await repository.getAll()).single.isDraft, isFalse);
      },
    );

    test('sealing in the past is rejected without writing', () async {
      final draft = Letter.create(now: now, title: 'Draft', body: 'Body');
      final repository = FakeLetterRepository(<Letter>[draft]);
      final service = buildService(
        repository: repository,
        notifications: FakeNotificationService(),
      );

      await expectLater(
        service.seal(
          letter: draft,
          openAt: now.subtract(const Duration(minutes: 1)),
        ),
        throwsArgumentError,
      );
      expect((await repository.getAll()).single.isDraft, isTrue);
    });

    test('past and already opened letters are not scheduled', () async {
      final ready = Letter.create(
        now: now.subtract(const Duration(days: 3)),
        title: 'Ready',
        body: 'Body',
        openAt: now.subtract(const Duration(days: 1)),
        isDraft: false,
      );
      final opened = Letter.create(
        now: now.subtract(const Duration(days: 5)),
        title: 'Opened',
        body: 'Body',
        openAt: now.subtract(const Duration(days: 4)),
        isDraft: false,
      ).copyWith(openedAt: now.subtract(const Duration(days: 4)));
      final future = Letter.create(
        now: now,
        title: 'Future',
        body: 'Body',
        openAt: now.add(const Duration(days: 2)),
        isDraft: false,
      );

      final repository = FakeLetterRepository(<Letter>[ready, opened, future]);
      final notifications = FakeNotificationService();
      final service = buildService(
        repository: repository,
        notifications: notifications,
      );

      final error = await service.synchronizeSchedules();

      expect(error, isNull);
      expect(notifications.scheduled.length, 1);
      expect(notifications.scheduled.single.letterId, future.id);
    });
  });

  group('opening and deleting', () {
    test('opening is blocked while the letter is sealed', () async {
      final sealed = Letter.create(
        now: now,
        title: 'Sealed',
        body: 'Secret body',
        openAt: now.add(const Duration(days: 1)),
        isDraft: false,
      );
      final repository = FakeLetterRepository(<Letter>[sealed]);
      final service = buildService(
        repository: repository,
        notifications: FakeNotificationService(),
      );

      await expectLater(service.markOpened(sealed), throwsA(isA<StateError>()));
      expect((await repository.getAll()).single.openedAt, isNull);
    });

    test(
      'opening after the date stores openedAt and cancels pending alerts',
      () async {
        final ready = Letter.create(
          now: now.subtract(const Duration(days: 4)),
          title: 'Ready',
          body: 'Body',
          openAt: now.subtract(const Duration(days: 2)),
          isDraft: false,
        );
        final repository = FakeLetterRepository(<Letter>[ready]);
        final notifications = FakeNotificationService();
        final service = buildService(
          repository: repository,
          notifications: notifications,
        );

        final result = await service.markOpened(ready);

        expect(result.letter.openedAt, now);
        expect((await repository.getAll()).single.openedAt, now);
        expect(notifications.scheduled, isEmpty);
      },
    );

    test('deleting a letter removes it and its pending notification', () async {
      final future = Letter.create(
        now: now,
        title: 'Future',
        body: 'Body',
        openAt: now.add(const Duration(days: 5)),
        isDraft: false,
      );
      final repository = FakeLetterRepository(<Letter>[future]);
      final notifications = FakeNotificationService();
      final service = buildService(
        repository: repository,
        notifications: notifications,
      );

      await service.delete(future);

      expect(await repository.getAll(), isEmpty);
      expect(notifications.scheduled, isEmpty);
      expect(notifications.cancelAllCount, greaterThan(0));
    });

    test(
      'rescheduling a sealed letter changes the notification time',
      () async {
        final sealed = Letter.create(
          now: now,
          title: 'Sealed',
          body: 'Body',
          openAt: now.add(const Duration(days: 3)),
          isDraft: false,
        );
        final newDate = now.add(const Duration(days: 20));
        final repository = FakeLetterRepository(<Letter>[sealed]);
        final notifications = FakeNotificationService();
        final service = buildService(
          repository: repository,
          notifications: notifications,
        );

        await service.updateSealed(
          letter: sealed,
          title: sealed.title,
          body: sealed.body,
          openAt: newDate,
        );

        expect(notifications.scheduled.single.openAt, newDate);
        expect((await repository.getAll()).single.openAt, newDate);
      },
    );
  });

  group('permissions, locale and failures', () {
    test(
      'denied permission cancels the schedule but keeps the letter',
      () async {
        final draft = Letter.create(now: now, title: 'Draft', body: 'Body');
        final repository = FakeLetterRepository(<Letter>[draft]);
        final notifications = FakeNotificationService(
          permission: NotificationPermissionStatus.denied,
        );
        final service = buildService(
          repository: repository,
          notifications: notifications,
        );

        final result = await service.seal(
          letter: draft,
          openAt: now.add(const Duration(days: 2)),
        );

        expect(result.letter.isDraft, isFalse);
        expect(notifications.scheduled, isEmpty);
        expect(notifications.cancelAllCount, greaterThan(0));
        expect((await repository.getAll()).single.isDraft, isFalse);
      },
    );

    test('disabled notifications cancel the schedule', () async {
      final future = Letter.create(
        now: now,
        title: 'Future',
        body: 'Body',
        openAt: now.add(const Duration(days: 5)),
        isDraft: false,
      );
      final repository = FakeLetterRepository(<Letter>[future]);
      final notifications = FakeNotificationService();
      final service = buildService(
        repository: repository,
        notifications: notifications,
        settings: const AppSettings(
          theme: AppThemeOption.dark,
          locale: AppLocaleOption.russian,
          notificationsEnabled: false,
        ),
      );

      await service.synchronizeSchedules();
      expect(notifications.scheduled, isEmpty);
      expect(notifications.cancelAllCount, greaterThan(0));
    });

    test('localizes notification copy after a language change', () async {
      final draft = Letter.create(now: now, title: 'Draft', body: 'Body');
      final repository = FakeLetterRepository(<Letter>[draft]);
      final notifications = FakeNotificationService();
      final service = buildService(
        repository: repository,
        notifications: notifications,
        settings: const AppSettings(
          theme: AppThemeOption.dark,
          locale: AppLocaleOption.english,
          notificationsEnabled: true,
        ),
      );

      await service.seal(
        letter: draft,
        openAt: now.add(const Duration(days: 1)),
      );

      expect(notifications.lastLocaleCode, 'en');
      expect(notifications.lastTitle, 'A letter from your past 💌');
    });

    test(
      'a notification failure is reported but does not lose the letter',
      () async {
        final draft = Letter.create(now: now, title: 'Draft', body: 'Body');
        final repository = FakeLetterRepository(<Letter>[draft]);
        final notifications = FakeNotificationService(
          syncError: const NotificationException('scheduler failed'),
        );
        final service = buildService(
          repository: repository,
          notifications: notifications,
        );

        final result = await service.seal(
          letter: draft,
          openAt: now.add(const Duration(days: 2)),
        );

        expect(result.letter.isDraft, isFalse);
        expect(result.notificationError, isA<NotificationException>());
        expect((await repository.getAll()).single.isDraft, isFalse);
      },
    );

    test('a storage failure propagates and leaves no false success', () async {
      final draft = Letter.create(now: now, title: 'Draft', body: 'Body');
      final repository = FakeLetterRepository(<Letter>[draft])
        ..failWrites = true;
      final service = buildService(
        repository: repository,
        notifications: FakeNotificationService(),
      );

      await expectLater(
        service.seal(letter: draft, openAt: now.add(const Duration(days: 2))),
        throwsStateError,
      );
    });
  });

  test('notification payload parsing accepts only letter links', () {
    final service = buildService(
      repository: FakeLetterRepository(),
      notifications: FakeNotificationService(),
    );
    expect(service.letterIdFromPayload('letter:abc-123'), 'abc-123');
    expect(service.letterIdFromPayload('test'), isNull);
    expect(service.letterIdFromPayload(null), isNull);
    expect(service.letterIdFromPayload('letter:'), isNull);
  });
}
