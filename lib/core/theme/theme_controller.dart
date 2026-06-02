import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

enum MoodTheme {
  classic,
  calmBlue,
  warmCozy,
  night,
  toonPop,
  winterFrost,
  springBloom,
}

extension MoodThemeLabel on MoodTheme {
  String get label {
    switch (this) {
      case MoodTheme.classic:
        return 'Classic';
      case MoodTheme.calmBlue:
        return 'Calm Blue';
      case MoodTheme.warmCozy:
        return 'Warm Cozy';
      case MoodTheme.night:
        return 'Night Mode';
      case MoodTheme.toonPop:
        return 'Toon Pop';
      case MoodTheme.winterFrost:
        return 'Winter Frost';
      case MoodTheme.springBloom:
        return 'Spring Bloom';
    }
  }
}

final moodThemeProvider = StateNotifierProvider<MoodThemeController, MoodTheme>(
  (ref) {
    return MoodThemeController();
  },
);

class MoodThemeController extends StateNotifier<MoodTheme> {
  MoodThemeController() : super(MoodTheme.classic) {
    _loadTheme();
  }

  static const _themeKey = 'selected_mood_theme';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == null) return;

    state = MoodTheme.values.firstWhere(
      (theme) => theme.name == savedTheme,
      orElse: () => MoodTheme.classic,
    );
  }

  Future<void> setTheme(MoodTheme theme) async {
    state = theme;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }
}

class MoodThemes {
  MoodThemes._();

  static ThemeData themeFor(MoodTheme mood) {
    switch (mood) {
      case MoodTheme.classic:
        return AppTheme.lightTheme;

      case MoodTheme.calmBlue:
        return _buildTheme(
          seedColor: const Color(0xFF2563EB),
          background: const Color(0xFFEFF6FF),
          surface: Colors.white,
          cardRadius: 16,
          buttonRadius: 16,
          elevation: 1,
        );

      case MoodTheme.warmCozy:
        return _buildTheme(
          seedColor: const Color(0xFFC2410C),
          background: const Color(0xFFFFF7ED),
          surface: const Color(0xFFFFFBF5),
          cardRadius: 20,
          buttonRadius: 20,
          elevation: 2,
        );

      case MoodTheme.night:
        return AppTheme.darkTheme;

      case MoodTheme.toonPop:
        return _buildTheme(
          seedColor: const Color(0xFFE11D48),
          background: const Color(0xFFFFFBEB),
          surface: Colors.white,
          cardRadius: 28,
          buttonRadius: 999,
          elevation: 4,
        );

      case MoodTheme.winterFrost:
        return _buildWinterFrostTheme();

      case MoodTheme.springBloom:
        return _buildSpringBloomTheme();
    }
  }

  static ThemeData _buildWinterFrostTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF0369A1),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF0369A1),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFB7D7EA),
          onPrimaryContainer: const Color(0xFF082F49),
          secondary: const Color(0xFF475569),
          secondaryContainer: const Color(0xFFC9DCEB),
          onSecondaryContainer: const Color(0xFF0F172A),
          tertiary: const Color(0xFF38BDF8),
          tertiaryContainer: const Color(0xFFB6E3F8),
          onTertiaryContainer: const Color(0xFF082F49),
          surface: const Color(0xFFE6F0F8),
          surfaceContainerHighest: const Color(0xFFD2E4F1),
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: const Color(0xFF334155),
          outlineVariant: const Color(0xFF8FBAD4),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFBFD7EA),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: const Color(0xFFBFD7EA),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.88),
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.96),
            width: 1.2,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFE6F0F8).withValues(alpha: 0.94),
        indicatorColor: const Color(0xFFB7D7EA),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colorScheme.onSurface),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0369A1),
          foregroundColor: Colors.white,
          shadowColor: const Color(0xFF075985).withValues(alpha: 0.35),
          elevation: 2,
          minimumSize: const Size(0, 46),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.72),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF075985),
          backgroundColor: const Color(0xFFD8EAF7).withValues(alpha: 0.90),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.4),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF075985),
          backgroundColor: const Color(0xFFD8EAF7).withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: const Color(0xFF7DD3FC).withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE6F0F8).withValues(alpha: 0.96),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF8FBAD4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData _buildSpringBloomTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFDFA7B8),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFFB97C91),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFF7E7ED),
          onPrimaryContainer: const Color(0xFF4B2D37),

          secondary: const Color(0xFFE7C8D3),
          secondaryContainer: const Color(0xFFFAEEF2),
          onSecondaryContainer: const Color(0xFF51313C),

          tertiary: const Color(0xFFF3D8E1),
          tertiaryContainer: const Color(0xFFFFF5F8),
          onTertiaryContainer: const Color(0xFF5A3944),

          surface: const Color(0xFFFDFBFC),
          surfaceContainerHighest: const Color(0xCCFFFFFF),

          onSurface: const Color(0xFF2E2428),
          onSurfaceVariant: const Color(0xFF6C5C63),

          outline: const Color(0xFFE9D8DE),
          outlineVariant: const Color(0xFFF1E5EA),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFDF8FA),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white.withValues(alpha: 0.30),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.82),
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.90),
            width: 1.1,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.84),
        indicatorColor: const Color(0xFFFFE4EE).withValues(alpha: 0.92),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: colorScheme.onSurface),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colorScheme.onSurface),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.88),
          foregroundColor: const Color(0xFF3A2B31),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          minimumSize: const Size(0, 46),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3A2B31),
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          elevation: 0,
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.1,
          ),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.42),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.72),
            width: 1.1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.92),
            width: 1.5,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.30),
        selectedColor: Colors.white.withValues(alpha: 0.52),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(color: colorScheme.onSurface),
      ),
    );
  }

  static ThemeData _buildTheme({
    required Color seedColor,
    required Color background,
    required Color surface,
    required double cardRadius,
    required double buttonRadius,
    required double elevation,
  }) {
    final base = AppTheme.lightTheme;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ).copyWith(surface: surface);

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: surface,
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
