import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin für StateNotifier: kapselt den isLoading/try/catch/error-Pattern.
///
/// Nutzung:
/// ```dart
/// class MyNotifier extends StateNotifier<MyState> with AsyncOp<MyState> { ... }
///
/// await runAsync(
///   () async { /* gRPC call */ },
///   setLoading: (s, l) => s.copyWith(isLoading: l, error: null),
///   setError:   (s, e) => s.copyWith(isLoading: false, error: e),
/// );
/// ```
mixin AsyncOp<S> on StateNotifier<S> {
  Future<void> runAsync(
    Future<void> Function() op, {
    required S Function(S state, bool loading) setLoading,
    required S Function(S state, String error) setError,
  }) async {
    state = setLoading(state, true);
    try {
      await op();
      state = setLoading(state, false);
    } catch (e) {
      state = setError(state, e.toString());
    }
  }
}
