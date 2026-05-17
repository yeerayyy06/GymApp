import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _seedColor = Color(0xFF6366F1);
  static const _scaffold = Color(0xFF000000);
  static const _surface = Color(0xFF0E0E10);
  static const _surfaceContainer = Color(0xFF16161A);
  static const _surfaceContainerHigh = Color(0xFF1E1E24);
  static const _surfaceContainerHighest = Color(0xFF26262E);
  static const _separator = Color(0xFF2A2A33);

  static ThemeData get darkTheme {
    final base = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    final colorScheme = base.copyWith(
      surface: _surface,
      onSurface: const Color(0xFFE9E9EE),
      surfaceContainerLowest: const Color(0xFF09090B),
      surfaceContainerLow: const Color(0xFF111114),
      surfaceContainer: _surfaceContainer,
      surfaceContainerHigh: _surfaceContainerHigh,
      surfaceContainerHighest: _surfaceContainerHighest,
      outline: _separator,
      outlineVariant: _separator,
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _scaffold,
      canvasColor: _scaffold,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _scaffold,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: const Color(0xFF74747D),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: _separator),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: _surfaceContainer,
      ),
      dividerTheme: const DividerThemeData(
        color: _separator,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceContainerHigh,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: _surfaceContainer,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(colorScheme.primary),
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;

    TextStyle style({
      required double size,
      required FontWeight weight,
      double letter = 0,
      double? height,
      Color? color,
    }) {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letter,
        height: height,
        color: color ?? onSurface,
      );
    }

    return base.copyWith(
      displayLarge: style(size: 57, weight: FontWeight.w800, letter: -1.6, height: 1.05),
      displayMedium: style(size: 45, weight: FontWeight.w800, letter: -1.2, height: 1.1),
      displaySmall: style(size: 36, weight: FontWeight.w800, letter: -0.9, height: 1.15),
      headlineLarge: style(size: 32, weight: FontWeight.w700, letter: -0.6, height: 1.2),
      headlineMedium: style(size: 28, weight: FontWeight.w700, letter: -0.5, height: 1.25),
      headlineSmall: style(size: 24, weight: FontWeight.w700, letter: -0.4, height: 1.3),
      titleLarge: style(size: 20, weight: FontWeight.w700, letter: -0.3, height: 1.3),
      titleMedium: style(size: 16, weight: FontWeight.w600, letter: -0.15, height: 1.35),
      titleSmall: style(size: 14, weight: FontWeight.w600, letter: -0.05, height: 1.4),
      bodyLarge: style(size: 16, weight: FontWeight.w400, letter: 0, height: 1.45),
      bodyMedium: style(size: 14, weight: FontWeight.w400, letter: 0, height: 1.45),
      bodySmall: style(
        size: 12.5,
        weight: FontWeight.w400,
        letter: 0,
        height: 1.4,
        color: onSurfaceVariant,
      ),
      labelLarge: style(size: 14, weight: FontWeight.w600, letter: 0.1, height: 1.3),
      labelMedium: style(
        size: 12,
        weight: FontWeight.w500,
        letter: 0.2,
        height: 1.3,
        color: onSurfaceVariant,
      ),
      labelSmall: style(
        size: 11,
        weight: FontWeight.w500,
        letter: 0.35,
        height: 1.3,
        color: onSurfaceVariant,
      ),
    );
  }
}
