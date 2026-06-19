// ═══════════════════════════════════════════════════════════════════════════════
// QuitMate Design System
// Inspired by Headspace · Calm · Noom · Fabulous
//
// Philosophy: Nature-infused wellness palette, generous whitespace,
// ultra-subtle depth, rounded friendly forms. Every color comes from
// the theme — zero hardcoded values in widgets.
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — Semantic color tokens via ThemeExtension
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
    required this.achievementColor,
    required this.companionColor,
    required this.coachColor,
    required this.primaryLight,
    required this.textTertiary,
    required this.dividerColor,
  });

  /// Positive feedback — milestones reached, streaks alive
  final Color successColor;

  /// Caution — relapse risk, upcoming cravings
  final Color warningColor;

  /// Destructive actions — used VERY sparingly
  final Color dangerColor;

  /// Celebration / reward moments — badges unlocked, goals crushed
  final Color achievementColor;

  /// Companion bot personality color — warm, inviting
  final Color companionColor;

  /// Coach / guidance color — authoritative yet gentle
  final Color coachColor;

  /// Light tint of primary for backgrounds and selections
  final Color primaryLight;

  /// Lightest text level — placeholders, timestamps
  final Color textTertiary;

  /// Hairline dividers, card outlines
  final Color dividerColor;

  @override
  AppColors copyWith({
    Color? successColor,
    Color? warningColor,
    Color? dangerColor,
    Color? achievementColor,
    Color? companionColor,
    Color? coachColor,
    Color? primaryLight,
    Color? textTertiary,
    Color? dividerColor,
  }) {
    return AppColors(
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      dangerColor: dangerColor ?? this.dangerColor,
      achievementColor: achievementColor ?? this.achievementColor,
      companionColor: companionColor ?? this.companionColor,
      coachColor: coachColor ?? this.coachColor,
      primaryLight: primaryLight ?? this.primaryLight,
      textTertiary: textTertiary ?? this.textTertiary,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      dangerColor: Color.lerp(dangerColor, other.dangerColor, t)!,
      achievementColor:
          Color.lerp(achievementColor, other.achievementColor, t)!,
      companionColor: Color.lerp(companionColor, other.companionColor, t)!,
      coachColor: Color.lerp(coachColor, other.coachColor, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSpacing — Consistent spacing & radius tokens via ThemeExtension
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.screenPadding,
    required this.cardPadding,
    required this.cardRadius,
    required this.buttonRadius,
    required this.inputRadius,
    required this.chipRadius,
    required this.iconRadius,
    required this.sectionGap,
    required this.itemGap,
  });

  /// 4px — micro breathing room
  final double xxs;

  /// 8px — tight spacing
  final double xs;

  /// 12px — compact gaps
  final double sm;

  /// 16px — default padding / comfortable gap
  final double md;

  /// 24px — section breathing room
  final double lg;

  /// 32px — generous vertical rhythm
  final double xl;

  /// 48px — major section separators
  final double xxl;

  /// Horizontal edge insets for screen-level layouts
  final double screenPadding;

  /// Internal padding inside cards
  final double cardPadding;

  /// Card corner radius
  final double cardRadius;

  /// Button corner radius
  final double buttonRadius;

  /// Input field corner radius
  final double inputRadius;

  /// Chip corner radius (pill)
  final double chipRadius;

  /// Small icon container radius
  final double iconRadius;

  /// Gap between top-level sections
  final double sectionGap;

  /// Gap between list items / inline elements
  final double itemGap;

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? screenPadding,
    double? cardPadding,
    double? cardRadius,
    double? buttonRadius,
    double? inputRadius,
    double? chipRadius,
    double? iconRadius,
    double? sectionGap,
    double? itemGap,
  }) {
    return AppSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      screenPadding: screenPadding ?? this.screenPadding,
      cardPadding: cardPadding ?? this.cardPadding,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      inputRadius: inputRadius ?? this.inputRadius,
      chipRadius: chipRadius ?? this.chipRadius,
      iconRadius: iconRadius ?? this.iconRadius,
      sectionGap: sectionGap ?? this.sectionGap,
      itemGap: itemGap ?? this.itemGap,
    );
  }

  @override
  AppSpacing lerp(covariant AppSpacing? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xxs: _lerpDouble(xxs, other.xxs, t),
      xs: _lerpDouble(xs, other.xs, t),
      sm: _lerpDouble(sm, other.sm, t),
      md: _lerpDouble(md, other.md, t),
      lg: _lerpDouble(lg, other.lg, t),
      xl: _lerpDouble(xl, other.xl, t),
      xxl: _lerpDouble(xxl, other.xxl, t),
      screenPadding: _lerpDouble(screenPadding, other.screenPadding, t),
      cardPadding: _lerpDouble(cardPadding, other.cardPadding, t),
      cardRadius: _lerpDouble(cardRadius, other.cardRadius, t),
      buttonRadius: _lerpDouble(buttonRadius, other.buttonRadius, t),
      inputRadius: _lerpDouble(inputRadius, other.inputRadius, t),
      chipRadius: _lerpDouble(chipRadius, other.chipRadius, t),
      iconRadius: _lerpDouble(iconRadius, other.iconRadius, t),
      sectionGap: _lerpDouble(sectionGap, other.sectionGap, t),
      itemGap: _lerpDouble(itemGap, other.itemGap, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme — Light & Dark theme construction
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  // ── Public API ─────────────────────────────────────────────────────────────

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  // ── Theme Builder ─────────────────────────────────────────────────────────

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // ── Color decisions ──────────────────────────────────────────────────────
    final primary = isDark ? const Color(0xFF4ECDC4) : const Color(0xFF2E7D6F);
    final onPrimary = const Color(0xFFFFFFFF);
    final primaryContainer =
        isDark ? const Color(0xFF1A3A35) : const Color(0xFFE8F5F1);
    final onPrimaryContainer =
        isDark ? const Color(0xFFA7F3D0) : const Color(0xFF1B4332);

    final secondary =
        isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1);
    final onSecondary = const Color(0xFFFFFFFF);
    final secondaryContainer =
        isDark ? const Color(0xFF2E2E5E) : const Color(0xFFEEF2FF);
    final onSecondaryContainer =
        isDark ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3);

    final surface = isDark ? const Color(0xFF1B2838) : const Color(0xFFFFFFFF);
    final onSurface =
        isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);
    final surfaceContainerHighest =
        isDark ? const Color(0xFF243447) : const Color(0xFFF0F1F3);
    final outlineVariant =
        isDark ? const Color(0xFF2A3F55) : const Color(0xFFE2E5E9);

    final error = const Color(0xFFEF5350);
    final onError = const Color(0xFFFFFFFF);
    final background =
        isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F8FA);
    final onBackground =
        isDark ? const Color(0xFFE8ECF0) : const Color(0xFF1A1A2E);

    final scaffoldBackground = background;
    final dialogBackground = surface;

    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final textTertiary =
        isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);

    // ── ColorScheme ───────────────────────────────────────────────────────────
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: primary, // reuse primary as tertiary for cohesion
      onTertiary: onPrimary,
      error: error,
      onError: onError,
      errorContainer:
          isDark ? const Color(0xFF4C1D1C) : const Color(0xFFFFDAD6),
      onErrorContainer:
          isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainerHighest,
      outlineVariant: outlineVariant,
      outline: isDark ? const Color(0xFF3B5068) : const Color(0xFFC4C9CF),
    );

    // ── AppColors extension ──────────────────────────────────────────────────
    final appColors = AppColors(
      successColor: isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50),
      warningColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFFFB74D),
      dangerColor: const Color(0xFFEF5350),
      achievementColor:
          isDark ? const Color(0xFFFFB74D) : const Color(0xFFF4A261),
      companionColor:
          isDark ? const Color(0xFF80DEEA) : const Color(0xFF4DD0E1),
      coachColor: isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6),
      primaryLight: isDark ? const Color(0xFF1A3A35) : const Color(0xFFE8F5F1),
      textTertiary: textTertiary,
      dividerColor: outlineVariant,
    );

    // ── AppSpacing extension ─────────────────────────────────────────────────
    const spacing = AppSpacing(
      xxs: 4,
      xs: 8,
      sm: 12,
      md: 16,
      lg: 24,
      xl: 32,
      xxl: 48,
      screenPadding: 20,
      cardPadding: 20,
      cardRadius: 16,
      buttonRadius: 12,
      inputRadius: 10,
      chipRadius: 20,
      iconRadius: 10,
      sectionGap: 24,
      itemGap: 12,
    );

    // ── Text Theme ─────────────────────────────────────────────────────────
    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03,
        height: 1.2,
        color: onBackground,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02,
        height: 1.25,
        color: onBackground,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        height: 1.3,
        color: onBackground,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        height: 1.3,
        color: onBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.35,
        color: onBackground,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01,
        height: 1.4,
        color: onBackground,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.02,
        height: 1.5,
        color: onBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.01,
        height: 1.5,
        color: textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.03,
        height: 1.4,
        color: textTertiary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.01,
        height: 1.35,
        color: onBackground,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02,
        height: 1.35,
        color: textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.03,
        height: 1.3,
        color: textTertiary,
      ),
    );

    // ── Compose ThemeData ────────────────────────────────────────────────────
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[appColors, spacing],

      // ── Scaffolds ───────────────────────────────────────────────────────────
      scaffoldBackgroundColor: scaffoldBackground,
      dialogBackgroundColor: dialogBackground,
      dialogTheme: DialogTheme(
        backgroundColor: dialogBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outlineVariant, width: 0.5),
        ),
        titleTextStyle: textTheme.headlineMedium,
        contentTextStyle: textTheme.bodyLarge,
      ),

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        titleTextStyle: textTheme.titleLarge,
        toolbarTextStyle: textTheme.bodyLarge,
      ),

      // ── Cards — elevation 0, subtle border ─────────────────────────────────
      cardTheme: CardTheme(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.cardRadius),
          side: BorderSide(color: outlineVariant, width: 0.5),
        ),
        margin: EdgeInsets.zero, // let parents control margin
      ),

      // ── Elevated Button ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
          enableFeedback: true,
        ),
      ),

      // ── Filled Button ──────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Outlined Button ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.buttonRadius),
          ),
          side: BorderSide(color: primary, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Text Button ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.buttonRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Icon Button ────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          maximumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing.iconRadius),
          ),
          enableFeedback: true,
        ),
      ),

      // ── Floating Action Button ─────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enableFeedback: true,
      ),

      // ── Input Decoration ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.inputRadius),
          borderSide: BorderSide(color: outlineVariant, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.inputRadius),
          borderSide: BorderSide(color: outlineVariant, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.inputRadius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.inputRadius),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyLarge?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyMedium,
        isDense: false,
      ),

      // ── Chips — pill shaped ─────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.chipRadius),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        side: BorderSide(color: outlineVariant, width: 0.5),
        backgroundColor: surfaceContainerHighest,
        selectedColor: primaryContainer,
        checkmarkColor: primary,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 0.5,
        space: 1,
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        elevation: 0,
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        modalElevation: 0,
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF7F8FA),
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Tab Bar ─────────────────────────────────────────────────────────────
      tabBarTheme: TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: textTertiary,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: Colors.transparent,
      ),

      // ── Switch ──────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return surfaceContainerHighest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withOpacity(0.4);
          }
          return outlineVariant;
        }),
      ),

      // ── Progress Indicator ───────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceContainerHighest,
        circularTrackColor: surfaceContainerHighest,
      ),

      // ── Slider ─────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceContainerHighest,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // ── Page Transitions ───────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ── Text Selection ──────────────────────────────────────────────────────
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withOpacity(0.3),
        selectionHandleColor: primary,
      ),

      // ── Scrollbar ──────────────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(4),
        trackVisibility: WidgetStateProperty.all(false),
        thumbColor: WidgetStateProperty.all(
          textTertiary.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience accessors — keeps widget code clean
// ─────────────────────────────────────────────────────────────────────────────

/// Semantic colors from the current theme.
///
/// Usage: `final colors = context.appColors;`
extension AppColorsExtension on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? _lightAppColors;
}

