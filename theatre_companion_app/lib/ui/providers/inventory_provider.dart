// inventory_provider.dart
// ─────────────────────────
// Riverpod state management for the Inventory feature.
//
// Listens to [itemUpdateStreamProvider] and maintains a deduped, sorted
// map of inventory items keyed by itemId.
//
// Status codes:
//   0 = InPlace, 1 = CheckedOut, 2 = Missing, 3 = Damaged

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/isolate/isolate_messages.dart';
import 'network_state_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Display model (UI-only, not persisted)
// ─────────────────────────────────────────────────────────────────────────────

enum InventoryStatus {
  inPlace(0, 'Vorhanden'),
  checkedOut(1, 'Ausgecheckt'),
  missing(2, 'Fehlend'),
  damaged(3, 'Beschädigt');

  final int code;
  final String label;
  const InventoryStatus(this.code, this.label);

  static InventoryStatus fromCode(int code) {
    return InventoryStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => InventoryStatus.inPlace,
    );
  }
}

class InventoryItemDisplay {
  final String itemId;
  final int statusId;
  final String? locationTag;
  final String sourceDeviceId;
  final DateTime lastUpdated;
  final bool isSyncedToServer;

  const InventoryItemDisplay({
    required this.itemId,
    required this.statusId,
    required this.locationTag,
    required this.sourceDeviceId,
    required this.lastUpdated,
    required this.isSyncedToServer,
  });

  InventoryStatus get status => InventoryStatus.fromCode(statusId);

  /// Short display label for the item ID.
  String get shortId {
    if (itemId.startsWith('~')) return itemId; // placeholder
    return itemId.length > 16
        ? '${itemId.substring(0, 8)}…${itemId.substring(itemId.length - 6)}'
        : itemId;
  }

  InventoryItemDisplay copyWith({
    int? statusId,
    String? locationTag,
    String? sourceDeviceId,
    DateTime? lastUpdated,
    bool? isSyncedToServer,
  }) {
    return InventoryItemDisplay(
      itemId: itemId,
      statusId: statusId ?? this.statusId,
      locationTag: locationTag ?? this.locationTag,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSyncedToServer: isSyncedToServer ?? this.isSyncedToServer,
    );
  }

  factory InventoryItemDisplay.fromEvent(ItemUpdatedEvent e) =>
      InventoryItemDisplay(
        itemId: e.itemId,
        statusId: e.statusId,
        locationTag: e.locationTag,
        sourceDeviceId: e.sourceDeviceId,
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(e.timestampMs),
        isSyncedToServer: e.isSyncedToServer,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// StateNotifier
// ─────────────────────────────────────────────────────────────────────────────

class InventoryNotifier extends StateNotifier<List<InventoryItemDisplay>> {
  final Ref _ref;
  ProviderSubscription? _sub;

  InventoryNotifier(this._ref) : super([]) {
    _sub = _ref.listen<AsyncValue<ItemUpdatedEvent>>(
      itemUpdateStreamProvider,
      (_, next) {
        next.whenData(_onEvent);
      },
    );
  }

  void _onEvent(ItemUpdatedEvent event) {
    final updated = InventoryItemDisplay.fromEvent(event);
    final idx = state.indexWhere((i) => i.itemId == updated.itemId);
    if (idx >= 0) {
      // Update existing entry if the new event is more recent.
      if (updated.lastUpdated.isAfter(state[idx].lastUpdated)) {
        final newState = [...state];
        newState[idx] = updated;
        state = newState..sort(_byUpdated);
      }
    } else {
      state = ([...state, updated])..sort(_byUpdated);
    }
  }

  /// Sort by most recently updated first.
  static int _byUpdated(InventoryItemDisplay a, InventoryItemDisplay b) =>
      b.lastUpdated.compareTo(a.lastUpdated);

  /// Send a status update for an existing item.
  Future<void> updateStatus(String itemId, int newStatusId) async {
    final manager = await _ref.read(networkIsolateManagerProvider.future);
    manager.send(ScanItemCommand(
      itemId: itemId,
      statusId: newStatusId,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Scan / add a new item.
  Future<void> addItem({
    required String itemId,
    required int statusId,
    String? locationTag,
  }) async {
    if (itemId.trim().isEmpty) return;
    final manager = await _ref.read(networkIsolateManagerProvider.future);
    manager.send(ScanItemCommand(
      itemId: itemId.trim(),
      statusId: statusId,
      locationTag: locationTag?.trim().isEmpty == true ? null : locationTag?.trim(),
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, List<InventoryItemDisplay>>((ref) {
  return InventoryNotifier(ref);
});

/// Filtered view of the inventory list.
/// [filterStatus] = null means show all.
final inventoryFilterProvider = StateProvider<InventoryStatus?>((ref) => null);

final filteredInventoryProvider = Provider<List<InventoryItemDisplay>>((ref) {
  final all = ref.watch(inventoryProvider);
  final filter = ref.watch(inventoryFilterProvider);
  if (filter == null) return all;
  return all.where((i) => i.statusId == filter.code).toList();
});

