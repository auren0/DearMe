import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/app_font_option.dart';
import '../core/models/app_theme_option.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_keys.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class DearMeApp extends ConsumerStatefulWidget {
  const DearMeApp({super.key});

  @override
  ConsumerState<DearMeApp> createState() => _DearMeAppState();
}

class _DearMeAppState extends ConsumerState<DearMeApp> {
  late final GoRouter _router;
  AppLifecycleListener? _lifecycleListener;
  AppFontOption? _lastFont;
  AppThemeOption? _lastTheme;

  @override
  void initState() {
    super.initState();
    _router = ref.read(routerProvider);
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final coordinator = ref.read(startupCoordinatorProvider);
      unawaited(
        coordinator.start(
          onOpenLetter: (letterId) {
            if (!mounted) {
              return;
            }
            // Push rather than replace so an open editor keeps its state and
            // autosave timer until the notification destination is popped.
            unawaited(_router.push('/letter/$letterId'));
          },
        ),
      );
    });
  }

  void _onResume() {
    if (!mounted) {
      return;
    }
    unawaited(ref.read(startupCoordinatorProvider).onResume());
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  bool get _isEditing {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    return path == '/editor' || path.startsWith('/editor/');
  }

  void _openNewLetter() {
    if (_isEditing) {
      return;
    }
    _router.go('/editor');
  }

  void _openSettings() {
    if (_isEditing) {
      return;
    }
    _router.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final theme = AppTheme.of(settings.theme, font: settings.font);
    final isLight = settings.theme == AppThemeOption.light;

    // A font change must be immediate. Theme colours still animate smoothly,
    // but interpolating a TextTheme would keep the old family for half of the
    // animation, so a pure font change skips the transition.
    final fontChanged = _lastFont != null && _lastFont != settings.font;
    final themeChanged = _lastTheme != null && _lastTheme != settings.theme;
    _lastFont = settings.font;
    _lastTheme = settings.theme;
    final themeAnimationDuration = fontChanged && !themeChanged
        ? Duration.zero
        : const Duration(milliseconds: 420);

    return MaterialApp.router(
      title: 'DearMe',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: theme,
      darkTheme: theme,
      themeMode: isLight ? ThemeMode.light : ThemeMode.dark,
      themeAnimationDuration: themeAnimationDuration,
      themeAnimationCurve: Curves.easeOutCubic,
      locale: settings.locale.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      scrollBehavior: const _AppScrollBehavior(),
      routerConfig: _router,
      builder: (context, child) {
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyN, control: true):
                _openNewLetter,
            const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
                _openNewLetter,
            const SingleActivator(LogicalKeyboardKey.comma, control: true):
                _openSettings,
            const SingleActivator(LogicalKeyboardKey.comma, meta: true):
                _openSettings,
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.invertedStylus,
  };
}
