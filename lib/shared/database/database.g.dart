// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DiaryEntriesTable extends DiaryEntries
    with TableInfo<$DiaryEntriesTable, DiaryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiaryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cloudIdMeta =
      const VerificationMeta('cloudId');
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
      'cloud_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationNameMeta =
      const VerificationMeta('locationName');
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
      'location_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlsMeta =
      const VerificationMeta('imageUrls');
  @override
  late final GeneratedColumn<String> imageUrls = GeneratedColumn<String>(
      'image_urls', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notebookIdMeta =
      const VerificationMeta('notebookId');
  @override
  late final GeneratedColumn<int> notebookId = GeneratedColumn<int>(
      'notebook_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cloudId,
        content,
        mood,
        date,
        createdAt,
        updatedAt,
        userId,
        location,
        locationName,
        imageUrls,
        notebookId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diary_entries';
  @override
  VerificationContext validateIntegrity(Insertable<DiaryEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cloud_id')) {
      context.handle(_cloudIdMeta,
          cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('location_name')) {
      context.handle(
          _locationNameMeta,
          locationName.isAcceptableOrUnknown(
              data['location_name']!, _locationNameMeta));
    }
    if (data.containsKey('image_urls')) {
      context.handle(_imageUrlsMeta,
          imageUrls.isAcceptableOrUnknown(data['image_urls']!, _imageUrlsMeta));
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
          _notebookIdMeta,
          notebookId.isAcceptableOrUnknown(
              data['notebook_id']!, _notebookIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cloudId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cloud_id']),
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      locationName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location_name']),
      imageUrls: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_urls']),
      notebookId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notebook_id']),
    );
  }

  @override
  $DiaryEntriesTable createAlias(String alias) {
    return $DiaryEntriesTable(attachedDatabase, alias);
  }
}

class DiaryEntry extends DataClass implements Insertable<DiaryEntry> {
  /// 自增主键 - 日记条目的唯一标识符
  final int id;

  /// 云端主键 ID（Supabase UUID）
  ///
  /// 本地 SQLite 与云端 Supabase 使用不同的主键策略：
  /// - 本地使用自增整数，便于 Drift 查询和关联
  /// - 云端使用稳定 UUID，支持多设备同步
  final String? cloudId;

  /// 日记正文内容
  ///
  /// 存储用户通过富文本编辑器输入的日记内容。
  /// 可以是纯文本，也可以是 Flutter Quill 的 Delta JSON 格式。
  final String content;

  /// 心情标记（可选）
  ///
  /// 存储用户选择的心情值（如 'happy', 'sad' 等）。
  /// 对应 [Mood] 枚举的 value 属性。
  /// 允许为 null，表示用户未选择心情。
  final String? mood;

  /// 日记所属日期
  ///
  /// 注意：这是日记"记录的"日期，不一定等于创建日期。
  /// 用户可能会补写之前日期的日记。
  final DateTime date;

  /// 记录创建时间
  final DateTime createdAt;

  /// 记录最后更新时间
  ///
  /// 每次编辑日记时应更新此字段。
  final DateTime updatedAt;

  /// 所属用户 ID
  ///
  /// 关联 Supabase Auth 中的用户标识符。
  /// 用于数据隔离，确保每个用户只能访问自己的日记。
  final String userId;

  /// 地理位置字符串（可选），格式："纬度,经度"
  ///
  /// 记录写日记时的地理坐标，用于展示记录地点。
  final String? location;

  /// 位置地名（可选），存储经 geocoding 解析后的可读地址
  ///
  /// 例如："酸奶紫米露(西华记忆店)西华..."
  final String? locationName;

  /// 图片 URL 列表（可选），以英文逗号分隔
  ///
  /// 日记中插入的所有图片的 URL，逗号分隔。
  /// 展示时取第一张作为封面缩略图。
  final String? imageUrls;

  /// 所属日记本 ID（可选）
  ///
  /// 关联 [Notebooks] 表的主键。为 null 时归属默认日记本。
  final int? notebookId;
  const DiaryEntry(
      {required this.id,
      this.cloudId,
      required this.content,
      this.mood,
      required this.date,
      required this.createdAt,
      required this.updatedAt,
      required this.userId,
      this.location,
      this.locationName,
      this.imageUrls,
      this.notebookId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['date'] = Variable<DateTime>(date);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || imageUrls != null) {
      map['image_urls'] = Variable<String>(imageUrls);
    }
    if (!nullToAbsent || notebookId != null) {
      map['notebook_id'] = Variable<int>(notebookId);
    }
    return map;
  }

  DiaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DiaryEntriesCompanion(
      id: Value(id),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      content: Value(content),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      date: Value(date),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      userId: Value(userId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      imageUrls: imageUrls == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrls),
      notebookId: notebookId == null && nullToAbsent
          ? const Value.absent()
          : Value(notebookId),
    );
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryEntry(
      id: serializer.fromJson<int>(json['id']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      content: serializer.fromJson<String>(json['content']),
      mood: serializer.fromJson<String?>(json['mood']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      userId: serializer.fromJson<String>(json['userId']),
      location: serializer.fromJson<String?>(json['location']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      imageUrls: serializer.fromJson<String?>(json['imageUrls']),
      notebookId: serializer.fromJson<int?>(json['notebookId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cloudId': serializer.toJson<String?>(cloudId),
      'content': serializer.toJson<String>(content),
      'mood': serializer.toJson<String?>(mood),
      'date': serializer.toJson<DateTime>(date),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'userId': serializer.toJson<String>(userId),
      'location': serializer.toJson<String?>(location),
      'locationName': serializer.toJson<String?>(locationName),
      'imageUrls': serializer.toJson<String?>(imageUrls),
      'notebookId': serializer.toJson<int?>(notebookId),
    };
  }

  DiaryEntry copyWith(
          {int? id,
          Value<String?> cloudId = const Value.absent(),
          String? content,
          Value<String?> mood = const Value.absent(),
          DateTime? date,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? userId,
          Value<String?> location = const Value.absent(),
          Value<String?> locationName = const Value.absent(),
          Value<String?> imageUrls = const Value.absent(),
          Value<int?> notebookId = const Value.absent()}) =>
      DiaryEntry(
        id: id ?? this.id,
        cloudId: cloudId.present ? cloudId.value : this.cloudId,
        content: content ?? this.content,
        mood: mood.present ? mood.value : this.mood,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        userId: userId ?? this.userId,
        location: location.present ? location.value : this.location,
        locationName:
            locationName.present ? locationName.value : this.locationName,
        imageUrls: imageUrls.present ? imageUrls.value : this.imageUrls,
        notebookId: notebookId.present ? notebookId.value : this.notebookId,
      );
  DiaryEntry copyWithCompanion(DiaryEntriesCompanion data) {
    return DiaryEntry(
      id: data.id.present ? data.id.value : this.id,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      content: data.content.present ? data.content.value : this.content,
      mood: data.mood.present ? data.mood.value : this.mood,
      date: data.date.present ? data.date.value : this.date,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
      location: data.location.present ? data.location.value : this.location,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      imageUrls: data.imageUrls.present ? data.imageUrls.value : this.imageUrls,
      notebookId:
          data.notebookId.present ? data.notebookId.value : this.notebookId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntry(')
          ..write('id: $id, ')
          ..write('cloudId: $cloudId, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('location: $location, ')
          ..write('locationName: $locationName, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('notebookId: $notebookId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cloudId, content, mood, date, createdAt,
      updatedAt, userId, location, locationName, imageUrls, notebookId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryEntry &&
          other.id == this.id &&
          other.cloudId == this.cloudId &&
          other.content == this.content &&
          other.mood == this.mood &&
          other.date == this.date &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.userId == this.userId &&
          other.location == this.location &&
          other.locationName == this.locationName &&
          other.imageUrls == this.imageUrls &&
          other.notebookId == this.notebookId);
}

class DiaryEntriesCompanion extends UpdateCompanion<DiaryEntry> {
  final Value<int> id;
  final Value<String?> cloudId;
  final Value<String> content;
  final Value<String?> mood;
  final Value<DateTime> date;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> userId;
  final Value<String?> location;
  final Value<String?> locationName;
  final Value<String?> imageUrls;
  final Value<int?> notebookId;
  const DiaryEntriesCompanion({
    this.id = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.content = const Value.absent(),
    this.mood = const Value.absent(),
    this.date = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userId = const Value.absent(),
    this.location = const Value.absent(),
    this.locationName = const Value.absent(),
    this.imageUrls = const Value.absent(),
    this.notebookId = const Value.absent(),
  });
  DiaryEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.cloudId = const Value.absent(),
    required String content,
    this.mood = const Value.absent(),
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String userId,
    this.location = const Value.absent(),
    this.locationName = const Value.absent(),
    this.imageUrls = const Value.absent(),
    this.notebookId = const Value.absent(),
  })  : content = Value(content),
        date = Value(date),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        userId = Value(userId);
  static Insertable<DiaryEntry> custom({
    Expression<int>? id,
    Expression<String>? cloudId,
    Expression<String>? content,
    Expression<String>? mood,
    Expression<DateTime>? date,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? userId,
    Expression<String>? location,
    Expression<String>? locationName,
    Expression<String>? imageUrls,
    Expression<int>? notebookId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cloudId != null) 'cloud_id': cloudId,
      if (content != null) 'content': content,
      if (mood != null) 'mood': mood,
      if (date != null) 'date': date,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userId != null) 'user_id': userId,
      if (location != null) 'location': location,
      if (locationName != null) 'location_name': locationName,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (notebookId != null) 'notebook_id': notebookId,
    });
  }

  DiaryEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String?>? cloudId,
      Value<String>? content,
      Value<String?>? mood,
      Value<DateTime>? date,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? userId,
      Value<String?>? location,
      Value<String?>? locationName,
      Value<String?>? imageUrls,
      Value<int?>? notebookId}) {
    return DiaryEntriesCompanion(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      imageUrls: imageUrls ?? this.imageUrls,
      notebookId: notebookId ?? this.notebookId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (imageUrls.present) {
      map['image_urls'] = Variable<String>(imageUrls.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('cloudId: $cloudId, ')
          ..write('content: $content, ')
          ..write('mood: $mood, ')
          ..write('date: $date, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId, ')
          ..write('location: $location, ')
          ..write('locationName: $locationName, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('notebookId: $notebookId')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cloudIdMeta =
      const VerificationMeta('cloudId');
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
      'cloud_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('todo'));
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cloudId,
        title,
        description,
        priority,
        status,
        dueDate,
        sortOrder,
        createdAt,
        userId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cloud_id')) {
      context.handle(_cloudIdMeta,
          cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cloudId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cloud_id']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  /// 自增主键 - 任务的唯一标识符
  final int id;

  /// 云端主键 ID（Supabase UUID）
  final String? cloudId;

  /// 任务标题
  ///
  /// 简洁描述任务内容的一句话文本。
  final String title;

  /// 任务详细描述（可选）
  ///
  /// 对任务的补充说明、操作步骤等详细信息。
  final String? description;

  /// 任务优先级
  ///
  /// 使用整数表示：1 = 高优先级，2 = 中优先级（默认），3 = 低优先级。
  /// 数字越小优先级越高，便于按优先级升序排列。
  final int priority;

  /// 任务状态
  ///
  /// 可选值：'todo'（待办）、'in_progress'（进行中）、'done'（已完成）。
  /// 默认为 'todo'。
  final String status;

  /// 截止日期（可选）
  ///
  /// 任务的预期完成时间。允许为 null，表示没有截止日期。
  final DateTime? dueDate;

  /// 排序序号
  ///
  /// 用于用户自定义排序（如拖拽排序）。
  /// 数值越小越靠前显示，默认为 0。
  final int sortOrder;

  /// 记录创建时间
  final DateTime createdAt;

  /// 所属用户 ID
  final String userId;
  const Task(
      {required this.id,
      this.cloudId,
      required this.title,
      this.description,
      required this.priority,
      required this.status,
      this.dueDate,
      required this.sortOrder,
      required this.createdAt,
      required this.userId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      status: Value(status),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      userId: Value(userId),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cloudId': serializer.toJson<String?>(cloudId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'userId': serializer.toJson<String>(userId),
    };
  }

  Task copyWith(
          {int? id,
          Value<String?> cloudId = const Value.absent(),
          String? title,
          Value<String?> description = const Value.absent(),
          int? priority,
          String? status,
          Value<DateTime?> dueDate = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt,
          String? userId}) =>
      Task(
        id: id ?? this.id,
        cloudId: cloudId.present ? cloudId.value : this.cloudId,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        userId: userId ?? this.userId,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('cloudId: $cloudId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cloudId, title, description, priority,
      status, dueDate, sortOrder, createdAt, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.cloudId == this.cloudId &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.dueDate == this.dueDate &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.userId == this.userId);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String?> cloudId;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> priority;
  final Value<String> status;
  final Value<DateTime?> dueDate;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<String> userId;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.userId = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.cloudId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required String userId,
  })  : title = Value(title),
        createdAt = Value(createdAt),
        userId = Value(userId);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? cloudId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<DateTime>? dueDate,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cloudId != null) 'cloud_id': cloudId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (dueDate != null) 'due_date': dueDate,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (userId != null) 'user_id': userId,
    });
  }

  TasksCompanion copyWith(
      {Value<int>? id,
      Value<String?>? cloudId,
      Value<String>? title,
      Value<String?>? description,
      Value<int>? priority,
      Value<String>? status,
      Value<DateTime?>? dueDate,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<String>? userId}) {
    return TasksCompanion(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('cloudId: $cloudId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dueDate: $dueDate, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

class $NewsSummariesTable extends NewsSummaries
    with TableInfo<$NewsSummariesTable, NewsSummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NewsSummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _headlineMeta =
      const VerificationMeta('headline');
  @override
  late final GeneratedColumn<String> headline = GeneratedColumn<String>(
      'headline', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryMeta =
      const VerificationMeta('summary');
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
      'summary', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceUrlMeta =
      const VerificationMeta('sourceUrl');
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
      'source_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, category, headline, summary, sourceUrl, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'news_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<NewsSummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('headline')) {
      context.handle(_headlineMeta,
          headline.isAcceptableOrUnknown(data['headline']!, _headlineMeta));
    } else if (isInserting) {
      context.missing(_headlineMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(_summaryMeta,
          summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta));
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(_sourceUrlMeta,
          sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NewsSummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NewsSummary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      headline: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}headline'])!,
      summary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary'])!,
      sourceUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_url']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NewsSummariesTable createAlias(String alias) {
    return $NewsSummariesTable(attachedDatabase, alias);
  }
}

class NewsSummary extends DataClass implements Insertable<NewsSummary> {
  /// 自增主键 - 新闻摘要的唯一标识符
  final int id;

  /// 新闻所属日期
  ///
  /// 用于按日期分组和查询新闻列表。
  final DateTime date;

  /// 新闻分类
  ///
  /// 存储分类标识符（如 'technology', 'finance' 等）。
  /// 对应 [NewsCategory] 枚举的 value 属性。
  final String category;

  /// 新闻标题
  ///
  /// 简洁概括新闻核心内容的一句话。
  final String headline;

  /// 新闻摘要正文
  ///
  /// AI 生成的新闻内容摘要。
  final String summary;

  /// 新闻来源 URL（可选）
  ///
  /// 原始新闻文章的链接。允许为 null。
  final String? sourceUrl;

  /// 记录创建时间
  final DateTime createdAt;
  const NewsSummary(
      {required this.id,
      required this.date,
      required this.category,
      required this.headline,
      required this.summary,
      this.sourceUrl,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['category'] = Variable<String>(category);
    map['headline'] = Variable<String>(headline);
    map['summary'] = Variable<String>(summary);
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NewsSummariesCompanion toCompanion(bool nullToAbsent) {
    return NewsSummariesCompanion(
      id: Value(id),
      date: Value(date),
      category: Value(category),
      headline: Value(headline),
      summary: Value(summary),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      createdAt: Value(createdAt),
    );
  }

  factory NewsSummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NewsSummary(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<String>(json['category']),
      headline: serializer.fromJson<String>(json['headline']),
      summary: serializer.fromJson<String>(json['summary']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<String>(category),
      'headline': serializer.toJson<String>(headline),
      'summary': serializer.toJson<String>(summary),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NewsSummary copyWith(
          {int? id,
          DateTime? date,
          String? category,
          String? headline,
          String? summary,
          Value<String?> sourceUrl = const Value.absent(),
          DateTime? createdAt}) =>
      NewsSummary(
        id: id ?? this.id,
        date: date ?? this.date,
        category: category ?? this.category,
        headline: headline ?? this.headline,
        summary: summary ?? this.summary,
        sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
        createdAt: createdAt ?? this.createdAt,
      );
  NewsSummary copyWithCompanion(NewsSummariesCompanion data) {
    return NewsSummary(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      headline: data.headline.present ? data.headline.value : this.headline,
      summary: data.summary.present ? data.summary.value : this.summary,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NewsSummary(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('headline: $headline, ')
          ..write('summary: $summary, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, category, headline, summary, sourceUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NewsSummary &&
          other.id == this.id &&
          other.date == this.date &&
          other.category == this.category &&
          other.headline == this.headline &&
          other.summary == this.summary &&
          other.sourceUrl == this.sourceUrl &&
          other.createdAt == this.createdAt);
}

class NewsSummariesCompanion extends UpdateCompanion<NewsSummary> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> category;
  final Value<String> headline;
  final Value<String> summary;
  final Value<String?> sourceUrl;
  final Value<DateTime> createdAt;
  const NewsSummariesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.headline = const Value.absent(),
    this.summary = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NewsSummariesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String category,
    required String headline,
    required String summary,
    this.sourceUrl = const Value.absent(),
    required DateTime createdAt,
  })  : date = Value(date),
        category = Value(category),
        headline = Value(headline),
        summary = Value(summary),
        createdAt = Value(createdAt);
  static Insertable<NewsSummary> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? headline,
    Expression<String>? summary,
    Expression<String>? sourceUrl,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (headline != null) 'headline': headline,
      if (summary != null) 'summary': summary,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NewsSummariesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<String>? category,
      Value<String>? headline,
      Value<String>? summary,
      Value<String?>? sourceUrl,
      Value<DateTime>? createdAt}) {
    return NewsSummariesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (headline.present) {
      map['headline'] = Variable<String>(headline.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NewsSummariesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('headline: $headline, ')
          ..write('summary: $summary, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $NewsBookmarksTable extends NewsBookmarks
    with TableInfo<$NewsBookmarksTable, NewsBookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NewsBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _newsIdMeta = const VerificationMeta('newsId');
  @override
  late final GeneratedColumn<int> newsId = GeneratedColumn<int>(
      'news_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, userId, newsId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'news_bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<NewsBookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('news_id')) {
      context.handle(_newsIdMeta,
          newsId.isAcceptableOrUnknown(data['news_id']!, _newsIdMeta));
    } else if (isInserting) {
      context.missing(_newsIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NewsBookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NewsBookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      newsId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}news_id'])!,
    );
  }

  @override
  $NewsBookmarksTable createAlias(String alias) {
    return $NewsBookmarksTable(attachedDatabase, alias);
  }
}

class NewsBookmark extends DataClass implements Insertable<NewsBookmark> {
  /// 自增主键 - 书签的唯一标识符
  final int id;

  /// 收藏该新闻的用户 ID
  final String userId;

  /// 被收藏的新闻摘要 ID
  ///
  /// 对应 [NewsSummaries] 表中的 id 字段。
  final int newsId;
  const NewsBookmark(
      {required this.id, required this.userId, required this.newsId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['news_id'] = Variable<int>(newsId);
    return map;
  }

  NewsBookmarksCompanion toCompanion(bool nullToAbsent) {
    return NewsBookmarksCompanion(
      id: Value(id),
      userId: Value(userId),
      newsId: Value(newsId),
    );
  }

  factory NewsBookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NewsBookmark(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      newsId: serializer.fromJson<int>(json['newsId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'newsId': serializer.toJson<int>(newsId),
    };
  }

  NewsBookmark copyWith({int? id, String? userId, int? newsId}) => NewsBookmark(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        newsId: newsId ?? this.newsId,
      );
  NewsBookmark copyWithCompanion(NewsBookmarksCompanion data) {
    return NewsBookmark(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      newsId: data.newsId.present ? data.newsId.value : this.newsId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NewsBookmark(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('newsId: $newsId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, newsId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NewsBookmark &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.newsId == this.newsId);
}

class NewsBookmarksCompanion extends UpdateCompanion<NewsBookmark> {
  final Value<int> id;
  final Value<String> userId;
  final Value<int> newsId;
  const NewsBookmarksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.newsId = const Value.absent(),
  });
  NewsBookmarksCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required int newsId,
  })  : userId = Value(userId),
        newsId = Value(newsId);
  static Insertable<NewsBookmark> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<int>? newsId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (newsId != null) 'news_id': newsId,
    });
  }

  NewsBookmarksCompanion copyWith(
      {Value<int>? id, Value<String>? userId, Value<int>? newsId}) {
    return NewsBookmarksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      newsId: newsId ?? this.newsId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (newsId.present) {
      map['news_id'] = Variable<int>(newsId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NewsBookmarksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('newsId: $newsId')
          ..write(')'))
        .toString();
  }
}

class $NotebooksTable extends Notebooks
    with TableInfo<$NotebooksTable, Notebook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cloudIdMeta =
      const VerificationMeta('cloudId');
  @override
  late final GeneratedColumn<String> cloudId = GeneratedColumn<String>(
      'cloud_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, cloudId, name, coverUrl, sortOrder, createdAt, updatedAt, userId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebooks';
  @override
  VerificationContext validateIntegrity(Insertable<Notebook> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cloud_id')) {
      context.handle(_cloudIdMeta,
          cloudId.isAcceptableOrUnknown(data['cloud_id']!, _cloudIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notebook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notebook(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cloudId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cloud_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
    );
  }

  @override
  $NotebooksTable createAlias(String alias) {
    return $NotebooksTable(attachedDatabase, alias);
  }
}

class Notebook extends DataClass implements Insertable<Notebook> {
  /// 自增主键
  final int id;

  /// 云端主键 ID（Supabase UUID）
  final String? cloudId;

  /// 日记本名称
  final String name;

  /// 封面图片 URL（可选）
  final String? coverUrl;

  /// 排序序号（数值越小越靠前）
  final int sortOrder;

  /// 记录创建时间
  final DateTime createdAt;

  /// 记录最后更新时间
  final DateTime updatedAt;

  /// 所属用户 ID
  final String userId;
  const Notebook(
      {required this.id,
      this.cloudId,
      required this.name,
      this.coverUrl,
      required this.sortOrder,
      required this.createdAt,
      required this.updatedAt,
      required this.userId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || cloudId != null) {
      map['cloud_id'] = Variable<String>(cloudId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  NotebooksCompanion toCompanion(bool nullToAbsent) {
    return NotebooksCompanion(
      id: Value(id),
      cloudId: cloudId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudId),
      name: Value(name),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      userId: Value(userId),
    );
  }

  factory Notebook.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notebook(
      id: serializer.fromJson<int>(json['id']),
      cloudId: serializer.fromJson<String?>(json['cloudId']),
      name: serializer.fromJson<String>(json['name']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cloudId': serializer.toJson<String?>(cloudId),
      'name': serializer.toJson<String>(name),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'userId': serializer.toJson<String>(userId),
    };
  }

  Notebook copyWith(
          {int? id,
          Value<String?> cloudId = const Value.absent(),
          String? name,
          Value<String?> coverUrl = const Value.absent(),
          int? sortOrder,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? userId}) =>
      Notebook(
        id: id ?? this.id,
        cloudId: cloudId.present ? cloudId.value : this.cloudId,
        name: name ?? this.name,
        coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        userId: userId ?? this.userId,
      );
  Notebook copyWithCompanion(NotebooksCompanion data) {
    return Notebook(
      id: data.id.present ? data.id.value : this.id,
      cloudId: data.cloudId.present ? data.cloudId.value : this.cloudId,
      name: data.name.present ? data.name.value : this.name,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notebook(')
          ..write('id: $id, ')
          ..write('cloudId: $cloudId, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, cloudId, name, coverUrl, sortOrder, createdAt, updatedAt, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notebook &&
          other.id == this.id &&
          other.cloudId == this.cloudId &&
          other.name == this.name &&
          other.coverUrl == this.coverUrl &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.userId == this.userId);
}

class NotebooksCompanion extends UpdateCompanion<Notebook> {
  final Value<int> id;
  final Value<String?> cloudId;
  final Value<String> name;
  final Value<String?> coverUrl;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> userId;
  const NotebooksCompanion({
    this.id = const Value.absent(),
    this.cloudId = const Value.absent(),
    this.name = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.userId = const Value.absent(),
  });
  NotebooksCompanion.insert({
    this.id = const Value.absent(),
    this.cloudId = const Value.absent(),
    required String name,
    this.coverUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required String userId,
  })  : name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        userId = Value(userId);
  static Insertable<Notebook> custom({
    Expression<int>? id,
    Expression<String>? cloudId,
    Expression<String>? name,
    Expression<String>? coverUrl,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cloudId != null) 'cloud_id': cloudId,
      if (name != null) 'name': name,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (userId != null) 'user_id': userId,
    });
  }

  NotebooksCompanion copyWith(
      {Value<int>? id,
      Value<String?>? cloudId,
      Value<String>? name,
      Value<String?>? coverUrl,
      Value<int>? sortOrder,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? userId}) {
    return NotebooksCompanion(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cloudId.present) {
      map['cloud_id'] = Variable<String>(cloudId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebooksCompanion(')
          ..write('id: $id, ')
          ..write('cloudId: $cloudId, ')
          ..write('name: $name, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiaryEntriesTable diaryEntries = $DiaryEntriesTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $NewsSummariesTable newsSummaries = $NewsSummariesTable(this);
  late final $NewsBookmarksTable newsBookmarks = $NewsBookmarksTable(this);
  late final $NotebooksTable notebooks = $NotebooksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [diaryEntries, tasks, newsSummaries, newsBookmarks, notebooks];
}

typedef $$DiaryEntriesTableCreateCompanionBuilder = DiaryEntriesCompanion
    Function({
  Value<int> id,
  Value<String?> cloudId,
  required String content,
  Value<String?> mood,
  required DateTime date,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String userId,
  Value<String?> location,
  Value<String?> locationName,
  Value<String?> imageUrls,
  Value<int?> notebookId,
});
typedef $$DiaryEntriesTableUpdateCompanionBuilder = DiaryEntriesCompanion
    Function({
  Value<int> id,
  Value<String?> cloudId,
  Value<String> content,
  Value<String?> mood,
  Value<DateTime> date,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> userId,
  Value<String?> location,
  Value<String?> locationName,
  Value<String?> imageUrls,
  Value<int?> notebookId,
});

class $$DiaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cloudId => $composableBuilder(
      column: $table.cloudId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locationName => $composableBuilder(
      column: $table.locationName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrls => $composableBuilder(
      column: $table.imageUrls, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnFilters(column));
}

class $$DiaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cloudId => $composableBuilder(
      column: $table.cloudId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationName => $composableBuilder(
      column: $table.locationName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrls => $composableBuilder(
      column: $table.imageUrls, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => ColumnOrderings(column));
}

class $$DiaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiaryEntriesTable> {
  $$DiaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
      column: $table.locationName, builder: (column) => column);

  GeneratedColumn<String> get imageUrls =>
      $composableBuilder(column: $table.imageUrls, builder: (column) => column);

  GeneratedColumn<int> get notebookId => $composableBuilder(
      column: $table.notebookId, builder: (column) => column);
}

class $$DiaryEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DiaryEntriesTable,
    DiaryEntry,
    $$DiaryEntriesTableFilterComposer,
    $$DiaryEntriesTableOrderingComposer,
    $$DiaryEntriesTableAnnotationComposer,
    $$DiaryEntriesTableCreateCompanionBuilder,
    $$DiaryEntriesTableUpdateCompanionBuilder,
    (DiaryEntry, BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntry>),
    DiaryEntry,
    PrefetchHooks Function()> {
  $$DiaryEntriesTableTableManager(_$AppDatabase db, $DiaryEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiaryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> cloudId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> locationName = const Value.absent(),
            Value<String?> imageUrls = const Value.absent(),
            Value<int?> notebookId = const Value.absent(),
          }) =>
              DiaryEntriesCompanion(
            id: id,
            cloudId: cloudId,
            content: content,
            mood: mood,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            userId: userId,
            location: location,
            locationName: locationName,
            imageUrls: imageUrls,
            notebookId: notebookId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> cloudId = const Value.absent(),
            required String content,
            Value<String?> mood = const Value.absent(),
            required DateTime date,
            required DateTime createdAt,
            required DateTime updatedAt,
            required String userId,
            Value<String?> location = const Value.absent(),
            Value<String?> locationName = const Value.absent(),
            Value<String?> imageUrls = const Value.absent(),
            Value<int?> notebookId = const Value.absent(),
          }) =>
              DiaryEntriesCompanion.insert(
            id: id,
            cloudId: cloudId,
            content: content,
            mood: mood,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            userId: userId,
            location: location,
            locationName: locationName,
            imageUrls: imageUrls,
            notebookId: notebookId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DiaryEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DiaryEntriesTable,
    DiaryEntry,
    $$DiaryEntriesTableFilterComposer,
    $$DiaryEntriesTableOrderingComposer,
    $$DiaryEntriesTableAnnotationComposer,
    $$DiaryEntriesTableCreateCompanionBuilder,
    $$DiaryEntriesTableUpdateCompanionBuilder,
    (DiaryEntry, BaseReferences<_$AppDatabase, $DiaryEntriesTable, DiaryEntry>),
    DiaryEntry,
    PrefetchHooks Function()>;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String?> cloudId,
  required String title,
  Value<String?> description,
  Value<int> priority,
  Value<String> status,
  Value<DateTime?> dueDate,
  Value<int> sortOrder,
  required DateTime createdAt,
  required String userId,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String?> cloudId,
  Value<String> title,
  Value<String?> description,
  Value<int> priority,
  Value<String> status,
  Value<DateTime?> dueDate,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<String> userId,
});

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cloudId => $composableBuilder(
      column: $table.cloudId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));
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
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cloudId => $composableBuilder(
      column: $table.cloudId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> cloudId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> userId = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            cloudId: cloudId,
            title: title,
            description: description,
            priority: priority,
            status: status,
            dueDate: dueDate,
            sortOrder: sortOrder,
            createdAt: createdAt,
            userId: userId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> cloudId = const Value.absent(),
            required String title,
            Value<String?> description = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required String userId,
          }) =>
              TasksCompanion.insert(
            id: id,
            cloudId: cloudId,
            title: title,
            description: description,
            priority: priority,
            status: status,
            dueDate: dueDate,
            sortOrder: sortOrder,
            createdAt: createdAt,
            userId: userId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()>;
typedef $$NewsSummariesTableCreateCompanionBuilder = NewsSummariesCompanion
    Function({
  Value<int> id,
  required DateTime date,
  required String category,
  required String headline,
  required String summary,
  Value<String?> sourceUrl,
  required DateTime createdAt,
});
typedef $$NewsSummariesTableUpdateCompanionBuilder = NewsSummariesCompanion
    Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String> category,
  Value<String> headline,
  Value<String> summary,
  Value<String?> sourceUrl,
  Value<DateTime> createdAt,
});

class $$NewsSummariesTableFilterComposer
    extends Composer<_$AppDatabase, $NewsSummariesTable> {
  $$NewsSummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get headline => $composableBuilder(
      column: $table.headline, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceUrl => $composableBuilder(
      column: $table.sourceUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$NewsSummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $NewsSummariesTable> {
  $$NewsSummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get headline => $composableBuilder(
      column: $table.headline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summary => $composableBuilder(
      column: $table.summary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
      column: $table.sourceUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$NewsSummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NewsSummariesTable> {
  $$NewsSummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get headline =>
      $composableBuilder(column: $table.headline, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$NewsSummariesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NewsSummariesTable,
    NewsSummary,
    $$NewsSummariesTableFilterComposer,
    $$NewsSummariesTableOrderingComposer,
    $$NewsSummariesTableAnnotationComposer,
    $$NewsSummariesTableCreateCompanionBuilder,
    $$NewsSummariesTableUpdateCompanionBuilder,
    (
      NewsSummary,
      BaseReferences<_$AppDatabase, $NewsSummariesTable, NewsSummary>
    ),
    NewsSummary,
    PrefetchHooks Function()> {
  $$NewsSummariesTableTableManager(_$AppDatabase db, $NewsSummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NewsSummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NewsSummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NewsSummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> headline = const Value.absent(),
            Value<String> summary = const Value.absent(),
            Value<String?> sourceUrl = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              NewsSummariesCompanion(
            id: id,
            date: date,
            category: category,
            headline: headline,
            summary: summary,
            sourceUrl: sourceUrl,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required String category,
            required String headline,
            required String summary,
            Value<String?> sourceUrl = const Value.absent(),
            required DateTime createdAt,
          }) =>
              NewsSummariesCompanion.insert(
            id: id,
            date: date,
            category: category,
            headline: headline,
            summary: summary,
            sourceUrl: sourceUrl,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NewsSummariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NewsSummariesTable,
    NewsSummary,
    $$NewsSummariesTableFilterComposer,
    $$NewsSummariesTableOrderingComposer,
    $$NewsSummariesTableAnnotationComposer,
    $$NewsSummariesTableCreateCompanionBuilder,
    $$NewsSummariesTableUpdateCompanionBuilder,
    (
      NewsSummary,
      BaseReferences<_$AppDatabase, $NewsSummariesTable, NewsSummary>
    ),
    NewsSummary,
    PrefetchHooks Function()>;
typedef $$NewsBookmarksTableCreateCompanionBuilder = NewsBookmarksCompanion
    Function({
  Value<int> id,
  required String userId,
  required int newsId,
});
typedef $$NewsBookmarksTableUpdateCompanionBuilder = NewsBookmarksCompanion
    Function({
  Value<int> id,
  Value<String> userId,
  Value<int> newsId,
});

class $$NewsBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $NewsBookmarksTable> {
  $$NewsBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newsId => $composableBuilder(
      column: $table.newsId, builder: (column) => ColumnFilters(column));
}

class $$NewsBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $NewsBookmarksTable> {
  $$NewsBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newsId => $composableBuilder(
      column: $table.newsId, builder: (column) => ColumnOrderings(column));
}

class $$NewsBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NewsBookmarksTable> {
  $$NewsBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get newsId =>
      $composableBuilder(column: $table.newsId, builder: (column) => column);
}

class $$NewsBookmarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NewsBookmarksTable,
    NewsBookmark,
    $$NewsBookmarksTableFilterComposer,
    $$NewsBookmarksTableOrderingComposer,
    $$NewsBookmarksTableAnnotationComposer,
    $$NewsBookmarksTableCreateCompanionBuilder,
    $$NewsBookmarksTableUpdateCompanionBuilder,
    (
      NewsBookmark,
      BaseReferences<_$AppDatabase, $NewsBookmarksTable, NewsBookmark>
    ),
    NewsBookmark,
    PrefetchHooks Function()> {
  $$NewsBookmarksTableTableManager(_$AppDatabase db, $NewsBookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NewsBookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NewsBookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NewsBookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<int> newsId = const Value.absent(),
          }) =>
              NewsBookmarksCompanion(
            id: id,
            userId: userId,
            newsId: newsId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String userId,
            required int newsId,
          }) =>
              NewsBookmarksCompanion.insert(
            id: id,
            userId: userId,
            newsId: newsId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NewsBookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NewsBookmarksTable,
    NewsBookmark,
    $$NewsBookmarksTableFilterComposer,
    $$NewsBookmarksTableOrderingComposer,
    $$NewsBookmarksTableAnnotationComposer,
    $$NewsBookmarksTableCreateCompanionBuilder,
    $$NewsBookmarksTableUpdateCompanionBuilder,
    (
      NewsBookmark,
      BaseReferences<_$AppDatabase, $NewsBookmarksTable, NewsBookmark>
    ),
    NewsBookmark,
    PrefetchHooks Function()>;
typedef $$NotebooksTableCreateCompanionBuilder = NotebooksCompanion Function({
  Value<int> id,
  Value<String?> cloudId,
  required String name,
  Value<String?> coverUrl,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String userId,
});
typedef $$NotebooksTableUpdateCompanionBuilder = NotebooksCompanion Function({
  Value<int> id,
  Value<String?> cloudId,
  Value<String> name,
  Value<String?> coverUrl,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> userId,
});

class $$NotebooksTableFilterComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cloudId => $composableBuilder(
      column: $table.cloudId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));
}

class $$NotebooksTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cloudId => $composableBuilder(
      column: $table.cloudId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));
}

class $$NotebooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cloudId =>
      $composableBuilder(column: $table.cloudId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);
}

class $$NotebooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotebooksTable,
    Notebook,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (Notebook, BaseReferences<_$AppDatabase, $NotebooksTable, Notebook>),
    Notebook,
    PrefetchHooks Function()> {
  $$NotebooksTableTableManager(_$AppDatabase db, $NotebooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> cloudId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> coverUrl = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> userId = const Value.absent(),
          }) =>
              NotebooksCompanion(
            id: id,
            cloudId: cloudId,
            name: name,
            coverUrl: coverUrl,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            userId: userId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String?> cloudId = const Value.absent(),
            required String name,
            Value<String?> coverUrl = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            required String userId,
          }) =>
              NotebooksCompanion.insert(
            id: id,
            cloudId: cloudId,
            name: name,
            coverUrl: coverUrl,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt,
            userId: userId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotebooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotebooksTable,
    Notebook,
    $$NotebooksTableFilterComposer,
    $$NotebooksTableOrderingComposer,
    $$NotebooksTableAnnotationComposer,
    $$NotebooksTableCreateCompanionBuilder,
    $$NotebooksTableUpdateCompanionBuilder,
    (Notebook, BaseReferences<_$AppDatabase, $NotebooksTable, Notebook>),
    Notebook,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiaryEntriesTableTableManager get diaryEntries =>
      $$DiaryEntriesTableTableManager(_db, _db.diaryEntries);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$NewsSummariesTableTableManager get newsSummaries =>
      $$NewsSummariesTableTableManager(_db, _db.newsSummaries);
  $$NewsBookmarksTableTableManager get newsBookmarks =>
      $$NewsBookmarksTableTableManager(_db, _db.newsBookmarks);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db, _db.notebooks);
}
