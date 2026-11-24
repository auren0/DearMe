/// Fonts bundled with DearMe.
///
/// All three families are licensed under the SIL Open Font License 1.1 and
/// contain Cyrillic glyphs, so they work for both supported languages.
enum AppFontOption {
  googleSans('google-sans', 'Google Sans'),
  shantellSans('shantell-sans', 'Shantell Sans'),
  tiny5Duo('tiny5-duo', 'Tiny5Duo');

  const AppFontOption(this.storageKey, this.family);

  /// Stable key written to SharedPreferences. Never rename it casually: doing
  /// so would silently reset an existing user's choice.
  final String storageKey;

  /// Family name exactly as registered in `pubspec.yaml`.
  final String family;

  static AppFontOption fromStorage(String? value) {
    return AppFontOption.values.firstWhere(
      (option) => option.storageKey == value,
      orElse: () => AppFontOption.googleSans,
    );
  }
}
