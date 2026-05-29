import 'package:flutter/material.dart';
import 'sc_colors.dart';

/// Show-Control typography constants.
/// Use [ScText.*] helpers instead of raw [TextStyle] in SC widgets.
abstract final class ScText {
  // ── Monospace / Tabular numbers ───────────────────────────────────────────
  static const _tabular = [FontFeature.tabularFigures()];

  /// Cue numbers, timers, counters — always fixed-width.
  static const number = TextStyle(
    fontFeatures: _tabular,
    color: ScColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
  );

  static const numberLarge = TextStyle(
    fontFeatures: _tabular,
    color: ScColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const numberSmall = TextStyle(
    fontFeatures: _tabular,
    color: ScColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const timer = TextStyle(
    fontFeatures: _tabular,
    color: ScColors.active,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // ── Labels ────────────────────────────────────────────────────────────────

  static const label = TextStyle(
    color: ScColors.textSecondary,
    fontSize: 11,
    letterSpacing: 0.5,
  );

  static const labelBold = TextStyle(
    color: ScColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const cueLabel = TextStyle(
    color: ScColors.textPrimary,
    fontSize: 14,
  );

  static const cueLabelActive = TextStyle(
    color: ScColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const cueLabelPast = TextStyle(
    color: ScColors.textDim,
    fontSize: 14,
    decoration: TextDecoration.lineThrough,
    decorationColor: ScColors.textDim,
  );

  // ── Status ────────────────────────────────────────────────────────────────

  static const status = TextStyle(
    color: ScColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
  );

  static const statusSmall = TextStyle(
    color: ScColors.textDim,
    fontSize: 10,
    letterSpacing: 0.8,
  );

  // ── Titles ────────────────────────────────────────────────────────────────

  static const panelTitle = TextStyle(
    color: ScColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  static const sectionTitle = TextStyle(
    color: ScColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  // ── Transport ─────────────────────────────────────────────────────────────

  static const goButton = TextStyle(
    color: Colors.black,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 6,
  );

  static const shortcutHint = TextStyle(
    color: ScColors.textDim,
    fontSize: 9,
    letterSpacing: 0.5,
  );
}
