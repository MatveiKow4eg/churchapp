import 'package:flutter/material.dart';

/// Snapchat-like design system:
/// - Dark UI surfaces
/// - High-contrast yellow accent
/// - Rounded/pill components
/// - Consistent typography
final class AppTheme {
  AppTheme._();

  static const Color snapYellow = Color(0xFFFFFC00);
  static const Color _bg = Color(0xFF0B0D10);
  static const Color _surface = Color(0xFF12151B);
  static const Color _surface2 = Color(0xFF171C24);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SF Pro Display',
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: snapYellow,
      brightness: Brightness.dark,
      primary: snapYellow,
      onPrimary: Colors.black,
      surface: _surface,
      onSurface: const Color(0xFFECEEF3),
      surfaceContainerHighest: _surface2,
      onSurfaceVariant: const Color(0xFFB3B9C6),
      outline: const Color(0xFF2A2F3A),
      error: const Color(0xFFFF4D4D),
      onError: Colors.black,
    ).copyWith(
      secondary: const Color(0xFF6DE2FF),
      onSecondary: Colors.black,
      tertiary: const Color(0xFFFF7AD9),
      onTertiary: Colors.black,
    );

    final r12 = BorderRadius.circular(12);
    final r16 = BorderRadius.circular(16);
    final r999 = BorderRadius.circular(999);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _bg,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: r16),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: r16),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.8),
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C2230),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: r12),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _bg,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _bg,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const StadiumBorder(),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.black.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: r999),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: r999),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: r999),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        labelStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: r999),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: r12,
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: r12,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: r12,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: r12,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: r12,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        hintStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        subtitleTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: r12),
      ),

      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),

      // Slightly thicker scrollbar for dark UI.
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(false),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(999),
      ),

      // Default shapes for material surfaces.
      extensions: <ThemeExtension<dynamic>>[],

      // Provide consistent rounded corners for common components.
      splashColor: scheme.primary.withValues(alpha: 0.12),
      highlightColor: scheme.primary.withValues(alpha: 0.06),

      // Use rounded menus.
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: r16),
          ),
        ),
      ),

      // Dropdowns / popups.
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: r16),
        textStyle: base.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),

      // Keep Material containers rounded.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: r16.topLeft)),
      ),

      // Make progress indicators pop.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
