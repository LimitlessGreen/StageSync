// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _crdtJsonMeta =
      const VerificationMeta('crdtJson');
  @override
  late final GeneratedColumn<String> crdtJson = GeneratedColumn<String>(
      'crdt_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusIdMeta =
      const VerificationMeta('statusId');
  @override
  late final GeneratedColumn<int> statusId = GeneratedColumn<int>(
      'status_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _locationTagMeta =
      const VerificationMeta('locationTag');
  @override
  late final GeneratedColumn<String> locationTag = GeneratedColumn<String>(
      'location_tag', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUpdatedMsMeta =
      const VerificationMeta('lastUpdatedMs');
  @override
  late final GeneratedColumn<int> lastUpdatedMs = GeneratedColumn<int>(
      'last_updated_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sourceDeviceIdMeta =
      const VerificationMeta('sourceDeviceId');
  @override
  late final GeneratedColumn<String> sourceDeviceId = GeneratedColumn<String>(
      'source_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedToServerMeta =
      const VerificationMeta('isSyncedToServer');
  @override
  late final GeneratedColumn<bool> isSyncedToServer = GeneratedColumn<bool>(
      'is_synced_to_server', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_synced_to_server" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        itemId,
        crdtJson,
        statusId,
        locationTag,
        lastUpdatedMs,
        sourceDeviceId,
        isSyncedToServer
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('crdt_json')) {
      context.handle(_crdtJsonMeta,
          crdtJson.isAcceptableOrUnknown(data['crdt_json']!, _crdtJsonMeta));
    } else if (isInserting) {
      context.missing(_crdtJsonMeta);
    }
    if (data.containsKey('status_id')) {
      context.handle(_statusIdMeta,
          statusId.isAcceptableOrUnknown(data['status_id']!, _statusIdMeta));
    } else if (isInserting) {
      context.missing(_statusIdMeta);
    }
    if (data.containsKey('location_tag')) {
      context.handle(
          _locationTagMeta,
          locationTag.isAcceptableOrUnknown(
              data['location_tag']!, _locationTagMeta));
    }
    if (data.containsKey('last_updated_ms')) {
      context.handle(
          _lastUpdatedMsMeta,
          lastUpdatedMs.isAcceptableOrUnknown(
              data['last_updated_ms']!, _lastUpdatedMsMeta));
    } else if (isInserting) {
      context.missing(_lastUpdatedMsMeta);
    }
    if (data.containsKey('source_device_id')) {
      context.handle(
          _sourceDeviceIdMeta,
          sourceDeviceId.isAcceptableOrUnknown(
              data['source_device_id']!, _sourceDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceDeviceIdMeta);
    }
    if (data.containsKey('is_synced_to_server')) {
      context.handle(
          _isSyncedToServerMeta,
          isSyncedToServer.isAcceptableOrUnknown(
              data['is_synced_to_server']!, _isSyncedToServerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      crdtJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}crdt_json'])!,
      statusId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status_id'])!,
      locationTag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_tag']),
      lastUpdatedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_updated_ms'])!,
      sourceDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_device_id'])!,
      isSyncedToServer: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}is_synced_to_server'])!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  /// Auto-increment primary key (local DB-only; not distributed).
  final int id;

  /// Application-level globally unique item ID (QR value / UUID string).
  final String itemId;

  /// Serialised [InventoryItemCrdt] JSON – single source of truth.
  final String crdtJson;

  /// StatusId cached at the DB row level for fast SQL filtering.
  final int statusId;

  /// Location tag cached for fast SQL querying.
  final String? locationTag;

  /// Wall-clock ms of the most recent local write (for quick ordering).
  final int lastUpdatedMs;

  /// DeviceID that made the most recent write to this row.
  final String sourceDeviceId;

  /// True once the central server acknowledged this item's current CRDT state.
  final bool isSyncedToServer;
  const InventoryItem(
      {required this.id,
      required this.itemId,
      required this.crdtJson,
      required this.statusId,
      this.locationTag,
      required this.lastUpdatedMs,
      required this.sourceDeviceId,
      required this.isSyncedToServer});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['crdt_json'] = Variable<String>(crdtJson);
    map['status_id'] = Variable<int>(statusId);
    if (!nullToAbsent || locationTag != null) {
      map['location_tag'] = Variable<String>(locationTag);
    }
    map['last_updated_ms'] = Variable<int>(lastUpdatedMs);
    map['source_device_id'] = Variable<String>(sourceDeviceId);
    map['is_synced_to_server'] = Variable<bool>(isSyncedToServer);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      crdtJson: Value(crdtJson),
      statusId: Value(statusId),
      locationTag: locationTag == null && nullToAbsent
          ? const Value.absent()
          : Value(locationTag),
      lastUpdatedMs: Value(lastUpdatedMs),
      sourceDeviceId: Value(sourceDeviceId),
      isSyncedToServer: Value(isSyncedToServer),
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      crdtJson: serializer.fromJson<String>(json['crdtJson']),
      statusId: serializer.fromJson<int>(json['statusId']),
      locationTag: serializer.fromJson<String?>(json['locationTag']),
      lastUpdatedMs: serializer.fromJson<int>(json['lastUpdatedMs']),
      sourceDeviceId: serializer.fromJson<String>(json['sourceDeviceId']),
      isSyncedToServer: serializer.fromJson<bool>(json['isSyncedToServer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'crdtJson': serializer.toJson<String>(crdtJson),
      'statusId': serializer.toJson<int>(statusId),
      'locationTag': serializer.toJson<String?>(locationTag),
      'lastUpdatedMs': serializer.toJson<int>(lastUpdatedMs),
      'sourceDeviceId': serializer.toJson<String>(sourceDeviceId),
      'isSyncedToServer': serializer.toJson<bool>(isSyncedToServer),
    };
  }

  InventoryItem copyWith(
          {int? id,
          String? itemId,
          String? crdtJson,
          int? statusId,
          Value<String?> locationTag = const Value.absent(),
          int? lastUpdatedMs,
          String? sourceDeviceId,
          bool? isSyncedToServer}) =>
      InventoryItem(
        id: id ?? this.id,
        itemId: itemId ?? this.itemId,
        crdtJson: crdtJson ?? this.crdtJson,
        statusId: statusId ?? this.statusId,
        locationTag: locationTag.present ? locationTag.value : this.locationTag,
        lastUpdatedMs: lastUpdatedMs ?? this.lastUpdatedMs,
        sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
        isSyncedToServer: isSyncedToServer ?? this.isSyncedToServer,
      );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      crdtJson: data.crdtJson.present ? data.crdtJson.value : this.crdtJson,
      statusId: data.statusId.present ? data.statusId.value : this.statusId,
      locationTag:
          data.locationTag.present ? data.locationTag.value : this.locationTag,
      lastUpdatedMs: data.lastUpdatedMs.present
          ? data.lastUpdatedMs.value
          : this.lastUpdatedMs,
      sourceDeviceId: data.sourceDeviceId.present
          ? data.sourceDeviceId.value
          : this.sourceDeviceId,
      isSyncedToServer: data.isSyncedToServer.present
          ? data.isSyncedToServer.value
          : this.isSyncedToServer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('crdtJson: $crdtJson, ')
          ..write('statusId: $statusId, ')
          ..write('locationTag: $locationTag, ')
          ..write('lastUpdatedMs: $lastUpdatedMs, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('isSyncedToServer: $isSyncedToServer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, crdtJson, statusId, locationTag,
      lastUpdatedMs, sourceDeviceId, isSyncedToServer);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.crdtJson == this.crdtJson &&
          other.statusId == this.statusId &&
          other.locationTag == this.locationTag &&
          other.lastUpdatedMs == this.lastUpdatedMs &&
          other.sourceDeviceId == this.sourceDeviceId &&
          other.isSyncedToServer == this.isSyncedToServer);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> crdtJson;
  final Value<int> statusId;
  final Value<String?> locationTag;
  final Value<int> lastUpdatedMs;
  final Value<String> sourceDeviceId;
  final Value<bool> isSyncedToServer;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.crdtJson = const Value.absent(),
    this.statusId = const Value.absent(),
    this.locationTag = const Value.absent(),
    this.lastUpdatedMs = const Value.absent(),
    this.sourceDeviceId = const Value.absent(),
    this.isSyncedToServer = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String crdtJson,
    required int statusId,
    this.locationTag = const Value.absent(),
    required int lastUpdatedMs,
    required String sourceDeviceId,
    this.isSyncedToServer = const Value.absent(),
  })  : itemId = Value(itemId),
        crdtJson = Value(crdtJson),
        statusId = Value(statusId),
        lastUpdatedMs = Value(lastUpdatedMs),
        sourceDeviceId = Value(sourceDeviceId);
  static Insertable<InventoryItem> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? crdtJson,
    Expression<int>? statusId,
    Expression<String>? locationTag,
    Expression<int>? lastUpdatedMs,
    Expression<String>? sourceDeviceId,
    Expression<bool>? isSyncedToServer,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (crdtJson != null) 'crdt_json': crdtJson,
      if (statusId != null) 'status_id': statusId,
      if (locationTag != null) 'location_tag': locationTag,
      if (lastUpdatedMs != null) 'last_updated_ms': lastUpdatedMs,
      if (sourceDeviceId != null) 'source_device_id': sourceDeviceId,
      if (isSyncedToServer != null) 'is_synced_to_server': isSyncedToServer,
    });
  }

  InventoryItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? itemId,
      Value<String>? crdtJson,
      Value<int>? statusId,
      Value<String?>? locationTag,
      Value<int>? lastUpdatedMs,
      Value<String>? sourceDeviceId,
      Value<bool>? isSyncedToServer}) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      crdtJson: crdtJson ?? this.crdtJson,
      statusId: statusId ?? this.statusId,
      locationTag: locationTag ?? this.locationTag,
      lastUpdatedMs: lastUpdatedMs ?? this.lastUpdatedMs,
      sourceDeviceId: sourceDeviceId ?? this.sourceDeviceId,
      isSyncedToServer: isSyncedToServer ?? this.isSyncedToServer,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (crdtJson.present) {
      map['crdt_json'] = Variable<String>(crdtJson.value);
    }
    if (statusId.present) {
      map['status_id'] = Variable<int>(statusId.value);
    }
    if (locationTag.present) {
      map['location_tag'] = Variable<String>(locationTag.value);
    }
    if (lastUpdatedMs.present) {
      map['last_updated_ms'] = Variable<int>(lastUpdatedMs.value);
    }
    if (sourceDeviceId.present) {
      map['source_device_id'] = Variable<String>(sourceDeviceId.value);
    }
    if (isSyncedToServer.present) {
      map['is_synced_to_server'] = Variable<bool>(isSyncedToServer.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('crdtJson: $crdtJson, ')
          ..write('statusId: $statusId, ')
          ..write('locationTag: $locationTag, ')
          ..write('lastUpdatedMs: $lastUpdatedMs, ')
          ..write('sourceDeviceId: $sourceDeviceId, ')
          ..write('isSyncedToServer: $isSyncedToServer')
          ..write(')'))
        .toString();
  }
}

