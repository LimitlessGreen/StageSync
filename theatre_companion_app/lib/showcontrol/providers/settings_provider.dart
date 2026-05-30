import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState {
  final bool keepScreenOn;

  const SettingsState({
    this.keepScreenOn = false,
  });

  SettingsState copyWith({bool? keepScreenOn}) => SettingsState(
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _keyKeepScreenOn = 'settings.keepScreenOn';

  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keepOn = prefs.getBool(_keyKeepScreenOn) ?? false;
    state = SettingsState(keepScreenOn: keepOn);
    await WakelockPlus.toggle(enable: keepOn);
  }

  Future<void> setKeepScreenOn(bool value) async {
    state = state.copyWith(keepScreenOn: value);
    await WakelockPlus.toggle(enable: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepScreenOn, value);
  }
}
