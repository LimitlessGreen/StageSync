import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shared vsync ticker — one Ticker drives all timing widgets in the subtree.
///
/// Place [ScTick] once at shell level. Any widget in the subtree that needs
/// live timing calls [ScTick.of(context)] from its build method to subscribe.
/// Flutter will rebuild the subscriber on every vsync frame while the ticker
/// runs.
///
/// The bug this design avoids: multiple independent Timer.periodic instances
/// fire at slightly different times, causing inter-widget clock skew of up to
/// one timer interval (~50–100 ms).
class ScTick extends StatefulWidget {
  final Widget child;
  const ScTick({super.key, required this.child});

  /// Subscribe to the shared ticker from a build method.
  /// No return value — the side-effect is that this widget will be rebuilt
  /// on every vsync frame as long as [ScTick] is running.
  static void of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_ScTickProvider>();
  }

  @override
  State<ScTick> createState() => _ScTickState();
}

class _ScTickState extends State<ScTick> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() => _generation++));
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ScTickProvider(
      generation: _generation,
      child: widget.child,
    );
  }
}

// ── InheritedWidget ───────────────────────────────────────────────────────────

class _ScTickProvider extends InheritedWidget {
  final int generation;

  const _ScTickProvider({required this.generation, required super.child});

  @override
  bool updateShouldNotify(_ScTickProvider old) => generation != old.generation;
}