class $PacketQueueTable extends PacketQueue
    with TableInfo<$PacketQueueTable, PacketQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PacketQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _encryptedPayloadMeta =
      const VerificationMeta('encryptedPayload');
  @override
  late final GeneratedColumn<Uint8List> encryptedPayload =
      GeneratedColumn<Uint8List>('encrypted_payload', aliasedName, false,
          type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _targetDeviceIdMeta =
      const VerificationMeta('targetDeviceId');
  @override
  late final GeneratedColumn<String> targetDeviceId = GeneratedColumn<String>(
      'target_device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _packetTypeByteMeta =
      const VerificationMeta('packetTypeByte');
  @override
  late final GeneratedColumn<int> packetTypeByte = GeneratedColumn<int>(
      'packet_type_byte', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMsMeta =
      const VerificationMeta('createdAtMs');
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
      'created_at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isDeliveredMeta =
      const VerificationMeta('isDelivered');
  @override
  late final GeneratedColumn<bool> isDelivered = GeneratedColumn<bool>(
      'is_delivered', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_delivered" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        encryptedPayload,
        targetDeviceId,
        packetTypeByte,
        createdAtMs,
        retryCount,
        isDelivered
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'packet_queue';
  @override
  VerificationContext validateIntegrity(Insertable<PacketQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
          _encryptedPayloadMeta,
          encryptedPayload.isAcceptableOrUnknown(
              data['encrypted_payload']!, _encryptedPayloadMeta));
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('target_device_id')) {
      context.handle(
          _targetDeviceIdMeta,
          targetDeviceId.isAcceptableOrUnknown(
              data['target_device_id']!, _targetDeviceIdMeta));
    }
    if (data.containsKey('packet_type_byte')) {
      context.handle(
          _packetTypeByteMeta,
          packetTypeByte.isAcceptableOrUnknown(
              data['packet_type_byte']!, _packetTypeByteMeta));
    } else if (isInserting) {
      context.missing(_packetTypeByteMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
          _createdAtMsMeta,
          createdAtMs.isAcceptableOrUnknown(
              data['created_at_ms']!, _createdAtMsMeta));
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('is_delivered')) {
      context.handle(
          _isDeliveredMeta,
          isDelivered.isAcceptableOrUnknown(
              data['is_delivered']!, _isDeliveredMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PacketQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PacketQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      encryptedPayload: attachedDatabase.typeMapping.read(
          DriftSqlType.blob, data['${effectivePrefix}encrypted_payload'])!,
      targetDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_device_id']),
      packetTypeByte: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}packet_type_byte'])!,
      createdAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_ms'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      isDelivered: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_delivered'])!,
    );
  }

  @override
  $PacketQueueTable createAlias(String alias) {
    return $PacketQueueTable(attachedDatabase, alias);
  }
}

class PacketQueueData extends DataClass implements Insertable<PacketQueueData> {
  final int id;

  /// Raw ENCRYPTED bytes of the BLE packet.
  final Uint8List encryptedPayload;

  /// Target peer device ID; null means broadcast to all reachable peers.
  final String? targetDeviceId;

  /// PacketType byte (mirrors [BlePacketType.wireValue]) for fast filtering.
  final int packetTypeByte;

  /// Creation timestamp (ms) – used for TTL expiration of stale queue entries.
  final int createdAtMs;

  /// Number of delivery attempts made so far.
  final int retryCount;

