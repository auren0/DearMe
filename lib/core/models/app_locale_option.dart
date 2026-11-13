import 'dart:ui';

/// Languages explicitly supported by DearMe.
///
/// The system locale is deliberately not used as an implicit override: a user
/// choice is persisted and Russian is the default.
enum AppLocaleOption {
  russian('ru'),
  english('en');

  const AppLocaleOption(this.languageCode);

  final String languageCode;

  Locale get locale => Locale(languageCode);

  static AppLocaleOption fromStorage(String? value) {
    return AppLocaleOption.values.firstWhere(
      (option) => option.languageCode == value,
      orElse: () => AppLocaleOption.russian,
    );
  }
}
