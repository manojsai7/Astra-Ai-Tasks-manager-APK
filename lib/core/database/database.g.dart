// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $InboxItemsTable extends InboxItems
    with TableInfo<$InboxItemsTable, InboxItemEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InboxItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processingStatusMeta = const VerificationMeta(
    'processingStatus',
  );
  @override
  late final GeneratedColumn<String> processingStatus = GeneratedColumn<String>(
    'processing_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawText,
    sourceType,
    processingStatus,
    receivedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inbox_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InboxItemEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('processing_status')) {
      context.handle(
        _processingStatusMeta,
        processingStatus.isAcceptableOrUnknown(
          data['processing_status']!,
          _processingStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processingStatusMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InboxItemEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InboxItemEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      processingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}processing_status'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InboxItemsTable createAlias(String alias) {
    return $InboxItemsTable(attachedDatabase, alias);
  }
}

class InboxItemEntry extends DataClass implements Insertable<InboxItemEntry> {
  final String id;
  final String rawText;
  final String sourceType;
  final String processingStatus;
  final DateTime receivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InboxItemEntry({
    required this.id,
    required this.rawText,
    required this.sourceType,
    required this.processingStatus,
    required this.receivedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['raw_text'] = Variable<String>(rawText);
    map['source_type'] = Variable<String>(sourceType);
    map['processing_status'] = Variable<String>(processingStatus);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InboxItemsCompanion toCompanion(bool nullToAbsent) {
    return InboxItemsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      sourceType: Value(sourceType),
      processingStatus: Value(processingStatus),
      receivedAt: Value(receivedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InboxItemEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InboxItemEntry(
      id: serializer.fromJson<String>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      processingStatus: serializer.fromJson<String>(json['processingStatus']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rawText': serializer.toJson<String>(rawText),
      'sourceType': serializer.toJson<String>(sourceType),
      'processingStatus': serializer.toJson<String>(processingStatus),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InboxItemEntry copyWith({
    String? id,
    String? rawText,
    String? sourceType,
    String? processingStatus,
    DateTime? receivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InboxItemEntry(
    id: id ?? this.id,
    rawText: rawText ?? this.rawText,
    sourceType: sourceType ?? this.sourceType,
    processingStatus: processingStatus ?? this.processingStatus,
    receivedAt: receivedAt ?? this.receivedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InboxItemEntry copyWithCompanion(InboxItemsCompanion data) {
    return InboxItemEntry(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      processingStatus: data.processingStatus.present
          ? data.processingStatus.value
          : this.processingStatus,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InboxItemEntry(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('sourceType: $sourceType, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawText,
    sourceType,
    processingStatus,
    receivedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InboxItemEntry &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.sourceType == this.sourceType &&
          other.processingStatus == this.processingStatus &&
          other.receivedAt == this.receivedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InboxItemsCompanion extends UpdateCompanion<InboxItemEntry> {
  final Value<String> id;
  final Value<String> rawText;
  final Value<String> sourceType;
  final Value<String> processingStatus;
  final Value<DateTime> receivedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InboxItemsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.processingStatus = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InboxItemsCompanion.insert({
    required String id,
    required String rawText,
    required String sourceType,
    required String processingStatus,
    required DateTime receivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawText = Value(rawText),
       sourceType = Value(sourceType),
       processingStatus = Value(processingStatus),
       receivedAt = Value(receivedAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InboxItemEntry> custom({
    Expression<String>? id,
    Expression<String>? rawText,
    Expression<String>? sourceType,
    Expression<String>? processingStatus,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (sourceType != null) 'source_type': sourceType,
      if (processingStatus != null) 'processing_status': processingStatus,
      if (receivedAt != null) 'received_at': receivedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InboxItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? rawText,
    Value<String>? sourceType,
    Value<String>? processingStatus,
    Value<DateTime>? receivedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InboxItemsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      sourceType: sourceType ?? this.sourceType,
      processingStatus: processingStatus ?? this.processingStatus,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (processingStatus.present) {
      map['processing_status'] = Variable<String>(processingStatus.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InboxItemsCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('sourceType: $sourceType, ')
          ..write('processingStatus: $processingStatus, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inboxItemIdMeta = const VerificationMeta(
    'inboxItemId',
  );
  @override
  late final GeneratedColumn<String> inboxItemId = GeneratedColumn<String>(
    'inbox_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskTypeMeta = const VerificationMeta(
    'taskType',
  );
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
    'task_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('reminder'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('medium'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
    'order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _subtasksJsonMeta = const VerificationMeta(
    'subtasksJson',
  );
  @override
  late final GeneratedColumn<String> subtasksJson = GeneratedColumn<String>(
    'subtasks_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _organizationMeta = const VerificationMeta(
    'organization',
  );
  @override
  late final GeneratedColumn<String> organization = GeneratedColumn<String>(
    'organization',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inboxItemId,
    title,
    description,
    taskType,
    priority,
    status,
    order,
    subtasksJson,
    dueAt,
    completedAt,
    createdAt,
    updatedAt,
    source,
    sourceId,
    category,
    organization,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('inbox_item_id')) {
      context.handle(
        _inboxItemIdMeta,
        inboxItemId.isAcceptableOrUnknown(
          data['inbox_item_id']!,
          _inboxItemIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('task_type')) {
      context.handle(
        _taskTypeMeta,
        taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('order')) {
      context.handle(
        _orderMeta,
        order.isAcceptableOrUnknown(data['order']!, _orderMeta),
      );
    }
    if (data.containsKey('subtasks_json')) {
      context.handle(
        _subtasksJsonMeta,
        subtasksJson.isAcceptableOrUnknown(
          data['subtasks_json']!,
          _subtasksJsonMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('organization')) {
      context.handle(
        _organizationMeta,
        organization.isAcceptableOrUnknown(
          data['organization']!,
          _organizationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      inboxItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inbox_item_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      taskType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_type'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      order: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order'],
      )!,
      subtasksJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtasks_json'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      organization: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskEntry extends DataClass implements Insertable<TaskEntry> {
  final String id;
  final String? inboxItemId;
  final String title;
  final String? description;
  final String taskType;
  final String priority;
  final String status;
  final int order;
  final String subtasksJson;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? source;
  final String? sourceId;
  final String? category;
  final String? organization;
  const TaskEntry({
    required this.id,
    this.inboxItemId,
    required this.title,
    this.description,
    required this.taskType,
    required this.priority,
    required this.status,
    required this.order,
    required this.subtasksJson,
    this.dueAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.source,
    this.sourceId,
    this.category,
    this.organization,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || inboxItemId != null) {
      map['inbox_item_id'] = Variable<String>(inboxItemId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['task_type'] = Variable<String>(taskType);
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    map['order'] = Variable<int>(order);
    map['subtasks_json'] = Variable<String>(subtasksJson);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || organization != null) {
      map['organization'] = Variable<String>(organization);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      inboxItemId: inboxItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(inboxItemId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      taskType: Value(taskType),
      priority: Value(priority),
      status: Value(status),
      order: Value(order),
      subtasksJson: Value(subtasksJson),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      organization: organization == null && nullToAbsent
          ? const Value.absent()
          : Value(organization),
    );
  }

  factory TaskEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntry(
      id: serializer.fromJson<String>(json['id']),
      inboxItemId: serializer.fromJson<String?>(json['inboxItemId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      taskType: serializer.fromJson<String>(json['taskType']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      order: serializer.fromJson<int>(json['order']),
      subtasksJson: serializer.fromJson<String>(json['subtasksJson']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      source: serializer.fromJson<String?>(json['source']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      category: serializer.fromJson<String?>(json['category']),
      organization: serializer.fromJson<String?>(json['organization']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'inboxItemId': serializer.toJson<String?>(inboxItemId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'taskType': serializer.toJson<String>(taskType),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
      'order': serializer.toJson<int>(order),
      'subtasksJson': serializer.toJson<String>(subtasksJson),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'source': serializer.toJson<String?>(source),
      'sourceId': serializer.toJson<String?>(sourceId),
      'category': serializer.toJson<String?>(category),
      'organization': serializer.toJson<String?>(organization),
    };
  }

  TaskEntry copyWith({
    String? id,
    Value<String?> inboxItemId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    String? taskType,
    String? priority,
    String? status,
    int? order,
    String? subtasksJson,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> source = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> organization = const Value.absent(),
  }) => TaskEntry(
    id: id ?? this.id,
    inboxItemId: inboxItemId.present ? inboxItemId.value : this.inboxItemId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    taskType: taskType ?? this.taskType,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    order: order ?? this.order,
    subtasksJson: subtasksJson ?? this.subtasksJson,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    source: source.present ? source.value : this.source,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    category: category.present ? category.value : this.category,
    organization: organization.present ? organization.value : this.organization,
  );
  TaskEntry copyWithCompanion(TasksCompanion data) {
    return TaskEntry(
      id: data.id.present ? data.id.value : this.id,
      inboxItemId: data.inboxItemId.present
          ? data.inboxItemId.value
          : this.inboxItemId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      order: data.order.present ? data.order.value : this.order,
      subtasksJson: data.subtasksJson.present
          ? data.subtasksJson.value
          : this.subtasksJson,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      category: data.category.present ? data.category.value : this.category,
      organization: data.organization.present
          ? data.organization.value
          : this.organization,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntry(')
          ..write('id: $id, ')
          ..write('inboxItemId: $inboxItemId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('taskType: $taskType, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('order: $order, ')
          ..write('subtasksJson: $subtasksJson, ')
          ..write('dueAt: $dueAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('category: $category, ')
          ..write('organization: $organization')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    inboxItemId,
    title,
    description,
    taskType,
    priority,
    status,
    order,
    subtasksJson,
    dueAt,
    completedAt,
    createdAt,
    updatedAt,
    source,
    sourceId,
    category,
    organization,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntry &&
          other.id == this.id &&
          other.inboxItemId == this.inboxItemId &&
          other.title == this.title &&
          other.description == this.description &&
          other.taskType == this.taskType &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.order == this.order &&
          other.subtasksJson == this.subtasksJson &&
          other.dueAt == this.dueAt &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.category == this.category &&
          other.organization == this.organization);
}

class TasksCompanion extends UpdateCompanion<TaskEntry> {
  final Value<String> id;
  final Value<String?> inboxItemId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> taskType;
  final Value<String> priority;
  final Value<String> status;
  final Value<int> order;
  final Value<String> subtasksJson;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> source;
  final Value<String?> sourceId;
  final Value<String?> category;
  final Value<String?> organization;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.inboxItemId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.taskType = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.order = const Value.absent(),
    this.subtasksJson = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.category = const Value.absent(),
    this.organization = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    this.inboxItemId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.taskType = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.order = const Value.absent(),
    this.subtasksJson = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.category = const Value.absent(),
    this.organization = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskEntry> custom({
    Expression<String>? id,
    Expression<String>? inboxItemId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? taskType,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<int>? order,
    Expression<String>? subtasksJson,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? category,
    Expression<String>? organization,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (inboxItemId != null) 'inbox_item_id': inboxItemId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (taskType != null) 'task_type': taskType,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (order != null) 'order': order,
      if (subtasksJson != null) 'subtasks_json': subtasksJson,
      if (dueAt != null) 'due_at': dueAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (category != null) 'category': category,
      if (organization != null) 'organization': organization,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String?>? inboxItemId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? taskType,
    Value<String>? priority,
    Value<String>? status,
    Value<int>? order,
    Value<String>? subtasksJson,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? source,
    Value<String?>? sourceId,
    Value<String?>? category,
    Value<String?>? organization,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      inboxItemId: inboxItemId ?? this.inboxItemId,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      order: order ?? this.order,
      subtasksJson: subtasksJson ?? this.subtasksJson,
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      category: category ?? this.category,
      organization: organization ?? this.organization,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (inboxItemId.present) {
      map['inbox_item_id'] = Variable<String>(inboxItemId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (subtasksJson.present) {
      map['subtasks_json'] = Variable<String>(subtasksJson.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (organization.present) {
      map['organization'] = Variable<String>(organization.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('inboxItemId: $inboxItemId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('taskType: $taskType, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('order: $order, ')
          ..write('subtasksJson: $subtasksJson, ')
          ..write('dueAt: $dueAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('category: $category, ')
          ..write('organization: $organization, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PanchangEventsTable extends PanchangEvents
    with TableInfo<$PanchangEventsTable, PanchangEventEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PanchangEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventNameMeta = const VerificationMeta(
    'eventName',
  );
  @override
  late final GeneratedColumn<String> eventName = GeneratedColumn<String>(
    'event_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventDateMeta = const VerificationMeta(
    'eventDate',
  );
  @override
  late final GeneratedColumn<DateTime> eventDate = GeneratedColumn<DateTime>(
    'event_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pakshaMeta = const VerificationMeta('paksha');
  @override
  late final GeneratedColumn<String> paksha = GeneratedColumn<String>(
    'paksha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lunarMonthMeta = const VerificationMeta(
    'lunarMonth',
  );
  @override
  late final GeneratedColumn<String> lunarMonth = GeneratedColumn<String>(
    'lunar_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calendarYearMeta = const VerificationMeta(
    'calendarYear',
  );
  @override
  late final GeneratedColumn<int> calendarYear = GeneratedColumn<int>(
    'calendar_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationScheduledMeta =
      const VerificationMeta('notificationScheduled');
  @override
  late final GeneratedColumn<bool> notificationScheduled =
      GeneratedColumn<bool>(
        'notification_scheduled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notification_scheduled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventName,
    displayName,
    eventDate,
    paksha,
    lunarMonth,
    description,
    calendarYear,
    notificationScheduled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'panchang_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PanchangEventEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_name')) {
      context.handle(
        _eventNameMeta,
        eventName.isAcceptableOrUnknown(data['event_name']!, _eventNameMeta),
      );
    } else if (isInserting) {
      context.missing(_eventNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('event_date')) {
      context.handle(
        _eventDateMeta,
        eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta),
      );
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('paksha')) {
      context.handle(
        _pakshaMeta,
        paksha.isAcceptableOrUnknown(data['paksha']!, _pakshaMeta),
      );
    } else if (isInserting) {
      context.missing(_pakshaMeta);
    }
    if (data.containsKey('lunar_month')) {
      context.handle(
        _lunarMonthMeta,
        lunarMonth.isAcceptableOrUnknown(data['lunar_month']!, _lunarMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_lunarMonthMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('calendar_year')) {
      context.handle(
        _calendarYearMeta,
        calendarYear.isAcceptableOrUnknown(
          data['calendar_year']!,
          _calendarYearMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calendarYearMeta);
    }
    if (data.containsKey('notification_scheduled')) {
      context.handle(
        _notificationScheduledMeta,
        notificationScheduled.isAcceptableOrUnknown(
          data['notification_scheduled']!,
          _notificationScheduledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PanchangEventEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PanchangEventEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_date'],
      )!,
      paksha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paksha'],
      )!,
      lunarMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lunar_month'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      calendarYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calendar_year'],
      )!,
      notificationScheduled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notification_scheduled'],
      )!,
    );
  }

  @override
  $PanchangEventsTable createAlias(String alias) {
    return $PanchangEventsTable(attachedDatabase, alias);
  }
}

class PanchangEventEntry extends DataClass
    implements Insertable<PanchangEventEntry> {
  final int id;
  final String eventName;
  final String displayName;
  final DateTime eventDate;
  final String paksha;
  final String lunarMonth;
  final String? description;
  final int calendarYear;
  final bool notificationScheduled;
  const PanchangEventEntry({
    required this.id,
    required this.eventName,
    required this.displayName,
    required this.eventDate,
    required this.paksha,
    required this.lunarMonth,
    this.description,
    required this.calendarYear,
    required this.notificationScheduled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_name'] = Variable<String>(eventName);
    map['display_name'] = Variable<String>(displayName);
    map['event_date'] = Variable<DateTime>(eventDate);
    map['paksha'] = Variable<String>(paksha);
    map['lunar_month'] = Variable<String>(lunarMonth);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['calendar_year'] = Variable<int>(calendarYear);
    map['notification_scheduled'] = Variable<bool>(notificationScheduled);
    return map;
  }

  PanchangEventsCompanion toCompanion(bool nullToAbsent) {
    return PanchangEventsCompanion(
      id: Value(id),
      eventName: Value(eventName),
      displayName: Value(displayName),
      eventDate: Value(eventDate),
      paksha: Value(paksha),
      lunarMonth: Value(lunarMonth),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      calendarYear: Value(calendarYear),
      notificationScheduled: Value(notificationScheduled),
    );
  }

  factory PanchangEventEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PanchangEventEntry(
      id: serializer.fromJson<int>(json['id']),
      eventName: serializer.fromJson<String>(json['eventName']),
      displayName: serializer.fromJson<String>(json['displayName']),
      eventDate: serializer.fromJson<DateTime>(json['eventDate']),
      paksha: serializer.fromJson<String>(json['paksha']),
      lunarMonth: serializer.fromJson<String>(json['lunarMonth']),
      description: serializer.fromJson<String?>(json['description']),
      calendarYear: serializer.fromJson<int>(json['calendarYear']),
      notificationScheduled: serializer.fromJson<bool>(
        json['notificationScheduled'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventName': serializer.toJson<String>(eventName),
      'displayName': serializer.toJson<String>(displayName),
      'eventDate': serializer.toJson<DateTime>(eventDate),
      'paksha': serializer.toJson<String>(paksha),
      'lunarMonth': serializer.toJson<String>(lunarMonth),
      'description': serializer.toJson<String?>(description),
      'calendarYear': serializer.toJson<int>(calendarYear),
      'notificationScheduled': serializer.toJson<bool>(notificationScheduled),
    };
  }

  PanchangEventEntry copyWith({
    int? id,
    String? eventName,
    String? displayName,
    DateTime? eventDate,
    String? paksha,
    String? lunarMonth,
    Value<String?> description = const Value.absent(),
    int? calendarYear,
    bool? notificationScheduled,
  }) => PanchangEventEntry(
    id: id ?? this.id,
    eventName: eventName ?? this.eventName,
    displayName: displayName ?? this.displayName,
    eventDate: eventDate ?? this.eventDate,
    paksha: paksha ?? this.paksha,
    lunarMonth: lunarMonth ?? this.lunarMonth,
    description: description.present ? description.value : this.description,
    calendarYear: calendarYear ?? this.calendarYear,
    notificationScheduled: notificationScheduled ?? this.notificationScheduled,
  );
  PanchangEventEntry copyWithCompanion(PanchangEventsCompanion data) {
    return PanchangEventEntry(
      id: data.id.present ? data.id.value : this.id,
      eventName: data.eventName.present ? data.eventName.value : this.eventName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      paksha: data.paksha.present ? data.paksha.value : this.paksha,
      lunarMonth: data.lunarMonth.present
          ? data.lunarMonth.value
          : this.lunarMonth,
      description: data.description.present
          ? data.description.value
          : this.description,
      calendarYear: data.calendarYear.present
          ? data.calendarYear.value
          : this.calendarYear,
      notificationScheduled: data.notificationScheduled.present
          ? data.notificationScheduled.value
          : this.notificationScheduled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PanchangEventEntry(')
          ..write('id: $id, ')
          ..write('eventName: $eventName, ')
          ..write('displayName: $displayName, ')
          ..write('eventDate: $eventDate, ')
          ..write('paksha: $paksha, ')
          ..write('lunarMonth: $lunarMonth, ')
          ..write('description: $description, ')
          ..write('calendarYear: $calendarYear, ')
          ..write('notificationScheduled: $notificationScheduled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventName,
    displayName,
    eventDate,
    paksha,
    lunarMonth,
    description,
    calendarYear,
    notificationScheduled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PanchangEventEntry &&
          other.id == this.id &&
          other.eventName == this.eventName &&
          other.displayName == this.displayName &&
          other.eventDate == this.eventDate &&
          other.paksha == this.paksha &&
          other.lunarMonth == this.lunarMonth &&
          other.description == this.description &&
          other.calendarYear == this.calendarYear &&
          other.notificationScheduled == this.notificationScheduled);
}

class PanchangEventsCompanion extends UpdateCompanion<PanchangEventEntry> {
  final Value<int> id;
  final Value<String> eventName;
  final Value<String> displayName;
  final Value<DateTime> eventDate;
  final Value<String> paksha;
  final Value<String> lunarMonth;
  final Value<String?> description;
  final Value<int> calendarYear;
  final Value<bool> notificationScheduled;
  const PanchangEventsCompanion({
    this.id = const Value.absent(),
    this.eventName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.paksha = const Value.absent(),
    this.lunarMonth = const Value.absent(),
    this.description = const Value.absent(),
    this.calendarYear = const Value.absent(),
    this.notificationScheduled = const Value.absent(),
  });
  PanchangEventsCompanion.insert({
    this.id = const Value.absent(),
    required String eventName,
    required String displayName,
    required DateTime eventDate,
    required String paksha,
    required String lunarMonth,
    this.description = const Value.absent(),
    required int calendarYear,
    this.notificationScheduled = const Value.absent(),
  }) : eventName = Value(eventName),
       displayName = Value(displayName),
       eventDate = Value(eventDate),
       paksha = Value(paksha),
       lunarMonth = Value(lunarMonth),
       calendarYear = Value(calendarYear);
  static Insertable<PanchangEventEntry> custom({
    Expression<int>? id,
    Expression<String>? eventName,
    Expression<String>? displayName,
    Expression<DateTime>? eventDate,
    Expression<String>? paksha,
    Expression<String>? lunarMonth,
    Expression<String>? description,
    Expression<int>? calendarYear,
    Expression<bool>? notificationScheduled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventName != null) 'event_name': eventName,
      if (displayName != null) 'display_name': displayName,
      if (eventDate != null) 'event_date': eventDate,
      if (paksha != null) 'paksha': paksha,
      if (lunarMonth != null) 'lunar_month': lunarMonth,
      if (description != null) 'description': description,
      if (calendarYear != null) 'calendar_year': calendarYear,
      if (notificationScheduled != null)
        'notification_scheduled': notificationScheduled,
    });
  }

  PanchangEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? eventName,
    Value<String>? displayName,
    Value<DateTime>? eventDate,
    Value<String>? paksha,
    Value<String>? lunarMonth,
    Value<String?>? description,
    Value<int>? calendarYear,
    Value<bool>? notificationScheduled,
  }) {
    return PanchangEventsCompanion(
      id: id ?? this.id,
      eventName: eventName ?? this.eventName,
      displayName: displayName ?? this.displayName,
      eventDate: eventDate ?? this.eventDate,
      paksha: paksha ?? this.paksha,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      description: description ?? this.description,
      calendarYear: calendarYear ?? this.calendarYear,
      notificationScheduled:
          notificationScheduled ?? this.notificationScheduled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventName.present) {
      map['event_name'] = Variable<String>(eventName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<DateTime>(eventDate.value);
    }
    if (paksha.present) {
      map['paksha'] = Variable<String>(paksha.value);
    }
    if (lunarMonth.present) {
      map['lunar_month'] = Variable<String>(lunarMonth.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (calendarYear.present) {
      map['calendar_year'] = Variable<int>(calendarYear.value);
    }
    if (notificationScheduled.present) {
      map['notification_scheduled'] = Variable<bool>(
        notificationScheduled.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PanchangEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventName: $eventName, ')
          ..write('displayName: $displayName, ')
          ..write('eventDate: $eventDate, ')
          ..write('paksha: $paksha, ')
          ..write('lunarMonth: $lunarMonth, ')
          ..write('description: $description, ')
          ..write('calendarYear: $calendarYear, ')
          ..write('notificationScheduled: $notificationScheduled')
          ..write(')'))
        .toString();
  }
}

class $RitualRulesTable extends RitualRules
    with TableInfo<$RitualRulesTable, RitualRuleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RitualRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindDaysBeforeMeta = const VerificationMeta(
    'remindDaysBefore',
  );
  @override
  late final GeneratedColumn<int> remindDaysBefore = GeneratedColumn<int>(
    'remind_days_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _remindAtTimeMeta = const VerificationMeta(
    'remindAtTime',
  );
  @override
  late final GeneratedColumn<String> remindAtTime = GeneratedColumn<String>(
    'remind_at_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('06:00'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    title,
    instructions,
    remindDaysBefore,
    remindAtTime,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ritual_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RitualRuleEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('remind_days_before')) {
      context.handle(
        _remindDaysBeforeMeta,
        remindDaysBefore.isAcceptableOrUnknown(
          data['remind_days_before']!,
          _remindDaysBeforeMeta,
        ),
      );
    }
    if (data.containsKey('remind_at_time')) {
      context.handle(
        _remindAtTimeMeta,
        remindAtTime.isAcceptableOrUnknown(
          data['remind_at_time']!,
          _remindAtTimeMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RitualRuleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RitualRuleEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      remindDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_days_before'],
      )!,
      remindAtTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remind_at_time'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $RitualRulesTable createAlias(String alias) {
    return $RitualRulesTable(attachedDatabase, alias);
  }
}

class RitualRuleEntry extends DataClass implements Insertable<RitualRuleEntry> {
  final int id;
  final String eventType;
  final String title;
  final String? instructions;
  final int remindDaysBefore;
  final String remindAtTime;
  final bool isActive;
  const RitualRuleEntry({
    required this.id,
    required this.eventType,
    required this.title,
    this.instructions,
    required this.remindDaysBefore,
    required this.remindAtTime,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_type'] = Variable<String>(eventType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    map['remind_days_before'] = Variable<int>(remindDaysBefore);
    map['remind_at_time'] = Variable<String>(remindAtTime);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  RitualRulesCompanion toCompanion(bool nullToAbsent) {
    return RitualRulesCompanion(
      id: Value(id),
      eventType: Value(eventType),
      title: Value(title),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      remindDaysBefore: Value(remindDaysBefore),
      remindAtTime: Value(remindAtTime),
      isActive: Value(isActive),
    );
  }

  factory RitualRuleEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RitualRuleEntry(
      id: serializer.fromJson<int>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      title: serializer.fromJson<String>(json['title']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      remindDaysBefore: serializer.fromJson<int>(json['remindDaysBefore']),
      remindAtTime: serializer.fromJson<String>(json['remindAtTime']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventType': serializer.toJson<String>(eventType),
      'title': serializer.toJson<String>(title),
      'instructions': serializer.toJson<String?>(instructions),
      'remindDaysBefore': serializer.toJson<int>(remindDaysBefore),
      'remindAtTime': serializer.toJson<String>(remindAtTime),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  RitualRuleEntry copyWith({
    int? id,
    String? eventType,
    String? title,
    Value<String?> instructions = const Value.absent(),
    int? remindDaysBefore,
    String? remindAtTime,
    bool? isActive,
  }) => RitualRuleEntry(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    title: title ?? this.title,
    instructions: instructions.present ? instructions.value : this.instructions,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    remindAtTime: remindAtTime ?? this.remindAtTime,
    isActive: isActive ?? this.isActive,
  );
  RitualRuleEntry copyWithCompanion(RitualRulesCompanion data) {
    return RitualRuleEntry(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      title: data.title.present ? data.title.value : this.title,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      remindDaysBefore: data.remindDaysBefore.present
          ? data.remindDaysBefore.value
          : this.remindDaysBefore,
      remindAtTime: data.remindAtTime.present
          ? data.remindAtTime.value
          : this.remindAtTime,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RitualRuleEntry(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('title: $title, ')
          ..write('instructions: $instructions, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('remindAtTime: $remindAtTime, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventType,
    title,
    instructions,
    remindDaysBefore,
    remindAtTime,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RitualRuleEntry &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.title == this.title &&
          other.instructions == this.instructions &&
          other.remindDaysBefore == this.remindDaysBefore &&
          other.remindAtTime == this.remindAtTime &&
          other.isActive == this.isActive);
}

class RitualRulesCompanion extends UpdateCompanion<RitualRuleEntry> {
  final Value<int> id;
  final Value<String> eventType;
  final Value<String> title;
  final Value<String?> instructions;
  final Value<int> remindDaysBefore;
  final Value<String> remindAtTime;
  final Value<bool> isActive;
  const RitualRulesCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.title = const Value.absent(),
    this.instructions = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.remindAtTime = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  RitualRulesCompanion.insert({
    this.id = const Value.absent(),
    required String eventType,
    required String title,
    this.instructions = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.remindAtTime = const Value.absent(),
    this.isActive = const Value.absent(),
  }) : eventType = Value(eventType),
       title = Value(title);
  static Insertable<RitualRuleEntry> custom({
    Expression<int>? id,
    Expression<String>? eventType,
    Expression<String>? title,
    Expression<String>? instructions,
    Expression<int>? remindDaysBefore,
    Expression<String>? remindAtTime,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (title != null) 'title': title,
      if (instructions != null) 'instructions': instructions,
      if (remindDaysBefore != null) 'remind_days_before': remindDaysBefore,
      if (remindAtTime != null) 'remind_at_time': remindAtTime,
      if (isActive != null) 'is_active': isActive,
    });
  }

  RitualRulesCompanion copyWith({
    Value<int>? id,
    Value<String>? eventType,
    Value<String>? title,
    Value<String?>? instructions,
    Value<int>? remindDaysBefore,
    Value<String>? remindAtTime,
    Value<bool>? isActive,
  }) {
    return RitualRulesCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      remindAtTime: remindAtTime ?? this.remindAtTime,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (remindDaysBefore.present) {
      map['remind_days_before'] = Variable<int>(remindDaysBefore.value);
    }
    if (remindAtTime.present) {
      map['remind_at_time'] = Variable<String>(remindAtTime.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RitualRulesCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('title: $title, ')
          ..write('instructions: $instructions, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('remindAtTime: $remindAtTime, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $TaskContextsTable extends TaskContexts
    with TableInfo<$TaskContextsTable, TaskContextEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requirementsMeta = const VerificationMeta(
    'requirements',
  );
  @override
  late final GeneratedColumn<String> requirements = GeneratedColumn<String>(
    'requirements',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _applicationLinkMeta = const VerificationMeta(
    'applicationLink',
  );
  @override
  late final GeneratedColumn<String> applicationLink = GeneratedColumn<String>(
    'application_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailSnippetMeta = const VerificationMeta(
    'emailSnippet',
  );
  @override
  late final GeneratedColumn<String> emailSnippet = GeneratedColumn<String>(
    'email_snippet',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fullEmailMeta = const VerificationMeta(
    'fullEmail',
  );
  @override
  late final GeneratedColumn<String> fullEmail = GeneratedColumn<String>(
    'full_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasAppliedMeta = const VerificationMeta(
    'hasApplied',
  );
  @override
  late final GeneratedColumn<bool> hasApplied = GeneratedColumn<bool>(
    'has_applied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_applied" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
    'applied_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stipendMeta = const VerificationMeta(
    'stipend',
  );
  @override
  late final GeneratedColumn<String> stipend = GeneratedColumn<String>(
    'stipend',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionItemsMeta = const VerificationMeta(
    'actionItems',
  );
  @override
  late final GeneratedColumn<String> actionItems = GeneratedColumn<String>(
    'action_items',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gmail'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    companyName,
    role,
    requirements,
    applicationLink,
    emailSnippet,
    fullEmail,
    hasApplied,
    appliedAt,
    eventType,
    location,
    stipend,
    actionItems,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskContextEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('requirements')) {
      context.handle(
        _requirementsMeta,
        requirements.isAcceptableOrUnknown(
          data['requirements']!,
          _requirementsMeta,
        ),
      );
    }
    if (data.containsKey('application_link')) {
      context.handle(
        _applicationLinkMeta,
        applicationLink.isAcceptableOrUnknown(
          data['application_link']!,
          _applicationLinkMeta,
        ),
      );
    }
    if (data.containsKey('email_snippet')) {
      context.handle(
        _emailSnippetMeta,
        emailSnippet.isAcceptableOrUnknown(
          data['email_snippet']!,
          _emailSnippetMeta,
        ),
      );
    }
    if (data.containsKey('full_email')) {
      context.handle(
        _fullEmailMeta,
        fullEmail.isAcceptableOrUnknown(data['full_email']!, _fullEmailMeta),
      );
    }
    if (data.containsKey('has_applied')) {
      context.handle(
        _hasAppliedMeta,
        hasApplied.isAcceptableOrUnknown(data['has_applied']!, _hasAppliedMeta),
      );
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('stipend')) {
      context.handle(
        _stipendMeta,
        stipend.isAcceptableOrUnknown(data['stipend']!, _stipendMeta),
      );
    }
    if (data.containsKey('action_items')) {
      context.handle(
        _actionItemsMeta,
        actionItems.isAcceptableOrUnknown(
          data['action_items']!,
          _actionItemsMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskContextEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskContextEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      requirements: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requirements'],
      ),
      applicationLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}application_link'],
      ),
      emailSnippet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_snippet'],
      ),
      fullEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_email'],
      ),
      hasApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_applied'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_at'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      stipend: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stipend'],
      ),
      actionItems: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_items'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $TaskContextsTable createAlias(String alias) {
    return $TaskContextsTable(attachedDatabase, alias);
  }
}

class TaskContextEntry extends DataClass
    implements Insertable<TaskContextEntry> {
  final int id;
  final String taskId;
  final String? companyName;
  final String? role;
  final String? requirements;
  final String? applicationLink;
  final String? emailSnippet;
  final String? fullEmail;
  final bool hasApplied;
  final DateTime? appliedAt;
  final String? eventType;
  final String? location;
  final String? stipend;
  final String? actionItems;
  final String source;
  const TaskContextEntry({
    required this.id,
    required this.taskId,
    this.companyName,
    this.role,
    this.requirements,
    this.applicationLink,
    this.emailSnippet,
    this.fullEmail,
    required this.hasApplied,
    this.appliedAt,
    this.eventType,
    this.location,
    this.stipend,
    this.actionItems,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<String>(taskId);
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || requirements != null) {
      map['requirements'] = Variable<String>(requirements);
    }
    if (!nullToAbsent || applicationLink != null) {
      map['application_link'] = Variable<String>(applicationLink);
    }
    if (!nullToAbsent || emailSnippet != null) {
      map['email_snippet'] = Variable<String>(emailSnippet);
    }
    if (!nullToAbsent || fullEmail != null) {
      map['full_email'] = Variable<String>(fullEmail);
    }
    map['has_applied'] = Variable<bool>(hasApplied);
    if (!nullToAbsent || appliedAt != null) {
      map['applied_at'] = Variable<DateTime>(appliedAt);
    }
    if (!nullToAbsent || eventType != null) {
      map['event_type'] = Variable<String>(eventType);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || stipend != null) {
      map['stipend'] = Variable<String>(stipend);
    }
    if (!nullToAbsent || actionItems != null) {
      map['action_items'] = Variable<String>(actionItems);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  TaskContextsCompanion toCompanion(bool nullToAbsent) {
    return TaskContextsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      requirements: requirements == null && nullToAbsent
          ? const Value.absent()
          : Value(requirements),
      applicationLink: applicationLink == null && nullToAbsent
          ? const Value.absent()
          : Value(applicationLink),
      emailSnippet: emailSnippet == null && nullToAbsent
          ? const Value.absent()
          : Value(emailSnippet),
      fullEmail: fullEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(fullEmail),
      hasApplied: Value(hasApplied),
      appliedAt: appliedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(appliedAt),
      eventType: eventType == null && nullToAbsent
          ? const Value.absent()
          : Value(eventType),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      stipend: stipend == null && nullToAbsent
          ? const Value.absent()
          : Value(stipend),
      actionItems: actionItems == null && nullToAbsent
          ? const Value.absent()
          : Value(actionItems),
      source: Value(source),
    );
  }

  factory TaskContextEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskContextEntry(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      role: serializer.fromJson<String?>(json['role']),
      requirements: serializer.fromJson<String?>(json['requirements']),
      applicationLink: serializer.fromJson<String?>(json['applicationLink']),
      emailSnippet: serializer.fromJson<String?>(json['emailSnippet']),
      fullEmail: serializer.fromJson<String?>(json['fullEmail']),
      hasApplied: serializer.fromJson<bool>(json['hasApplied']),
      appliedAt: serializer.fromJson<DateTime?>(json['appliedAt']),
      eventType: serializer.fromJson<String?>(json['eventType']),
      location: serializer.fromJson<String?>(json['location']),
      stipend: serializer.fromJson<String?>(json['stipend']),
      actionItems: serializer.fromJson<String?>(json['actionItems']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<String>(taskId),
      'companyName': serializer.toJson<String?>(companyName),
      'role': serializer.toJson<String?>(role),
      'requirements': serializer.toJson<String?>(requirements),
      'applicationLink': serializer.toJson<String?>(applicationLink),
      'emailSnippet': serializer.toJson<String?>(emailSnippet),
      'fullEmail': serializer.toJson<String?>(fullEmail),
      'hasApplied': serializer.toJson<bool>(hasApplied),
      'appliedAt': serializer.toJson<DateTime?>(appliedAt),
      'eventType': serializer.toJson<String?>(eventType),
      'location': serializer.toJson<String?>(location),
      'stipend': serializer.toJson<String?>(stipend),
      'actionItems': serializer.toJson<String?>(actionItems),
      'source': serializer.toJson<String>(source),
    };
  }

  TaskContextEntry copyWith({
    int? id,
    String? taskId,
    Value<String?> companyName = const Value.absent(),
    Value<String?> role = const Value.absent(),
    Value<String?> requirements = const Value.absent(),
    Value<String?> applicationLink = const Value.absent(),
    Value<String?> emailSnippet = const Value.absent(),
    Value<String?> fullEmail = const Value.absent(),
    bool? hasApplied,
    Value<DateTime?> appliedAt = const Value.absent(),
    Value<String?> eventType = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<String?> stipend = const Value.absent(),
    Value<String?> actionItems = const Value.absent(),
    String? source,
  }) => TaskContextEntry(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    companyName: companyName.present ? companyName.value : this.companyName,
    role: role.present ? role.value : this.role,
    requirements: requirements.present ? requirements.value : this.requirements,
    applicationLink: applicationLink.present
        ? applicationLink.value
        : this.applicationLink,
    emailSnippet: emailSnippet.present ? emailSnippet.value : this.emailSnippet,
    fullEmail: fullEmail.present ? fullEmail.value : this.fullEmail,
    hasApplied: hasApplied ?? this.hasApplied,
    appliedAt: appliedAt.present ? appliedAt.value : this.appliedAt,
    eventType: eventType.present ? eventType.value : this.eventType,
    location: location.present ? location.value : this.location,
    stipend: stipend.present ? stipend.value : this.stipend,
    actionItems: actionItems.present ? actionItems.value : this.actionItems,
    source: source ?? this.source,
  );
  TaskContextEntry copyWithCompanion(TaskContextsCompanion data) {
    return TaskContextEntry(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      role: data.role.present ? data.role.value : this.role,
      requirements: data.requirements.present
          ? data.requirements.value
          : this.requirements,
      applicationLink: data.applicationLink.present
          ? data.applicationLink.value
          : this.applicationLink,
      emailSnippet: data.emailSnippet.present
          ? data.emailSnippet.value
          : this.emailSnippet,
      fullEmail: data.fullEmail.present ? data.fullEmail.value : this.fullEmail,
      hasApplied: data.hasApplied.present
          ? data.hasApplied.value
          : this.hasApplied,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      location: data.location.present ? data.location.value : this.location,
      stipend: data.stipend.present ? data.stipend.value : this.stipend,
      actionItems: data.actionItems.present
          ? data.actionItems.value
          : this.actionItems,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskContextEntry(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('companyName: $companyName, ')
          ..write('role: $role, ')
          ..write('requirements: $requirements, ')
          ..write('applicationLink: $applicationLink, ')
          ..write('emailSnippet: $emailSnippet, ')
          ..write('fullEmail: $fullEmail, ')
          ..write('hasApplied: $hasApplied, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('eventType: $eventType, ')
          ..write('location: $location, ')
          ..write('stipend: $stipend, ')
          ..write('actionItems: $actionItems, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    companyName,
    role,
    requirements,
    applicationLink,
    emailSnippet,
    fullEmail,
    hasApplied,
    appliedAt,
    eventType,
    location,
    stipend,
    actionItems,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskContextEntry &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.companyName == this.companyName &&
          other.role == this.role &&
          other.requirements == this.requirements &&
          other.applicationLink == this.applicationLink &&
          other.emailSnippet == this.emailSnippet &&
          other.fullEmail == this.fullEmail &&
          other.hasApplied == this.hasApplied &&
          other.appliedAt == this.appliedAt &&
          other.eventType == this.eventType &&
          other.location == this.location &&
          other.stipend == this.stipend &&
          other.actionItems == this.actionItems &&
          other.source == this.source);
}

class TaskContextsCompanion extends UpdateCompanion<TaskContextEntry> {
  final Value<int> id;
  final Value<String> taskId;
  final Value<String?> companyName;
  final Value<String?> role;
  final Value<String?> requirements;
  final Value<String?> applicationLink;
  final Value<String?> emailSnippet;
  final Value<String?> fullEmail;
  final Value<bool> hasApplied;
  final Value<DateTime?> appliedAt;
  final Value<String?> eventType;
  final Value<String?> location;
  final Value<String?> stipend;
  final Value<String?> actionItems;
  final Value<String> source;
  const TaskContextsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.role = const Value.absent(),
    this.requirements = const Value.absent(),
    this.applicationLink = const Value.absent(),
    this.emailSnippet = const Value.absent(),
    this.fullEmail = const Value.absent(),
    this.hasApplied = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.eventType = const Value.absent(),
    this.location = const Value.absent(),
    this.stipend = const Value.absent(),
    this.actionItems = const Value.absent(),
    this.source = const Value.absent(),
  });
  TaskContextsCompanion.insert({
    this.id = const Value.absent(),
    required String taskId,
    this.companyName = const Value.absent(),
    this.role = const Value.absent(),
    this.requirements = const Value.absent(),
    this.applicationLink = const Value.absent(),
    this.emailSnippet = const Value.absent(),
    this.fullEmail = const Value.absent(),
    this.hasApplied = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.eventType = const Value.absent(),
    this.location = const Value.absent(),
    this.stipend = const Value.absent(),
    this.actionItems = const Value.absent(),
    this.source = const Value.absent(),
  }) : taskId = Value(taskId);
  static Insertable<TaskContextEntry> custom({
    Expression<int>? id,
    Expression<String>? taskId,
    Expression<String>? companyName,
    Expression<String>? role,
    Expression<String>? requirements,
    Expression<String>? applicationLink,
    Expression<String>? emailSnippet,
    Expression<String>? fullEmail,
    Expression<bool>? hasApplied,
    Expression<DateTime>? appliedAt,
    Expression<String>? eventType,
    Expression<String>? location,
    Expression<String>? stipend,
    Expression<String>? actionItems,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (companyName != null) 'company_name': companyName,
      if (role != null) 'role': role,
      if (requirements != null) 'requirements': requirements,
      if (applicationLink != null) 'application_link': applicationLink,
      if (emailSnippet != null) 'email_snippet': emailSnippet,
      if (fullEmail != null) 'full_email': fullEmail,
      if (hasApplied != null) 'has_applied': hasApplied,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (eventType != null) 'event_type': eventType,
      if (location != null) 'location': location,
      if (stipend != null) 'stipend': stipend,
      if (actionItems != null) 'action_items': actionItems,
      if (source != null) 'source': source,
    });
  }

  TaskContextsCompanion copyWith({
    Value<int>? id,
    Value<String>? taskId,
    Value<String?>? companyName,
    Value<String?>? role,
    Value<String?>? requirements,
    Value<String?>? applicationLink,
    Value<String?>? emailSnippet,
    Value<String?>? fullEmail,
    Value<bool>? hasApplied,
    Value<DateTime?>? appliedAt,
    Value<String?>? eventType,
    Value<String?>? location,
    Value<String?>? stipend,
    Value<String?>? actionItems,
    Value<String>? source,
  }) {
    return TaskContextsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      requirements: requirements ?? this.requirements,
      applicationLink: applicationLink ?? this.applicationLink,
      emailSnippet: emailSnippet ?? this.emailSnippet,
      fullEmail: fullEmail ?? this.fullEmail,
      hasApplied: hasApplied ?? this.hasApplied,
      appliedAt: appliedAt ?? this.appliedAt,
      eventType: eventType ?? this.eventType,
      location: location ?? this.location,
      stipend: stipend ?? this.stipend,
      actionItems: actionItems ?? this.actionItems,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (requirements.present) {
      map['requirements'] = Variable<String>(requirements.value);
    }
    if (applicationLink.present) {
      map['application_link'] = Variable<String>(applicationLink.value);
    }
    if (emailSnippet.present) {
      map['email_snippet'] = Variable<String>(emailSnippet.value);
    }
    if (fullEmail.present) {
      map['full_email'] = Variable<String>(fullEmail.value);
    }
    if (hasApplied.present) {
      map['has_applied'] = Variable<bool>(hasApplied.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (stipend.present) {
      map['stipend'] = Variable<String>(stipend.value);
    }
    if (actionItems.present) {
      map['action_items'] = Variable<String>(actionItems.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskContextsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('companyName: $companyName, ')
          ..write('role: $role, ')
          ..write('requirements: $requirements, ')
          ..write('applicationLink: $applicationLink, ')
          ..write('emailSnippet: $emailSnippet, ')
          ..write('fullEmail: $fullEmail, ')
          ..write('hasApplied: $hasApplied, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('eventType: $eventType, ')
          ..write('location: $location, ')
          ..write('stipend: $stipend, ')
          ..write('actionItems: $actionItems, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $ChatSessionsTable extends ChatSessions
    with TableInfo<$ChatSessionsTable, ChatSessionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('New Chat'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatSessionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatSessionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatSessionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChatSessionsTable createAlias(String alias) {
    return $ChatSessionsTable(attachedDatabase, alias);
  }
}

class ChatSessionEntry extends DataClass
    implements Insertable<ChatSessionEntry> {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChatSessionEntry({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChatSessionsCompanion toCompanion(bool nullToAbsent) {
    return ChatSessionsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChatSessionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatSessionEntry(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChatSessionEntry copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChatSessionEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChatSessionEntry copyWithCompanion(ChatSessionsCompanion data) {
    return ChatSessionEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatSessionEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChatSessionsCompanion extends UpdateCompanion<ChatSessionEntry> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ChatSessionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChatSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ChatSessionEntry> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChatSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ChatSessionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatSessionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ChatMessagesTable extends ChatMessages
    with TableInfo<$ChatMessagesTable, ChatMessageEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chat_sessions (id)',
    ),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageTypeMeta = const VerificationMeta(
    'messageType',
  );
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    role,
    content,
    messageType,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatMessageEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
        _messageTypeMeta,
        messageType.isAcceptableOrUnknown(
          data['message_type']!,
          _messageTypeMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatMessageEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatMessageEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      messageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $ChatMessagesTable createAlias(String alias) {
    return $ChatMessagesTable(attachedDatabase, alias);
  }
}

class ChatMessageEntry extends DataClass
    implements Insertable<ChatMessageEntry> {
  final int id;
  final int sessionId;
  final String role;
  final String content;
  final String messageType;
  final DateTime timestamp;
  const ChatMessageEntry({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.messageType,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['message_type'] = Variable<String>(messageType);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  ChatMessagesCompanion toCompanion(bool nullToAbsent) {
    return ChatMessagesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      role: Value(role),
      content: Value(content),
      messageType: Value(messageType),
      timestamp: Value(timestamp),
    );
  }

  factory ChatMessageEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatMessageEntry(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      messageType: serializer.fromJson<String>(json['messageType']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'messageType': serializer.toJson<String>(messageType),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ChatMessageEntry copyWith({
    int? id,
    int? sessionId,
    String? role,
    String? content,
    String? messageType,
    DateTime? timestamp,
  }) => ChatMessageEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    role: role ?? this.role,
    content: content ?? this.content,
    messageType: messageType ?? this.messageType,
    timestamp: timestamp ?? this.timestamp,
  );
  ChatMessageEntry copyWithCompanion(ChatMessagesCompanion data) {
    return ChatMessageEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessageEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, role, content, messageType, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatMessageEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.messageType == this.messageType &&
          other.timestamp == this.timestamp);
}

class ChatMessagesCompanion extends UpdateCompanion<ChatMessageEntry> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> role;
  final Value<String> content;
  final Value<String> messageType;
  final Value<DateTime> timestamp;
  const ChatMessagesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.messageType = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  ChatMessagesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String role,
    required String content,
    this.messageType = const Value.absent(),
    required DateTime timestamp,
  }) : sessionId = Value(sessionId),
       role = Value(role),
       content = Value(content),
       timestamp = Value(timestamp);
  static Insertable<ChatMessageEntry> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? messageType,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (messageType != null) 'message_type': messageType,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  ChatMessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? role,
    Value<String>? content,
    Value<String>? messageType,
    Value<DateTime>? timestamp,
  }) {
    return ChatMessagesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatMessagesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('messageType: $messageType, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id)',
    ),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Asia/Kolkata'),
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('scheduled'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    scheduledAt,
    timezone,
    notificationId,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderEntry extends DataClass implements Insertable<ReminderEntry> {
  final String id;
  final String taskId;
  final DateTime scheduledAt;
  final String timezone;
  final int notificationId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ReminderEntry({
    required this.id,
    required this.taskId,
    required this.scheduledAt,
    required this.timezone,
    required this.notificationId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['timezone'] = Variable<String>(timezone);
    map['notification_id'] = Variable<int>(notificationId);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      scheduledAt: Value(scheduledAt),
      timezone: Value(timezone),
      notificationId: Value(notificationId),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReminderEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderEntry(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      timezone: serializer.fromJson<String>(json['timezone']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'timezone': serializer.toJson<String>(timezone),
      'notificationId': serializer.toJson<int>(notificationId),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReminderEntry copyWith({
    String? id,
    String? taskId,
    DateTime? scheduledAt,
    String? timezone,
    int? notificationId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ReminderEntry(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    timezone: timezone ?? this.timezone,
    notificationId: notificationId ?? this.notificationId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReminderEntry copyWithCompanion(RemindersCompanion data) {
    return ReminderEntry(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderEntry(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('timezone: $timezone, ')
          ..write('notificationId: $notificationId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    scheduledAt,
    timezone,
    notificationId,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderEntry &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.scheduledAt == this.scheduledAt &&
          other.timezone == this.timezone &&
          other.notificationId == this.notificationId &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RemindersCompanion extends UpdateCompanion<ReminderEntry> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<DateTime> scheduledAt;
  final Value<String> timezone;
  final Value<int> notificationId;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.timezone = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String taskId,
    required DateTime scheduledAt,
    this.timezone = const Value.absent(),
    required int notificationId,
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       scheduledAt = Value(scheduledAt),
       notificationId = Value(notificationId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReminderEntry> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<DateTime>? scheduledAt,
    Expression<String>? timezone,
    Expression<int>? notificationId,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (timezone != null) 'timezone': timezone,
      if (notificationId != null) 'notification_id': notificationId,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<DateTime>? scheduledAt,
    Value<String>? timezone,
    Value<int>? notificationId,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      timezone: timezone ?? this.timezone,
      notificationId: notificationId ?? this.notificationId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('timezone: $timezone, ')
          ..write('notificationId: $notificationId, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InboxItemsTable inboxItems = $InboxItemsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $PanchangEventsTable panchangEvents = $PanchangEventsTable(this);
  late final $RitualRulesTable ritualRules = $RitualRulesTable(this);
  late final $TaskContextsTable taskContexts = $TaskContextsTable(this);
  late final $ChatSessionsTable chatSessions = $ChatSessionsTable(this);
  late final $ChatMessagesTable chatMessages = $ChatMessagesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inboxItems,
    tasks,
    panchangEvents,
    ritualRules,
    taskContexts,
    chatSessions,
    chatMessages,
    reminders,
  ];
}

typedef $$InboxItemsTableCreateCompanionBuilder =
    InboxItemsCompanion Function({
      required String id,
      required String rawText,
      required String sourceType,
      required String processingStatus,
      required DateTime receivedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$InboxItemsTableUpdateCompanionBuilder =
    InboxItemsCompanion Function({
      Value<String> id,
      Value<String> rawText,
      Value<String> sourceType,
      Value<String> processingStatus,
      Value<DateTime> receivedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$InboxItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InboxItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InboxItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InboxItemsTable> {
  $$InboxItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get processingStatus => $composableBuilder(
    column: $table.processingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InboxItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InboxItemsTable,
          InboxItemEntry,
          $$InboxItemsTableFilterComposer,
          $$InboxItemsTableOrderingComposer,
          $$InboxItemsTableAnnotationComposer,
          $$InboxItemsTableCreateCompanionBuilder,
          $$InboxItemsTableUpdateCompanionBuilder,
          (
            InboxItemEntry,
            BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItemEntry>,
          ),
          InboxItemEntry,
          PrefetchHooks Function()
        > {
  $$InboxItemsTableTableManager(_$AppDatabase db, $InboxItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InboxItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InboxItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InboxItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> processingStatus = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InboxItemsCompanion(
                id: id,
                rawText: rawText,
                sourceType: sourceType,
                processingStatus: processingStatus,
                receivedAt: receivedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rawText,
                required String sourceType,
                required String processingStatus,
                required DateTime receivedAt,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InboxItemsCompanion.insert(
                id: id,
                rawText: rawText,
                sourceType: sourceType,
                processingStatus: processingStatus,
                receivedAt: receivedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InboxItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InboxItemsTable,
      InboxItemEntry,
      $$InboxItemsTableFilterComposer,
      $$InboxItemsTableOrderingComposer,
      $$InboxItemsTableAnnotationComposer,
      $$InboxItemsTableCreateCompanionBuilder,
      $$InboxItemsTableUpdateCompanionBuilder,
      (
        InboxItemEntry,
        BaseReferences<_$AppDatabase, $InboxItemsTable, InboxItemEntry>,
      ),
      InboxItemEntry,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      Value<String?> inboxItemId,
      required String title,
      Value<String?> description,
      Value<String> taskType,
      Value<String> priority,
      Value<String> status,
      Value<int> order,
      Value<String> subtasksJson,
      Value<DateTime?> dueAt,
      Value<DateTime?> completedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> source,
      Value<String?> sourceId,
      Value<String?> category,
      Value<String?> organization,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String?> inboxItemId,
      Value<String> title,
      Value<String?> description,
      Value<String> taskType,
      Value<String> priority,
      Value<String> status,
      Value<int> order,
      Value<String> subtasksJson,
      Value<DateTime?> dueAt,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> source,
      Value<String?> sourceId,
      Value<String?> category,
      Value<String?> organization,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, TaskEntry> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RemindersTable, List<ReminderEntry>>
  _remindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reminders,
    aliasName: 'tasks__id__reminders__task_id',
  );

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inboxItemId => $composableBuilder(
    column: $table.inboxItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtasksJson => $composableBuilder(
    column: $table.subtasksJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organization => $composableBuilder(
    column: $table.organization,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> remindersRefs(
    Expression<bool> Function($$RemindersTableFilterComposer f) f,
  ) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inboxItemId => $composableBuilder(
    column: $table.inboxItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get order => $composableBuilder(
    column: $table.order,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtasksJson => $composableBuilder(
    column: $table.subtasksJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organization => $composableBuilder(
    column: $table.organization,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get inboxItemId => $composableBuilder(
    column: $table.inboxItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<String> get subtasksJson => $composableBuilder(
    column: $table.subtasksJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get organization => $composableBuilder(
    column: $table.organization,
    builder: (column) => column,
  );

  Expression<T> remindersRefs<T extends Object>(
    Expression<T> Function($$RemindersTableAnnotationComposer a) f,
  ) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskEntry,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskEntry, $$TasksTableReferences),
          TaskEntry,
          PrefetchHooks Function({bool remindersRefs})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> inboxItemId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> taskType = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String> subtasksJson = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> organization = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                inboxItemId: inboxItemId,
                title: title,
                description: description,
                taskType: taskType,
                priority: priority,
                status: status,
                order: order,
                subtasksJson: subtasksJson,
                dueAt: dueAt,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                source: source,
                sourceId: sourceId,
                category: category,
                organization: organization,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> inboxItemId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> taskType = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> order = const Value.absent(),
                Value<String> subtasksJson = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> source = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> organization = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                inboxItemId: inboxItemId,
                title: title,
                description: description,
                taskType: taskType,
                priority: priority,
                status: status,
                order: order,
                subtasksJson: subtasksJson,
                dueAt: dueAt,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                source: source,
                sourceId: sourceId,
                category: category,
                organization: organization,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({remindersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (remindersRefs) db.reminders],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (remindersRefs)
                    await $_getPrefetchedData<
                      TaskEntry,
                      $TasksTable,
                      ReminderEntry
                    >(
                      currentTable: table,
                      referencedTable: $$TasksTableReferences
                          ._remindersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TasksTableReferences(db, table, p0).remindersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.taskId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskEntry,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskEntry, $$TasksTableReferences),
      TaskEntry,
      PrefetchHooks Function({bool remindersRefs})
    >;
typedef $$PanchangEventsTableCreateCompanionBuilder =
    PanchangEventsCompanion Function({
      Value<int> id,
      required String eventName,
      required String displayName,
      required DateTime eventDate,
      required String paksha,
      required String lunarMonth,
      Value<String?> description,
      required int calendarYear,
      Value<bool> notificationScheduled,
    });
typedef $$PanchangEventsTableUpdateCompanionBuilder =
    PanchangEventsCompanion Function({
      Value<int> id,
      Value<String> eventName,
      Value<String> displayName,
      Value<DateTime> eventDate,
      Value<String> paksha,
      Value<String> lunarMonth,
      Value<String?> description,
      Value<int> calendarYear,
      Value<bool> notificationScheduled,
    });

class $$PanchangEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PanchangEventsTable> {
  $$PanchangEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paksha => $composableBuilder(
    column: $table.paksha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lunarMonth => $composableBuilder(
    column: $table.lunarMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calendarYear => $composableBuilder(
    column: $table.calendarYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationScheduled => $composableBuilder(
    column: $table.notificationScheduled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PanchangEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PanchangEventsTable> {
  $$PanchangEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paksha => $composableBuilder(
    column: $table.paksha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lunarMonth => $composableBuilder(
    column: $table.lunarMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calendarYear => $composableBuilder(
    column: $table.calendarYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationScheduled => $composableBuilder(
    column: $table.notificationScheduled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PanchangEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PanchangEventsTable> {
  $$PanchangEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventName =>
      $composableBuilder(column: $table.eventName, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get paksha =>
      $composableBuilder(column: $table.paksha, builder: (column) => column);

  GeneratedColumn<String> get lunarMonth => $composableBuilder(
    column: $table.lunarMonth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calendarYear => $composableBuilder(
    column: $table.calendarYear,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notificationScheduled => $composableBuilder(
    column: $table.notificationScheduled,
    builder: (column) => column,
  );
}

class $$PanchangEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PanchangEventsTable,
          PanchangEventEntry,
          $$PanchangEventsTableFilterComposer,
          $$PanchangEventsTableOrderingComposer,
          $$PanchangEventsTableAnnotationComposer,
          $$PanchangEventsTableCreateCompanionBuilder,
          $$PanchangEventsTableUpdateCompanionBuilder,
          (
            PanchangEventEntry,
            BaseReferences<
              _$AppDatabase,
              $PanchangEventsTable,
              PanchangEventEntry
            >,
          ),
          PanchangEventEntry,
          PrefetchHooks Function()
        > {
  $$PanchangEventsTableTableManager(
    _$AppDatabase db,
    $PanchangEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PanchangEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PanchangEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PanchangEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventName = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DateTime> eventDate = const Value.absent(),
                Value<String> paksha = const Value.absent(),
                Value<String> lunarMonth = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> calendarYear = const Value.absent(),
                Value<bool> notificationScheduled = const Value.absent(),
              }) => PanchangEventsCompanion(
                id: id,
                eventName: eventName,
                displayName: displayName,
                eventDate: eventDate,
                paksha: paksha,
                lunarMonth: lunarMonth,
                description: description,
                calendarYear: calendarYear,
                notificationScheduled: notificationScheduled,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventName,
                required String displayName,
                required DateTime eventDate,
                required String paksha,
                required String lunarMonth,
                Value<String?> description = const Value.absent(),
                required int calendarYear,
                Value<bool> notificationScheduled = const Value.absent(),
              }) => PanchangEventsCompanion.insert(
                id: id,
                eventName: eventName,
                displayName: displayName,
                eventDate: eventDate,
                paksha: paksha,
                lunarMonth: lunarMonth,
                description: description,
                calendarYear: calendarYear,
                notificationScheduled: notificationScheduled,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PanchangEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PanchangEventsTable,
      PanchangEventEntry,
      $$PanchangEventsTableFilterComposer,
      $$PanchangEventsTableOrderingComposer,
      $$PanchangEventsTableAnnotationComposer,
      $$PanchangEventsTableCreateCompanionBuilder,
      $$PanchangEventsTableUpdateCompanionBuilder,
      (
        PanchangEventEntry,
        BaseReferences<_$AppDatabase, $PanchangEventsTable, PanchangEventEntry>,
      ),
      PanchangEventEntry,
      PrefetchHooks Function()
    >;
typedef $$RitualRulesTableCreateCompanionBuilder =
    RitualRulesCompanion Function({
      Value<int> id,
      required String eventType,
      required String title,
      Value<String?> instructions,
      Value<int> remindDaysBefore,
      Value<String> remindAtTime,
      Value<bool> isActive,
    });
typedef $$RitualRulesTableUpdateCompanionBuilder =
    RitualRulesCompanion Function({
      Value<int> id,
      Value<String> eventType,
      Value<String> title,
      Value<String?> instructions,
      Value<int> remindDaysBefore,
      Value<String> remindAtTime,
      Value<bool> isActive,
    });

class $$RitualRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RitualRulesTable> {
  $$RitualRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remindAtTime => $composableBuilder(
    column: $table.remindAtTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RitualRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RitualRulesTable> {
  $$RitualRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remindAtTime => $composableBuilder(
    column: $table.remindAtTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RitualRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RitualRulesTable> {
  $$RitualRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remindAtTime => $composableBuilder(
    column: $table.remindAtTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$RitualRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RitualRulesTable,
          RitualRuleEntry,
          $$RitualRulesTableFilterComposer,
          $$RitualRulesTableOrderingComposer,
          $$RitualRulesTableAnnotationComposer,
          $$RitualRulesTableCreateCompanionBuilder,
          $$RitualRulesTableUpdateCompanionBuilder,
          (
            RitualRuleEntry,
            BaseReferences<_$AppDatabase, $RitualRulesTable, RitualRuleEntry>,
          ),
          RitualRuleEntry,
          PrefetchHooks Function()
        > {
  $$RitualRulesTableTableManager(_$AppDatabase db, $RitualRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RitualRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RitualRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RitualRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<int> remindDaysBefore = const Value.absent(),
                Value<String> remindAtTime = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => RitualRulesCompanion(
                id: id,
                eventType: eventType,
                title: title,
                instructions: instructions,
                remindDaysBefore: remindDaysBefore,
                remindAtTime: remindAtTime,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventType,
                required String title,
                Value<String?> instructions = const Value.absent(),
                Value<int> remindDaysBefore = const Value.absent(),
                Value<String> remindAtTime = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => RitualRulesCompanion.insert(
                id: id,
                eventType: eventType,
                title: title,
                instructions: instructions,
                remindDaysBefore: remindDaysBefore,
                remindAtTime: remindAtTime,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RitualRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RitualRulesTable,
      RitualRuleEntry,
      $$RitualRulesTableFilterComposer,
      $$RitualRulesTableOrderingComposer,
      $$RitualRulesTableAnnotationComposer,
      $$RitualRulesTableCreateCompanionBuilder,
      $$RitualRulesTableUpdateCompanionBuilder,
      (
        RitualRuleEntry,
        BaseReferences<_$AppDatabase, $RitualRulesTable, RitualRuleEntry>,
      ),
      RitualRuleEntry,
      PrefetchHooks Function()
    >;
typedef $$TaskContextsTableCreateCompanionBuilder =
    TaskContextsCompanion Function({
      Value<int> id,
      required String taskId,
      Value<String?> companyName,
      Value<String?> role,
      Value<String?> requirements,
      Value<String?> applicationLink,
      Value<String?> emailSnippet,
      Value<String?> fullEmail,
      Value<bool> hasApplied,
      Value<DateTime?> appliedAt,
      Value<String?> eventType,
      Value<String?> location,
      Value<String?> stipend,
      Value<String?> actionItems,
      Value<String> source,
    });
typedef $$TaskContextsTableUpdateCompanionBuilder =
    TaskContextsCompanion Function({
      Value<int> id,
      Value<String> taskId,
      Value<String?> companyName,
      Value<String?> role,
      Value<String?> requirements,
      Value<String?> applicationLink,
      Value<String?> emailSnippet,
      Value<String?> fullEmail,
      Value<bool> hasApplied,
      Value<DateTime?> appliedAt,
      Value<String?> eventType,
      Value<String?> location,
      Value<String?> stipend,
      Value<String?> actionItems,
      Value<String> source,
    });

class $$TaskContextsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskContextsTable> {
  $$TaskContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requirements => $composableBuilder(
    column: $table.requirements,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get applicationLink => $composableBuilder(
    column: $table.applicationLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailSnippet => $composableBuilder(
    column: $table.emailSnippet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullEmail => $composableBuilder(
    column: $table.fullEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasApplied => $composableBuilder(
    column: $table.hasApplied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stipend => $composableBuilder(
    column: $table.stipend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionItems => $composableBuilder(
    column: $table.actionItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskContextsTable> {
  $$TaskContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requirements => $composableBuilder(
    column: $table.requirements,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get applicationLink => $composableBuilder(
    column: $table.applicationLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailSnippet => $composableBuilder(
    column: $table.emailSnippet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullEmail => $composableBuilder(
    column: $table.fullEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasApplied => $composableBuilder(
    column: $table.hasApplied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stipend => $composableBuilder(
    column: $table.stipend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionItems => $composableBuilder(
    column: $table.actionItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskContextsTable> {
  $$TaskContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get requirements => $composableBuilder(
    column: $table.requirements,
    builder: (column) => column,
  );

  GeneratedColumn<String> get applicationLink => $composableBuilder(
    column: $table.applicationLink,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emailSnippet => $composableBuilder(
    column: $table.emailSnippet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullEmail =>
      $composableBuilder(column: $table.fullEmail, builder: (column) => column);

  GeneratedColumn<bool> get hasApplied => $composableBuilder(
    column: $table.hasApplied,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get stipend =>
      $composableBuilder(column: $table.stipend, builder: (column) => column);

  GeneratedColumn<String> get actionItems => $composableBuilder(
    column: $table.actionItems,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$TaskContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskContextsTable,
          TaskContextEntry,
          $$TaskContextsTableFilterComposer,
          $$TaskContextsTableOrderingComposer,
          $$TaskContextsTableAnnotationComposer,
          $$TaskContextsTableCreateCompanionBuilder,
          $$TaskContextsTableUpdateCompanionBuilder,
          (
            TaskContextEntry,
            BaseReferences<_$AppDatabase, $TaskContextsTable, TaskContextEntry>,
          ),
          TaskContextEntry,
          PrefetchHooks Function()
        > {
  $$TaskContextsTableTableManager(_$AppDatabase db, $TaskContextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> requirements = const Value.absent(),
                Value<String?> applicationLink = const Value.absent(),
                Value<String?> emailSnippet = const Value.absent(),
                Value<String?> fullEmail = const Value.absent(),
                Value<bool> hasApplied = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<String?> eventType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> stipend = const Value.absent(),
                Value<String?> actionItems = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => TaskContextsCompanion(
                id: id,
                taskId: taskId,
                companyName: companyName,
                role: role,
                requirements: requirements,
                applicationLink: applicationLink,
                emailSnippet: emailSnippet,
                fullEmail: fullEmail,
                hasApplied: hasApplied,
                appliedAt: appliedAt,
                eventType: eventType,
                location: location,
                stipend: stipend,
                actionItems: actionItems,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String taskId,
                Value<String?> companyName = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> requirements = const Value.absent(),
                Value<String?> applicationLink = const Value.absent(),
                Value<String?> emailSnippet = const Value.absent(),
                Value<String?> fullEmail = const Value.absent(),
                Value<bool> hasApplied = const Value.absent(),
                Value<DateTime?> appliedAt = const Value.absent(),
                Value<String?> eventType = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<String?> stipend = const Value.absent(),
                Value<String?> actionItems = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => TaskContextsCompanion.insert(
                id: id,
                taskId: taskId,
                companyName: companyName,
                role: role,
                requirements: requirements,
                applicationLink: applicationLink,
                emailSnippet: emailSnippet,
                fullEmail: fullEmail,
                hasApplied: hasApplied,
                appliedAt: appliedAt,
                eventType: eventType,
                location: location,
                stipend: stipend,
                actionItems: actionItems,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskContextsTable,
      TaskContextEntry,
      $$TaskContextsTableFilterComposer,
      $$TaskContextsTableOrderingComposer,
      $$TaskContextsTableAnnotationComposer,
      $$TaskContextsTableCreateCompanionBuilder,
      $$TaskContextsTableUpdateCompanionBuilder,
      (
        TaskContextEntry,
        BaseReferences<_$AppDatabase, $TaskContextsTable, TaskContextEntry>,
      ),
      TaskContextEntry,
      PrefetchHooks Function()
    >;
typedef $$ChatSessionsTableCreateCompanionBuilder =
    ChatSessionsCompanion Function({
      Value<int> id,
      Value<String> title,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ChatSessionsTableUpdateCompanionBuilder =
    ChatSessionsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ChatSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChatSessionsTable, ChatSessionEntry> {
  $$ChatSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatMessagesTable, List<ChatMessageEntry>>
  _chatMessagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chatMessages,
    aliasName: 'chat_sessions__id__chat_messages__session_id',
  );

  $$ChatMessagesTableProcessedTableManager get chatMessagesRefs {
    final manager = $$ChatMessagesTableTableManager(
      $_db,
      $_db.chatMessages,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChatSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> chatMessagesRefs(
    Expression<bool> Function($$ChatMessagesTableFilterComposer f) f,
  ) {
    final $$ChatMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableFilterComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatSessionsTable> {
  $$ChatSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> chatMessagesRefs<T extends Object>(
    Expression<T> Function($$ChatMessagesTableAnnotationComposer a) f,
  ) {
    final $$ChatMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatMessages,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatMessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatSessionsTable,
          ChatSessionEntry,
          $$ChatSessionsTableFilterComposer,
          $$ChatSessionsTableOrderingComposer,
          $$ChatSessionsTableAnnotationComposer,
          $$ChatSessionsTableCreateCompanionBuilder,
          $$ChatSessionsTableUpdateCompanionBuilder,
          (ChatSessionEntry, $$ChatSessionsTableReferences),
          ChatSessionEntry,
          PrefetchHooks Function({bool chatMessagesRefs})
        > {
  $$ChatSessionsTableTableManager(_$AppDatabase db, $ChatSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ChatSessionsCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ChatSessionsCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatMessagesRefs) db.chatMessages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatMessagesRefs)
                    await $_getPrefetchedData<
                      ChatSessionEntry,
                      $ChatSessionsTable,
                      ChatMessageEntry
                    >(
                      currentTable: table,
                      referencedTable: $$ChatSessionsTableReferences
                          ._chatMessagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ChatSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).chatMessagesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChatSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatSessionsTable,
      ChatSessionEntry,
      $$ChatSessionsTableFilterComposer,
      $$ChatSessionsTableOrderingComposer,
      $$ChatSessionsTableAnnotationComposer,
      $$ChatSessionsTableCreateCompanionBuilder,
      $$ChatSessionsTableUpdateCompanionBuilder,
      (ChatSessionEntry, $$ChatSessionsTableReferences),
      ChatSessionEntry,
      PrefetchHooks Function({bool chatMessagesRefs})
    >;
typedef $$ChatMessagesTableCreateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<int> id,
      required int sessionId,
      required String role,
      required String content,
      Value<String> messageType,
      required DateTime timestamp,
    });
typedef $$ChatMessagesTableUpdateCompanionBuilder =
    ChatMessagesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> role,
      Value<String> content,
      Value<String> messageType,
      Value<DateTime> timestamp,
    });

final class $$ChatMessagesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChatMessagesTable, ChatMessageEntry> {
  $$ChatMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatSessionsTable _sessionIdTable(_$AppDatabase db) => db.chatSessions
      .createAlias('chat_messages__session_id__chat_sessions__id');

  $$ChatSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$ChatSessionsTableTableManager(
      $_db,
      $_db.chatSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$ChatSessionsTableFilterComposer get sessionId {
    final $$ChatSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableFilterComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChatSessionsTableOrderingComposer get sessionId {
    final $$ChatSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$ChatSessionsTableAnnotationComposer get sessionId {
    final $$ChatSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.chatSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.chatSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatMessagesTable,
          ChatMessageEntry,
          $$ChatMessagesTableFilterComposer,
          $$ChatMessagesTableOrderingComposer,
          $$ChatMessagesTableAnnotationComposer,
          $$ChatMessagesTableCreateCompanionBuilder,
          $$ChatMessagesTableUpdateCompanionBuilder,
          (ChatMessageEntry, $$ChatMessagesTableReferences),
          ChatMessageEntry,
          PrefetchHooks Function({bool sessionId})
        > {
  $$ChatMessagesTableTableManager(_$AppDatabase db, $ChatMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => ChatMessagesCompanion(
                id: id,
                sessionId: sessionId,
                role: role,
                content: content,
                messageType: messageType,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String role,
                required String content,
                Value<String> messageType = const Value.absent(),
                required DateTime timestamp,
              }) => ChatMessagesCompanion.insert(
                id: id,
                sessionId: sessionId,
                role: role,
                content: content,
                messageType: messageType,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$ChatMessagesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$ChatMessagesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatMessagesTable,
      ChatMessageEntry,
      $$ChatMessagesTableFilterComposer,
      $$ChatMessagesTableOrderingComposer,
      $$ChatMessagesTableAnnotationComposer,
      $$ChatMessagesTableCreateCompanionBuilder,
      $$ChatMessagesTableUpdateCompanionBuilder,
      (ChatMessageEntry, $$ChatMessagesTableReferences),
      ChatMessageEntry,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      required String taskId,
      required DateTime scheduledAt,
      Value<String> timezone,
      required int notificationId,
      Value<String> status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<DateTime> scheduledAt,
      Value<String> timezone,
      Value<int> notificationId,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderEntry> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderEntry,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (ReminderEntry, $$RemindersTableReferences),
          ReminderEntry,
          PrefetchHooks Function({bool taskId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                taskId: taskId,
                scheduledAt: scheduledAt,
                timezone: timezone,
                notificationId: notificationId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required DateTime scheduledAt,
                Value<String> timezone = const Value.absent(),
                required int notificationId,
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                taskId: taskId,
                scheduledAt: scheduledAt,
                timezone: timezone,
                notificationId: notificationId,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable: $$RemindersTableReferences
                                    ._taskIdTable(db),
                                referencedColumn: $$RemindersTableReferences
                                    ._taskIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderEntry,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (ReminderEntry, $$RemindersTableReferences),
      ReminderEntry,
      PrefetchHooks Function({bool taskId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InboxItemsTableTableManager get inboxItems =>
      $$InboxItemsTableTableManager(_db, _db.inboxItems);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$PanchangEventsTableTableManager get panchangEvents =>
      $$PanchangEventsTableTableManager(_db, _db.panchangEvents);
  $$RitualRulesTableTableManager get ritualRules =>
      $$RitualRulesTableTableManager(_db, _db.ritualRules);
  $$TaskContextsTableTableManager get taskContexts =>
      $$TaskContextsTableTableManager(_db, _db.taskContexts);
  $$ChatSessionsTableTableManager get chatSessions =>
      $$ChatSessionsTableTableManager(_db, _db.chatSessions);
  $$ChatMessagesTableTableManager get chatMessages =>
      $$ChatMessagesTableTableManager(_db, _db.chatMessages);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
}
