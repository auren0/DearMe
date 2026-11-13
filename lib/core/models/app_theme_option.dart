import 'package:flutter/material.dart';

/// The three visual themes shipped with DearMe.
///
/// Dark is intentionally the default. The storage key is stable so that
/// preferences survive app updates.
enum AppThemeOption {
  light('light'),
  dark('dark'),
  oled('oled');

  const AppThemeOption(this.storageKey);

  final String storageKey;

  static AppThemeOption fromStorage(String? value) {
    return AppThemeOption.values.firstWhere(
      (option) => option.storageKey == value,
      orElse: () => AppThemeOption.dark,
    );
  }

  Brightness get brightness =>
      this == AppThemeOption.light ? Brightness.light : Brightness.dark;
}
