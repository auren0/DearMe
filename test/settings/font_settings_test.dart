import 'package:dearme/app/providers.dart';
import 'package:dearme/app/theme/app_theme.dart';
import 'package:dearme/core/models/app_font_option.dart';
import 'package:dearme/core/models/app_locale_option.dart';
import 'package:dearme/core/models/app_settings.dart';
import 'package:dearme/core/models/app_theme_option.dart';
import 'package:dearme/features/settings/data/settings_repository.dart';
import 'package:dearme/features/settings/presentation/settings_screen.dart';
import 'package:dearme/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ru = lookupAppLocalizations(const Locale('ru'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('Google Sans is the default and unknown values fall back to it', () {
    expect(const AppSettings.defaults().font, AppFontOption.googleSans);
    expect(AppFontOption.fromStorage(null), AppFontOption.googleSans);
    expect(AppFontOption.fromStorage('missing'), AppFontOption.googleSans);
    expect(
      AppFontOption.fromStorage(AppFontOption.tiny5Duo.storageKey),
      AppFontOption.tiny5Duo,
    );
  });

  test('copyWith keeps the other settings intact', () {
    const original = AppSettings(
      theme: AppThemeOption.oled,
      locale: AppLocaleOption.english,
      notificationsEnabled: false,
      lastKnownTimeZone: 'Europe/Moscow',
    );
    final changed = original.copyWith(font: AppFontOption.shantellSans);

    expect(changed.font, AppFontOption.shantellSans);
    expect(changed.theme, original.theme);
    expect(changed.locale, original.locale);
    expect(changed.notificationsEnabled, original.notificationsEnabled);
    expect(changed.lastKnownTimeZone, original.lastKnownTimeZone);
  });

  test('the font survives a preferences restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = await SharedPreferencesSettingsRepository.create();
    const expected = AppSettings(
      theme: AppThemeOption.dark,
      locale: AppLocaleOption.russian,
      notificationsEnabled: true,
      font: AppFontOption.shantellSans,
    );
    await repository.save(expected);

    final restarted = await SharedPreferencesSettingsRepository.create();
    expect((await restarted.load()).font, AppFontOption.shantellSans);
  });

  test('every theme keeps every selected font', () {
    for (final theme in AppThemeOption.values) {
      for (final font in AppFontOption.values) {
        final data = AppTheme.of(theme, font: font);
        expect(data.textTheme.bodyMedium?.fontFamily, font.family);
        expect(data.textTheme.headlineSmall?.fontFamily, font.family);
        expect(data.brightness, theme.brightness);
      }
    }
  });

  test('the settings controller changes and persists the font', () async {
    final repository = InMemorySettingsRepository();
    final container = ProviderContainer(
      overrides: [
        initialSettingsProvider.overrideWithValue(const AppSettings.defaults()),
        settingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(settingsControllerProvider.notifier)
        .setFont(AppFontOption.tiny5Duo);

    expect(
      container.read(settingsControllerProvider).font,
      AppFontOption.tiny5Duo,
    );
    expect((await repository.load()).font, AppFontOption.tiny5Duo);
  });

  testWidgets('changing the font updates the whole theme immediately', (
    tester,
  ) async {
    final harness = await pumpTestApp(tester);
    await _tapVisible(tester, find.byTooltip(ru.a11yOpenSettings));
    expect(find.byType(SettingsScreen), findsOneWidget);

    await _tapVisible(tester, find.text(ru.fontTiny5Duo));

    final scaffold = tester.element(find.byType(Scaffold).first);
    expect(
      Theme.of(scaffold).textTheme.bodyMedium?.fontFamily,
      AppFontOption.tiny5Duo.family,
    );
    expect(
      Theme.of(scaffold).textTheme.headlineSmall?.fontFamily,
      AppFontOption.tiny5Duo.family,
    );
    expect(
      (await harness.settingsRepository.load()).font,
      AppFontOption.tiny5Duo,
    );

    await _tapVisible(tester, find.text(ru.fontGoogleSans));
    expect(
      Theme.of(scaffold).textTheme.bodyMedium?.fontFamily,
      AppFontOption.googleSans.family,
    );
    expect(
      (await harness.settingsRepository.load()).font,
      AppFontOption.googleSans,
    );
  });

  testWidgets('a font change is visible on the next frame', (tester) async {
    final harness = await pumpTestApp(tester);
    await _tapVisible(tester, find.byTooltip(ru.a11yOpenSettings));

    final tile = find.text(ru.fontTiny5Duo);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pump();

    final scaffold = tester.element(find.byType(Scaffold).first);
    expect(
      Theme.of(scaffold).textTheme.bodyMedium?.fontFamily,
      AppFontOption.tiny5Duo.family,
    );
    expect(
      (await harness.settingsRepository.load()).font,
      AppFontOption.tiny5Duo,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('the font setting is localized after a language change', (
    tester,
  ) async {
    await pumpTestApp(tester);
    await _tapVisible(tester, find.byTooltip(ru.a11yOpenSettings));
    await _tapVisible(tester, find.text(ru.languageEn));

    expect(find.text(en.settingsFont), findsOneWidget);
    expect(find.text(en.fontShantellSans), findsOneWidget);
    expect(find.text(en.fontTiny5Duo), findsOneWidget);
  });
}
