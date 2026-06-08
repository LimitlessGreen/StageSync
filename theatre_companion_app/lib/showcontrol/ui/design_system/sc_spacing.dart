/// Show-Control layout constants.
abstract final class ScSpacing {
  // ── CueList row heights ───────────────────────────────────────────────────
  static const double rowHeight = 48.0; // compact / editor rows
  static const double rowHeightActive = 80.0; // expanded active cue (GoScreen)

  // ── Panel / padding ───────────────────────────────────────────────────────
  static const double panelPad = 12.0;
  static const double panelPadLarge = 16.0;

  // ── Column widths ─────────────────────────────────────────────────────────
  static const double cueListWidth = 280.0;
  static const double monitoringWidth = 260.0;
  static const double cueNumberWidth = 48.0;
  static const double cueTypeIconWidth = 20.0;
  static const double cueDurationWidth = 56.0;
  static const double cueStatusDotWidth = 14.0;

  // ── Inspector fields ──────────────────────────────────────────────────────
  static const double inspectorLabelWidth = 64.0;

  // ── Transport bar ─────────────────────────────────────────────────────────
  static const double transportBarHeight = 56.0;

  // ── Buttons ───────────────────────────────────────────────────────────────
  static const double buttonHeightLarge = 80.0;
  static const double buttonHeightDefault = 36.0;
  static const double buttonHeightCompact = 28.0;

  // ── Split view ────────────────────────────────────────────────────────────
  static const double dividerThickness = 1.0;

  // ── Breakpoints ───────────────────────────────────────────────────────────
  static const double desktopBreakpoint = 900.0;
  static const double tabletBreakpoint = 600.0;
}
