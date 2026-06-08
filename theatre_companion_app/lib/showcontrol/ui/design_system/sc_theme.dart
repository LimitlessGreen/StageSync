import 'package:flutter/material.dart';
import 'sc_colors.dart';

/// Builds the [ThemeData] used by the Show-Control shell.
///
/// Wrap the top-level [ScAdaptiveShell] (or any sub-tree) with
/// `Theme(data: ScTheme.build(context), child: ...)`.
abstract final class ScTheme {
  /// Dark, low-saturation theatre theme.
  ///
  /// - Background  #0A0A0A
  /// - Surface     #141414
  /// - Primary     green (#00E676)
  /// - Error       red   (#FF1744)
  static ThemeData build(BuildContext context) {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: ScColors.bg,
      colorScheme: ColorScheme.dark(
        primary: ScColors.active,
        onPrimary: Colors.black,
        secondary: ScColors.warn,
        onSecondary: Colors.black,
        error: ScColors.error,
        onError: Colors.white,
        surface: ScColors.surface,
        onSurface: ScColors.textPrimary,
      ),
      dividerColor: ScColors.divider,
      cardColor: ScColors.surface,
      cardTheme: CardThemeData(
        color: ScColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      iconTheme: const IconThemeData(
        color: ScColors.textSecondary,
        size: 18,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ScColors.surface2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ScColors.divider),
        ),
        textStyle: const TextStyle(
          color: ScColors.textSecondary,
          fontSize: 11,
        ),
        waitDuration: const Duration(milliseconds: 600),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(ScColors.past),
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(2),
      ),
    );
  }
}
