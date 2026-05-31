import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/isolate/isolate_messages.dart';
import 'showcontrol/providers/session_provider.dart';
import 'ui/providers/network_state_provider.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/inventory_screen.dart';
import 'ui/screens/network_status_screen.dart';
import 'ui/screens/showcontrol/session_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: StageSyncApp()));
}

// ─────────────────────────────────────────────────────────────────────────────

class StageSyncApp extends StatelessWidget {
  const StageSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StageSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B3FA0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _NetworkBootstrap(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bootstrap: wartet auf DeviceId → Permission-Request → Isolate-Init
// ─────────────────────────────────────────────────────────────────────────────

class _NetworkBootstrap extends ConsumerWidget {
  const _NetworkBootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BLE-Mesh-Netzwerk-Stack vorübergehend deaktiviert — startet direkt in Show-Ansicht.
    // Original:
    // final managerAsync = ref.watch(networkIsolateManagerProvider);
    // return managerAsync.when(
    //   loading: () => const _SplashScreen(),
    //   error: (e, st) => _ErrorScreen(error: e.toString()),
    //   // data: (_) => const _AppShell(),
    //   data: (_) => const SessionScreen(),
    // );
    return const SessionScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.theater_comedy,
                  size: 72,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.8)),
              const SizedBox(height: 24),
              Text('StageSync',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 8),
              const Text('Netzwerk wird initialisiert…',
                  style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 32),
              const SizedBox(width: 200, child: LinearProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String error;
  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Netzwerk-Stack failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Shell – Multi-Screen mit NavigationBar
// ─────────────────────────────────────────────────────────────────────────────

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

// Erlaubt anderen Widgets (z.B. HomeScreen) den aktiven Tab zu wechseln.
final selectedTabProvider = StateProvider<int>((ref) => 0);

class _AppShellState extends ConsumerState<_AppShell> {

  static const _screens = [
    HomeScreen(),
    NetworkStatusScreen(),
    InventoryScreen(),
    ChatScreen(),
    SessionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(networkStatusProvider);
    final isLeader = ref.watch(isLeaderProvider);
    final permissionWarning = ref.watch(permissionWarningProvider);
    final selectedIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      body: Column(
        children: [
          if (permissionWarning != null)
            _PermissionWarningBanner(message: permissionWarning),
          Expanded(
            child: IndexedStack(index: selectedIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).state = i,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: (status?.connectedPeerCount ?? 0) > 0,
              label: Text('${status?.connectedPeerCount ?? 0}'),
              child: Icon(isLeader ? Icons.hub : Icons.hub_outlined),
            ),
            selectedIcon: Icon(isLeader ? Icons.hub : Icons.hub_outlined),
            label: 'Netzwerk',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventar',
          ),
          NavigationDestination(
            icon: _ChatNavIcon(status: status),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: _ShowNavIcon(
                isInSession: ref.watch(sessionProvider).isInSession),
            selectedIcon: const Icon(Icons.play_circle),
            label: 'Show',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission-Warning-Banner
// ─────────────────────────────────────────────────────────────────────────────

/// Nicht-blockierender Banner wenn BLE-Permissions verweigert wurden.
class _PermissionWarningBanner extends ConsumerWidget {
  final String message;
  const _PermissionWarningBanner({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPermanent = ref
            .watch(permissionResultProvider)
            .whenOrNull(data: (r) => r.isPermanentlyDenied) ??
        false;

    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.bluetooth_disabled,
                  size: 20,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isPermanent)
                TextButton(
                  onPressed: () async {
                    final result = ref.read(permissionResultProvider).value;
                    await result?.openSettings();
                  },
                  child: Text(
                    'Einstellungen',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat NavIcon mit Verbindungs-Dot
// ─────────────────────────────────────────────────────────────────────────────

class _ShowNavIcon extends StatelessWidget {
  final bool isInSession;
  const _ShowNavIcon({required this.isInSession});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.play_circle_outline),
        if (isInSession)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF00C853),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatNavIcon extends StatelessWidget {
  final NetworkStatusEvent? status;
  const _ChatNavIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final connected = (status?.connectedPeerCount ?? 0) > 0 ||
        (status?.hasServerConnection ?? false);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_bubble_outline),
        if (connected)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
