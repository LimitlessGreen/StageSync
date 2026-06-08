import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart'
    as pb;
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/common.pb.dart'
    as pb_common;
import 'package:theatre_companion_app/showcontrol/infrastructure/grpc/show_control_repository.dart';
import 'package:theatre_companion_app/showcontrol/domain/show.dart';
import 'package:theatre_companion_app/showcontrol/domain/cue_params.dart';
import 'package:theatre_companion_app/showcontrol/domain/patch_config.dart';
import 'package:theatre_companion_app/showcontrol/domain/node_status.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

pb.Cue _audioCueProto({
  String id = 'cue-1',
  String number = '1',
  String label = 'Intro',
  String assetId = 'sha256abc',
  double volumeDb = -6.0,
  double fadeInMs = 500,
  double fadeOutMs = 1000,
  bool loop = false,
  double startTimeMs = 0,
  double endTimeMs = 30000,
  String logicalOutputId = 'main-lr',
}) {
  return pb.Cue()
    ..cueId = id
    ..number = number
    ..label = label
    ..logicalOutputId = logicalOutputId
    ..audio = (pb.AudioCueParams()
      ..assetId = assetId
      ..volumeDb = volumeDb
      ..fadeInMs = fadeInMs
      ..fadeOutMs = fadeOutMs
      ..loop = loop
      ..startTimeMs = startTimeMs
      ..endTimeMs = endTimeMs);
}

pb.Cue _waitCueProto({String id = 'cue-w', double durationMs = 2000}) {
  return pb.Cue()
    ..cueId = id
    ..number = '2'
    ..label = 'Wait'
    ..wait = (pb.WaitCueParams()..durationMs = durationMs);
}

pb.Cue _maOscCueProto() {
  return pb.Cue()
    ..cueId = 'cue-ma'
    ..number = '3'
    ..label = 'MA Cue'
    ..maOsc = (pb.MaOscCueParams()
      ..oscAddress = '/ma2/cmd'
      ..oscArgument = 'GO'
      ..executorPage = 1
      ..executorNo = 101
      ..command = pb.MaOscCueParams_MaCommand.MA_CMD_GO
      ..gotoCue = 5);
}

pb.Cue _gotoCueProto() {
  return pb.Cue()
    ..cueId = 'cue-goto'
    ..number = '4'
    ..label = 'Goto'
    ..gotoP = (pb.GotoCueParams()
      ..targetCueId = 'cue-1'
      ..targetNumber = '1');
}

