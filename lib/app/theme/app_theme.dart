import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../../../core/models/app_theme_option.dart';

/// Decorative, non-semantic colours used by DearMe's bespoke visuals.
///
/// Keeping them in a theme extension means no widget hardcodes palette values
/// and every theme (including OLED) can be tuned in one place.
@immutable
class DearMePalette extends ThemeExtension<DearMePalette> {
  const DearMePalette({
    required this.letterPaper,
    required this.letterInk,
    required this.envelope,
    required this.envelopeFlap,
    required this.waxSeal,
    required this.glow,
    required this.grain,
    required this.heroStart,
    required this.heroEnd,
    required this.cardBorder,
    required this.success,
  });

  final Color letterPaper;
  final Color letterInk;
  final Color envelope;
  final Color envelopeFlap;
  final Color waxSeal;
  final Color glow;
  final Color grain;
  final Color heroStart;
  final Color heroEnd;
  final Color cardBorder;
  final Color success;

  static const DearMePalette light = DearMePalette(
    letterPaper: Color(0xFFFFFDF8),
    letterInk: Color(0xFF2A2119),
    envelope: Color(0xFFEADCC7),
    envelopeFlap: Color(0xFFDDC9AC),
    waxSeal: Color(0xFF9C5B45),
    glow: Color(0xFFE8C98F),
    grain: Color(0xFFD8C6AF),
    heroStart: Color(0xFFF7E9D3),
    heroEnd: Color(0xFFFBF4EA),
    cardBorder: Color(0xFFE2D6C5),
    success: Color(0xFF4E6B4B),
  );

  static const DearMePalette dark = DearMePalette(
    letterPaper: Color(0xFF211C16),
    letterInk: Color(0xFFF0E9DF),
    envelope: Color(0xFF31281F),
    envelopeFlap: Color(0xFF5A4732),
    waxSeal: Color(0xFFC97B62),
    glow: Color(0xFFE8B86D),
    grain: Color(0xFF3A332A),
    heroStart: Color(0xFF2A2117),
    heroEnd: Color(0xFF16120F),
    cardBorder: Color(0xFF352D24),
    success: Color(0xFFA9C3A2),
  );

  static const DearMePalette oled = DearMePalette(
    letterPaper: Color(0xFF0A0A0A),
    letterInk: Color(0xFFF5F5F5),
    envelope: Color(0xFF16130F),
    envelopeFlap: Color(0xFF2C251B),
    waxSeal: Color(0xFFE28A6B),
    glow: Color(0xFFF0C27B),
    grain: Color(0xFF1F1D19),
    heroStart: Color(0xFF0B0A09),
    heroEnd: Color(0xFF000000),
    cardBorder: Color(0xFF26221D),
    success: Color(0xFFB7D2B0),
  );

  @override
  DearMePalette copyWith({
    Color? letterPaper,
    Color? letterInk,
    Color? envelope,
    Color? envelopeFlap,
    Color? waxSeal,
    Color? glow,
    Color? grain,
    Color? heroStart,
    Color? heroEnd,
    Color? cardBorder,
    Color? success,
  }) {
    return DearMePalette(
      letterPaper: letterPaper ?? this.letterPaper,
      letterInk: letterInk ?? this.letterInk,
      envelope: envelope ?? this.envelope,
      envelopeFlap: envelopeFlap ?? this.envelopeFlap,
      waxSeal: waxSeal ?? this.waxSeal,
      glow: glow ?? this.glow,
      grain: grain ?? this.grain,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      cardBorder: cardBorder ?? this.cardBorder,
      success: success ?? this.success,
    );
  }

