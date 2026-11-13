import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/app_locale_option.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/models/app_theme_option.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);

  Future<void> clear();
}

/// Settings are small, scalar values, so SharedPreferences is appropriate.
/// Letters intentionally use the Sembast database instead.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const String _themeKey = 'settings.theme';
  static const String _localeKey = 'settings.locale';
  static const String _notificationsKey = 'settings.notificationsEnabled';
  static const String _permissionRequestedKey =
      'settings.notificationPermissionRequested';
  static const String _timeZoneKey = 'settings.lastKnownTimeZone';

  static Future<SharedPreferencesSettingsRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesSettingsRepository(preferences);
  }

  @override
  Future<AppSettings> load() async {
    try {
      return AppSettings(
        theme: AppThemeOption.fromStorage(_preferences.getString(_themeKey)),
        locale: AppLocaleOption.fromStorage(_preferences.getString(_localeKey)),
        notificationsEnabled: _preferences.getBool(_notificationsKey) ?? true,
        lastKnownTimeZone: _preferences.getString(_timeZoneKey),
        notificationPermissionRequested:
            _preferences.getBool(_permissionRequestedKey) ?? false,
      );
    } on Object {
      return const AppSettings.defaults();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    final results = await Future.wait<bool>([
      _preferences.setString(_themeKey, settings.theme.storageKey),
      _preferences.setString(_localeKey, settings.locale.languageCode),
      _preferences.setBool(_notificationsKey, settings.notificationsEnabled),
      _preferences.setBool(
        _permissionRequestedKey,
        settings.notificationPermissionRequested,
      ),
      if (settings.lastKnownTimeZone == null)
        _preferences.remove(_timeZoneKey)
      else
        _preferences.setString(_timeZoneKey, settings.lastKnownTimeZone!),
    ]);

    if (results.any((saved) => !saved)) {
      throw StateError('Settings could not be persisted.');
    }
  }

  @override
  Future<void> clear() async {
    await Future.wait<bool>([
      _preferences.remove(_themeKey),
      _preferences.remove(_localeKey),
      _preferences.remove(_notificationsKey),
      _preferences.remove(_permissionRequestedKey),
      _preferences.remove(_timeZoneKey),
    ]);
  }
}

/// Deterministic in-memory implementation used by tests.
class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([this._settings = const AppSettings.defaults()]);

  AppSettings _settings;

  int saveCount = 0;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
    saveCount++;
  }

  @override
  Future<void> clear() async {
    _settings = const AppSettings.defaults();
    saveCount++;
  }
}