  /// Delivered successfully – retained briefly for idempotent deduplication.
  final bool isDelivered;
  const PacketQueueData(
      {required this.id,
      required this.encryptedPayload,
      this.targetDeviceId,
      required this.packetTypeByte,
      required this.createdAtMs,
      required this.retryCount,
      required this.isDelivered});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload);
    if (!nullToAbsent || targetDeviceId != null) {
      map['target_device_id'] = Variable<String>(targetDeviceId);
    }
    map['packet_type_byte'] = Variable<int>(packetTypeByte);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['retry_count'] = Variable<int>(retryCount);
    map['is_delivered'] = Variable<bool>(isDelivered);
    return map;
  }

  PacketQueueCompanion toCompanion(bool nullToAbsent) {
    return PacketQueueCompanion(
      id: Value(id),
      encryptedPayload: Value(encryptedPayload),
      targetDeviceId: targetDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDeviceId),
      packetTypeByte: Value(packetTypeByte),
      createdAtMs: Value(createdAtMs),
      retryCount: Value(retryCount),
      isDelivered: Value(isDelivered),
    );
  }

  factory PacketQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PacketQueueData(
      id: serializer.fromJson<int>(json['id']),
      encryptedPayload:
          serializer.fromJson<Uint8List>(json['encryptedPayload']),
      targetDeviceId: serializer.fromJson<String?>(json['targetDeviceId']),
      packetTypeByte: serializer.fromJson<int>(json['packetTypeByte']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      isDelivered: serializer.fromJson<bool>(json['isDelivered']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'encryptedPayload': serializer.toJson<Uint8List>(encryptedPayload),
      'targetDeviceId': serializer.toJson<String?>(targetDeviceId),
      'packetTypeByte': serializer.toJson<int>(packetTypeByte),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'retryCount': serializer.toJson<int>(retryCount),
      'isDelivered': serializer.toJson<bool>(isDelivered),
    };
  }

  PacketQueueData copyWith(
          {int? id,
          Uint8List? encryptedPayload,
          Value<String?> targetDeviceId = const Value.absent(),
          int? packetTypeByte,
          int? createdAtMs,
          int? retryCount,
          bool? isDelivered}) =>
      PacketQueueData(
        id: id ?? this.id,
        encryptedPayload: encryptedPayload ?? this.encryptedPayload,
        targetDeviceId:
            targetDeviceId.present ? targetDeviceId.value : this.targetDeviceId,
        packetTypeByte: packetTypeByte ?? this.packetTypeByte,
        createdAtMs: createdAtMs ?? this.createdAtMs,
        retryCount: retryCount ?? this.retryCount,
        isDelivered: isDelivered ?? this.isDelivered,
      );
  PacketQueueData copyWithCompanion(PacketQueueCompanion data) {
    return PacketQueueData(
      id: data.id.present ? data.id.value : this.id,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      targetDeviceId: data.targetDeviceId.present
          ? data.targetDeviceId.value
          : this.targetDeviceId,
      packetTypeByte: data.packetTypeByte.present
          ? data.packetTypeByte.value
          : this.packetTypeByte,
      createdAtMs:
          data.createdAtMs.present ? data.createdAtMs.value : this.createdAtMs,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      isDelivered:
          data.isDelivered.present ? data.isDelivered.value : this.isDelivered,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PacketQueueData(')
          ..write('id: $id, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('targetDeviceId: $targetDeviceId, ')
          ..write('packetTypeByte: $packetTypeByte, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('retryCount: $retryCount, ')
          ..write('isDelivered: $isDelivered')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, $driftBlobEquality.hash(encryptedPayload),
      targetDeviceId, packetTypeByte, createdAtMs, retryCount, isDelivered);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PacketQueueData &&
          other.id == this.id &&
          $driftBlobEquality.equals(
              other.encryptedPayload, this.encryptedPayload) &&
          other.targetDeviceId == this.targetDeviceId &&
          other.packetTypeByte == this.packetTypeByte &&
          other.createdAtMs == this.createdAtMs &&
          other.retryCount == this.retryCount &&
          other.isDelivered == this.isDelivered);
}

class PacketQueueCompanion extends UpdateCompanion<PacketQueueData> {
  final Value<int> id;
  final Value<Uint8List> encryptedPayload;
  final Value<String?> targetDeviceId;
  final Value<int> packetTypeByte;
  final Value<int> createdAtMs;
  final Value<int> retryCount;
  final Value<bool> isDelivered;
  const PacketQueueCompanion({
    this.id = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.targetDeviceId = const Value.absent(),
    this.packetTypeByte = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.isDelivered = const Value.absent(),
  });
  PacketQueueCompanion.insert({
    this.id = const Value.absent(),
    required Uint8List encryptedPayload,
    this.targetDeviceId = const Value.absent(),
    required int packetTypeByte,
    required int createdAtMs,
    this.retryCount = const Value.absent(),
    this.isDelivered = const Value.absent(),
  })  : encryptedPayload = Value(encryptedPayload),
        packetTypeByte = Value(packetTypeByte),
        createdAtMs = Value(createdAtMs);
  static Insertable<PacketQueueData> custom({
    Expression<int>? id,
    Expression<Uint8List>? encryptedPayload,
    Expression<String>? targetDeviceId,
    Expression<int>? packetTypeByte,
    Expression<int>? createdAtMs,
    Expression<int>? retryCount,
    Expression<bool>? isDelivered,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (targetDeviceId != null) 'target_device_id': targetDeviceId,
      if (packetTypeByte != null) 'packet_type_byte': packetTypeByte,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (retryCount != null) 'retry_count': retryCount,
      if (isDelivered != null) 'is_delivered': isDelivered,
    });
  }

  PacketQueueCompanion copyWith(
      {Value<int>? id,
      Value<Uint8List>? encryptedPayload,
      Value<String?>? targetDeviceId,
      Value<int>? packetTypeByte,
      Value<int>? createdAtMs,
      Value<int>? retryCount,
      Value<bool>? isDelivered}) {
    return PacketQueueCompanion(
      id: id ?? this.id,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      targetDeviceId: targetDeviceId ?? this.targetDeviceId,
      packetTypeByte: packetTypeByte ?? this.packetTypeByte,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      retryCount: retryCount ?? this.retryCount,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload.value);
    }
    if (targetDeviceId.present) {
      map['target_device_id'] = Variable<String>(targetDeviceId.value);
    }
    if (packetTypeByte.present) {
      map['packet_type_byte'] = Variable<int>(packetTypeByte.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (isDelivered.present) {
      map['is_delivered'] = Variable<bool>(isDelivered.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PacketQueueCompanion(')
          ..write('id: $id, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('targetDeviceId: $targetDeviceId, ')
          ..write('packetTypeByte: $packetTypeByte, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('retryCount: $retryCount, ')
          ..write('isDelivered: $isDelivered')
          ..write(')'))
        .toString();
  }
}

class $PeerTableTable extends PeerTable
    with TableInfo<$PeerTableTable, PeerTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeerTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceShortIdMeta =
      const VerificationMeta('deviceShortId');
  @override
  late final GeneratedColumn<int> deviceShortId = GeneratedColumn<int>(
      'device_short_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _electionScoreMeta =
      const VerificationMeta('electionScore');
  @override
  late final GeneratedColumn<int> electionScore = GeneratedColumn<int>(
      'election_score', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _rssiMeta = const VerificationMeta('rssi');
  @override
  late final GeneratedColumn<int> rssi = GeneratedColumn<int>(
      'rssi', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(-100));
  static const VerificationMeta _lastSeenMsMeta =
      const VerificationMeta('lastSeenMs');
  @override
  late final GeneratedColumn<int> lastSeenMs = GeneratedColumn<int>(
      'last_seen_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isLeaderMeta =
      const VerificationMeta('isLeader');
  @override
  late final GeneratedColumn<bool> isLeader = GeneratedColumn<bool>(
      'is_leader', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_leader" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _hasInternetMeta =
      const VerificationMeta('hasInternet');
  @override
  late final GeneratedColumn<bool> hasInternet = GeneratedColumn<bool>(
      'has_internet', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_internet" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        deviceId,
        deviceShortId,
        electionScore,
        rssi,
        lastSeenMs,
        isLeader,
        hasInternet
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peer_table';
  @override
  VerificationContext validateIntegrity(Insertable<PeerTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_short_id')) {
      context.handle(
          _deviceShortIdMeta,
          deviceShortId.isAcceptableOrUnknown(
              data['device_short_id']!, _deviceShortIdMeta));
    } else if (isInserting) {
      context.missing(_deviceShortIdMeta);
    }
    if (data.containsKey('election_score')) {
      context.handle(
          _electionScoreMeta,
          electionScore.isAcceptableOrUnknown(
              data['election_score']!, _electionScoreMeta));
    }
    if (data.containsKey('rssi')) {
      context.handle(
          _rssiMeta, rssi.isAcceptableOrUnknown(data['rssi']!, _rssiMeta));
    }
    if (data.containsKey('last_seen_ms')) {
      context.handle(
          _lastSeenMsMeta,
          lastSeenMs.isAcceptableOrUnknown(
              data['last_seen_ms']!, _lastSeenMsMeta));
    } else if (isInserting) {
      context.missing(_lastSeenMsMeta);
    }
    if (data.containsKey('is_leader')) {
      context.handle(_isLeaderMeta,
          isLeader.isAcceptableOrUnknown(data['is_leader']!, _isLeaderMeta));
    }
    if (data.containsKey('has_internet')) {
      context.handle(
          _hasInternetMeta,
          hasInternet.isAcceptableOrUnknown(
              data['has_internet']!, _hasInternetMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  PeerTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeerTableData(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deviceShortId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}device_short_id'])!,
      electionScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}election_score'])!,
      rssi: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rssi'])!,
      lastSeenMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_seen_ms'])!,
      isLeader: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_leader'])!,
      hasInternet: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_internet'])!,
    );
  }

  @override
  $PeerTableTable createAlias(String alias) {
    return $PeerTableTable(attachedDatabase, alias);
  }
}

class PeerTableData extends DataClass implements Insertable<PeerTableData> {
  /// Full device ID string (UUID or platform BLE device ID).
  final String deviceId;

  /// Pre-computed uint16 short ID (lower 16 bits of djb2 hash of deviceId).
  final int deviceShortId;

  /// Most recently received election score from this peer.
  final int electionScore;

  /// Last received RSSI value (dBm, negative).
  final int rssi;

  /// Epoch ms of the most recent contact (scan, heartbeat, or data packet).
  final int lastSeenMs;

  /// True if this peer is currently considered the network leader.
  final bool isLeader;

  /// True if this peer is believed to have an active internet connection.
  final bool hasInternet;
  const PeerTableData(
      {required this.deviceId,
      required this.deviceShortId,
      required this.electionScore,
      required this.rssi,
      required this.lastSeenMs,
      required this.isLeader,
      required this.hasInternet});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['device_short_id'] = Variable<int>(deviceShortId);
    map['election_score'] = Variable<int>(electionScore);
    map['rssi'] = Variable<int>(rssi);
    map['last_seen_ms'] = Variable<int>(lastSeenMs);
    map['is_leader'] = Variable<bool>(isLeader);
    map['has_internet'] = Variable<bool>(hasInternet);
    return map;
  }

  PeerTableCompanion toCompanion(bool nullToAbsent) {
    return PeerTableCompanion(
      deviceId: Value(deviceId),
      deviceShortId: Value(deviceShortId),
      electionScore: Value(electionScore),
      rssi: Value(rssi),
      lastSeenMs: Value(lastSeenMs),
      isLeader: Value(isLeader),
      hasInternet: Value(hasInternet),
    );
  }

  factory PeerTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeerTableData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceShortId: serializer.fromJson<int>(json['deviceShortId']),
      electionScore: serializer.fromJson<int>(json['electionScore']),
      rssi: serializer.fromJson<int>(json['rssi']),
      lastSeenMs: serializer.fromJson<int>(json['lastSeenMs']),
      isLeader: serializer.fromJson<bool>(json['isLeader']),
      hasInternet: serializer.fromJson<bool>(json['hasInternet']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceShortId': serializer.toJson<int>(deviceShortId),
      'electionScore': serializer.toJson<int>(electionScore),
      'rssi': serializer.toJson<int>(rssi),
      'lastSeenMs': serializer.toJson<int>(lastSeenMs),
      'isLeader': serializer.toJson<bool>(isLeader),
      'hasInternet': serializer.toJson<bool>(hasInternet),
    };
  }

  PeerTableData copyWith(
          {String? deviceId,
          int? deviceShortId,
          int? electionScore,
          int? rssi,
          int? lastSeenMs,
          bool? isLeader,
          bool? hasInternet}) =>
      PeerTableData(
        deviceId: deviceId ?? this.deviceId,
        deviceShortId: deviceShortId ?? this.deviceShortId,
        electionScore: electionScore ?? this.electionScore,
        rssi: rssi ?? this.rssi,
        lastSeenMs: lastSeenMs ?? this.lastSeenMs,
        isLeader: isLeader ?? this.isLeader,
        hasInternet: hasInternet ?? this.hasInternet,
      );
  PeerTableData copyWithCompanion(PeerTableCompanion data) {
    return PeerTableData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceShortId: data.deviceShortId.present
          ? data.deviceShortId.value
          : this.deviceShortId,
      electionScore: data.electionScore.present
          ? data.electionScore.value
          : this.electionScore,
      rssi: data.rssi.present ? data.rssi.value : this.rssi,
      lastSeenMs:
          data.lastSeenMs.present ? data.lastSeenMs.value : this.lastSeenMs,
      isLeader: data.isLeader.present ? data.isLeader.value : this.isLeader,
      hasInternet:
          data.hasInternet.present ? data.hasInternet.value : this.hasInternet,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeerTableData(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceShortId: $deviceShortId, ')
          ..write('electionScore: $electionScore, ')
          ..write('rssi: $rssi, ')
          ..write('lastSeenMs: $lastSeenMs, ')
          ..write('isLeader: $isLeader, ')
          ..write('hasInternet: $hasInternet')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, deviceShortId, electionScore, rssi,
      lastSeenMs, isLeader, hasInternet);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeerTableData &&
          other.deviceId == this.deviceId &&
          other.deviceShortId == this.deviceShortId &&
          other.electionScore == this.electionScore &&
          other.rssi == this.rssi &&
          other.lastSeenMs == this.lastSeenMs &&
          other.isLeader == this.isLeader &&
          other.hasInternet == this.hasInternet);
}

class PeerTableCompanion extends UpdateCompanion<PeerTableData> {
  final Value<String> deviceId;
  final Value<int> deviceShortId;
  final Value<int> electionScore;
  final Value<int> rssi;
  final Value<int> lastSeenMs;
  final Value<bool> isLeader;
  final Value<bool> hasInternet;
  final Value<int> rowid;
  const PeerTableCompanion({
    this.deviceId = const Value.absent(),
    this.deviceShortId = const Value.absent(),
    this.electionScore = const Value.absent(),
    this.rssi = const Value.absent(),
    this.lastSeenMs = const Value.absent(),
    this.isLeader = const Value.absent(),
    this.hasInternet = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeerTableCompanion.insert({
    required String deviceId,
    required int deviceShortId,
    this.electionScore = const Value.absent(),
    this.rssi = const Value.absent(),
    required int lastSeenMs,
    this.isLeader = const Value.absent(),
    this.hasInternet = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        deviceShortId = Value(deviceShortId),
        lastSeenMs = Value(lastSeenMs);
  static Insertable<PeerTableData> custom({
    Expression<String>? deviceId,
    Expression<int>? deviceShortId,
    Expression<int>? electionScore,
    Expression<int>? rssi,
    Expression<int>? lastSeenMs,
    Expression<bool>? isLeader,
    Expression<bool>? hasInternet,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (deviceShortId != null) 'device_short_id': deviceShortId,
      if (electionScore != null) 'election_score': electionScore,
      if (rssi != null) 'rssi': rssi,
      if (lastSeenMs != null) 'last_seen_ms': lastSeenMs,
      if (isLeader != null) 'is_leader': isLeader,
      if (hasInternet != null) 'has_internet': hasInternet,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeerTableCompanion copyWith(
      {Value<String>? deviceId,
      Value<int>? deviceShortId,
      Value<int>? electionScore,
      Value<int>? rssi,
      Value<int>? lastSeenMs,
      Value<bool>? isLeader,
      Value<bool>? hasInternet,
      Value<int>? rowid}) {
    return PeerTableCompanion(
      deviceId: deviceId ?? this.deviceId,
      deviceShortId: deviceShortId ?? this.deviceShortId,
      electionScore: electionScore ?? this.electionScore,
      rssi: rssi ?? this.rssi,
      lastSeenMs: lastSeenMs ?? this.lastSeenMs,
      isLeader: isLeader ?? this.isLeader,
      hasInternet: hasInternet ?? this.hasInternet,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceShortId.present) {
      map['device_short_id'] = Variable<int>(deviceShortId.value);
    }
    if (electionScore.present) {
      map['election_score'] = Variable<int>(electionScore.value);
    }
    if (rssi.present) {
      map['rssi'] = Variable<int>(rssi.value);
    }
    if (lastSeenMs.present) {
      map['last_seen_ms'] = Variable<int>(lastSeenMs.value);
    }
    if (isLeader.present) {
      map['is_leader'] = Variable<bool>(isLeader.value);
    }
    if (hasInternet.present) {
      map['has_internet'] = Variable<bool>(hasInternet.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeerTableCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceShortId: $deviceShortId, ')
          ..write('electionScore: $electionScore, ')
          ..write('rssi: $rssi, ')
          ..write('lastSeenMs: $lastSeenMs, ')
          ..write('isLeader: $isLeader, ')
          ..write('hasInternet: $hasInternet, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _senderDeviceIdMeta =
      const VerificationMeta('senderDeviceId');
  @override
  late final GeneratedColumn<String> senderDeviceId = GeneratedColumn<String>(
      'sender_device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderShortIdMeta =
      const VerificationMeta('senderShortId');
  @override
  late final GeneratedColumn<int> senderShortId = GeneratedColumn<int>(
      'sender_short_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _senderLabelMeta =
      const VerificationMeta('senderLabel');
  @override
  late final GeneratedColumn<String> senderLabel = GeneratedColumn<String>(
      'sender_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMsMeta =
      const VerificationMeta('timestampMs');
  @override
  late final GeneratedColumn<int> timestampMs = GeneratedColumn<int>(
      'timestamp_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isMineMeta = const VerificationMeta('isMine');
  @override
  late final GeneratedColumn<bool> isMine = GeneratedColumn<bool>(
      'is_mine', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_mine" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        messageId,
        senderDeviceId,
        senderShortId,
        senderLabel,
        content,
        timestampMs,
        isMine
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(Insertable<ChatMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('sender_device_id')) {
      context.handle(
          _senderDeviceIdMeta,
          senderDeviceId.isAcceptableOrUnknown(
              data['sender_device_id']!, _senderDeviceIdMeta));
    } else if (isInserting) {
      context.missing(_senderDeviceIdMeta);
    }
    if (data.containsKey('sender_short_id')) {
      context.handle(
          _senderShortIdMeta,
          senderShortId.isAcceptableOrUnknown(
              data['sender_short_id']!, _senderShortIdMeta));
    } else if (isInserting) {
      context.missing(_senderShortIdMeta);
    }
    if (data.containsKey('sender_label')) {
      context.handle(
          _senderLabelMeta,
          senderLabel.isAcceptableOrUnknown(
              data['sender_label']!, _senderLabelMeta));
    } else if (isInserting) {
      context.missing(_senderLabelMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp_ms')) {
      context.handle(
          _timestampMsMeta,
          timestampMs.isAcceptableOrUnknown(
              data['timestamp_ms']!, _timestampMsMeta));
    } else if (isInserting) {
      context.missing(_timestampMsMeta);
    }
    if (data.containsKey('is_mine')) {
      context.handle(_isMineMeta,
          isMine.isAcceptableOrUnknown(data['is_mine']!, _isMineMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      senderDeviceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sender_device_id'])!,
      senderShortId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sender_short_id'])!,
      senderLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_label'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      timestampMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp_ms'])!,
      isMine: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_mine'])!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessage extends DataClass implements Insertable<ChatMessage> {
  final int id;

  /// UUID string that uniquely identifies the message across the whole mesh.
  final String messageId;

  /// Full device ID of the author.
  final String senderDeviceId;

  /// uint16 short ID of the sender (for compact display).
  final int senderShortId;

  /// Human-readable label derived from senderDeviceId.
  final String senderLabel;

  /// UTF-8 text content.
  final String content;

  /// Wall-clock ms when the message was created by the sender.
  final int timestampMs;

  /// True if this device originated the message.
  final bool isMine;
  const ChatMessage(
      {required this.id,
      required this.messageId,
      required this.senderDeviceId,
      required this.senderShortId,
      required this.senderLabel,
      required this.content,
      required this.timestampMs,
      required this.isMine});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['message_id'] = Variable<String>(messageId);
    map['sender_device_id'] = Variable<String>(senderDeviceId);
    map['sender_short_id'] = Variable<int>(senderShortId);
    map['sender_label'] = Variable<String>(senderLabel);
    map['content'] = Variable<String>(content);
    map['timestamp_ms'] = Variable<int>(timestampMs);
    map['is_mine'] = Variable<bool>(isMine);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      messageId: Value(messageId),
      senderDeviceId: Value(senderDeviceId),
      senderShortId: Value(senderShortId),
      senderLabel: Value(senderLabel),
      content: Value(content),
      timestampMs: Value(timestampMs),
      isMine: Value(isMine),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessage(
      id: serializer.fromJson<int>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      senderDeviceId: serializer.fromJson<String>(json['senderDeviceId']),
      senderShortId: serializer.fromJson<int>(json['senderShortId']),
      senderLabel: serializer.fromJson<String>(json['senderLabel']),
      content: serializer.fromJson<String>(json['content']),
      timestampMs: serializer.fromJson<int>(json['timestampMs']),
      isMine: serializer.fromJson<bool>(json['isMine']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'messageId': serializer.toJson<String>(messageId),
      'senderDeviceId': serializer.toJson<String>(senderDeviceId),
      'senderShortId': serializer.toJson<int>(senderShortId),
      'senderLabel': serializer.toJson<String>(senderLabel),
      'content': serializer.toJson<String>(content),
      'timestampMs': serializer.toJson<int>(timestampMs),
      'isMine': serializer.toJson<bool>(isMine),
    };
  }

  ChatMessage copyWith(
          {int? id,
          String? messageId,
          String? senderDeviceId,
          int? senderShortId,
          String? senderLabel,
          String? content,
          int? timestampMs,
          bool? isMine}) =>
      ChatMessage(
        id: id ?? this.id,
        messageId: messageId ?? this.messageId,
        senderDeviceId: senderDeviceId ?? this.senderDeviceId,
        senderShortId: senderShortId ?? this.senderShortId,
        senderLabel: senderLabel ?? this.senderLabel,
        content: content ?? this.content,
        timestampMs: timestampMs ?? this.timestampMs,
        isMine: isMine ?? this.isMine,
      );
  ChatMessage copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessage(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      senderDeviceId: data.senderDeviceId.present
          ? data.senderDeviceId.value
          : this.senderDeviceId,
      senderShortId: data.senderShortId.present
          ? data.senderShortId.value
          : this.senderShortId,
      senderLabel:
          data.senderLabel.present ? data.senderLabel.value : this.senderLabel,
      content: data.content.present ? data.content.value : this.content,
      timestampMs:
          data.timestampMs.present ? data.timestampMs.value : this.timestampMs,
      isMine: data.isMine.present ? data.isMine.value : this.isMine,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessage(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('senderShortId: $senderShortId, ')
          ..write('senderLabel: $senderLabel, ')
          ..write('content: $content, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('isMine: $isMine')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, messageId, senderDeviceId, senderShortId,
      senderLabel, content, timestampMs, isMine);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessage &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.senderDeviceId == this.senderDeviceId &&
          other.senderShortId == this.senderShortId &&
          other.senderLabel == this.senderLabel &&
          other.content == this.content &&
          other.timestampMs == this.timestampMs &&
          other.isMine == this.isMine);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessage> {
  final Value<int> id;
  final Value<String> messageId;
  final Value<String> senderDeviceId;
  final Value<int> senderShortId;
  final Value<String> senderLabel;
  final Value<String> content;
  final Value<int> timestampMs;
  final Value<bool> isMine;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.senderDeviceId = const Value.absent(),
    this.senderShortId = const Value.absent(),
    this.senderLabel = const Value.absent(),
    this.content = const Value.absent(),
    this.timestampMs = const Value.absent(),
    this.isMine = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    this.id = const Value.absent(),
    required String messageId,
    required String senderDeviceId,
    required int senderShortId,
    required String senderLabel,
    required String content,
    required int timestampMs,
    this.isMine = const Value.absent(),
  })  : messageId = Value(messageId),
        senderDeviceId = Value(senderDeviceId),
        senderShortId = Value(senderShortId),
        senderLabel = Value(senderLabel),
        content = Value(content),
        timestampMs = Value(timestampMs);
  static Insertable<ChatMessage> custom({
    Expression<int>? id,
    Expression<String>? messageId,
    Expression<String>? senderDeviceId,
    Expression<int>? senderShortId,
    Expression<String>? senderLabel,
    Expression<String>? content,
    Expression<int>? timestampMs,
    Expression<bool>? isMine,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (senderDeviceId != null) 'sender_device_id': senderDeviceId,
      if (senderShortId != null) 'sender_short_id': senderShortId,
      if (senderLabel != null) 'sender_label': senderLabel,
      if (content != null) 'content': content,
      if (timestampMs != null) 'timestamp_ms': timestampMs,
      if (isMine != null) 'is_mine': isMine,
    });
  }

  ChatMessagesCompanion copyWith(
      {Value<int>? id,
      Value<String>? messageId,
      Value<String>? senderDeviceId,
      Value<int>? senderShortId,
      Value<String>? senderLabel,
      Value<String>? content,
      Value<int>? timestampMs,
      Value<bool>? isMine}) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      senderShortId: senderShortId ?? this.senderShortId,
      senderLabel: senderLabel ?? this.senderLabel,
      content: content ?? this.content,
      timestampMs: timestampMs ?? this.timestampMs,
      isMine: isMine ?? this.isMine,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (senderDeviceId.present) {
      map['sender_device_id'] = Variable<String>(senderDeviceId.value);
    }
    if (senderShortId.present) {
      map['sender_short_id'] = Variable<int>(senderShortId.value);
    }
    if (senderLabel.present) {
      map['sender_label'] = Variable<String>(senderLabel.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestampMs.present) {
      map['timestamp_ms'] = Variable<int>(timestampMs.value);
    }
    if (isMine.present) {
      map['is_mine'] = Variable<bool>(isMine.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('senderShortId: $senderShortId, ')
          ..write('senderLabel: $senderLabel, ')
          ..write('content: $content, ')
          ..write('timestampMs: $timestampMs, ')
          ..write('isMine: $isMine')
          ..write(')'))
        .toString();
  }
}

class $ShowCueListsTable extends ShowCueLists
    with TableInfo<$ShowCueListsTable, ShowCueList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShowCueListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _updatedAtMsMeta =
      const VerificationMeta('updatedAtMs');
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
      'updated_at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sessionId, name, version, updatedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'show_cue_lists';
  @override
  VerificationContext validateIntegrity(Insertable<ShowCueList> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
          _updatedAtMsMeta,
          updatedAtMs.isAcceptableOrUnknown(
              data['updated_at_ms']!, _updatedAtMsMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShowCueList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShowCueList(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      updatedAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at_ms'])!,
    );
  }

  @override
  $ShowCueListsTable createAlias(String alias) {
    return $ShowCueListsTable(attachedDatabase, alias);
  }
}

class ShowCueList extends DataClass implements Insertable<ShowCueList> {
  final String id;
  final String sessionId;
  final String name;
  final int version;
  final int updatedAtMs;
  const ShowCueList(
      {required this.id,
      required this.sessionId,
      required this.name,
      required this.version,
      required this.updatedAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['name'] = Variable<String>(name);
    map['version'] = Variable<int>(version);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  ShowCueListsCompanion toCompanion(bool nullToAbsent) {
    return ShowCueListsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      name: Value(name),
      version: Value(version),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory ShowCueList.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShowCueList(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<int>(json['version']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<int>(version),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
    };
  }

  ShowCueList copyWith(
          {String? id,
          String? sessionId,
          String? name,
          int? version,
          int? updatedAtMs}) =>
      ShowCueList(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        name: name ?? this.name,
        version: version ?? this.version,
        updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      );
  ShowCueList copyWithCompanion(ShowCueListsCompanion data) {
    return ShowCueList(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      updatedAtMs:
          data.updatedAtMs.present ? data.updatedAtMs.value : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShowCueList(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, name, version, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShowCueList &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.name == this.name &&
          other.version == this.version &&
          other.updatedAtMs == this.updatedAtMs);
}

class ShowCueListsCompanion extends UpdateCompanion<ShowCueList> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> name;
  final Value<int> version;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const ShowCueListsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShowCueListsCompanion.insert({
    required String id,
    required String sessionId,
    required String name,
    this.version = const Value.absent(),
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sessionId = Value(sessionId),
        name = Value(name),
        updatedAtMs = Value(updatedAtMs);
  static Insertable<ShowCueList> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? name,
    Expression<int>? version,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShowCueListsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sessionId,
      Value<String>? name,
      Value<int>? version,
      Value<int>? updatedAtMs,
      Value<int>? rowid}) {
    return ShowCueListsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      version: version ?? this.version,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShowCueListsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShowCuesTable extends ShowCues with TableInfo<$ShowCuesTable, ShowCue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShowCuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cueListIdMeta =
      const VerificationMeta('cueListId');
  @override
  late final GeneratedColumn<String> cueListId = GeneratedColumn<String>(
      'cue_list_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
      'number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cueTypeMeta =
      const VerificationMeta('cueType');
  @override
  late final GeneratedColumn<int> cueType = GeneratedColumn<int>(
      'cue_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _paramsJsonMeta =
      const VerificationMeta('paramsJson');
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
      'params_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetNodeIdMeta =
      const VerificationMeta('targetNodeId');
  @override
  late final GeneratedColumn<String> targetNodeId = GeneratedColumn<String>(
      'target_node_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _autoContinueMeta =
      const VerificationMeta('autoContinue');
  @override
  late final GeneratedColumn<bool> autoContinue = GeneratedColumn<bool>(
      'auto_continue', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_continue" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _preWaitMsMeta =
      const VerificationMeta('preWaitMs');
  @override
  late final GeneratedColumn<double> preWaitMs = GeneratedColumn<double>(
      'pre_wait_ms', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _postWaitMsMeta =
      const VerificationMeta('postWaitMs');
  @override
  late final GeneratedColumn<double> postWaitMs = GeneratedColumn<double>(
      'post_wait_ms', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cueListId,
        number,
        label,
        cueType,
        paramsJson,
        orderIndex,
        targetNodeId,
        autoContinue,
        preWaitMs,
        postWaitMs,
        version
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'show_cues';
  @override
  VerificationContext validateIntegrity(Insertable<ShowCue> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('cue_list_id')) {
      context.handle(
          _cueListIdMeta,
          cueListId.isAcceptableOrUnknown(
              data['cue_list_id']!, _cueListIdMeta));
    } else if (isInserting) {
      context.missing(_cueListIdMeta);
    }
    if (data.containsKey('number')) {
      context.handle(_numberMeta,
          number.isAcceptableOrUnknown(data['number']!, _numberMeta));
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('cue_type')) {
      context.handle(_cueTypeMeta,
          cueType.isAcceptableOrUnknown(data['cue_type']!, _cueTypeMeta));
    } else if (isInserting) {
      context.missing(_cueTypeMeta);
    }
    if (data.containsKey('params_json')) {
      context.handle(
          _paramsJsonMeta,
          paramsJson.isAcceptableOrUnknown(
              data['params_json']!, _paramsJsonMeta));
    } else if (isInserting) {
      context.missing(_paramsJsonMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('target_node_id')) {
      context.handle(
          _targetNodeIdMeta,
          targetNodeId.isAcceptableOrUnknown(
              data['target_node_id']!, _targetNodeIdMeta));
    }
    if (data.containsKey('auto_continue')) {
      context.handle(
          _autoContinueMeta,
          autoContinue.isAcceptableOrUnknown(
              data['auto_continue']!, _autoContinueMeta));
    }
    if (data.containsKey('pre_wait_ms')) {
      context.handle(
          _preWaitMsMeta,
          preWaitMs.isAcceptableOrUnknown(
              data['pre_wait_ms']!, _preWaitMsMeta));
    }
    if (data.containsKey('post_wait_ms')) {
      context.handle(
          _postWaitMsMeta,
          postWaitMs.isAcceptableOrUnknown(
              data['post_wait_ms']!, _postWaitMsMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShowCue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShowCue(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      cueListId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cue_list_id'])!,
      number: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}number'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      cueType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cue_type'])!,
      paramsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}params_json'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      targetNodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_node_id']),
      autoContinue: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_continue'])!,
      preWaitMs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}pre_wait_ms'])!,
      postWaitMs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}post_wait_ms'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
    );
  }

  @override
  $ShowCuesTable createAlias(String alias) {
    return $ShowCuesTable(attachedDatabase, alias);
  }
}

class ShowCue extends DataClass implements Insertable<ShowCue> {
  final String id;
  final String cueListId;
  final String number;
  final String label;
  final int cueType;
  final String paramsJson;
  final int orderIndex;
  final String? targetNodeId;
  final bool autoContinue;
  final double preWaitMs;
  final double postWaitMs;
  final int version;
  const ShowCue(
      {required this.id,
      required this.cueListId,
      required this.number,
      required this.label,
      required this.cueType,
      required this.paramsJson,
      required this.orderIndex,
      this.targetNodeId,
      required this.autoContinue,
      required this.preWaitMs,
      required this.postWaitMs,
      required this.version});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['cue_list_id'] = Variable<String>(cueListId);
    map['number'] = Variable<String>(number);
    map['label'] = Variable<String>(label);
    map['cue_type'] = Variable<int>(cueType);
    map['params_json'] = Variable<String>(paramsJson);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || targetNodeId != null) {
      map['target_node_id'] = Variable<String>(targetNodeId);
    }
    map['auto_continue'] = Variable<bool>(autoContinue);
    map['pre_wait_ms'] = Variable<double>(preWaitMs);
    map['post_wait_ms'] = Variable<double>(postWaitMs);
    map['version'] = Variable<int>(version);
    return map;
  }

  ShowCuesCompanion toCompanion(bool nullToAbsent) {
    return ShowCuesCompanion(
      id: Value(id),
      cueListId: Value(cueListId),
      number: Value(number),
      label: Value(label),
      cueType: Value(cueType),
      paramsJson: Value(paramsJson),
      orderIndex: Value(orderIndex),
      targetNodeId: targetNodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetNodeId),
      autoContinue: Value(autoContinue),
      preWaitMs: Value(preWaitMs),
      postWaitMs: Value(postWaitMs),
      version: Value(version),
    );
  }

  factory ShowCue.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShowCue(
      id: serializer.fromJson<String>(json['id']),
      cueListId: serializer.fromJson<String>(json['cueListId']),
      number: serializer.fromJson<String>(json['number']),
      label: serializer.fromJson<String>(json['label']),
      cueType: serializer.fromJson<int>(json['cueType']),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      targetNodeId: serializer.fromJson<String?>(json['targetNodeId']),
      autoContinue: serializer.fromJson<bool>(json['autoContinue']),
      preWaitMs: serializer.fromJson<double>(json['preWaitMs']),
      postWaitMs: serializer.fromJson<double>(json['postWaitMs']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cueListId': serializer.toJson<String>(cueListId),
      'number': serializer.toJson<String>(number),
      'label': serializer.toJson<String>(label),
      'cueType': serializer.toJson<int>(cueType),
      'paramsJson': serializer.toJson<String>(paramsJson),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'targetNodeId': serializer.toJson<String?>(targetNodeId),
      'autoContinue': serializer.toJson<bool>(autoContinue),
      'preWaitMs': serializer.toJson<double>(preWaitMs),
      'postWaitMs': serializer.toJson<double>(postWaitMs),
      'version': serializer.toJson<int>(version),
    };
  }

  ShowCue copyWith(
          {String? id,
          String? cueListId,
          String? number,
          String? label,
          int? cueType,
          String? paramsJson,
          int? orderIndex,
          Value<String?> targetNodeId = const Value.absent(),
          bool? autoContinue,
          double? preWaitMs,
          double? postWaitMs,
          int? version}) =>
      ShowCue(
        id: id ?? this.id,
        cueListId: cueListId ?? this.cueListId,
        number: number ?? this.number,
        label: label ?? this.label,
        cueType: cueType ?? this.cueType,
        paramsJson: paramsJson ?? this.paramsJson,
        orderIndex: orderIndex ?? this.orderIndex,
        targetNodeId:
            targetNodeId.present ? targetNodeId.value : this.targetNodeId,
        autoContinue: autoContinue ?? this.autoContinue,
        preWaitMs: preWaitMs ?? this.preWaitMs,
        postWaitMs: postWaitMs ?? this.postWaitMs,
        version: version ?? this.version,
      );
  ShowCue copyWithCompanion(ShowCuesCompanion data) {
    return ShowCue(
      id: data.id.present ? data.id.value : this.id,
      cueListId: data.cueListId.present ? data.cueListId.value : this.cueListId,
      number: data.number.present ? data.number.value : this.number,
      label: data.label.present ? data.label.value : this.label,
      cueType: data.cueType.present ? data.cueType.value : this.cueType,
      paramsJson:
          data.paramsJson.present ? data.paramsJson.value : this.paramsJson,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      targetNodeId: data.targetNodeId.present
          ? data.targetNodeId.value
          : this.targetNodeId,
      autoContinue: data.autoContinue.present
          ? data.autoContinue.value
          : this.autoContinue,
      preWaitMs: data.preWaitMs.present ? data.preWaitMs.value : this.preWaitMs,
      postWaitMs:
          data.postWaitMs.present ? data.postWaitMs.value : this.postWaitMs,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShowCue(')
          ..write('id: $id, ')
          ..write('cueListId: $cueListId, ')
          ..write('number: $number, ')
          ..write('label: $label, ')
          ..write('cueType: $cueType, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('targetNodeId: $targetNodeId, ')
          ..write('autoContinue: $autoContinue, ')
          ..write('preWaitMs: $preWaitMs, ')
          ..write('postWaitMs: $postWaitMs, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      cueListId,
      number,
      label,
      cueType,
      paramsJson,
      orderIndex,
      targetNodeId,
      autoContinue,
      preWaitMs,
      postWaitMs,
      version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShowCue &&
          other.id == this.id &&
          other.cueListId == this.cueListId &&
          other.number == this.number &&
          other.label == this.label &&
          other.cueType == this.cueType &&
          other.paramsJson == this.paramsJson &&
          other.orderIndex == this.orderIndex &&
          other.targetNodeId == this.targetNodeId &&
          other.autoContinue == this.autoContinue &&
          other.preWaitMs == this.preWaitMs &&
          other.postWaitMs == this.postWaitMs &&
          other.version == this.version);
}

class ShowCuesCompanion extends UpdateCompanion<ShowCue> {
  final Value<String> id;
  final Value<String> cueListId;
  final Value<String> number;
  final Value<String> label;
  final Value<int> cueType;
  final Value<String> paramsJson;
  final Value<int> orderIndex;
  final Value<String?> targetNodeId;
  final Value<bool> autoContinue;
  final Value<double> preWaitMs;
  final Value<double> postWaitMs;
  final Value<int> version;
  final Value<int> rowid;
  const ShowCuesCompanion({
    this.id = const Value.absent(),
    this.cueListId = const Value.absent(),
    this.number = const Value.absent(),
    this.label = const Value.absent(),
    this.cueType = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.targetNodeId = const Value.absent(),
    this.autoContinue = const Value.absent(),
    this.preWaitMs = const Value.absent(),
    this.postWaitMs = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShowCuesCompanion.insert({
    required String id,
    required String cueListId,
    required String number,
    required String label,
    required int cueType,
    required String paramsJson,
    required int orderIndex,
    this.targetNodeId = const Value.absent(),
    this.autoContinue = const Value.absent(),
    this.preWaitMs = const Value.absent(),
    this.postWaitMs = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        cueListId = Value(cueListId),
        number = Value(number),
        label = Value(label),
        cueType = Value(cueType),
        paramsJson = Value(paramsJson),
        orderIndex = Value(orderIndex);
  static Insertable<ShowCue> custom({
    Expression<String>? id,
    Expression<String>? cueListId,
    Expression<String>? number,
    Expression<String>? label,
    Expression<int>? cueType,
    Expression<String>? paramsJson,
    Expression<int>? orderIndex,
    Expression<String>? targetNodeId,
    Expression<bool>? autoContinue,
    Expression<double>? preWaitMs,
    Expression<double>? postWaitMs,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cueListId != null) 'cue_list_id': cueListId,
      if (number != null) 'number': number,
      if (label != null) 'label': label,
      if (cueType != null) 'cue_type': cueType,
      if (paramsJson != null) 'params_json': paramsJson,
      if (orderIndex != null) 'order_index': orderIndex,
      if (targetNodeId != null) 'target_node_id': targetNodeId,
      if (autoContinue != null) 'auto_continue': autoContinue,
      if (preWaitMs != null) 'pre_wait_ms': preWaitMs,
      if (postWaitMs != null) 'post_wait_ms': postWaitMs,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShowCuesCompanion copyWith(
      {Value<String>? id,
      Value<String>? cueListId,
      Value<String>? number,
      Value<String>? label,
      Value<int>? cueType,
      Value<String>? paramsJson,
      Value<int>? orderIndex,
      Value<String?>? targetNodeId,
      Value<bool>? autoContinue,
      Value<double>? preWaitMs,
      Value<double>? postWaitMs,
      Value<int>? version,
      Value<int>? rowid}) {
    return ShowCuesCompanion(
      id: id ?? this.id,
      cueListId: cueListId ?? this.cueListId,
      number: number ?? this.number,
      label: label ?? this.label,
      cueType: cueType ?? this.cueType,
      paramsJson: paramsJson ?? this.paramsJson,
      orderIndex: orderIndex ?? this.orderIndex,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      autoContinue: autoContinue ?? this.autoContinue,
      preWaitMs: preWaitMs ?? this.preWaitMs,
      postWaitMs: postWaitMs ?? this.postWaitMs,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cueListId.present) {
      map['cue_list_id'] = Variable<String>(cueListId.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (cueType.present) {
      map['cue_type'] = Variable<int>(cueType.value);
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (targetNodeId.present) {
      map['target_node_id'] = Variable<String>(targetNodeId.value);
    }
    if (autoContinue.present) {
      map['auto_continue'] = Variable<bool>(autoContinue.value);
    }
    if (preWaitMs.present) {
      map['pre_wait_ms'] = Variable<double>(preWaitMs.value);
    }
    if (postWaitMs.present) {
      map['post_wait_ms'] = Variable<double>(postWaitMs.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShowCuesCompanion(')
          ..write('id: $id, ')
          ..write('cueListId: $cueListId, ')
          ..write('number: $number, ')
          ..write('label: $label, ')
          ..write('cueType: $cueType, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('targetNodeId: $targetNodeId, ')
          ..write('autoContinue: $autoContinue, ')
          ..write('preWaitMs: $preWaitMs, ')
          ..write('postWaitMs: $postWaitMs, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $PacketQueueTable packetQueue = $PacketQueueTable(this);
  late final $PeerTableTable peerTable = $PeerTableTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $ShowCueListsTable showCueLists = $ShowCueListsTable(this);
  late final $ShowCuesTable showCues = $ShowCuesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        inventoryItems,
        packetQueue,
        peerTable,
        chatMessages,
        showCueLists,
        showCues
      ];
}

typedef $$InventoryItemsTableCreateCompanionBuilder = InventoryItemsCompanion
    Function({
  Value<int> id,
  required String itemId,
  required String crdtJson,
  required int statusId,
  Value<String?> locationTag,
  required int lastUpdatedMs,
  required String sourceDeviceId,
  Value<bool> isSyncedToServer,
});
typedef $$InventoryItemsTableUpdateCompanionBuilder = InventoryItemsCompanion
    Function({
  Value<int> id,
  Value<String> itemId,
  Value<String> crdtJson,
  Value<int> statusId,
  Value<String?> locationTag,
  Value<int> lastUpdatedMs,
  Value<String> sourceDeviceId,
  Value<bool> isSyncedToServer,
});

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get crdtJson => $composableBuilder(
      column: $table.crdtJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get statusId => $composableBuilder(
      column: $table.statusId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locationTag => $composableBuilder(
      column: $table.locationTag, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastUpdatedMs => $composableBuilder(
      column: $table.lastUpdatedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceDeviceId => $composableBuilder(
      column: $table.sourceDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSyncedToServer => $composableBuilder(
      column: $table.isSyncedToServer,
      builder: (column) => ColumnFilters(column));
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get crdtJson => $composableBuilder(
      column: $table.crdtJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get statusId => $composableBuilder(
      column: $table.statusId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationTag => $composableBuilder(
      column: $table.locationTag, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastUpdatedMs => $composableBuilder(
      column: $table.lastUpdatedMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceDeviceId => $composableBuilder(
      column: $table.sourceDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSyncedToServer => $composableBuilder(
      column: $table.isSyncedToServer,
      builder: (column) => ColumnOrderings(column));
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get crdtJson =>
      $composableBuilder(column: $table.crdtJson, builder: (column) => column);

  GeneratedColumn<int> get statusId =>
      $composableBuilder(column: $table.statusId, builder: (column) => column);

  GeneratedColumn<String> get locationTag => $composableBuilder(
      column: $table.locationTag, builder: (column) => column);

  GeneratedColumn<int> get lastUpdatedMs => $composableBuilder(
      column: $table.lastUpdatedMs, builder: (column) => column);

  GeneratedColumn<String> get sourceDeviceId => $composableBuilder(
      column: $table.sourceDeviceId, builder: (column) => column);

  GeneratedColumn<bool> get isSyncedToServer => $composableBuilder(
      column: $table.isSyncedToServer, builder: (column) => column);
}

class $$InventoryItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryItemsTable,
    InventoryItem,
    $$InventoryItemsTableFilterComposer,
    $$InventoryItemsTableOrderingComposer,
    $$InventoryItemsTableAnnotationComposer,
    $$InventoryItemsTableCreateCompanionBuilder,
    $$InventoryItemsTableUpdateCompanionBuilder,
    (
      InventoryItem,
      BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>
    ),
    InventoryItem,
    PrefetchHooks Function()> {
  $$InventoryItemsTableTableManager(
      _$AppDatabase db, $InventoryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<String> crdtJson = const Value.absent(),
            Value<int> statusId = const Value.absent(),
            Value<String?> locationTag = const Value.absent(),
            Value<int> lastUpdatedMs = const Value.absent(),
            Value<String> sourceDeviceId = const Value.absent(),
            Value<bool> isSyncedToServer = const Value.absent(),
          }) =>
              InventoryItemsCompanion(
            id: id,
            itemId: itemId,
            crdtJson: crdtJson,
            statusId: statusId,
            locationTag: locationTag,
            lastUpdatedMs: lastUpdatedMs,
            sourceDeviceId: sourceDeviceId,
            isSyncedToServer: isSyncedToServer,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String itemId,
            required String crdtJson,
            required int statusId,
            Value<String?> locationTag = const Value.absent(),
            required int lastUpdatedMs,
            required String sourceDeviceId,
            Value<bool> isSyncedToServer = const Value.absent(),
          }) =>
              InventoryItemsCompanion.insert(
            id: id,
            itemId: itemId,
            crdtJson: crdtJson,
            statusId: statusId,
            locationTag: locationTag,
            lastUpdatedMs: lastUpdatedMs,
            sourceDeviceId: sourceDeviceId,
            isSyncedToServer: isSyncedToServer,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryItemsTable,
    InventoryItem,
    $$InventoryItemsTableFilterComposer,
    $$InventoryItemsTableOrderingComposer,
    $$InventoryItemsTableAnnotationComposer,
    $$InventoryItemsTableCreateCompanionBuilder,
    $$InventoryItemsTableUpdateCompanionBuilder,
    (
      InventoryItem,
      BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>
    ),
    InventoryItem,
    PrefetchHooks Function()>;
typedef $$PacketQueueTableCreateCompanionBuilder = PacketQueueCompanion
    Function({
  Value<int> id,
  required Uint8List encryptedPayload,
  Value<String?> targetDeviceId,
  required int packetTypeByte,
  required int createdAtMs,
  Value<int> retryCount,
  Value<bool> isDelivered,
});
typedef $$PacketQueueTableUpdateCompanionBuilder = PacketQueueCompanion
    Function({
  Value<int> id,
  Value<Uint8List> encryptedPayload,
  Value<String?> targetDeviceId,
  Value<int> packetTypeByte,
  Value<int> createdAtMs,
  Value<int> retryCount,
  Value<bool> isDelivered,
});

class $$PacketQueueTableFilterComposer
    extends Composer<_$AppDatabase, $PacketQueueTable> {
  $$PacketQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get encryptedPayload => $composableBuilder(
      column: $table.encryptedPayload,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetDeviceId => $composableBuilder(
      column: $table.targetDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get packetTypeByte => $composableBuilder(
      column: $table.packetTypeByte,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDelivered => $composableBuilder(
      column: $table.isDelivered, builder: (column) => ColumnFilters(column));
}

class $$PacketQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $PacketQueueTable> {
  $$PacketQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get encryptedPayload => $composableBuilder(
      column: $table.encryptedPayload,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetDeviceId => $composableBuilder(
      column: $table.targetDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get packetTypeByte => $composableBuilder(
      column: $table.packetTypeByte,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDelivered => $composableBuilder(
      column: $table.isDelivered, builder: (column) => ColumnOrderings(column));
}

class $$PacketQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $PacketQueueTable> {
  $$PacketQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedPayload => $composableBuilder(
      column: $table.encryptedPayload, builder: (column) => column);

  GeneratedColumn<String> get targetDeviceId => $composableBuilder(
      column: $table.targetDeviceId, builder: (column) => column);

  GeneratedColumn<int> get packetTypeByte => $composableBuilder(
      column: $table.packetTypeByte, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<bool> get isDelivered => $composableBuilder(
      column: $table.isDelivered, builder: (column) => column);
}

class $$PacketQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PacketQueueTable,
    PacketQueueData,
    $$PacketQueueTableFilterComposer,
    $$PacketQueueTableOrderingComposer,
    $$PacketQueueTableAnnotationComposer,
    $$PacketQueueTableCreateCompanionBuilder,
    $$PacketQueueTableUpdateCompanionBuilder,
    (
      PacketQueueData,
      BaseReferences<_$AppDatabase, $PacketQueueTable, PacketQueueData>
    ),
    PacketQueueData,
    PrefetchHooks Function()> {
  $$PacketQueueTableTableManager(_$AppDatabase db, $PacketQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PacketQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PacketQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PacketQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<Uint8List> encryptedPayload = const Value.absent(),
            Value<String?> targetDeviceId = const Value.absent(),
            Value<int> packetTypeByte = const Value.absent(),
            Value<int> createdAtMs = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<bool> isDelivered = const Value.absent(),
          }) =>
              PacketQueueCompanion(
            id: id,
            encryptedPayload: encryptedPayload,
            targetDeviceId: targetDeviceId,
            packetTypeByte: packetTypeByte,
            createdAtMs: createdAtMs,
            retryCount: retryCount,
            isDelivered: isDelivered,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required Uint8List encryptedPayload,
            Value<String?> targetDeviceId = const Value.absent(),
            required int packetTypeByte,
            required int createdAtMs,
            Value<int> retryCount = const Value.absent(),
            Value<bool> isDelivered = const Value.absent(),
          }) =>
              PacketQueueCompanion.insert(
            id: id,
            encryptedPayload: encryptedPayload,
            targetDeviceId: targetDeviceId,
            packetTypeByte: packetTypeByte,
            createdAtMs: createdAtMs,
            retryCount: retryCount,
            isDelivered: isDelivered,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PacketQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PacketQueueTable,
    PacketQueueData,
    $$PacketQueueTableFilterComposer,
    $$PacketQueueTableOrderingComposer,
    $$PacketQueueTableAnnotationComposer,
    $$PacketQueueTableCreateCompanionBuilder,
    $$PacketQueueTableUpdateCompanionBuilder,
    (
      PacketQueueData,
      BaseReferences<_$AppDatabase, $PacketQueueTable, PacketQueueData>
    ),
    PacketQueueData,
    PrefetchHooks Function()>;
typedef $$PeerTableTableCreateCompanionBuilder = PeerTableCompanion Function({
  required String deviceId,
  required int deviceShortId,
  Value<int> electionScore,
  Value<int> rssi,
  required int lastSeenMs,
  Value<bool> isLeader,
  Value<bool> hasInternet,
  Value<int> rowid,
});
typedef $$PeerTableTableUpdateCompanionBuilder = PeerTableCompanion Function({
  Value<String> deviceId,
  Value<int> deviceShortId,
  Value<int> electionScore,
  Value<int> rssi,
  Value<int> lastSeenMs,
  Value<bool> isLeader,
  Value<bool> hasInternet,
  Value<int> rowid,
});

class $$PeerTableTableFilterComposer
    extends Composer<_$AppDatabase, $PeerTableTable> {
  $$PeerTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deviceShortId => $composableBuilder(
      column: $table.deviceShortId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get electionScore => $composableBuilder(
      column: $table.electionScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rssi => $composableBuilder(
      column: $table.rssi, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastSeenMs => $composableBuilder(
      column: $table.lastSeenMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLeader => $composableBuilder(
      column: $table.isLeader, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasInternet => $composableBuilder(
      column: $table.hasInternet, builder: (column) => ColumnFilters(column));
}

class $$PeerTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PeerTableTable> {
  $$PeerTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deviceShortId => $composableBuilder(
      column: $table.deviceShortId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get electionScore => $composableBuilder(
      column: $table.electionScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rssi => $composableBuilder(
      column: $table.rssi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastSeenMs => $composableBuilder(
      column: $table.lastSeenMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLeader => $composableBuilder(
      column: $table.isLeader, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasInternet => $composableBuilder(
      column: $table.hasInternet, builder: (column) => ColumnOrderings(column));
}

class $$PeerTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeerTableTable> {
  $$PeerTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get deviceShortId => $composableBuilder(
      column: $table.deviceShortId, builder: (column) => column);

  GeneratedColumn<int> get electionScore => $composableBuilder(
      column: $table.electionScore, builder: (column) => column);

  GeneratedColumn<int> get rssi =>
      $composableBuilder(column: $table.rssi, builder: (column) => column);

  GeneratedColumn<int> get lastSeenMs => $composableBuilder(
      column: $table.lastSeenMs, builder: (column) => column);

  GeneratedColumn<bool> get isLeader =>
      $composableBuilder(column: $table.isLeader, builder: (column) => column);

  GeneratedColumn<bool> get hasInternet => $composableBuilder(
      column: $table.hasInternet, builder: (column) => column);
}

class $$PeerTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeerTableTable,
    PeerTableData,
    $$PeerTableTableFilterComposer,
    $$PeerTableTableOrderingComposer,
    $$PeerTableTableAnnotationComposer,
    $$PeerTableTableCreateCompanionBuilder,
    $$PeerTableTableUpdateCompanionBuilder,
    (
      PeerTableData,
      BaseReferences<_$AppDatabase, $PeerTableTable, PeerTableData>
    ),
    PeerTableData,
    PrefetchHooks Function()> {
  $$PeerTableTableTableManager(_$AppDatabase db, $PeerTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeerTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeerTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeerTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<int> deviceShortId = const Value.absent(),
            Value<int> electionScore = const Value.absent(),
            Value<int> rssi = const Value.absent(),
            Value<int> lastSeenMs = const Value.absent(),
            Value<bool> isLeader = const Value.absent(),
            Value<bool> hasInternet = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeerTableCompanion(
            deviceId: deviceId,
            deviceShortId: deviceShortId,
            electionScore: electionScore,
            rssi: rssi,
            lastSeenMs: lastSeenMs,
            isLeader: isLeader,
            hasInternet: hasInternet,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required int deviceShortId,
            Value<int> electionScore = const Value.absent(),
            Value<int> rssi = const Value.absent(),
            required int lastSeenMs,
            Value<bool> isLeader = const Value.absent(),
            Value<bool> hasInternet = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PeerTableCompanion.insert(
            deviceId: deviceId,
            deviceShortId: deviceShortId,
            electionScore: electionScore,
            rssi: rssi,
            lastSeenMs: lastSeenMs,
            isLeader: isLeader,
            hasInternet: hasInternet,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PeerTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PeerTableTable,
    PeerTableData,
    $$PeerTableTableFilterComposer,
    $$PeerTableTableOrderingComposer,
    $$PeerTableTableAnnotationComposer,
    $$PeerTableTableCreateCompanionBuilder,
    $$PeerTableTableUpdateCompanionBuilder,
    (
      PeerTableData,
      BaseReferences<_$AppDatabase, $PeerTableTable, PeerTableData>
    ),
    PeerTableData,
    PrefetchHooks Function()>;
typedef $$ChatMessagesTableCreateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<int> id,
  required String messageId,
  required String senderDeviceId,
  required int senderShortId,
  required String senderLabel,
  required String content,
  required int timestampMs,
  Value<bool> isMine,
});
typedef $$ChatMessagesTableUpdateCompanionBuilder = ChatMessagesCompanion
    Function({
  Value<int> id,
  Value<String> messageId,
  Value<String> senderDeviceId,
  Value<int> senderShortId,
  Value<String> senderLabel,
  Value<String> content,
  Value<int> timestampMs,
  Value<bool> isMine,
});

class $$ChatMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderDeviceId => $composableBuilder(
      column: $table.senderDeviceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get senderShortId => $composableBuilder(
      column: $table.senderShortId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderLabel => $composableBuilder(
      column: $table.senderLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestampMs => $composableBuilder(
      column: $table.timestampMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMine => $composableBuilder(
      column: $table.isMine, builder: (column) => ColumnFilters(column));
}

class $$ChatMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderDeviceId => $composableBuilder(
      column: $table.senderDeviceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get senderShortId => $composableBuilder(
      column: $table.senderShortId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderLabel => $composableBuilder(
      column: $table.senderLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestampMs => $composableBuilder(
      column: $table.timestampMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMine => $composableBuilder(
      column: $table.isMine, builder: (column) => ColumnOrderings(column));
}

class $$ChatMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatMessagesTable> {
  $$ChatMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get senderDeviceId => $composableBuilder(
      column: $table.senderDeviceId, builder: (column) => column);

  GeneratedColumn<int> get senderShortId => $composableBuilder(
      column: $table.senderShortId, builder: (column) => column);

  GeneratedColumn<String> get senderLabel => $composableBuilder(
      column: $table.senderLabel, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get timestampMs => $composableBuilder(
      column: $table.timestampMs, builder: (column) => column);

  GeneratedColumn<bool> get isMine =>
      $composableBuilder(column: $table.isMine, builder: (column) => column);
}

class $$ChatMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()> {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> senderDeviceId = const Value.absent(),
            Value<int> senderShortId = const Value.absent(),
            Value<String> senderLabel = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int> timestampMs = const Value.absent(),
            Value<bool> isMine = const Value.absent(),
          }) =>
              ChatMessagesCompanion(
            id: id,
            messageId: messageId,
            senderDeviceId: senderDeviceId,
            senderShortId: senderShortId,
            senderLabel: senderLabel,
            content: content,
            timestampMs: timestampMs,
            isMine: isMine,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String messageId,
            required String senderDeviceId,
            required int senderShortId,
            required String senderLabel,
            required String content,
            required int timestampMs,
            Value<bool> isMine = const Value.absent(),
          }) =>
              ChatMessagesCompanion.insert(
            id: id,
            messageId: messageId,
            senderDeviceId: senderDeviceId,
            senderShortId: senderShortId,
            senderLabel: senderLabel,
            content: content,
            timestampMs: timestampMs,
            isMine: isMine,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatMessagesTable,
    ChatMessage,
    $$ChatMessagesTableFilterComposer,
    $$ChatMessagesTableOrderingComposer,
    $$ChatMessagesTableAnnotationComposer,
    $$ChatMessagesTableCreateCompanionBuilder,
    $$ChatMessagesTableUpdateCompanionBuilder,
    (
      ChatMessage,
      BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessage>
    ),
    ChatMessage,
    PrefetchHooks Function()>;
typedef $$ShowCueListsTableCreateCompanionBuilder = ShowCueListsCompanion
    Function({
  required String id,
  required String sessionId,
  required String name,
  Value<int> version,
  required int updatedAtMs,
  Value<int> rowid,
});
typedef $$ShowCueListsTableUpdateCompanionBuilder = ShowCueListsCompanion
    Function({
  Value<String> id,
  Value<String> sessionId,
  Value<String> name,
  Value<int> version,
  Value<int> updatedAtMs,
  Value<int> rowid,
});

class $$ShowCueListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShowCueListsTable> {
  $$ShowCueListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
      column: $table.updatedAtMs, builder: (column) => ColumnFilters(column));
}

class $$ShowCueListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShowCueListsTable> {
  $$ShowCueListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
      column: $table.updatedAtMs, builder: (column) => ColumnOrderings(column));
}

class $$ShowCueListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShowCueListsTable> {
  $$ShowCueListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
      column: $table.updatedAtMs, builder: (column) => column);
}

class $$ShowCueListsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShowCueListsTable,
    ShowCueList,
    $$ShowCueListsTableFilterComposer,
    $$ShowCueListsTableOrderingComposer,
    $$ShowCueListsTableAnnotationComposer,
    $$ShowCueListsTableCreateCompanionBuilder,
    $$ShowCueListsTableUpdateCompanionBuilder,
    (
      ShowCueList,
      BaseReferences<_$AppDatabase, $ShowCueListsTable, ShowCueList>
    ),
    ShowCueList,
    PrefetchHooks Function()> {
  $$ShowCueListsTableTableManager(_$AppDatabase db, $ShowCueListsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShowCueListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShowCueListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShowCueListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> updatedAtMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShowCueListsCompanion(
            id: id,
            sessionId: sessionId,
            name: name,
            version: version,
            updatedAtMs: updatedAtMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sessionId,
            required String name,
            Value<int> version = const Value.absent(),
            required int updatedAtMs,
            Value<int> rowid = const Value.absent(),
          }) =>
              ShowCueListsCompanion.insert(
            id: id,
            sessionId: sessionId,
            name: name,
            version: version,
            updatedAtMs: updatedAtMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShowCueListsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShowCueListsTable,
    ShowCueList,
    $$ShowCueListsTableFilterComposer,
    $$ShowCueListsTableOrderingComposer,
    $$ShowCueListsTableAnnotationComposer,
    $$ShowCueListsTableCreateCompanionBuilder,
    $$ShowCueListsTableUpdateCompanionBuilder,
    (
      ShowCueList,
      BaseReferences<_$AppDatabase, $ShowCueListsTable, ShowCueList>
    ),
    ShowCueList,
    PrefetchHooks Function()>;
typedef $$ShowCuesTableCreateCompanionBuilder = ShowCuesCompanion Function({
  required String id,
  required String cueListId,
  required String number,
  required String label,
  required int cueType,
  required String paramsJson,
  required int orderIndex,
  Value<String?> targetNodeId,
  Value<bool> autoContinue,
  Value<double> preWaitMs,
  Value<double> postWaitMs,
  Value<int> version,
  Value<int> rowid,
});
typedef $$ShowCuesTableUpdateCompanionBuilder = ShowCuesCompanion Function({
  Value<String> id,
  Value<String> cueListId,
  Value<String> number,
  Value<String> label,
  Value<int> cueType,
  Value<String> paramsJson,
  Value<int> orderIndex,
  Value<String?> targetNodeId,
  Value<bool> autoContinue,
  Value<double> preWaitMs,
  Value<double> postWaitMs,
  Value<int> version,
  Value<int> rowid,
});

class $$ShowCuesTableFilterComposer
    extends Composer<_$AppDatabase, $ShowCuesTable> {
  $$ShowCuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cueListId => $composableBuilder(
      column: $table.cueListId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cueType => $composableBuilder(
      column: $table.cueType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paramsJson => $composableBuilder(
      column: $table.paramsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetNodeId => $composableBuilder(
      column: $table.targetNodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoContinue => $composableBuilder(
      column: $table.autoContinue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get preWaitMs => $composableBuilder(
      column: $table.preWaitMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get postWaitMs => $composableBuilder(
      column: $table.postWaitMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));
}

class $$ShowCuesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShowCuesTable> {
  $$ShowCuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cueListId => $composableBuilder(
      column: $table.cueListId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get number => $composableBuilder(
      column: $table.number, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cueType => $composableBuilder(
      column: $table.cueType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paramsJson => $composableBuilder(
      column: $table.paramsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetNodeId => $composableBuilder(
      column: $table.targetNodeId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoContinue => $composableBuilder(
      column: $table.autoContinue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get preWaitMs => $composableBuilder(
      column: $table.preWaitMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get postWaitMs => $composableBuilder(
      column: $table.postWaitMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));
}

class $$ShowCuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShowCuesTable> {
  $$ShowCuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cueListId =>
      $composableBuilder(column: $table.cueListId, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get cueType =>
      $composableBuilder(column: $table.cueType, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
      column: $table.paramsJson, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get targetNodeId => $composableBuilder(
      column: $table.targetNodeId, builder: (column) => column);

  GeneratedColumn<bool> get autoContinue => $composableBuilder(
      column: $table.autoContinue, builder: (column) => column);

  GeneratedColumn<double> get preWaitMs =>
      $composableBuilder(column: $table.preWaitMs, builder: (column) => column);

  GeneratedColumn<double> get postWaitMs => $composableBuilder(
      column: $table.postWaitMs, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ShowCuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShowCuesTable,
    ShowCue,
    $$ShowCuesTableFilterComposer,
    $$ShowCuesTableOrderingComposer,
    $$ShowCuesTableAnnotationComposer,
    $$ShowCuesTableCreateCompanionBuilder,
    $$ShowCuesTableUpdateCompanionBuilder,
    (ShowCue, BaseReferences<_$AppDatabase, $ShowCuesTable, ShowCue>),
    ShowCue,
    PrefetchHooks Function()> {
  $$ShowCuesTableTableManager(_$AppDatabase db, $ShowCuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShowCuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShowCuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShowCuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> cueListId = const Value.absent(),
            Value<String> number = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> cueType = const Value.absent(),
            Value<String> paramsJson = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String?> targetNodeId = const Value.absent(),
            Value<bool> autoContinue = const Value.absent(),
            Value<double> preWaitMs = const Value.absent(),
            Value<double> postWaitMs = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShowCuesCompanion(
            id: id,
            cueListId: cueListId,
            number: number,
            label: label,
            cueType: cueType,
            paramsJson: paramsJson,
            orderIndex: orderIndex,
            targetNodeId: targetNodeId,
            autoContinue: autoContinue,
            preWaitMs: preWaitMs,
            postWaitMs: postWaitMs,
            version: version,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String cueListId,
            required String number,
            required String label,
            required int cueType,
            required String paramsJson,
            required int orderIndex,
            Value<String?> targetNodeId = const Value.absent(),
            Value<bool> autoContinue = const Value.absent(),
            Value<double> preWaitMs = const Value.absent(),
            Value<double> postWaitMs = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShowCuesCompanion.insert(
            id: id,
            cueListId: cueListId,
            number: number,
            label: label,
            cueType: cueType,
            paramsJson: paramsJson,
            orderIndex: orderIndex,
            targetNodeId: targetNodeId,
            autoContinue: autoContinue,
            preWaitMs: preWaitMs,
            postWaitMs: postWaitMs,
            version: version,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShowCuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShowCuesTable,
    ShowCue,
    $$ShowCuesTableFilterComposer,
    $$ShowCuesTableOrderingComposer,
    $$ShowCuesTableAnnotationComposer,
    $$ShowCuesTableCreateCompanionBuilder,
    $$ShowCuesTableUpdateCompanionBuilder,
    (ShowCue, BaseReferences<_$AppDatabase, $ShowCuesTable, ShowCue>),
    ShowCue,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$PacketQueueTableTableManager get packetQueue =>
      $$PacketQueueTableTableManager(_db, _db.packetQueue);
  $$PeerTableTableTableManager get peerTable =>
      $$PeerTableTableTableManager(_db, _db.peerTable);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$ShowCueListsTableTableManager get showCueLists =>
      $$ShowCueListsTableTableManager(_db, _db.showCueLists);
  $$ShowCuesTableTableManager get showCues =>
      $$ShowCuesTableTableManager(_db, _db.showCues);
}
