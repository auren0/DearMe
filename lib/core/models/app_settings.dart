import 'app_font_option.dart';
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
    this.font = AppFontOption.googleSans,
    this.lastKnownTimeZone,
    this.notificationPermissionRequested = false,
  });

  const AppSettings.defaults()
    : theme = AppThemeOption.dark,
      locale = AppLocaleOption.russian,
      notificationsEnabled = true,
      font = AppFontOption.googleSans,
      lastKnownTimeZone = null,
      notificationPermissionRequested = false;

  final AppThemeOption theme;
  final AppLocaleOption locale;
  final bool notificationsEnabled;

  /// The font applied to the whole application. Defaults to Google Sans.
  final AppFontOption font;

  final String? lastKnownTimeZone;

  /// Android can report only "not enabled", not "never asked". This flag lets
  /// the Settings UI show an honest "not requested yet" state.
  final bool notificationPermissionRequested;

  AppSettings copyWith({
    AppThemeOption? theme,
    AppLocaleOption? locale,
    bool? notificationsEnabled,
    AppFontOption? font,
    Object? lastKnownTimeZone = _unset,
    bool? notificationPermissionRequested,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      font: font ?? this.font,
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
        other.font == font &&
        other.lastKnownTimeZone == lastKnownTimeZone &&
        other.notificationPermissionRequested ==
            notificationPermissionRequested;
  }

  @override
  int get hashCode => Object.hash(
    theme,
    locale,
    notificationsEnabled,
    font,
    lastKnownTimeZone,
    notificationPermissionRequested,
  );
}
