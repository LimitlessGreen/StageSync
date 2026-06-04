import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Shared vsync ticker — one AnimationController drives all timing widgets.
///
/// Attach [ScTickProvider] once in the widget tree (at shell level or above any
/// component that needs live timing). Child widgets call [ScTick.of(context)]
/// to subscribe; they rebuild on every frame while the ticker is running.
///
/// Usage:
/// ```dart
/// // In the shell's State (with TickerProviderStateMixin):
/// ScTickProvider(ticker: _ticker, child: …)
///
/// // In any timing widget's build():
/// ScTick.of(context); // subscribe — widget rebuilds each frame
/// ```
class ScTickProvider extends InheritedWidget {
  final _ScTickState _state;

  const ScTickProvider._({
    required _ScTickState state,
    required super.child,
  }) : _state = state;

  /// Subscribe to the shared ticker.
  /// Calling this from build() registers a dependency — Flutter rebuilds the
  /// widget whenever the ticker fires (every vsync frame while active).
  static void of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<ScTickProvider>();
  }

  @override
  bool updateShouldNotify(ScTickProvider old) => !identical(_state, old._state);
}

/// Wrap this around your shell widget to provide the shared ticker.
/// The shell must use [TickerProviderStateMixin].
class ScTick extends StatefulWidget {
  final Widget child;

  const ScTick({super.key, required this.child});

  /// Subscribe from within a build method. Returns nothing — the side-effect
  /// is that the calling widget will be rebuilt on each ticker frame.
  static void of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<ScTickProvider>();
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
    _ticker = createTicker((_) {
      setState(() => _generation++);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScTickProvider._(
      state: this,
      child: widget.child,
    );
  }
}
