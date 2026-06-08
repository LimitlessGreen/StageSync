import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/showcontrol.pb.dart';
import 'session_provider.dart';

/// Erkannter Stille-Offset (ms) für ein Audio-Asset, oder null wenn noch
/// nicht preloaded / kein interner Audio-Node aktiv.
///
/// Nur verfügbar nachdem der Server das Asset einmal vorgeladen hat.
final assetSilenceProvider =
    FutureProvider.family<double?, String>((ref, assetId) async {
  if (assetId.isEmpty) return null;
  final session = ref.read(sessionProvider);
  if (!session.isInSession) return null;

  final req = GetAssetSilenceInfoRequest()
    ..sessionId = session.session!.sessionId
    ..token = session.token!
    ..assetId = assetId;

  final resp =
      await StageSyncClient.instance.showControl.getAssetSilenceInfo(req);
  if (!resp.detected) return null;
  return resp.silenceMs.toDouble();
});
