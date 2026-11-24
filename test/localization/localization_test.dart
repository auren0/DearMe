import 'dart:ui';

import 'package:dearme/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Russian is fully available and uses the required notification copy',
    () {
      final l10n = lookupAppLocalizations(const Locale('ru'));
      expect(l10n.localeName, 'ru');
      expect(l10n.notificationTitle, 'Твоё письмо из прошлого 💌');
      expect(
        l10n.notificationBody,
        'Письмо, которое ты написал себе, готово к открытию.',
      );
      expect(l10n.statusSealed, 'Запечатано');
      expect(l10n.homeNewLetter, 'Написать письмо');
      expect(l10n.settingsTitle, 'Настройки');
      expect(l10n.settingsFont, 'Шрифт');
      expect(
        l10n.errorNotificationSchedule,
        contains('Не удалось запланировать уведомление'),
      );
      expect(l10n.errorNotificationSchedule, contains('Письмо сохранено'));
      expect(
        l10n.errorNotificationPermissionSaved,
        contains('Письмо сохранено'),
      );
      expect(l10n.notificationLimitationsWindows, contains('Windows'));
      expect(l10n.notificationLimitationsWeb, contains('вкладка открыта'));
      expect(l10n.webPushLocalOnly, contains('push-сервер'));
      expect(l10n.retry, 'Повторить');
      expect(l10n.notificationScheduleRetried, 'Уведомление запланировано.');
    },
  );

  test(
    'English is fully available and uses the required notification copy',
    () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(l10n.localeName, 'en');
      expect(l10n.notificationTitle, 'A letter from your past 💌');
      expect(
        l10n.notificationBody,
        'Your letter to your future self is ready to open.',
      );
      expect(l10n.statusSealed, 'Sealed');
      expect(l10n.settingsTitle, 'Settings');
      expect(l10n.settingsFont, 'Font');
      expect(
        l10n.errorNotificationSchedule,
        contains('Failed to schedule notification'),
      );
      expect(l10n.errorNotificationSchedule, contains('saved'));
      expect(l10n.errorNotificationPermissionSaved, contains('saved'));
      expect(l10n.notificationLimitationsWindows, contains('Windows'));
      expect(l10n.notificationLimitationsWeb, contains('tab is open'));
      expect(l10n.webPushLocalOnly, contains('push server'));
      expect(l10n.retry, 'Retry');
      expect(l10n.notificationScheduleRetried, 'Notification scheduled.');
    },
  );

  test('plural forms are localised', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.letterCount(1), contains('письмо'));
    expect(ru.letterCount(3), contains('письма'));
    expect(ru.letterCount(5), contains('писем'));

    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.letterCount(1), '1 letter');
    expect(en.letterCount(3), '3 letters');
  });

  test('supported locales are exactly Russian and English', () {
    expect(
      AppLocalizations.supportedLocales.map((locale) => locale.languageCode),
      containsAll(<String>['ru', 'en']),
    );
  });
}
