import 'package:dearme/app/providers.dart';
import 'package:dearme/core/models/app_locale_option.dart';
import 'package:dearme/core/models/app_settings.dart';
import 'package:dearme/core/models/app_theme_option.dart';
import 'package:dearme/features/settings/data/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FailingSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings.defaults();

  @override
  Future<void> save(AppSettings settings) async {
    throw StateError('disk full');
  }

  @override
  Future<void> clear() async {
    throw StateError('disk full');
  }
}

void main() {
  test('theme and locale update immediately and persist', () async {
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
        .setTheme(AppThemeOption.light);
    expect(
      container.read(settingsControllerProvider).theme,
      AppThemeOption.light,
    );

    await container
        .read(settingsControllerProvider.notifier)
        .setLocale(AppLocaleOption.english);
    expect(
      container.read(settingsControllerProvider).locale,
      AppLocaleOption.english,
    );

    final persisted = await repository.load();
    expect(persisted.theme, AppThemeOption.light);
    expect(persisted.locale, AppLocaleOption.english);
  });

  test('a persistence failure reverts the optimistic UI change', () async {
    final container = ProviderContainer(
      overrides: [
        initialSettingsProvider.overrideWithValue(const AppSettings.defaults()),
        settingsRepositoryProvider.overrideWithValue(
          FailingSettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container
          .read(settingsControllerProvider.notifier)
          .setTheme(AppThemeOption.oled),
      throwsStateError,
    );
    expect(
      container.read(settingsControllerProvider).theme,
      AppThemeOption.dark,
    );
  });

  test('reset returns to dark and Russian defaults', () async {
    final repository = InMemorySettingsRepository(
      const AppSettings(
        theme: AppThemeOption.oled,
        locale: AppLocaleOption.english,
        notificationsEnabled: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        initialSettingsProvider.overrideWithValue(
          const AppSettings(
            theme: AppThemeOption.oled,
            locale: AppLocaleOption.english,
            notificationsEnabled: false,
          ),
        ),
        settingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(settingsControllerProvider.notifier).resetToDefaults();
    expect(
      container.read(settingsControllerProvider),
      const AppSettings.defaults(),
    );
    expect(await repository.load(), const AppSettings.defaults());
  });
}
