import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState {
  final bool keepScreenOn;
  final int goLockDurationMs;
  final String? sessionLocalName;

  const SettingsState({
    this.keepScreenOn = false,
    this.goLockDurationMs = 1000,
    this.sessionLocalName,
  });

  SettingsState copyWith({
    bool? keepScreenOn,
    int? goLockDurationMs,
    Object? sessionLocalName = _unset,
  }) =>
      SettingsState(
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        goLockDurationMs: goLockDurationMs ?? this.goLockDurationMs,
        sessionLocalName: identical(sessionLocalName, _unset)
            ? this.sessionLocalName
            : sessionLocalName as String?,
      );
}

const Object _unset = Object();

// ── Provider ──────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _keyKeepScreenOn = 'settings.keepScreenOn';
  static const _keyGoLockDurationMs = 'settings.goLockDurationMs';
  static const _keySessionLocalName = 'settings.sessionLocalName';

  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keepOn = prefs.getBool(_keyKeepScreenOn) ?? false;
    final goLock = prefs.getInt(_keyGoLockDurationMs) ?? 1000;
    final sessionName = prefs.getString(_keySessionLocalName);
    state = SettingsState(
      keepScreenOn: keepOn,
      goLockDurationMs: goLock,
      sessionLocalName: sessionName,
    );
    await WakelockPlus.toggle(enable: keepOn);
  }

  Future<void> setKeepScreenOn(bool value) async {
    state = state.copyWith(keepScreenOn: value);
    await WakelockPlus.toggle(enable: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepScreenOn, value);
  }

  Future<void> setGoLockDurationMs(int ms) async {
    final clamped = ms.clamp(0, 10000);
    state = state.copyWith(goLockDurationMs: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGoLockDurationMs, clamped);
  }

  Future<void> setSessionLocalName(String? name) async {
    final trimmed = name?.trim().isEmpty == true ? null : name?.trim();
    state = state.copyWith(sessionLocalName: trimmed);
    final prefs = await SharedPreferences.getInstance();
    if (trimmed == null) {
      await prefs.remove(_keySessionLocalName);
    } else {
      await prefs.setString(_keySessionLocalName, trimmed);
    }
  }
}
