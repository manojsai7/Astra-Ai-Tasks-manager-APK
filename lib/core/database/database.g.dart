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
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    inboxItemId,
    title,
    description,
    taskType,
    priority,
    status,
    dueAt,
    completedAt,
    createdAt,
    updatedAt,
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
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
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
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TaskEntry({
    required this.id,
    this.inboxItemId,
    required this.title,
    this.description,
    required this.taskType,
    required this.priority,
    required this.status,
    this.dueAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
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
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
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
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
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
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
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
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TaskEntry(
    id: id ?? this.id,
    inboxItemId: inboxItemId.present ? inboxItemId.value : this.inboxItemId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    taskType: taskType ?? this.taskType,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
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
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
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
          ..write('dueAt: $dueAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
    dueAt,
    completedAt,
    createdAt,
    updatedAt,
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
          other.dueAt == this.dueAt &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<TaskEntry> {
  final Value<String> id;
  final Value<String?> inboxItemId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> taskType;
  final Value<String> priority;
  final Value<String> status;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.inboxItemId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.taskType = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    this.inboxItemId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required String taskType,
    required String priority,
    required String status,
    this.dueAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       taskType = Value(taskType),
       priority = Value(priority),
       status = Value(status),
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
    Expression<DateTime>? dueAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
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
      if (dueAt != null) 'due_at': dueAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
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
    Value<DateTime?>? dueAt,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
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
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
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
          ..write('dueAt: $dueAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InboxItemsTable inboxItems = $InboxItemsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $PanchangEventsTable panchangEvents = $PanchangEventsTable(this);
  late final $RitualRulesTable ritualRules = $RitualRulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inboxItems,
    tasks,
    panchangEvents,
    ritualRules,
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
      required String taskType,
      required String priority,
      required String status,
      Value<DateTime?> dueAt,
      Value<DateTime?> completedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
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
      Value<DateTime?> dueAt,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

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
          (TaskEntry, BaseReferences<_$AppDatabase, $TasksTable, TaskEntry>),
          TaskEntry,
          PrefetchHooks Function()
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
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                inboxItemId: inboxItemId,
                title: title,
                description: description,
                taskType: taskType,
                priority: priority,
                status: status,
                dueAt: dueAt,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> inboxItemId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required String taskType,
                required String priority,
                required String status,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                inboxItemId: inboxItemId,
                title: title,
                description: description,
                taskType: taskType,
                priority: priority,
                status: status,
                dueAt: dueAt,
                completedAt: completedAt,
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
      (TaskEntry, BaseReferences<_$AppDatabase, $TasksTable, TaskEntry>),
      TaskEntry,
      PrefetchHooks Function()
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
}
