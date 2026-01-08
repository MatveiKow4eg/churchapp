import 'package:flutter/material.dart';

ThemeData buildTheme({
  required Brightness brightness,
  required Color accentColor,
}) {
  // Keep dark theme matching the current UI as closely as possible.
  const darkBg = Color(0xFF0B0D10);
  const darkSurface = Color(0xFF12151B);
  const darkSurface2 = Color(0xFF171C24);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'SF Pro Display',
  );

  final scheme = ColorScheme.fromSeed(
    seedColor: accentColor,
    brightness: brightness,
    primary: accentColor,
    secondary: accentColor,
    // We'll set scaffold bg explicitly below.
    surface: brightness == Brightness.dark ? darkSurface : Colors.white,
    error: const Color(0xFFFF4D4D),
    onPrimary: brightness == Brightness.dark ? Colors.black : Colors.black,
    onSecondary: brightness == Brightness.dark ? Colors.black : Colors.black,
    onError: Colors.black,
  ).copyWith(
    background: brightness == Brightness.dark ? Colors.black : Colors.white,
  );

  final r12 = BorderRadius.circular(12);
  final r16 = BorderRadius.circular(16);
  final r999 = BorderRadius.circular(999);

  final scaffoldBg = brightness == Brightness.dark ? darkBg : Colors.white;

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    splashFactory: InkSparkle.splashFactory,

    iconTheme: IconThemeData(color: accentColor),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scaffoldBg,
      foregroundColor:
          brightness == Brightness.dark ? scheme.onSurface : Colors.black,
      centerTitle: true,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    ),

    cardTheme: CardThemeData(
      color: brightness == Brightness.dark ? darkSurface : scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: r16),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor:
          brightness == Brightness.dark ? darkSurface : scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: r16),
    ),

    dividerTheme: DividerThemeData(
      color: scheme.outline.withValues(alpha: 0.8),
      thickness: 1,
      space: 1,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scaffoldBg,
      selectedItemColor: accentColor,
      unselectedItemColor:
          brightness == Brightness.dark ? scheme.onSurfaceVariant : Colors.black54,
      type: BottomNavigationBarType.fixed,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scaffoldBg,
      indicatorColor: accentColor.withValues(alpha: 0.16),
      labelTextStyle: WidgetStatePropertyAll(
        base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? accentColor : scheme.onSurfaceVariant,
        );
      }),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: const StadiumBorder(),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        disabledBackgroundColor: accentColor.withValues(alpha: 0.35),
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
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
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
        foregroundColor: accentColor,
        textStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accentColor;
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accentColor.withValues(alpha: 0.45);
        }
        return null;
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accentColor;
        return null;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.black),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accentColor;
        return null;
      }),
    ),

    chipTheme: base.chipTheme.copyWith(
      backgroundColor: brightness == Brightness.dark ? darkSurface2 : scheme.surface,
      selectedColor: accentColor.withValues(alpha: 0.18),
      disabledColor: (brightness == Brightness.dark ? darkSurface2 : scheme.surface)
          .withValues(alpha: 0.5),
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
      fillColor: brightness == Brightness.dark ? darkSurface2 : scheme.surface,
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
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: r12,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: r12,
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),

    // Provide consistent rounded corners for common components.
    splashColor: accentColor.withValues(alpha: 0.12),
    highlightColor: accentColor.withValues(alpha: 0.06),

    // Make progress indicators pop.
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: accentColor,
      linearTrackColor: brightness == Brightness.dark ? darkSurface2 : scheme.surface,
      circularTrackColor: brightness == Brightness.dark ? darkSurface2 : scheme.surface,
    ),
  );
}
