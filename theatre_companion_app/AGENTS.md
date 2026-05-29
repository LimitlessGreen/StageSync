# AGENTS.md – StageSync Companion App

**StageSync** is a Flutter P2P BLE-mesh app for theater inventory management.  
Devices form a leaderless mesh; the elected leader bridges to a central server.

---

## Architecture Overview

```
UI (Main Isolate)                    Network (Background Isolate)
─────────────────                    ────────────────────────────
networkIsolateManagerProvider  ──►  NetworkIsolateManager._initNative()
  Riverpod FutureProvider              │
  (providers/network_state_provider)   ▼
                                NetworkRepositoryWeaver  ←─ coordinator of all routing
                                  ├─ BleMeshService / GossipEngine  (BLE P2P)
                                  ├─ WebSocketService               (leader ↔ server)
                                  ├─ CloudConnectService            (Socket.IO)
                                  ├─ LeaderElectionEngine           (score-based election)
                                  └─ Drift DAOs (InventoryDao, ChatDao, PacketQueueDao)
```

**Web platform**: uses synchronous `NetworkRepositoryWeaver` on the main isolate with in-memory `_WebNoOp*` DAO stubs (no SQLite, no native BLE).  
**Native (Android/iOS)**: spawns a background isolate via `Isolate.spawn`; uses real Drift/SQLite and `BleMeshService`.

---

## Cross-Isolate Message Protocol

All communication between isolates uses **sealed classes** in `lib/network/isolate/isolate_messages.dart`:

- `NetworkCommand` → UI sends to network isolate (e.g. `ScanItemCommand`, `CloudConnectCommand`, `ShutdownCommand`)
- `NetworkEvent` ← network isolate emits to UI (e.g. `ItemUpdatedEvent`, `NetworkStatusEvent`, `LeaderChangedEvent`)

**Never** add raw maps or primitives to this protocol – always extend the sealed hierarchy.

---

## Key Data Flow: Inventory Scan

1. UI calls `ref.read(networkIsolateManagerProvider.notifier).send(ScanItemCommand(...))`
2. `NetworkRepositoryWeaver.handleCommand` → `_handleScanItem`
3. CRDT is persisted to SQLite **before** any network op (ACID guarantee)
4. If leader & server connected → `WebSocketService.send(encrypted)`; else → `GossipEngine.originateDataPacket` (BLE mesh relay)
5. `ItemUpdatedEvent` is emitted back to UI immediately

---

## CRDT Model

`lib/network/models/inventory_item_crdt.dart` – LWW-Element-Set per field:
- Each mutable field (`status`, `location`) is a `LwwField<T>` with its own `VectorClock`
- Conflict resolution: causal order → wall-clock → `ownerShortId` (deterministic tiebreaker)
- Compact BLE packets carry only `itemShortId` (16-bit hash of UUID), not the full UUID; CRDT merge only happens if the item is already known locally

---

## Riverpod State Management

Providers live in `lib/ui/providers/`:
- `deviceIdProvider` – UUID persisted in `SharedPreferences` (generated once)
- `networkIsolateManagerProvider` – boots sequence: deviceId → permissions → isolate start → auto-connect cloud
- `networkEventStreamProvider` – raw `Stream<NetworkEvent>` from the isolate
- Derived providers filter the stream by event type: `networkStatusProvider`, `itemUpdateStreamProvider`, `chatEventStreamProvider`

Pattern for sending from a widget:
```dart
ref.read(networkIsolateManagerProvider.notifier).send(ScanItemCommand(...));
```

---

## Database (Drift / SQLite)

- Schema: `lib/network/db/app_database.dart` – tables `InventoryItems`, `PacketQueue`, `ChatMessages`
- Generated file: `app_database.g.dart` – **must regenerate after schema changes**:
  ```
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- DAOs are in `lib/network/db/dao/`; each DAO method is an interface (also has a `_WebNoOp*` in-memory implementation for web)

---

## Build & Test Commands

```bash
# Run app (debug)
flutter run

# Regenerate Drift code after DB schema changes
flutter pub run build_runner build --delete-conflicting-outputs

# Run all tests
flutter test

# Run a specific test file
flutter test test/network/coordinator/network_repository_weaver_test.dart
```

---

## Testing Conventions

- Use **mocktail** (`Mock`) for all service dependencies; `FakeBleService` injects packets via a `StreamController`
- Helper `makeTestCrdt(...)` and `inventoryItemFromCrdt(...)` in the weaver test are the canonical test-object factories
- Tests live in `test/network/` mirroring `lib/network/` directory structure

---

## Platform Abstraction

- `AbstractBleService` (`lib/network/platform/abstract_ble_service.dart`) is the BLE interface
- `BleMeshService` = real implementation (Android/iOS only)
- `StubBleService` = no-op fallback (desktop, web, BLE-permission denied)
- `PlatformCapabilities.detect()` + `PermissionService.requestAll()` determine which is used at runtime; permissions must be requested on the **main isolate before** the network isolate starts

---

## Key Files Reference

| File | Role |
|---|---|
| `lib/network/isolate/isolate_messages.dart` | Full cross-isolate protocol |
| `lib/network/isolate/network_isolate_manager.dart` | Isolate bridge + web fallback |
| `lib/network/coordinator/network_repository_weaver.dart` | Central routing coordinator |
| `lib/network/models/inventory_item_crdt.dart` | LWW-CRDT implementation |
| `lib/network/db/app_database.dart` | Drift schema (edit → rebuild) |
| `lib/ui/providers/network_state_provider.dart` | All Riverpod providers |
| `lib/main.dart` | Bootstrap sequence |

