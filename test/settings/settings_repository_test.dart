import 'package:dearme/core/models/app_locale_option.dart';
import 'package:dearme/core/models/app_settings.dart';
import 'package:dearme/core/models/app_theme_option.dart';
import 'package:dearme/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults are dark theme and Russian locale', () {
    const settings = AppSettings.defaults();
    expect(settings.theme, AppThemeOption.dark);
    expect(settings.locale, AppLocaleOption.russian);
    expect(settings.notificationsEnabled, isTrue);
  });

  test('theme and locale survive a repository restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = await SharedPreferencesSettingsRepository.create();
    const expected = AppSettings(
      theme: AppThemeOption.oled,
      locale: AppLocaleOption.english,
      notificationsEnabled: false,
      lastKnownTimeZone: 'Europe/Moscow',
    );
    await repository.save(expected);

    final second = await SharedPreferencesSettingsRepository.create();
    final loaded = await second.load();
    expect(loaded, expected);
  });

  test('clear restores defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final repository = await SharedPreferencesSettingsRepository.create();
    await repository.save(
      const AppSettings(
        theme: AppThemeOption.light,
        locale: AppLocaleOption.english,
        notificationsEnabled: false,
      ),
    );
    await repository.clear();
    final loaded = await repository.load();
    expect(loaded, const AppSettings.defaults());
  });

  test('in-memory repository persists within a session', () async {
    final repository = InMemorySettingsRepository();
    const expected = AppSettings(
      theme: AppThemeOption.light,
      locale: AppLocaleOption.english,
      notificationsEnabled: true,
    );
    await repository.save(expected);
    expect(await repository.load(), expected);
  });
}
