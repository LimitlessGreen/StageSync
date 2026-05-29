# AGENTS.md – StageSync Companion App

**StageSync** is a Flutter + Go system for theater show control.  
The Go server (`../stagesync-server`) is the single authority for all show state.  
Flutter clients are Operators (desktop) or Viewers/Remotes (mobile); they send commands and receive state via gRPC.

---

## Repository Layout

```
Companion-App/
├── stagesync-server/          # Go gRPC server — single source of truth
│   ├── cmd/server/main.go
│   ├── internal/
│   │   ├── grpc/              # gRPC handlers (session, showcontrol, node)
│   │   ├── showcontrol/       # ShowEngine: playhead, cue execution
│   │   ├── session/           # SessionManager, NodeRegistry, ClockSync
│   │   ├── node/              # NodeDispatcher, Capability checks
│   │   └── media/             # Content-addressable MediaStore (SHA-256)
│   └── proto/stagesync/v1/    # Protobuf definitions (source of truth)
└── theatre_companion_app/     # Flutter multi-platform client
    ├── lib/showcontrol/
    │   ├── domain/            # Immutable Dart domain models (no proto types)
    │   ├── infrastructure/    # gRPC repos, MediaSync, DB DAOs
    │   ├── nodes/             # AudioNodeService (SoLoud), MaNodeService (OSC)
    │   ├── providers/         # Riverpod notifiers/providers
    │   ├── session/           # ClockSync, SessionService
    │   └── ui/                # Design system + screens + shell
    └── test/showcontrol/      # Unit & integration tests mirror lib/showcontrol/
```

---

## Architecture Overview

```
Flutter UI (main isolate)
  └─ Riverpod Providers
       ├─ ShowControlProvider  ──► ShowControlNotifier (domain state)
       ├─ SessionProvider      ──► SessionService (clock-sync, heartbeat)
       ├─ AudioNodeProvider    ──► AudioNodeService (SoLoud, MediaSync)
       └─ NodeManagementProvider

ShowControlNotifier
  └─ ShowControlRepository (infrastructure/grpc/)
       ├─ StageSyncClient      ──► gRPC Channel + Stubs (long-lived, one per session)
       ├─ DefinitionStream     ──► ShowDefinitionEvent (cues, patch, assets)
       ├─ ExecutionStream      ──► ShowExecutionEvent (playhead, cue run states)
       ├─ HealthStream         ──► NodeHealthEvent
       └─ MediaSyncStream      ──► MediaSyncEvent

Go Server (stagesync-server)
  └─ gRPC Services
       ├─ SessionService       — register node, heartbeat, clock
       ├─ ShowControlService   — GO / STOP / PAUSE / RESUME (role-checked)
       └─ NodeService          — WatchNodes, SendNodeCommand
```

**Go server is the single master**: all show-state mutations happen there.  
Flutter clients are command senders and state receivers only — no client-side authority.

---

## Domain Model (Flutter-side)

Proto types are the transport format only. Flutter uses its own **immutable Dart classes** in `lib/showcontrol/domain/`:

| File | Contents |
|---|---|
| `show.dart` | `Show`, `CueList`, `Cue` (immutable + `copyWith`) |
| `cue_params.dart` | `sealed CueParams` hierarchy (`AudioParams`, `WaitParams`, …) |
| `cue_trigger.dart` | `CueTrigger` sealed |
| `playhead.dart` | `PlayheadState`, `CueRunState`, `NodeExecState` |
| `patch_config.dart` | 4-layer model (CueBus → NodePatch → DevicePatch → AuditionBus) |
| `asset.dart` | `Asset`, `AudioMetadata`, `AssetReadiness` (4-level enum) |
| `node_status.dart` | `NodeStatus`, `AuditionCapability` |

`ShowControlRepository` (`infrastructure/grpc/show_control_repository.dart`) is the **only** place that converts between proto types and domain types.

---

## gRPC Channel Strategy

- One `ClientChannel` per session, reused for all stubs.
- **4 long-lived server streams**: Definition, Execution, Health, MediaSync.
- On stream error: **only that stream** is cancelled and rebuilt — the channel stays up.
- On full disconnect (3 heartbeat failures): exponential backoff 1 s → 30 s, then all 4 streams rebuild from snapshot.

---

## Roles & Permissions

Role enforcement is **always on the server**. Flutter only shows/hides buttons as UX convenience.

| Role | Can send |
|---|---|
| `NODE_TASK_MASTER` / `NODE_TASK_EDITOR` | GO, STOP, PAUSE, RESUME, SendNodeCommand |
| `NODE_TASK_VIEWER` | read-only; no transport commands |

