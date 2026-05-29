import 'package:flutter/material.dart';

/// Show-Control color palette.
/// Semantically named — never use hex literals in widgets directly.
abstract final class ScColors {
  // ── Backgrounds ─────────────────────────────────────────────────────────
  static const bg      = Color(0xFF0A0A0A); // page background
  static const surface = Color(0xFF141414); // panel / card surface
  static const surface2 = Color(0xFF1E1E1E); // slightly lighter panel
  static const divider = Color(0xFF2A2A2A);

  // ── State / Semantic ──────────────────────────────────────────────────────
  static const active   = Color(0xFF00E676); // green: playing / ok / GO
  static const warn     = Color(0xFFFFAB00); // amber: paused / warning / RESUME
  static const error    = Color(0xFFFF1744); // red: error / STOP
  static const past     = Color(0xFF444444); // grey: done / inactive

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textDim       = Color(0xFF555555);
  static const textDisabled  = Color(0xFF333333);

  // ── Status dots ───────────────────────────────────────────────────────────
  static const online  = active;
  static const offline = past;

  // ── Interactive ───────────────────────────────────────────────────────────
  static const hover    = Color(0xFF1C1C1C);
  static const selected = Color(0xFF1A2A1A);

  // ── Audio level meter ─────────────────────────────────────────────────────
  static const meterLow  = Color(0xFF00C853);
  static const meterMid  = Color(0xFFFFD600);
  static const meterHigh = Color(0xFFFF1744);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the semantic state colour for a cue row.
  static Color forCueState({
    required bool isActive,
    required bool isPast,
    required bool isError,
    required bool isPaused,
  }) {
    if (isError)  return error;
    if (isActive) return active;
    if (isPaused) return warn;
    if (isPast)   return past;
    return textSecondary;
  }
}
