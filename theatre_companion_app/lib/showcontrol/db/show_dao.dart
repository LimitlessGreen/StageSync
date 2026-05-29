import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';

import '../../network/db/app_database.dart';
import '../grpc/generated/stagesync/v1/showcontrol.pb.dart' as pb;
import '../grpc/generated/stagesync/v1/common.pb.dart' as pb_common;

part 'show_dao.g.dart';

@DriftAccessor(tables: [ShowCueLists, ShowCues])
class ShowDao extends DatabaseAccessor<AppDatabase> with _$ShowDaoMixin {
  ShowDao(super.db);

  // ── CueList ───────────────────────────────────────────────────────────────

  Future<ShowCueList?> getCueList(String id) =>
      (select(showCueLists)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ShowCueList>> getAllCueLists(String sessionId) =>
      (select(showCueLists)..where((t) => t.sessionId.equals(sessionId))).get();

  Future<void> upsertCueList(pb.CueList proto) async {
    await into(showCueLists).insertOnConflictUpdate(ShowCueListsCompanion(
      id: Value(proto.cueListId),
      sessionId: const Value('local'),
      name: Value(proto.name),
      version: Value(proto.version.toInt()),
      updatedAtMs: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteCueList(String id) async {
    await (delete(showCues)..where((t) => t.cueListId.equals(id))).go();
    await (delete(showCueLists)..where((t) => t.id.equals(id))).go();
  }

  // ── Cues ─────────────────────────────────────────────────────────────────

  Future<List<ShowCue>> getCues(String cueListId) =>
      (select(showCues)
            ..where((t) => t.cueListId.equals(cueListId))
            ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
          .get();

  Future<void> upsertCue(String cueListId, pb.Cue proto, int orderIndex) async {
    await into(showCues).insertOnConflictUpdate(ShowCuesCompanion(
      id: Value(proto.cueId),
      cueListId: Value(cueListId),
      number: Value(proto.number),
      label: Value(proto.label),
      cueType: Value(proto.cueType.value),
      paramsJson: Value(_encodeParams(proto)),
      orderIndex: Value(orderIndex),
      targetNodeId: Value(proto.targetNodeId.isEmpty ? null : proto.targetNodeId),
      autoContinue: Value(proto.autoContinue),
      preWaitMs: Value(proto.preWaitMs),
      postWaitMs: Value(proto.postWaitMs),
      version: Value(proto.version.toInt()),
    ));
  }

  Future<void> deleteCue(String cueId) =>
      (delete(showCues)..where((t) => t.id.equals(cueId))).go();

  // ── Proto-Konvertierung ───────────────────────────────────────────────────

  Future<pb.CueList> loadAsCueListProto(String cueListId) async {
    final row = await getCueList(cueListId);
    final cueRows = await getCues(cueListId);

    final proto = pb.CueList()
      ..cueListId = cueListId
      ..name = row?.name ?? ''
      ..version = Int64(row?.version ?? 1);

    for (final c in cueRows) {
      proto.cues.add(_rowToProto(c));
    }
    return proto;
  }

  Future<void> saveCueListProto(pb.CueList proto) async {
    await upsertCueList(proto);
    for (var i = 0; i < proto.cues.length; i++) {
      await upsertCue(proto.cueListId, proto.cues[i], i);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  pb.Cue _rowToProto(ShowCue row) {
    final cue = pb.Cue()
      ..cueId = row.id
      ..number = row.number
      ..label = row.label
      ..cueType = pb_common.CueType.valueOf(row.cueType) ?? pb_common.CueType.CUE_TYPE_UNSPECIFIED
      ..autoContinue = row.autoContinue
      ..preWaitMs = row.preWaitMs
      ..postWaitMs = row.postWaitMs
      ..version = Int64(row.version);

    if (row.targetNodeId != null) cue.targetNodeId = row.targetNodeId!;
    _decodeParams(cue, row.paramsJson);
    return cue;
  }

  String _encodeParams(pb.Cue cue) {
    final params = switch (cue.whichParams()) {
      pb.Cue_Params.audio => {
          'type': 'audio',
          'filePath': cue.audio.filePath,
          'volumeDb': cue.audio.volumeDb,
          'fadeInMs': cue.audio.fadeInMs,
          'fadeOutMs': cue.audio.fadeOutMs,
          'loop': cue.audio.loop,
          'startTimeMs': cue.audio.startTimeMs,
          'endTimeMs': cue.audio.endTimeMs,
          'outputDevice': cue.audio.outputDevice,
        },
      pb.Cue_Params.maOsc => {
          'type': 'ma_osc',
          'oscAddress': cue.maOsc.oscAddress,
          'oscArgument': cue.maOsc.oscArgument,
          'executorPage': cue.maOsc.executorPage,
          'executorNo': cue.maOsc.executorNo,
          'command': cue.maOsc.command.value,
          'gotoCue': cue.maOsc.gotoCue,
        },
      pb.Cue_Params.wait => {'type': 'wait', 'durationMs': cue.wait.durationMs},
      pb.Cue_Params.gotoP => {
          'type': 'goto',
          'targetCueId': cue.gotoP.targetCueId,
          'targetNumber': cue.gotoP.targetNumber,
        },
      pb.Cue_Params.group => {
          'type': 'group',
          'childCueIds': cue.group.childCueIds.toList(),
          'sequential': cue.group.sequential,
        },
      pb.Cue_Params.notSet => {'type': 'none'},
    };
    return jsonEncode(params);
  }

  void _decodeParams(pb.Cue cue, String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    switch (map['type']) {
      case 'audio':
        cue.audio = pb.AudioCueParams()
          ..filePath = map['filePath'] ?? ''
          ..volumeDb = (map['volumeDb'] ?? 0.0).toDouble()
          ..fadeInMs = (map['fadeInMs'] ?? 0.0).toDouble()
          ..fadeOutMs = (map['fadeOutMs'] ?? 0.0).toDouble()
          ..loop = map['loop'] ?? false
          ..startTimeMs = (map['startTimeMs'] ?? 0.0).toDouble()
          ..endTimeMs = (map['endTimeMs'] ?? 0.0).toDouble()
          ..outputDevice = map['outputDevice'] ?? '';
      case 'ma_osc':
        cue.maOsc = pb.MaOscCueParams()
          ..oscAddress = map['oscAddress'] ?? ''
          ..oscArgument = map['oscArgument'] ?? ''
          ..executorPage = map['executorPage'] ?? 0
          ..executorNo = map['executorNo'] ?? 0
          ..command = pb.MaOscCueParams_MaCommand.valueOf(map['command'] ?? 0) ??
              pb.MaOscCueParams_MaCommand.MA_CMD_UNSPECIFIED
          ..gotoCue = map['gotoCue'] ?? 0;
      case 'wait':
        cue.wait = pb.WaitCueParams()..durationMs = (map['durationMs'] ?? 0.0).toDouble();
      case 'goto':
        cue.gotoP = pb.GotoCueParams()
          ..targetCueId = map['targetCueId'] ?? ''
          ..targetNumber = map['targetNumber'] ?? '';
    }
  }
}