---

## Audio Node

`AudioNodeService` (`nodes/audio_node/`) runs SoLoud and handles:
- `AudioPlayCommand` from server (server-synced timestamp)
- `MediaSync` — lazy pull of assets by SHA-256 from server HTTP API
- `auditionPlay()` — local preview, isolated handle, no server roundtrip, no show-state impact

`AbstractAudioEngine` is the testable interface; `SoLoudAudioEngine` is the real implementation.

---

## Key Data Flows

### GO command
1. `TransportBar` → `ref.read(showControlProvider.notifier).go()`
2. `ShowControlNotifier` calls `ShowControlRepository.sendGo(commandId, cueId)`
3. Repository sends gRPC `GoRequest` (with UUID `commandId` for server-side deduplication)
4. Server executes, sends `ShowExecutionEvent` on Execution stream
5. `ShowControlNotifier` updates `PlayheadState` → UI rebuilds

### Audio playback
1. Server sends `AudioPlayCommand` on Node-Command stream to AudioNode
2. `AudioNodeService` ensures file is local (lazy fetch via `MediaSync`)
3. SoLoud plays at server-anchored timestamp

---

## Build & Test Commands

```bash
# Flutter app (debug)
flutter run

# All tests
flutter test

# Tests for a specific area
flutter test test/showcontrol/

# Regenerate gRPC Dart stubs (after proto changes)
# Run from stagesync-server/: make gen
# Then copy generated files to lib/showcontrol/grpc/generated/

# Regenerate Drift DB code (after schema changes)
flutter pub run build_runner build --delete-conflicting-outputs
```

Go server:
```bash
# Run server
cd ../stagesync-server && go run ./cmd/server

# Run Go tests
cd ../stagesync-server && go test ./...

# Regenerate proto (Go + Dart)
cd ../stagesync-server && make gen
```

---

## Testing Conventions

### Flutter
- Mirror `lib/showcontrol/` structure under `test/showcontrol/`.
- Every new feature or significant refactor ships with tests.
- Use **mocktail** for service dependencies.
- `AbstractAudioEngine` / other abstract interfaces allow engine-free unit tests.
- For domain model tests: pure Dart — no Flutter framework needed, fast to run.
- For notifier tests: use `ProviderContainer` + mocked repositories.

### Go
- Unit tests live next to the file they test (`_test.go`).
- Integration tests that hit real gRPC go in `internal/*/integration_test.go`.
- Use `testify/assert` and `testify/mock`.

---

## Design System

```
lib/showcontrol/ui/design_system/
├── sc_colors.dart       # ScColors — state colors (active/warn/error/idle)
├── sc_typography.dart   # ScText — mono/label/number/status/title
├── sc_spacing.dart      # ScSpacing — row heights, panel padding
├── sc_theme.dart        # ThemeData for ShowControl
├── primitives/          # No domain knowledge — pure layout/style widgets
│   └── sc_button, sc_chip, sc_inline_field, sc_meter, sc_panel, sc_split_view
└── domain_components/   # Know domain types, not proto/gRPC
    └── cue_list_row, transport_bar, node_status_badge, active_cue_monitor,
        patch_matrix, audio_cue_minibar, level_meter
```

Widgets never contain gRPC or proto imports. Business logic lives in notifiers/repositories.

---

## Key Files Reference

| File | Role |
|---|---|
| `stagesync-server/internal/showcontrol/engine.go` | Authoritative show-state machine |
| `stagesync-server/internal/grpc/showcontrol_handler.go` | GO/STOP/PAUSE gRPC handlers |
| `lib/showcontrol/grpc/stage_sync_client.dart` | Long-lived gRPC channel + stubs |
| `lib/showcontrol/infrastructure/grpc/show_control_repository.dart` | Proto ↔ domain mapper |
| `lib/showcontrol/providers/show_control_provider.dart` | Main Riverpod notifier |
| `lib/showcontrol/providers/show_control_domain_provider.dart` | Domain state providers |
| `lib/showcontrol/nodes/audio_node/audio_node_service.dart` | SoLoud + MediaSync integration |
| `lib/showcontrol/ui/shell/sc_adaptive_shell.dart` | Keyboard-first adaptive shell |

---

## BLE / Inventory Module (separate feature)

The original BLE mesh inventory feature still exists in `lib/network/` and `test/network/`.  
Its architecture is documented separately in the network module's own provider/service files.  
ShowControl and BLE/Inventory are independent — they do not share providers or state.
