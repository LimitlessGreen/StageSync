import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/grid.pb.dart';
import 'session_provider.dart';

/// Dekodierte Waveform: min/max-Paare als normalisierte Werte (-1..1).
class WaveformData {
  /// Länge = Anzahl Buckets. mins[i]/maxs[i] sind die Hüllkurven-Extrema.
  final Float32List mins;
  final Float32List maxs;
  final double durationMs;

  const WaveformData({
    required this.mins,
    required this.maxs,
    required this.durationMs,
  });

  int get buckets => mins.length;
  bool get isEmpty => mins.isEmpty;

  static final empty =
      WaveformData(mins: Float32List(0), maxs: Float32List(0), durationMs: 0);
}

/// Lädt die server-seitig berechneten Peaks für ein Asset (gecacht via Riverpod).
final waveformProvider =
    FutureProvider.family<WaveformData, String>((ref, assetId) async {
  if (assetId.isEmpty) return WaveformData.empty;
  final session = ref.read(sessionProvider);
  if (!session.isInSession) return WaveformData.empty;

  final req = WaveformRequest()
    ..sessionId = session.session!.sessionId
    ..token = session.token!
    ..assetId = assetId
    ..buckets = 2000;

  final builder = BytesBuilder();
  double durationMs = 0;
  await for (final chunk in StageSyncClient.instance.grid.getWaveform(req)) {
    builder.add(chunk.data);
    if (chunk.durationMs != 0) durationMs = chunk.durationMs;
  }

  final bytes = builder.toBytes();
  // Interleaved int16 LE: [min0, max0, min1, max1, ...]
  final pairs = bytes.length ~/ 4;
  final mins = Float32List(pairs);
  final maxs = Float32List(pairs);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < pairs; i++) {
    final mn = view.getInt16(i * 4, Endian.little);
    final mx = view.getInt16(i * 4 + 2, Endian.little);
    mins[i] = mn / 32767.0;
    maxs[i] = mx / 32767.0;
  }
  return WaveformData(mins: mins, maxs: maxs, durationMs: durationMs);
});

/// Niedrig aufgelöste Peaks für den Waveform-Ghost im Cue-Listen-Row.
/// 300 Buckets reichen für die Zeilenhöhe (48-80 px) vollständig aus und
/// werden vom Server separat gecacht — unabhängig vom Inspector-Provider.
final waveformGhostProvider =
    FutureProvider.family<WaveformData, String>((ref, assetId) async {
  if (assetId.isEmpty) return WaveformData.empty;
  final session = ref.read(sessionProvider);
  if (!session.isInSession) return WaveformData.empty;

  final req = WaveformRequest()
    ..sessionId = session.session!.sessionId
    ..token = session.token!
    ..assetId = assetId
    ..buckets = 300;

  final builder = BytesBuilder();
  double durationMs = 0;
  await for (final chunk in StageSyncClient.instance.grid.getWaveform(req)) {
    builder.add(chunk.data);
    if (chunk.durationMs != 0) durationMs = chunk.durationMs;
  }

  final bytes = builder.toBytes();
  final pairs = bytes.length ~/ 4;
  final mins = Float32List(pairs);
  final maxs = Float32List(pairs);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i < pairs; i++) {
    final mn = view.getInt16(i * 4, Endian.little);
    final mx = view.getInt16(i * 4 + 2, Endian.little);
    mins[i] = mn / 32767.0;
    maxs[i] = mx / 32767.0;
  }
  return WaveformData(mins: mins, maxs: maxs, durationMs: durationMs);
});