  @override
  DearMePalette lerp(ThemeExtension<DearMePalette>? other, double t) {
    if (other is! DearMePalette) {
      return this;
    }
    return DearMePalette(
      letterPaper: Color.lerp(letterPaper, other.letterPaper, t)!,
      letterInk: Color.lerp(letterInk, other.letterInk, t)!,
      envelope: Color.lerp(envelope, other.envelope, t)!,
      envelopeFlap: Color.lerp(envelopeFlap, other.envelopeFlap, t)!,
      waxSeal: Color.lerp(waxSeal, other.waxSeal, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      grain: Color.lerp(grain, other.grain, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

/// Centralised Material 3 theme factory.
abstract final class AppTheme {
  static const String fontFamily = 'Tiny5Duo';
  static const List<String> fontFallback = <String>[
    'Segoe UI Emoji',
    'Apple Color Emoji',
    'Noto Color Emoji',
    'sans-serif',
  ];

  static ThemeData of(AppThemeOption option) {
    return switch (option) {
      AppThemeOption.light => light,
      AppThemeOption.dark => dark,
      AppThemeOption.oled => oled,
    };
  }

  static ColorScheme _lightScheme() {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF8A5A2B),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF7B542D),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: const Color(0xFFF0DCC4),
      onPrimaryContainer: const Color(0xFF2C1A08),
      secondary: const Color(0xFF5D6957),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFE1E9DA),
      onSecondaryContainer: const Color(0xFF1B2418),
      tertiary: const Color(0xFF7D5262),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFF4D9E2),
      onTertiaryContainer: const Color(0xFF2F111D),
      error: const Color(0xFF9F4038),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFDAD5),
      onErrorContainer: const Color(0xFF410002),
      surface: const Color(0xFFFBF6EE),
      onSurface: const Color(0xFF241E18),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF7F1E7),
      surfaceContainer: const Color(0xFFF1EADD),
      surfaceContainerHigh: const Color(0xFFEAE2D4),
      surfaceContainerHighest: const Color(0xFFE3DACB),
      surfaceDim: const Color(0xFFDFD6C7),
      surfaceBright: const Color(0xFFFBF6EE),
      outline: const Color(0xFF8B7E6E),
      outlineVariant: const Color(0xFFD9CEBE),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFF39322B),
      onInverseSurface: const Color(0xFFF8EFE6),
      inversePrimary: const Color(0xFFE8C08E),
      surfaceTint: const Color(0xFF7B542D),
    );
  }

  static ColorScheme _darkScheme() {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFFD8A85F),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFE7BD7C),
      onPrimary: const Color(0xFF3A2508),
      primaryContainer: const Color(0xFF553A17),
      onPrimaryContainer: const Color(0xFFFFE1B5),
      secondary: const Color(0xFFB8C4B0),
      onSecondary: const Color(0xFF24301F),
      secondaryContainer: const Color(0xFF3A4634),
      onSecondaryContainer: const Color(0xFFD4E1CB),
      tertiary: const Color(0xFFD6B3C2),
      onTertiary: const Color(0xFF3D1E2B),
      tertiaryContainer: const Color(0xFF553341),
      onTertiaryContainer: const Color(0xFFF4D9E2),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: const Color(0xFF14110E),
      onSurface: const Color(0xFFF0E9DF),
      surfaceContainerLowest: const Color(0xFF0C0A08),
      surfaceContainerLow: const Color(0xFF191612),
      surfaceContainer: const Color(0xFF1F1B16),
      surfaceContainerHigh: const Color(0xFF27221C),
      surfaceContainerHighest: const Color(0xFF302A23),
      surfaceDim: const Color(0xFF14110E),
      surfaceBright: const Color(0xFF3C342B),
      outline: const Color(0xFF9B8E7D),
      outlineVariant: const Color(0xFF4C443A),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFFF0E9DF),
      onInverseSurface: const Color(0xFF2C2620),
      inversePrimary: const Color(0xFF7B5730),
      surfaceTint: const Color(0xFFE7BD7C),
    );
  }

  static ColorScheme _oledScheme() {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFFF0C27B),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFFF2C987),
      onPrimary: const Color(0xFF2F1F06),
      primaryContainer: const Color(0xFF3D2A0D),
      onPrimaryContainer: const Color(0xFFFFDFA9),
      secondary: const Color(0xFFA9BBA4),
      onSecondary: const Color(0xFF172414),
      secondaryContainer: const Color(0xFF283722),
      onSecondaryContainer: const Color(0xFFC5D7BE),
      tertiary: const Color(0xFFE0B7C7),
      onTertiary: const Color(0xFF3A1C28),
      tertiaryContainer: const Color(0xFF4F2D3A),
      onTertiaryContainer: const Color(0xFFF8DCE6),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: const Color(0xFF000000),
      onSurface: const Color(0xFFF4F4F4),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF080807),
      surfaceContainer: const Color(0xFF0D0C0B),
      surfaceContainerHigh: const Color(0xFF151311),
      surfaceContainerHighest: const Color(0xFF1C1917),
      surfaceDim: const Color(0xFF000000),
      surfaceBright: const Color(0xFF2B2824),
      outline: const Color(0xFF6E665C),
      outlineVariant: const Color(0xFF2A2621),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: const Color(0xFFF4F4F4),
      onInverseSurface: const Color(0xFF1B1917),
      inversePrimary: const Color(0xFF7A5730),
      surfaceTint: const Color(0xFFF2C987),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 46,
      fontWeight: FontWeight.w600,
      height: 1.08,
      letterSpacing: -0.8,
    ),
    displayMedium: TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w600,
      height: 1.12,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontSize: 31,
      fontWeight: FontWeight.w600,
      height: 1.16,
      letterSpacing: -0.3,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.24,
    ),
    headlineSmall: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      height: 1.28,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(fontSize: 17, height: 1.6),
    bodyMedium: TextStyle(fontSize: 15, height: 1.6),
    bodySmall: TextStyle(fontSize: 13.5, height: 1.55),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.4,
    ),
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required DearMePalette palette,
    required bool isOled,
  }) {
    final textTheme = _textTheme.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final outlineShape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isOled ? Colors.black : scheme.surface,
      canvasColor: isOled ? Colors.black : scheme.surface,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[palette],
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: isOled ? scheme.surfaceContainerLow : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.cardBorder),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isOled
            ? const Color(0xFF090909)
            : scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.labelLarge?.copyWith(
          color: scheme.primary,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        border: outlineShape,
        enabledBorder: outlineShape,
        disabledBorder: outlineShape.copyWith(
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: outlineShape.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: outlineShape.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: outlineShape.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        headerBackgroundColor: scheme.surfaceContainer,
        headerForegroundColor: scheme.onSurface,
        dayShape: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const CircleBorder();
          }
          return const CircleBorder();
        }),
        todayBorder: BorderSide(color: scheme.primary),
        rangeSelectionBackgroundColor: scheme.primaryContainer,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        dialBackgroundColor: scheme.surfaceContainer,
        dialHandColor: scheme.primary,
        dialTextColor: scheme.onSurface,
        hourMinuteColor: scheme.surfaceContainer,
        hourMinuteTextColor: scheme.onSurface,
        entryModeIconColor: scheme.onSurfaceVariant,
        helpTextStyle: textTheme.labelLarge,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelMedium,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.28),
        selectionHandleColor: scheme.primary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          scheme.outline.withValues(alpha: 0.55),
        ),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }

  static final ThemeData light = _build(
    scheme: _lightScheme(),
    palette: DearMePalette.light,
    isOled: false,
  );

  static final ThemeData dark = _build(
    scheme: _darkScheme(),
    palette: DearMePalette.dark,
    isOled: false,
  );

  static final ThemeData oled = _build(
    scheme: _oledScheme(),
    palette: DearMePalette.oled,
    isOled: true,
  );
}
