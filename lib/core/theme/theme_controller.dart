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
    }
  }
}

final moodThemeProvider =
    StateNotifierProvider<MoodThemeController, MoodTheme>((ref) {
  return MoodThemeController();
});

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
    }
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
    ).copyWith(
      surface: surface,
    );

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
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
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
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}