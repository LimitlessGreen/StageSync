import 'package:meta/meta.dart';

import '../nodes/audio_node/audio_device.dart';

enum NodeHealthPhase { online, reconnecting, offline, degraded }

/// Audition/preview capability of a node.
///
/// This is a NODE-LOCAL capability — not part of the authoritative show state.
/// The server never writes or modifies this; the node self-reports it on
/// [RegisterNode].
@immutable
class AuditionCapability {
  final bool supported;
  final String? deviceName; // e.g. "Headphones", "Kopfhörer"
  final int? deviceIndex;

  const AuditionCapability({
    required this.supported,
    this.deviceName,
    this.deviceIndex,
  });

  static const AuditionCapability none = AuditionCapability(supported: false);
}

@immutable
class NodeStatus {
  final String nodeId;
  final String name;

  /// String task codes: 'master', 'audio', 'editor', 'viewer', 'ma_osc'.
  final List<String> tasks;

  final NodeHealthPhase health;

  /// Measured offset in ms against the server clock (from heartbeat NTP-style).
  final int? clockDeltaMs;

  final AuditionCapability audition;

  /// Audio output devices reported by this node via NodeCapabilities.
  /// Empty for nodes that have no audio capability or haven't reported yet.
  final List<AudioDevice> availableDevices;

  /// Currently selected output device index as reported by the node.
  final int? selectedDeviceIndex;

  /// Currently active audio backend (e.g. jack/alsa/wasapi).
  final AudioBackend? activeBackend;

  /// Backend fallback order configured on the node.
  final List<AudioBackend> backendPriority;

  /// Current runtime sample rate in Hz. Null when the node does not report it.
  final int? sampleRate;

  /// Current runtime channel count. Null when the node does not report it.
  final int? channels;

  const NodeStatus({
    required this.nodeId,
    required this.name,
    required this.tasks,
    required this.health,
    this.clockDeltaMs,
    this.audition = AuditionCapability.none,
    this.availableDevices = const [],
    this.selectedDeviceIndex,
    this.activeBackend,
    this.backendPriority = const [],
    this.sampleRate,
    this.channels,
  });

  AudioDevice? get selectedAudioDevice {
    if (selectedDeviceIndex == null) return null;
    for (final device in availableDevices) {
      if (device.index == selectedDeviceIndex) return device;
    }
    return null;
  }

  bool get isOnline =>
      health == NodeHealthPhase.online || health == NodeHealthPhase.degraded;
  bool get isAudio => tasks.contains('audio');
  bool get isMaNode => tasks.contains('ma_osc');
  bool get isMaster => tasks.contains('master');
  bool get isEditor => tasks.contains('editor');

  NodeStatus copyWith({
    String? nodeId,
    String? name,
    List<String>? tasks,
    NodeHealthPhase? health,
    int? clockDeltaMs,
    AuditionCapability? audition,
    List<AudioDevice>? availableDevices,
    int? selectedDeviceIndex,
    AudioBackend? activeBackend,
    List<AudioBackend>? backendPriority,
    int? sampleRate,
    int? channels,
  }) =>
      NodeStatus(
        nodeId: nodeId ?? this.nodeId,
        name: name ?? this.name,
        tasks: tasks ?? this.tasks,
        health: health ?? this.health,
        clockDeltaMs: clockDeltaMs ?? this.clockDeltaMs,
        audition: audition ?? this.audition,
        availableDevices: availableDevices ?? this.availableDevices,
        selectedDeviceIndex: selectedDeviceIndex ?? this.selectedDeviceIndex,
        activeBackend: activeBackend ?? this.activeBackend,
        backendPriority: backendPriority ?? this.backendPriority,
        sampleRate: sampleRate ?? this.sampleRate,
        channels: channels ?? this.channels,
      );
}