pb.Cue _groupCueProto() {
  return pb.Cue()
    ..cueId = 'cue-grp'
    ..number = '5'
    ..label = 'Group'
    ..group = (pb.GroupCueParams()
      ..childCueIds.addAll(['cue-1', 'cue-w'])
      ..sequential = true);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── cueFromProto — AudioParams ────────────────────────────────────────────

  group('cueFromProto — AudioParams', () {
    test('maps all basic fields', () {
      final cue = ShowControlRepository.cueFromProto(_audioCueProto());
      expect(cue.id, 'cue-1');
      expect(cue.number, '1');
      expect(cue.label, 'Intro');
      expect(cue.params, isA<AudioParams>());
    });

    test('assetId from proto.audio.assetId', () {
      final cue = ShowControlRepository.cueFromProto(
          _audioCueProto(assetId: 'sha256abc'));
      expect((cue.params as AudioParams).assetId, 'sha256abc');
    });

    test('assetId falls back to basename(filePath) when assetId is empty', () {
      final proto = pb.Cue()
        ..cueId = 'c'
        ..number = '1'
        ..label = 'L'
        ..audio = (pb.AudioCueParams()
          ..assetId = ''
          ..filePath = '/media/intro.wav');
      final cue = ShowControlRepository.cueFromProto(proto);
      expect((cue.params as AudioParams).assetId, 'intro.wav');
    });

    test('maps volumeDb, fadeInMs, fadeOutMs', () {
      final cue = ShowControlRepository.cueFromProto(
          _audioCueProto(volumeDb: -12, fadeInMs: 200, fadeOutMs: 500));
      final p = cue.params as AudioParams;
      expect(p.volumeDb, -12);
      expect(p.fadeInMs, 200);
      expect(p.fadeOutMs, 500);
    });

    test('maps loop flag', () {
      final cue =
          ShowControlRepository.cueFromProto(_audioCueProto(loop: true));
      expect((cue.params as AudioParams).loop, isTrue);
    });

    test('logicalOutputId taken from proto.logicalOutputId', () {
      final cue = ShowControlRepository.cueFromProto(
          _audioCueProto(logicalOutputId: 'surround'));
      expect(cue.logicalOutputId, 'surround');
    });

    test(
        'logicalOutputId falls back to targetNodeId when logicalOutputId empty',
        () {
      final proto = pb.Cue()
        ..cueId = 'c'
        ..number = '1'
        ..label = 'L'
        ..logicalOutputId = ''
        ..targetNodeId = 'node-fallback'
        ..audio = (pb.AudioCueParams()..assetId = 'x');
      final cue = ShowControlRepository.cueFromProto(proto);
      expect(cue.logicalOutputId, 'node-fallback');
    });

    test('logicalOutputId is null when both fields empty', () {
      final proto = pb.Cue()
        ..cueId = 'c'
        ..number = '1'
        ..label = 'L'
        ..audio = (pb.AudioCueParams()..assetId = 'x');
      final cue = ShowControlRepository.cueFromProto(proto);
      expect(cue.logicalOutputId, isNull);
    });

    test('timing fields mapped correctly', () {
      final proto = _audioCueProto()
        ..preWaitMs = 100
        ..postWaitMs = 200
        ..autoContinue = true;
      final cue = ShowControlRepository.cueFromProto(proto);
      expect(cue.timing.preWaitMs, 100);
      expect(cue.timing.postWaitMs, 200);
      expect(cue.timing.autoContinue, isTrue);
    });
  });

  // ── cueFromProto — WaitParams ─────────────────────────────────────────────

  group('cueFromProto — WaitParams', () {
    test('maps durationMs', () {
      final cue =
          ShowControlRepository.cueFromProto(_waitCueProto(durationMs: 5000));
      expect(cue.params, isA<WaitParams>());
      expect((cue.params as WaitParams).durationMs, 5000);
    });

    test('durationMs set in timing', () {
      final cue = ShowControlRepository.cueFromProto(_waitCueProto());
      expect(cue.timing.durationMs, 2000);
    });
  });

  // ── cueFromProto — MaOscParams ────────────────────────────────────────────

  group('cueFromProto — MaOscParams', () {
    test('maps all ma_osc fields', () {
      final cue = ShowControlRepository.cueFromProto(_maOscCueProto());
      expect(cue.params, isA<MaOscParams>());
      final p = cue.params as MaOscParams;
      expect(p.oscAddress, '/ma2/cmd');
      expect(p.executorPage, 1);
      expect(p.executorNo, 101);
      expect(p.command, MaOscCommand.go);
      expect(p.gotoCue, 5.0);
    });
  });

  // ── cueFromProto — GotoParams ─────────────────────────────────────────────

  group('cueFromProto — GotoParams', () {
    test('maps targetCueId and targetNumber', () {
      final cue = ShowControlRepository.cueFromProto(_gotoCueProto());
      expect(cue.params, isA<GotoParams>());
      final p = cue.params as GotoParams;
      expect(p.targetCueId, 'cue-1');
      expect(p.targetNumber, '1');
    });
  });

  // ── cueFromProto — GroupParams ────────────────────────────────────────────

  group('cueFromProto — GroupParams', () {
    test('maps childCueIds and sequential flag', () {
      final cue = ShowControlRepository.cueFromProto(_groupCueProto());
      expect(cue.params, isA<GroupParams>());
      final p = cue.params as GroupParams;
      expect(p.childCueIds, ['cue-1', 'cue-w']);
      expect(p.sequential, isTrue);
    });
  });

  // ── cueListFromProto ──────────────────────────────────────────────────────

  group('cueListFromProto', () {
    test('maps id, name, and all cues', () {
      final proto = pb.CueList()
        ..cueListId = 'list-1'
        ..name = 'Act 1'
        ..cues.addAll([_audioCueProto(), _waitCueProto()]);
      final list = ShowControlRepository.cueListFromProto(proto);
      expect(list.id, 'list-1');
      expect(list.name, 'Act 1');
      expect(list.cues, hasLength(2));
      expect(list.cues[0].params, isA<AudioParams>());
      expect(list.cues[1].params, isA<WaitParams>());
    });

    test('empty cue list', () {
      final proto = pb.CueList()
        ..cueListId = 'l'
        ..name = 'Empty';
      expect(ShowControlRepository.cueListFromProto(proto).cues, isEmpty);
    });
  });

  // ── cueToProto roundtrip ──────────────────────────────────────────────────

  group('cueToProto — roundtrip', () {
    test('AudioCue roundtrip preserves all fields', () {
      final original = ShowControlRepository.cueFromProto(_audioCueProto(
        assetId: 'sha256roundtrip',
        volumeDb: -3,
        fadeInMs: 100,
        fadeOutMs: 200,
        loop: true,
        startTimeMs: 500,
        endTimeMs: 10000,
        logicalOutputId: 'monitor',
      ));
      final proto = ShowControlRepository.cueToProto(original);
      final roundtripped = ShowControlRepository.cueFromProto(proto);

      expect(roundtripped.id, original.id);
      expect(roundtripped.label, original.label);
      expect(roundtripped.logicalOutputId, original.logicalOutputId);
      final p = roundtripped.params as AudioParams;
      expect(p.assetId, 'sha256roundtrip');
      expect(p.volumeDb, -3);
      expect(p.fadeInMs, 100);
      expect(p.fadeOutMs, 200);
      expect(p.loop, isTrue);
    });

    test('WaitCue roundtrip preserves durationMs', () {
      final original =
          ShowControlRepository.cueFromProto(_waitCueProto(durationMs: 3500));
      final proto = ShowControlRepository.cueToProto(original);
      final rt = ShowControlRepository.cueFromProto(proto);
      expect((rt.params as WaitParams).durationMs, 3500);
    });

    test('GotoCue roundtrip preserves targetCueId', () {
      final original = ShowControlRepository.cueFromProto(_gotoCueProto());
      final proto = ShowControlRepository.cueToProto(original);
      final rt = ShowControlRepository.cueFromProto(proto);
      expect((rt.params as GotoParams).targetCueId, 'cue-1');
    });
  });

  // ── patchConfigFromProto ──────────────────────────────────────────────────

  group('patchConfigFromProto', () {
    test('maps logicalOutputs', () {
      final proto = pb.PatchConfig()
        ..logicalOutputs.add(pb.PatchLogicalOutput()
          ..id = 'main-lr'
          ..name = 'Main L/R');
      final config = ShowControlRepository.patchConfigFromProto(proto);
      expect(config.logicalOutputs, hasLength(1));
      expect(config.logicalOutputs.first.id, 'main-lr');
      expect(config.logicalOutputs.first.name, 'Main L/R');
    });

    test('maps nodePatches', () {
      final proto = pb.PatchConfig()
        ..nodeAssigns.add(pb.PatchNodeAssign()
          ..logicalOutputId = 'main-lr'
          ..nodeIds.addAll(['node-1', 'node-2']));
      final config = ShowControlRepository.patchConfigFromProto(proto);
      expect(config.nodePatches.first.nodeIds, ['node-1', 'node-2']);
    });

    test('maps devicePatches', () {
      final proto = pb.PatchConfig()
        ..deviceAssigns.add(pb.PatchDeviceAssign()
          ..logicalOutputId = 'main-lr'
          ..nodeId = 'node-1'
          ..deviceIndex = 2
          ..deviceName = 'ASIO Out 1-2');
      final config = ShowControlRepository.patchConfigFromProto(proto);
      final dp = config.devicePatches.first;
      expect(dp.deviceIndex, 2);
      expect(dp.deviceName, 'ASIO Out 1-2');
    });

    test('patchConfig roundtrip via patchConfigToProto', () {
      final original = PatchConfig(
        logicalOutputs: const [LogicalOutput(id: 'main', name: 'Main')],
        nodePatches: const [
          NodePatch(logicalOutputId: 'main', nodeIds: ['n1'])
        ],
        devicePatches: const [
          DevicePatch(
              logicalOutputId: 'main',
              nodeId: 'n1',
              deviceIndex: 0,
              deviceName: 'ASIO')
        ],
      );
      final proto = ShowControlRepository.patchConfigToProto(original);
      final rt = ShowControlRepository.patchConfigFromProto(proto);
      expect(rt.logicalOutputs.first.id, 'main');
      expect(rt.nodePatches.first.nodeIds, ['n1']);
      expect(rt.devicePatches.first.deviceName, 'ASIO');
    });
  });

  // ── nodeStatusesFromNodes ─────────────────────────────────────────────────

  group('nodeStatusesFromNodes', () {
    pb_common.NodeInfo _nodeInfo(
        {required String id,
        required String name,
        bool online = true,
        List<pb_common.NodeTask> tasks = const []}) {
      return pb_common.NodeInfo()
        ..nodeId = id
        ..name = name
        ..online = online
        ..tasks.addAll(tasks);
    }

    test('online node → NodeHealthPhase.online', () {
      final nodes = [_nodeInfo(id: 'n1', name: 'Audio', online: true)];
      final statuses = ShowControlRepository.nodeStatusesFromNodes(nodes, true);
      expect(statuses.first.health, NodeHealthPhase.online);
    });

    test('offline node → NodeHealthPhase.offline', () {
      final nodes = [_nodeInfo(id: 'n1', name: 'Audio', online: false)];
      final statuses = ShowControlRepository.nodeStatusesFromNodes(nodes, true);
      expect(statuses.first.health, NodeHealthPhase.offline);
    });

    test('session disconnected → NodeHealthPhase.reconnecting for all', () {
      final nodes = [
        _nodeInfo(id: 'n1', name: 'A', online: true),
        _nodeInfo(id: 'n2', name: 'B', online: false),
      ];
      final statuses =
          ShowControlRepository.nodeStatusesFromNodes(nodes, false);
      expect(statuses.every((s) => s.health == NodeHealthPhase.reconnecting),
          isTrue);
    });

    test('maps task value 2 → "audio"', () {
      final nodes = [
        _nodeInfo(
            id: 'n1',
            name: 'A',
            tasks: [pb_common.NodeTask.NODE_TASK_AUDIO_OUTPUT])
      ];
      final statuses = ShowControlRepository.nodeStatusesFromNodes(nodes, true);
      expect(statuses.first.tasks, contains('audio'));
    });

    test('maps task value 1 → "master"', () {
      final tasks = ShowControlRepository.tasksFromProto(
          [pb_common.NodeTask.NODE_TASK_MASTER]);
      expect(tasks, contains('master'));
    });

    test('empty nodes list returns empty', () {
      expect(ShowControlRepository.nodeStatusesFromNodes([], true), isEmpty);
    });
  });
}