/// Spacing tokens from the current theme.
///
/// Usage: `final sp = context.appSpacing;`
extension AppSpacingExtension on BuildContext {
  AppSpacing get appSpacing =>
      Theme.of(this).extension<AppSpacing>() ?? _defaultSpacing;
}

/// Convenience getter for stat-style text on any BuildContext.
extension StatTextExtension on BuildContext {
  TextStyle get statStyle => Theme.of(this).textTheme.displayMedium!.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03,
        height: 1.1,
        color: Theme.of(this).colorScheme.onBackground,
      );
}

/// Fallback so extension accessors never crash outside MaterialApp.
const _lightAppColors = AppColors(
  successColor: Color(0xFF4CAF50),
  warningColor: Color(0xFFFFB74D),
  dangerColor: Color(0xFFEF5350),
  achievementColor: Color(0xFFF4A261),
  companionColor: Color(0xFF4DD0E1),
  coachColor: Color(0xFF8B5CF6),
  primaryLight: Color(0xFFE8F5F1),
  textTertiary: Color(0xFF9CA3AF),
  dividerColor: Color(0xFFE2E5E9),
);

const _defaultSpacing = AppSpacing(
  xxs: 4,
  xs: 8,
  sm: 12,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
  screenPadding: 20,
  cardPadding: 20,
  cardRadius: 16,
  buttonRadius: 12,
  inputRadius: 10,
  chipRadius: 20,
  iconRadius: 10,
  sectionGap: 24,
  itemGap: 12,
);
