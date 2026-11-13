import 'app_locale_option.dart';
import 'app_theme_option.dart';

/// Persisted application preferences.
///
/// Notification content is not stored here: it is generated from the current
/// locale when a notification is scheduled.
class AppSettings {
  const AppSettings({
    required this.theme,
    required this.locale,
    required this.notificationsEnabled,
    this.lastKnownTimeZone,
    this.notificationPermissionRequested = false,
  });

  const AppSettings.defaults()
    : theme = AppThemeOption.dark,
      locale = AppLocaleOption.russian,
      notificationsEnabled = true,
      lastKnownTimeZone = null,
      notificationPermissionRequested = false;

  final AppThemeOption theme;
  final AppLocaleOption locale;
  final bool notificationsEnabled;
  final String? lastKnownTimeZone;

  /// Android can report only "not enabled", not "never asked". This flag lets
  /// the Settings UI show an honest "not requested yet" state.
  final bool notificationPermissionRequested;

  AppSettings copyWith({
    AppThemeOption? theme,
    AppLocaleOption? locale,
    bool? notificationsEnabled,
    Object? lastKnownTimeZone = _unset,
    bool? notificationPermissionRequested,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastKnownTimeZone: identical(lastKnownTimeZone, _unset)
          ? this.lastKnownTimeZone
          : lastKnownTimeZone as String?,
      notificationPermissionRequested:
          notificationPermissionRequested ??
          this.notificationPermissionRequested,
    );
  }

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.theme == theme &&
        other.locale == locale &&
        other.notificationsEnabled == notificationsEnabled &&
        other.lastKnownTimeZone == lastKnownTimeZone &&
        other.notificationPermissionRequested ==
            notificationPermissionRequested;
  }

  @override
  int get hashCode => Object.hash(
    theme,
    locale,
    notificationsEnabled,
    lastKnownTimeZone,
    notificationPermissionRequested,
  );
}
