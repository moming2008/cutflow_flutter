// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VideoItemsTable extends VideoItems
    with TableInfo<$VideoItemsTable, VideoItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frameRateMeta = const VerificationMeta(
    'frameRate',
  );
  @override
  late final GeneratedColumn<double> frameRate = GeneratedColumn<double>(
    'frame_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codecMeta = const VerificationMeta('codec');
  @override
  late final GeneratedColumn<String> codec = GeneratedColumn<String>(
    'codec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<int> importedAt = GeneratedColumn<int>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    name,
    duration,
    width,
    height,
    fileSize,
    frameRate,
    codec,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<VideoItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('frame_rate')) {
      context.handle(
        _frameRateMeta,
        frameRate.isAcceptableOrUnknown(data['frame_rate']!, _frameRateMeta),
      );
    } else if (isInserting) {
      context.missing(_frameRateMeta);
    }
    if (data.containsKey('codec')) {
      context.handle(
        _codecMeta,
        codec.isAcceptableOrUnknown(data['codec']!, _codecMeta),
      );
    } else if (isInserting) {
      context.missing(_codecMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VideoItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      frameRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}frame_rate'],
      )!,
      codec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codec'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $VideoItemsTable createAlias(String alias) {
    return $VideoItemsTable(attachedDatabase, alias);
  }
}

class VideoItem extends DataClass implements Insertable<VideoItem> {
  final int id;
  final String path;
  final String name;
  final int duration;
  final int width;
  final int height;
  final int fileSize;
  final double frameRate;
  final String codec;
  final int importedAt;
  const VideoItem({
    required this.id,
    required this.path,
    required this.name,
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.frameRate,
    required this.codec,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    map['duration'] = Variable<int>(duration);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['file_size'] = Variable<int>(fileSize);
    map['frame_rate'] = Variable<double>(frameRate);
    map['codec'] = Variable<String>(codec);
    map['imported_at'] = Variable<int>(importedAt);
    return map;
  }

  VideoItemsCompanion toCompanion(bool nullToAbsent) {
    return VideoItemsCompanion(
      id: Value(id),
      path: Value(path),
      name: Value(name),
      duration: Value(duration),
      width: Value(width),
      height: Value(height),
      fileSize: Value(fileSize),
      frameRate: Value(frameRate),
      codec: Value(codec),
      importedAt: Value(importedAt),
    );
  }

  factory VideoItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoItem(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      duration: serializer.fromJson<int>(json['duration']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      frameRate: serializer.fromJson<double>(json['frameRate']),
      codec: serializer.fromJson<String>(json['codec']),
      importedAt: serializer.fromJson<int>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'duration': serializer.toJson<int>(duration),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'fileSize': serializer.toJson<int>(fileSize),
      'frameRate': serializer.toJson<double>(frameRate),
      'codec': serializer.toJson<String>(codec),
      'importedAt': serializer.toJson<int>(importedAt),
    };
  }

  VideoItem copyWith({
    int? id,
    String? path,
    String? name,
    int? duration,
    int? width,
    int? height,
    int? fileSize,
    double? frameRate,
    String? codec,
    int? importedAt,
  }) => VideoItem(
    id: id ?? this.id,
    path: path ?? this.path,
    name: name ?? this.name,
    duration: duration ?? this.duration,
    width: width ?? this.width,
    height: height ?? this.height,
    fileSize: fileSize ?? this.fileSize,
    frameRate: frameRate ?? this.frameRate,
    codec: codec ?? this.codec,
    importedAt: importedAt ?? this.importedAt,
  );
  VideoItem copyWithCompanion(VideoItemsCompanion data) {
    return VideoItem(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      duration: data.duration.present ? data.duration.value : this.duration,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      frameRate: data.frameRate.present ? data.frameRate.value : this.frameRate,
      codec: data.codec.present ? data.codec.value : this.codec,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoItem(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('frameRate: $frameRate, ')
          ..write('codec: $codec, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    path,
    name,
    duration,
    width,
    height,
    fileSize,
    frameRate,
    codec,
    importedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoItem &&
          other.id == this.id &&
          other.path == this.path &&
          other.name == this.name &&
          other.duration == this.duration &&
          other.width == this.width &&
          other.height == this.height &&
          other.fileSize == this.fileSize &&
          other.frameRate == this.frameRate &&
          other.codec == this.codec &&
          other.importedAt == this.importedAt);
}

class VideoItemsCompanion extends UpdateCompanion<VideoItem> {
  final Value<int> id;
  final Value<String> path;
  final Value<String> name;
  final Value<int> duration;
  final Value<int> width;
  final Value<int> height;
  final Value<int> fileSize;
  final Value<double> frameRate;
  final Value<String> codec;
  final Value<int> importedAt;
  const VideoItemsCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.duration = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.frameRate = const Value.absent(),
    this.codec = const Value.absent(),
    this.importedAt = const Value.absent(),
  });
  VideoItemsCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required String name,
    required int duration,
    required int width,
    required int height,
    required int fileSize,
    required double frameRate,
    required String codec,
    required int importedAt,
  }) : path = Value(path),
       name = Value(name),
       duration = Value(duration),
       width = Value(width),
       height = Value(height),
       fileSize = Value(fileSize),
       frameRate = Value(frameRate),
       codec = Value(codec),
       importedAt = Value(importedAt);
  static Insertable<VideoItem> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<String>? name,
    Expression<int>? duration,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? fileSize,
    Expression<double>? frameRate,
    Expression<String>? codec,
    Expression<int>? importedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (duration != null) 'duration': duration,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fileSize != null) 'file_size': fileSize,
      if (frameRate != null) 'frame_rate': frameRate,
      if (codec != null) 'codec': codec,
      if (importedAt != null) 'imported_at': importedAt,
    });
  }

  VideoItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<String>? name,
    Value<int>? duration,
    Value<int>? width,
    Value<int>? height,
    Value<int>? fileSize,
    Value<double>? frameRate,
    Value<String>? codec,
    Value<int>? importedAt,
  }) {
    return VideoItemsCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      frameRate: frameRate ?? this.frameRate,
      codec: codec ?? this.codec,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (frameRate.present) {
      map['frame_rate'] = Variable<double>(frameRate.value);
    }
    if (codec.present) {
      map['codec'] = Variable<String>(codec.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<int>(importedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoItemsCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fileSize: $fileSize, ')
          ..write('frameRate: $frameRate, ')
          ..write('codec: $codec, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }
}

class $ExportTasksTable extends ExportTasks
    with TableInfo<$ExportTasksTable, ExportTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExportTasksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceVideoIdMeta = const VerificationMeta(
    'sourceVideoId',
  );
  @override
  late final GeneratedColumn<int> sourceVideoId = GeneratedColumn<int>(
    'source_video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputNameMeta = const VerificationMeta(
    'outputName',
  );
  @override
  late final GeneratedColumn<String> outputName = GeneratedColumn<String>(
    'output_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trimStartMsMeta = const VerificationMeta(
    'trimStartMs',
  );
  @override
  late final GeneratedColumn<int> trimStartMs = GeneratedColumn<int>(
    'trim_start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trimEndMsMeta = const VerificationMeta(
    'trimEndMs',
  );
  @override
  late final GeneratedColumn<int> trimEndMs = GeneratedColumn<int>(
    'trim_end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cropPresetIdMeta = const VerificationMeta(
    'cropPresetId',
  );
  @override
  late final GeneratedColumn<int> cropPresetId = GeneratedColumn<int>(
    'crop_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropSnapshotMeta = const VerificationMeta(
    'cropSnapshot',
  );
  @override
  late final GeneratedColumn<String> cropSnapshot = GeneratedColumn<String>(
    'crop_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropPresetNameMeta = const VerificationMeta(
    'cropPresetName',
  );
  @override
  late final GeneratedColumn<String> cropPresetName = GeneratedColumn<String>(
    'crop_preset_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cropRatioLabelMeta = const VerificationMeta(
    'cropRatioLabel',
  );
  @override
  late final GeneratedColumn<String> cropRatioLabel = GeneratedColumn<String>(
    'crop_ratio_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceVideoNameMeta = const VerificationMeta(
    'sourceVideoName',
  );
  @override
  late final GeneratedColumn<String> sourceVideoName = GeneratedColumn<String>(
    'source_video_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputPathMeta = const VerificationMeta(
    'outputPath',
  );
  @override
  late final GeneratedColumn<String> outputPath = GeneratedColumn<String>(
    'output_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceVideoId,
    outputName,
    trimStartMs,
    trimEndMs,
    cropPresetId,
    cropSnapshot,
    cropPresetName,
    cropRatioLabel,
    sourceVideoName,
    status,
    progress,
    createdAt,
    outputPath,
    completedAt,
    archivedAt,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_video_id')) {
      context.handle(
        _sourceVideoIdMeta,
        sourceVideoId.isAcceptableOrUnknown(
          data['source_video_id']!,
          _sourceVideoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceVideoIdMeta);
    }
    if (data.containsKey('output_name')) {
      context.handle(
        _outputNameMeta,
        outputName.isAcceptableOrUnknown(data['output_name']!, _outputNameMeta),
      );
    } else if (isInserting) {
      context.missing(_outputNameMeta);
    }
    if (data.containsKey('trim_start_ms')) {
      context.handle(
        _trimStartMsMeta,
        trimStartMs.isAcceptableOrUnknown(
          data['trim_start_ms']!,
          _trimStartMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trimStartMsMeta);
    }
    if (data.containsKey('trim_end_ms')) {
      context.handle(
        _trimEndMsMeta,
        trimEndMs.isAcceptableOrUnknown(data['trim_end_ms']!, _trimEndMsMeta),
      );
    } else if (isInserting) {
      context.missing(_trimEndMsMeta);
    }
    if (data.containsKey('crop_preset_id')) {
      context.handle(
        _cropPresetIdMeta,
        cropPresetId.isAcceptableOrUnknown(
          data['crop_preset_id']!,
          _cropPresetIdMeta,
        ),
      );
    }
    if (data.containsKey('crop_snapshot')) {
      context.handle(
        _cropSnapshotMeta,
        cropSnapshot.isAcceptableOrUnknown(
          data['crop_snapshot']!,
          _cropSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('crop_preset_name')) {
      context.handle(
        _cropPresetNameMeta,
        cropPresetName.isAcceptableOrUnknown(
          data['crop_preset_name']!,
          _cropPresetNameMeta,
        ),
      );
    }
    if (data.containsKey('crop_ratio_label')) {
      context.handle(
        _cropRatioLabelMeta,
        cropRatioLabel.isAcceptableOrUnknown(
          data['crop_ratio_label']!,
          _cropRatioLabelMeta,
        ),
      );
    }
    if (data.containsKey('source_video_name')) {
      context.handle(
        _sourceVideoNameMeta,
        sourceVideoName.isAcceptableOrUnknown(
          data['source_video_name']!,
          _sourceVideoNameMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
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
    if (data.containsKey('output_path')) {
      context.handle(
        _outputPathMeta,
        outputPath.isAcceptableOrUnknown(data['output_path']!, _outputPathMeta),
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
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceVideoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_video_id'],
      )!,
      outputName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_name'],
      )!,
      trimStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trim_start_ms'],
      )!,
      trimEndMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trim_end_ms'],
      )!,
      cropPresetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}crop_preset_id'],
      ),
      cropSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_snapshot'],
      ),
      cropPresetName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_preset_name'],
      ),
      cropRatioLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_ratio_label'],
      ),
      sourceVideoName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_video_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      outputPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_path'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $ExportTasksTable createAlias(String alias) {
    return $ExportTasksTable(attachedDatabase, alias);
  }
}

class ExportTask extends DataClass implements Insertable<ExportTask> {
  final int id;
  final int sourceVideoId;
  final String outputName;
  final int trimStartMs;
  final int trimEndMs;
  final int? cropPresetId;
  final String? cropSnapshot;
  final String? cropPresetName;
  final String? cropRatioLabel;
  final String? sourceVideoName;
  final String status;
  final int progress;
  final int createdAt;
  final String? outputPath;
  final int? completedAt;
  final int? archivedAt;
  final String? errorMessage;
  const ExportTask({
    required this.id,
    required this.sourceVideoId,
    required this.outputName,
    required this.trimStartMs,
    required this.trimEndMs,
    this.cropPresetId,
    this.cropSnapshot,
    this.cropPresetName,
    this.cropRatioLabel,
    this.sourceVideoName,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.outputPath,
    this.completedAt,
    this.archivedAt,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_video_id'] = Variable<int>(sourceVideoId);
    map['output_name'] = Variable<String>(outputName);
    map['trim_start_ms'] = Variable<int>(trimStartMs);
    map['trim_end_ms'] = Variable<int>(trimEndMs);
    if (!nullToAbsent || cropPresetId != null) {
      map['crop_preset_id'] = Variable<int>(cropPresetId);
    }
    if (!nullToAbsent || cropSnapshot != null) {
      map['crop_snapshot'] = Variable<String>(cropSnapshot);
    }
    if (!nullToAbsent || cropPresetName != null) {
      map['crop_preset_name'] = Variable<String>(cropPresetName);
    }
    if (!nullToAbsent || cropRatioLabel != null) {
      map['crop_ratio_label'] = Variable<String>(cropRatioLabel);
    }
    if (!nullToAbsent || sourceVideoName != null) {
      map['source_video_name'] = Variable<String>(sourceVideoName);
    }
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<int>(progress);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || outputPath != null) {
      map['output_path'] = Variable<String>(outputPath);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ExportTasksCompanion toCompanion(bool nullToAbsent) {
    return ExportTasksCompanion(
      id: Value(id),
      sourceVideoId: Value(sourceVideoId),
      outputName: Value(outputName),
      trimStartMs: Value(trimStartMs),
      trimEndMs: Value(trimEndMs),
      cropPresetId: cropPresetId == null && nullToAbsent
          ? const Value.absent()
          : Value(cropPresetId),
      cropSnapshot: cropSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(cropSnapshot),
      cropPresetName: cropPresetName == null && nullToAbsent
          ? const Value.absent()
          : Value(cropPresetName),
      cropRatioLabel: cropRatioLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(cropRatioLabel),
      sourceVideoName: sourceVideoName == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceVideoName),
      status: Value(status),
      progress: Value(progress),
      createdAt: Value(createdAt),
      outputPath: outputPath == null && nullToAbsent
          ? const Value.absent()
          : Value(outputPath),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ExportTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportTask(
      id: serializer.fromJson<int>(json['id']),
      sourceVideoId: serializer.fromJson<int>(json['sourceVideoId']),
      outputName: serializer.fromJson<String>(json['outputName']),
      trimStartMs: serializer.fromJson<int>(json['trimStartMs']),
      trimEndMs: serializer.fromJson<int>(json['trimEndMs']),
      cropPresetId: serializer.fromJson<int?>(json['cropPresetId']),
      cropSnapshot: serializer.fromJson<String?>(json['cropSnapshot']),
      cropPresetName: serializer.fromJson<String?>(json['cropPresetName']),
      cropRatioLabel: serializer.fromJson<String?>(json['cropRatioLabel']),
      sourceVideoName: serializer.fromJson<String?>(json['sourceVideoName']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      outputPath: serializer.fromJson<String?>(json['outputPath']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceVideoId': serializer.toJson<int>(sourceVideoId),
      'outputName': serializer.toJson<String>(outputName),
      'trimStartMs': serializer.toJson<int>(trimStartMs),
      'trimEndMs': serializer.toJson<int>(trimEndMs),
      'cropPresetId': serializer.toJson<int?>(cropPresetId),
      'cropSnapshot': serializer.toJson<String?>(cropSnapshot),
      'cropPresetName': serializer.toJson<String?>(cropPresetName),
      'cropRatioLabel': serializer.toJson<String?>(cropRatioLabel),
      'sourceVideoName': serializer.toJson<String?>(sourceVideoName),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<int>(progress),
      'createdAt': serializer.toJson<int>(createdAt),
      'outputPath': serializer.toJson<String?>(outputPath),
      'completedAt': serializer.toJson<int?>(completedAt),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ExportTask copyWith({
    int? id,
    int? sourceVideoId,
    String? outputName,
    int? trimStartMs,
    int? trimEndMs,
    Value<int?> cropPresetId = const Value.absent(),
    Value<String?> cropSnapshot = const Value.absent(),
    Value<String?> cropPresetName = const Value.absent(),
    Value<String?> cropRatioLabel = const Value.absent(),
    Value<String?> sourceVideoName = const Value.absent(),
    String? status,
    int? progress,
    int? createdAt,
    Value<String?> outputPath = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
    Value<int?> archivedAt = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => ExportTask(
    id: id ?? this.id,
    sourceVideoId: sourceVideoId ?? this.sourceVideoId,
    outputName: outputName ?? this.outputName,
    trimStartMs: trimStartMs ?? this.trimStartMs,
    trimEndMs: trimEndMs ?? this.trimEndMs,
    cropPresetId: cropPresetId.present ? cropPresetId.value : this.cropPresetId,
    cropSnapshot: cropSnapshot.present ? cropSnapshot.value : this.cropSnapshot,
    cropPresetName: cropPresetName.present
        ? cropPresetName.value
        : this.cropPresetName,
    cropRatioLabel: cropRatioLabel.present
        ? cropRatioLabel.value
        : this.cropRatioLabel,
    sourceVideoName: sourceVideoName.present
        ? sourceVideoName.value
        : this.sourceVideoName,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    createdAt: createdAt ?? this.createdAt,
    outputPath: outputPath.present ? outputPath.value : this.outputPath,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  ExportTask copyWithCompanion(ExportTasksCompanion data) {
    return ExportTask(
      id: data.id.present ? data.id.value : this.id,
      sourceVideoId: data.sourceVideoId.present
          ? data.sourceVideoId.value
          : this.sourceVideoId,
      outputName: data.outputName.present
          ? data.outputName.value
          : this.outputName,
      trimStartMs: data.trimStartMs.present
          ? data.trimStartMs.value
          : this.trimStartMs,
      trimEndMs: data.trimEndMs.present ? data.trimEndMs.value : this.trimEndMs,
      cropPresetId: data.cropPresetId.present
          ? data.cropPresetId.value
          : this.cropPresetId,
      cropSnapshot: data.cropSnapshot.present
          ? data.cropSnapshot.value
          : this.cropSnapshot,
      cropPresetName: data.cropPresetName.present
          ? data.cropPresetName.value
          : this.cropPresetName,
      cropRatioLabel: data.cropRatioLabel.present
          ? data.cropRatioLabel.value
          : this.cropRatioLabel,
      sourceVideoName: data.sourceVideoName.present
          ? data.sourceVideoName.value
          : this.sourceVideoName,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      outputPath: data.outputPath.present
          ? data.outputPath.value
          : this.outputPath,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportTask(')
          ..write('id: $id, ')
          ..write('sourceVideoId: $sourceVideoId, ')
          ..write('outputName: $outputName, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('cropPresetId: $cropPresetId, ')
          ..write('cropSnapshot: $cropSnapshot, ')
          ..write('cropPresetName: $cropPresetName, ')
          ..write('cropRatioLabel: $cropRatioLabel, ')
          ..write('sourceVideoName: $sourceVideoName, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('createdAt: $createdAt, ')
          ..write('outputPath: $outputPath, ')
          ..write('completedAt: $completedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceVideoId,
    outputName,
    trimStartMs,
    trimEndMs,
    cropPresetId,
    cropSnapshot,
    cropPresetName,
    cropRatioLabel,
    sourceVideoName,
    status,
    progress,
    createdAt,
    outputPath,
    completedAt,
    archivedAt,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportTask &&
          other.id == this.id &&
          other.sourceVideoId == this.sourceVideoId &&
          other.outputName == this.outputName &&
          other.trimStartMs == this.trimStartMs &&
          other.trimEndMs == this.trimEndMs &&
          other.cropPresetId == this.cropPresetId &&
          other.cropSnapshot == this.cropSnapshot &&
          other.cropPresetName == this.cropPresetName &&
          other.cropRatioLabel == this.cropRatioLabel &&
          other.sourceVideoName == this.sourceVideoName &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.createdAt == this.createdAt &&
          other.outputPath == this.outputPath &&
          other.completedAt == this.completedAt &&
          other.archivedAt == this.archivedAt &&
          other.errorMessage == this.errorMessage);
}

class ExportTasksCompanion extends UpdateCompanion<ExportTask> {
  final Value<int> id;
  final Value<int> sourceVideoId;
  final Value<String> outputName;
  final Value<int> trimStartMs;
  final Value<int> trimEndMs;
  final Value<int?> cropPresetId;
  final Value<String?> cropSnapshot;
  final Value<String?> cropPresetName;
  final Value<String?> cropRatioLabel;
  final Value<String?> sourceVideoName;
  final Value<String> status;
  final Value<int> progress;
  final Value<int> createdAt;
  final Value<String?> outputPath;
  final Value<int?> completedAt;
  final Value<int?> archivedAt;
  final Value<String?> errorMessage;
  const ExportTasksCompanion({
    this.id = const Value.absent(),
    this.sourceVideoId = const Value.absent(),
    this.outputName = const Value.absent(),
    this.trimStartMs = const Value.absent(),
    this.trimEndMs = const Value.absent(),
    this.cropPresetId = const Value.absent(),
    this.cropSnapshot = const Value.absent(),
    this.cropPresetName = const Value.absent(),
    this.cropRatioLabel = const Value.absent(),
    this.sourceVideoName = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.outputPath = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  ExportTasksCompanion.insert({
    this.id = const Value.absent(),
    required int sourceVideoId,
    required String outputName,
    required int trimStartMs,
    required int trimEndMs,
    this.cropPresetId = const Value.absent(),
    this.cropSnapshot = const Value.absent(),
    this.cropPresetName = const Value.absent(),
    this.cropRatioLabel = const Value.absent(),
    this.sourceVideoName = const Value.absent(),
    required String status,
    this.progress = const Value.absent(),
    required int createdAt,
    this.outputPath = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
  }) : sourceVideoId = Value(sourceVideoId),
       outputName = Value(outputName),
       trimStartMs = Value(trimStartMs),
       trimEndMs = Value(trimEndMs),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<ExportTask> custom({
    Expression<int>? id,
    Expression<int>? sourceVideoId,
    Expression<String>? outputName,
    Expression<int>? trimStartMs,
    Expression<int>? trimEndMs,
    Expression<int>? cropPresetId,
    Expression<String>? cropSnapshot,
    Expression<String>? cropPresetName,
    Expression<String>? cropRatioLabel,
    Expression<String>? sourceVideoName,
    Expression<String>? status,
    Expression<int>? progress,
    Expression<int>? createdAt,
    Expression<String>? outputPath,
    Expression<int>? completedAt,
    Expression<int>? archivedAt,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceVideoId != null) 'source_video_id': sourceVideoId,
      if (outputName != null) 'output_name': outputName,
      if (trimStartMs != null) 'trim_start_ms': trimStartMs,
      if (trimEndMs != null) 'trim_end_ms': trimEndMs,
      if (cropPresetId != null) 'crop_preset_id': cropPresetId,
      if (cropSnapshot != null) 'crop_snapshot': cropSnapshot,
      if (cropPresetName != null) 'crop_preset_name': cropPresetName,
      if (cropRatioLabel != null) 'crop_ratio_label': cropRatioLabel,
      if (sourceVideoName != null) 'source_video_name': sourceVideoName,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (createdAt != null) 'created_at': createdAt,
      if (outputPath != null) 'output_path': outputPath,
      if (completedAt != null) 'completed_at': completedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  ExportTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? sourceVideoId,
    Value<String>? outputName,
    Value<int>? trimStartMs,
    Value<int>? trimEndMs,
    Value<int?>? cropPresetId,
    Value<String?>? cropSnapshot,
    Value<String?>? cropPresetName,
    Value<String?>? cropRatioLabel,
    Value<String?>? sourceVideoName,
    Value<String>? status,
    Value<int>? progress,
    Value<int>? createdAt,
    Value<String?>? outputPath,
    Value<int?>? completedAt,
    Value<int?>? archivedAt,
    Value<String?>? errorMessage,
  }) {
    return ExportTasksCompanion(
      id: id ?? this.id,
      sourceVideoId: sourceVideoId ?? this.sourceVideoId,
      outputName: outputName ?? this.outputName,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      cropPresetId: cropPresetId ?? this.cropPresetId,
      cropSnapshot: cropSnapshot ?? this.cropSnapshot,
      cropPresetName: cropPresetName ?? this.cropPresetName,
      cropRatioLabel: cropRatioLabel ?? this.cropRatioLabel,
      sourceVideoName: sourceVideoName ?? this.sourceVideoName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      outputPath: outputPath ?? this.outputPath,
      completedAt: completedAt ?? this.completedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceVideoId.present) {
      map['source_video_id'] = Variable<int>(sourceVideoId.value);
    }
    if (outputName.present) {
      map['output_name'] = Variable<String>(outputName.value);
    }
    if (trimStartMs.present) {
      map['trim_start_ms'] = Variable<int>(trimStartMs.value);
    }
    if (trimEndMs.present) {
      map['trim_end_ms'] = Variable<int>(trimEndMs.value);
    }
    if (cropPresetId.present) {
      map['crop_preset_id'] = Variable<int>(cropPresetId.value);
    }
    if (cropSnapshot.present) {
      map['crop_snapshot'] = Variable<String>(cropSnapshot.value);
    }
    if (cropPresetName.present) {
      map['crop_preset_name'] = Variable<String>(cropPresetName.value);
    }
    if (cropRatioLabel.present) {
      map['crop_ratio_label'] = Variable<String>(cropRatioLabel.value);
    }
    if (sourceVideoName.present) {
      map['source_video_name'] = Variable<String>(sourceVideoName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (outputPath.present) {
      map['output_path'] = Variable<String>(outputPath.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportTasksCompanion(')
          ..write('id: $id, ')
          ..write('sourceVideoId: $sourceVideoId, ')
          ..write('outputName: $outputName, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('cropPresetId: $cropPresetId, ')
          ..write('cropSnapshot: $cropSnapshot, ')
          ..write('cropPresetName: $cropPresetName, ')
          ..write('cropRatioLabel: $cropRatioLabel, ')
          ..write('sourceVideoName: $sourceVideoName, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('createdAt: $createdAt, ')
          ..write('outputPath: $outputPath, ')
          ..write('completedAt: $completedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

class $CropPresetsTable extends CropPresets
    with TableInfo<$CropPresetsTable, CropPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CropPresetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratioLabelMeta = const VerificationMeta(
    'ratioLabel',
  );
  @override
  late final GeneratedColumn<String> ratioLabel = GeneratedColumn<String>(
    'ratio_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratioWMeta = const VerificationMeta('ratioW');
  @override
  late final GeneratedColumn<int> ratioW = GeneratedColumn<int>(
    'ratio_w',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratioHMeta = const VerificationMeta('ratioH');
  @override
  late final GeneratedColumn<int> ratioH = GeneratedColumn<int>(
    'ratio_h',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputWMeta = const VerificationMeta(
    'outputW',
  );
  @override
  late final GeneratedColumn<int> outputW = GeneratedColumn<int>(
    'output_w',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputHMeta = const VerificationMeta(
    'outputH',
  );
  @override
  late final GeneratedColumn<int> outputH = GeneratedColumn<int>(
    'output_h',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetXMeta = const VerificationMeta(
    'offsetX',
  );
  @override
  late final GeneratedColumn<int> offsetX = GeneratedColumn<int>(
    'offset_x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offsetYMeta = const VerificationMeta(
    'offsetY',
  );
  @override
  late final GeneratedColumn<int> offsetY = GeneratedColumn<int>(
    'offset_y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ratioLabel,
    ratioW,
    ratioH,
    outputW,
    outputH,
    offsetX,
    offsetY,
    isBuiltin,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'crop_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CropPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ratio_label')) {
      context.handle(
        _ratioLabelMeta,
        ratioLabel.isAcceptableOrUnknown(data['ratio_label']!, _ratioLabelMeta),
      );
    } else if (isInserting) {
      context.missing(_ratioLabelMeta);
    }
    if (data.containsKey('ratio_w')) {
      context.handle(
        _ratioWMeta,
        ratioW.isAcceptableOrUnknown(data['ratio_w']!, _ratioWMeta),
      );
    } else if (isInserting) {
      context.missing(_ratioWMeta);
    }
    if (data.containsKey('ratio_h')) {
      context.handle(
        _ratioHMeta,
        ratioH.isAcceptableOrUnknown(data['ratio_h']!, _ratioHMeta),
      );
    } else if (isInserting) {
      context.missing(_ratioHMeta);
    }
    if (data.containsKey('output_w')) {
      context.handle(
        _outputWMeta,
        outputW.isAcceptableOrUnknown(data['output_w']!, _outputWMeta),
      );
    } else if (isInserting) {
      context.missing(_outputWMeta);
    }
    if (data.containsKey('output_h')) {
      context.handle(
        _outputHMeta,
        outputH.isAcceptableOrUnknown(data['output_h']!, _outputHMeta),
      );
    } else if (isInserting) {
      context.missing(_outputHMeta);
    }
    if (data.containsKey('offset_x')) {
      context.handle(
        _offsetXMeta,
        offsetX.isAcceptableOrUnknown(data['offset_x']!, _offsetXMeta),
      );
    } else if (isInserting) {
      context.missing(_offsetXMeta);
    }
    if (data.containsKey('offset_y')) {
      context.handle(
        _offsetYMeta,
        offsetY.isAcceptableOrUnknown(data['offset_y']!, _offsetYMeta),
      );
    } else if (isInserting) {
      context.missing(_offsetYMeta);
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    } else if (isInserting) {
      context.missing(_isBuiltinMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CropPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CropPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ratioLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ratio_label'],
      )!,
      ratioW: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ratio_w'],
      )!,
      ratioH: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ratio_h'],
      )!,
      outputW: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_w'],
      )!,
      outputH: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_h'],
      )!,
      offsetX: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_x'],
      )!,
      offsetY: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offset_y'],
      )!,
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CropPresetsTable createAlias(String alias) {
    return $CropPresetsTable(attachedDatabase, alias);
  }
}

class CropPreset extends DataClass implements Insertable<CropPreset> {
  final int id;
  final String name;
  final String ratioLabel;
  final int ratioW;
  final int ratioH;
  final int outputW;
  final int outputH;
  final int offsetX;
  final int offsetY;
  final bool isBuiltin;
  final int sortOrder;
  const CropPreset({
    required this.id,
    required this.name,
    required this.ratioLabel,
    required this.ratioW,
    required this.ratioH,
    required this.outputW,
    required this.outputH,
    required this.offsetX,
    required this.offsetY,
    required this.isBuiltin,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['ratio_label'] = Variable<String>(ratioLabel);
    map['ratio_w'] = Variable<int>(ratioW);
    map['ratio_h'] = Variable<int>(ratioH);
    map['output_w'] = Variable<int>(outputW);
    map['output_h'] = Variable<int>(outputH);
    map['offset_x'] = Variable<int>(offsetX);
    map['offset_y'] = Variable<int>(offsetY);
    map['is_builtin'] = Variable<bool>(isBuiltin);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CropPresetsCompanion toCompanion(bool nullToAbsent) {
    return CropPresetsCompanion(
      id: Value(id),
      name: Value(name),
      ratioLabel: Value(ratioLabel),
      ratioW: Value(ratioW),
      ratioH: Value(ratioH),
      outputW: Value(outputW),
      outputH: Value(outputH),
      offsetX: Value(offsetX),
      offsetY: Value(offsetY),
      isBuiltin: Value(isBuiltin),
      sortOrder: Value(sortOrder),
    );
  }

  factory CropPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CropPreset(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ratioLabel: serializer.fromJson<String>(json['ratioLabel']),
      ratioW: serializer.fromJson<int>(json['ratioW']),
      ratioH: serializer.fromJson<int>(json['ratioH']),
      outputW: serializer.fromJson<int>(json['outputW']),
      outputH: serializer.fromJson<int>(json['outputH']),
      offsetX: serializer.fromJson<int>(json['offsetX']),
      offsetY: serializer.fromJson<int>(json['offsetY']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'ratioLabel': serializer.toJson<String>(ratioLabel),
      'ratioW': serializer.toJson<int>(ratioW),
      'ratioH': serializer.toJson<int>(ratioH),
      'outputW': serializer.toJson<int>(outputW),
      'outputH': serializer.toJson<int>(outputH),
      'offsetX': serializer.toJson<int>(offsetX),
      'offsetY': serializer.toJson<int>(offsetY),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CropPreset copyWith({
    int? id,
    String? name,
    String? ratioLabel,
    int? ratioW,
    int? ratioH,
    int? outputW,
    int? outputH,
    int? offsetX,
    int? offsetY,
    bool? isBuiltin,
    int? sortOrder,
  }) => CropPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    ratioLabel: ratioLabel ?? this.ratioLabel,
    ratioW: ratioW ?? this.ratioW,
    ratioH: ratioH ?? this.ratioH,
    outputW: outputW ?? this.outputW,
    outputH: outputH ?? this.outputH,
    offsetX: offsetX ?? this.offsetX,
    offsetY: offsetY ?? this.offsetY,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CropPreset copyWithCompanion(CropPresetsCompanion data) {
    return CropPreset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ratioLabel: data.ratioLabel.present
          ? data.ratioLabel.value
          : this.ratioLabel,
      ratioW: data.ratioW.present ? data.ratioW.value : this.ratioW,
      ratioH: data.ratioH.present ? data.ratioH.value : this.ratioH,
      outputW: data.outputW.present ? data.outputW.value : this.outputW,
      outputH: data.outputH.present ? data.outputH.value : this.outputH,
      offsetX: data.offsetX.present ? data.offsetX.value : this.offsetX,
      offsetY: data.offsetY.present ? data.offsetY.value : this.offsetY,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CropPreset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ratioLabel: $ratioLabel, ')
          ..write('ratioW: $ratioW, ')
          ..write('ratioH: $ratioH, ')
          ..write('outputW: $outputW, ')
          ..write('outputH: $outputH, ')
          ..write('offsetX: $offsetX, ')
          ..write('offsetY: $offsetY, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ratioLabel,
    ratioW,
    ratioH,
    outputW,
    outputH,
    offsetX,
    offsetY,
    isBuiltin,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CropPreset &&
          other.id == this.id &&
          other.name == this.name &&
          other.ratioLabel == this.ratioLabel &&
          other.ratioW == this.ratioW &&
          other.ratioH == this.ratioH &&
          other.outputW == this.outputW &&
          other.outputH == this.outputH &&
          other.offsetX == this.offsetX &&
          other.offsetY == this.offsetY &&
          other.isBuiltin == this.isBuiltin &&
          other.sortOrder == this.sortOrder);
}

class CropPresetsCompanion extends UpdateCompanion<CropPreset> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> ratioLabel;
  final Value<int> ratioW;
  final Value<int> ratioH;
  final Value<int> outputW;
  final Value<int> outputH;
  final Value<int> offsetX;
  final Value<int> offsetY;
  final Value<bool> isBuiltin;
  final Value<int> sortOrder;
  const CropPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ratioLabel = const Value.absent(),
    this.ratioW = const Value.absent(),
    this.ratioH = const Value.absent(),
    this.outputW = const Value.absent(),
    this.outputH = const Value.absent(),
    this.offsetX = const Value.absent(),
    this.offsetY = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CropPresetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String ratioLabel,
    required int ratioW,
    required int ratioH,
    required int outputW,
    required int outputH,
    required int offsetX,
    required int offsetY,
    required bool isBuiltin,
    required int sortOrder,
  }) : name = Value(name),
       ratioLabel = Value(ratioLabel),
       ratioW = Value(ratioW),
       ratioH = Value(ratioH),
       outputW = Value(outputW),
       outputH = Value(outputH),
       offsetX = Value(offsetX),
       offsetY = Value(offsetY),
       isBuiltin = Value(isBuiltin),
       sortOrder = Value(sortOrder);
  static Insertable<CropPreset> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? ratioLabel,
    Expression<int>? ratioW,
    Expression<int>? ratioH,
    Expression<int>? outputW,
    Expression<int>? outputH,
    Expression<int>? offsetX,
    Expression<int>? offsetY,
    Expression<bool>? isBuiltin,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ratioLabel != null) 'ratio_label': ratioLabel,
      if (ratioW != null) 'ratio_w': ratioW,
      if (ratioH != null) 'ratio_h': ratioH,
      if (outputW != null) 'output_w': outputW,
      if (outputH != null) 'output_h': outputH,
      if (offsetX != null) 'offset_x': offsetX,
      if (offsetY != null) 'offset_y': offsetY,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CropPresetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? ratioLabel,
    Value<int>? ratioW,
    Value<int>? ratioH,
    Value<int>? outputW,
    Value<int>? outputH,
    Value<int>? offsetX,
    Value<int>? offsetY,
    Value<bool>? isBuiltin,
    Value<int>? sortOrder,
  }) {
    return CropPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ratioLabel: ratioLabel ?? this.ratioLabel,
      ratioW: ratioW ?? this.ratioW,
      ratioH: ratioH ?? this.ratioH,
      outputW: outputW ?? this.outputW,
      outputH: outputH ?? this.outputH,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ratioLabel.present) {
      map['ratio_label'] = Variable<String>(ratioLabel.value);
    }
    if (ratioW.present) {
      map['ratio_w'] = Variable<int>(ratioW.value);
    }
    if (ratioH.present) {
      map['ratio_h'] = Variable<int>(ratioH.value);
    }
    if (outputW.present) {
      map['output_w'] = Variable<int>(outputW.value);
    }
    if (outputH.present) {
      map['output_h'] = Variable<int>(outputH.value);
    }
    if (offsetX.present) {
      map['offset_x'] = Variable<int>(offsetX.value);
    }
    if (offsetY.present) {
      map['offset_y'] = Variable<int>(offsetY.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CropPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ratioLabel: $ratioLabel, ')
          ..write('ratioW: $ratioW, ')
          ..write('ratioH: $ratioH, ')
          ..write('outputW: $outputW, ')
          ..write('outputH: $outputH, ')
          ..write('offsetX: $offsetX, ')
          ..write('offsetY: $offsetY, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $EditorDraftsTable extends EditorDrafts
    with TableInfo<$EditorDraftsTable, EditorDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EditorDraftsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceVideoIdMeta = const VerificationMeta(
    'sourceVideoId',
  );
  @override
  late final GeneratedColumn<int> sourceVideoId = GeneratedColumn<int>(
    'source_video_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _outputNameMeta = const VerificationMeta(
    'outputName',
  );
  @override
  late final GeneratedColumn<String> outputName = GeneratedColumn<String>(
    'output_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trimStartMsMeta = const VerificationMeta(
    'trimStartMs',
  );
  @override
  late final GeneratedColumn<int> trimStartMs = GeneratedColumn<int>(
    'trim_start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trimEndMsMeta = const VerificationMeta(
    'trimEndMs',
  );
  @override
  late final GeneratedColumn<int> trimEndMs = GeneratedColumn<int>(
    'trim_end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedCropPresetIdMeta =
      const VerificationMeta('selectedCropPresetId');
  @override
  late final GeneratedColumn<int> selectedCropPresetId = GeneratedColumn<int>(
    'selected_crop_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceVideoId,
    outputName,
    trimStartMs,
    trimEndMs,
    selectedCropPresetId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'editor_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<EditorDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_video_id')) {
      context.handle(
        _sourceVideoIdMeta,
        sourceVideoId.isAcceptableOrUnknown(
          data['source_video_id']!,
          _sourceVideoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceVideoIdMeta);
    }
    if (data.containsKey('output_name')) {
      context.handle(
        _outputNameMeta,
        outputName.isAcceptableOrUnknown(data['output_name']!, _outputNameMeta),
      );
    } else if (isInserting) {
      context.missing(_outputNameMeta);
    }
    if (data.containsKey('trim_start_ms')) {
      context.handle(
        _trimStartMsMeta,
        trimStartMs.isAcceptableOrUnknown(
          data['trim_start_ms']!,
          _trimStartMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trimStartMsMeta);
    }
    if (data.containsKey('trim_end_ms')) {
      context.handle(
        _trimEndMsMeta,
        trimEndMs.isAcceptableOrUnknown(data['trim_end_ms']!, _trimEndMsMeta),
      );
    } else if (isInserting) {
      context.missing(_trimEndMsMeta);
    }
    if (data.containsKey('selected_crop_preset_id')) {
      context.handle(
        _selectedCropPresetIdMeta,
        selectedCropPresetId.isAcceptableOrUnknown(
          data['selected_crop_preset_id']!,
          _selectedCropPresetIdMeta,
        ),
      );
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
  EditorDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EditorDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceVideoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_video_id'],
      )!,
      outputName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_name'],
      )!,
      trimStartMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trim_start_ms'],
      )!,
      trimEndMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trim_end_ms'],
      )!,
      selectedCropPresetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selected_crop_preset_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EditorDraftsTable createAlias(String alias) {
    return $EditorDraftsTable(attachedDatabase, alias);
  }
}

class EditorDraft extends DataClass implements Insertable<EditorDraft> {
  final int id;
  final int sourceVideoId;
  final String outputName;
  final int trimStartMs;
  final int trimEndMs;
  final int? selectedCropPresetId;
  final int updatedAt;
  const EditorDraft({
    required this.id,
    required this.sourceVideoId,
    required this.outputName,
    required this.trimStartMs,
    required this.trimEndMs,
    this.selectedCropPresetId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_video_id'] = Variable<int>(sourceVideoId);
    map['output_name'] = Variable<String>(outputName);
    map['trim_start_ms'] = Variable<int>(trimStartMs);
    map['trim_end_ms'] = Variable<int>(trimEndMs);
    if (!nullToAbsent || selectedCropPresetId != null) {
      map['selected_crop_preset_id'] = Variable<int>(selectedCropPresetId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  EditorDraftsCompanion toCompanion(bool nullToAbsent) {
    return EditorDraftsCompanion(
      id: Value(id),
      sourceVideoId: Value(sourceVideoId),
      outputName: Value(outputName),
      trimStartMs: Value(trimStartMs),
      trimEndMs: Value(trimEndMs),
      selectedCropPresetId: selectedCropPresetId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedCropPresetId),
      updatedAt: Value(updatedAt),
    );
  }

  factory EditorDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EditorDraft(
      id: serializer.fromJson<int>(json['id']),
      sourceVideoId: serializer.fromJson<int>(json['sourceVideoId']),
      outputName: serializer.fromJson<String>(json['outputName']),
      trimStartMs: serializer.fromJson<int>(json['trimStartMs']),
      trimEndMs: serializer.fromJson<int>(json['trimEndMs']),
      selectedCropPresetId: serializer.fromJson<int?>(
        json['selectedCropPresetId'],
      ),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceVideoId': serializer.toJson<int>(sourceVideoId),
      'outputName': serializer.toJson<String>(outputName),
      'trimStartMs': serializer.toJson<int>(trimStartMs),
      'trimEndMs': serializer.toJson<int>(trimEndMs),
      'selectedCropPresetId': serializer.toJson<int?>(selectedCropPresetId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  EditorDraft copyWith({
    int? id,
    int? sourceVideoId,
    String? outputName,
    int? trimStartMs,
    int? trimEndMs,
    Value<int?> selectedCropPresetId = const Value.absent(),
    int? updatedAt,
  }) => EditorDraft(
    id: id ?? this.id,
    sourceVideoId: sourceVideoId ?? this.sourceVideoId,
    outputName: outputName ?? this.outputName,
    trimStartMs: trimStartMs ?? this.trimStartMs,
    trimEndMs: trimEndMs ?? this.trimEndMs,
    selectedCropPresetId: selectedCropPresetId.present
        ? selectedCropPresetId.value
        : this.selectedCropPresetId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EditorDraft copyWithCompanion(EditorDraftsCompanion data) {
    return EditorDraft(
      id: data.id.present ? data.id.value : this.id,
      sourceVideoId: data.sourceVideoId.present
          ? data.sourceVideoId.value
          : this.sourceVideoId,
      outputName: data.outputName.present
          ? data.outputName.value
          : this.outputName,
      trimStartMs: data.trimStartMs.present
          ? data.trimStartMs.value
          : this.trimStartMs,
      trimEndMs: data.trimEndMs.present ? data.trimEndMs.value : this.trimEndMs,
      selectedCropPresetId: data.selectedCropPresetId.present
          ? data.selectedCropPresetId.value
          : this.selectedCropPresetId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EditorDraft(')
          ..write('id: $id, ')
          ..write('sourceVideoId: $sourceVideoId, ')
          ..write('outputName: $outputName, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('selectedCropPresetId: $selectedCropPresetId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceVideoId,
    outputName,
    trimStartMs,
    trimEndMs,
    selectedCropPresetId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EditorDraft &&
          other.id == this.id &&
          other.sourceVideoId == this.sourceVideoId &&
          other.outputName == this.outputName &&
          other.trimStartMs == this.trimStartMs &&
          other.trimEndMs == this.trimEndMs &&
          other.selectedCropPresetId == this.selectedCropPresetId &&
          other.updatedAt == this.updatedAt);
}

class EditorDraftsCompanion extends UpdateCompanion<EditorDraft> {
  final Value<int> id;
  final Value<int> sourceVideoId;
  final Value<String> outputName;
  final Value<int> trimStartMs;
  final Value<int> trimEndMs;
  final Value<int?> selectedCropPresetId;
  final Value<int> updatedAt;
  const EditorDraftsCompanion({
    this.id = const Value.absent(),
    this.sourceVideoId = const Value.absent(),
    this.outputName = const Value.absent(),
    this.trimStartMs = const Value.absent(),
    this.trimEndMs = const Value.absent(),
    this.selectedCropPresetId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EditorDraftsCompanion.insert({
    this.id = const Value.absent(),
    required int sourceVideoId,
    required String outputName,
    required int trimStartMs,
    required int trimEndMs,
    this.selectedCropPresetId = const Value.absent(),
    required int updatedAt,
  }) : sourceVideoId = Value(sourceVideoId),
       outputName = Value(outputName),
       trimStartMs = Value(trimStartMs),
       trimEndMs = Value(trimEndMs),
       updatedAt = Value(updatedAt);
  static Insertable<EditorDraft> custom({
    Expression<int>? id,
    Expression<int>? sourceVideoId,
    Expression<String>? outputName,
    Expression<int>? trimStartMs,
    Expression<int>? trimEndMs,
    Expression<int>? selectedCropPresetId,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceVideoId != null) 'source_video_id': sourceVideoId,
      if (outputName != null) 'output_name': outputName,
      if (trimStartMs != null) 'trim_start_ms': trimStartMs,
      if (trimEndMs != null) 'trim_end_ms': trimEndMs,
      if (selectedCropPresetId != null)
        'selected_crop_preset_id': selectedCropPresetId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EditorDraftsCompanion copyWith({
    Value<int>? id,
    Value<int>? sourceVideoId,
    Value<String>? outputName,
    Value<int>? trimStartMs,
    Value<int>? trimEndMs,
    Value<int?>? selectedCropPresetId,
    Value<int>? updatedAt,
  }) {
    return EditorDraftsCompanion(
      id: id ?? this.id,
      sourceVideoId: sourceVideoId ?? this.sourceVideoId,
      outputName: outputName ?? this.outputName,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      selectedCropPresetId: selectedCropPresetId ?? this.selectedCropPresetId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceVideoId.present) {
      map['source_video_id'] = Variable<int>(sourceVideoId.value);
    }
    if (outputName.present) {
      map['output_name'] = Variable<String>(outputName.value);
    }
    if (trimStartMs.present) {
      map['trim_start_ms'] = Variable<int>(trimStartMs.value);
    }
    if (trimEndMs.present) {
      map['trim_end_ms'] = Variable<int>(trimEndMs.value);
    }
    if (selectedCropPresetId.present) {
      map['selected_crop_preset_id'] = Variable<int>(
        selectedCropPresetId.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EditorDraftsCompanion(')
          ..write('id: $id, ')
          ..write('sourceVideoId: $sourceVideoId, ')
          ..write('outputName: $outputName, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('selectedCropPresetId: $selectedCropPresetId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideoItemsTable videoItems = $VideoItemsTable(this);
  late final $ExportTasksTable exportTasks = $ExportTasksTable(this);
  late final $CropPresetsTable cropPresets = $CropPresetsTable(this);
  late final $EditorDraftsTable editorDrafts = $EditorDraftsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    videoItems,
    exportTasks,
    cropPresets,
    editorDrafts,
    appSettings,
  ];
}

typedef $$VideoItemsTableCreateCompanionBuilder =
    VideoItemsCompanion Function({
      Value<int> id,
      required String path,
      required String name,
      required int duration,
      required int width,
      required int height,
      required int fileSize,
      required double frameRate,
      required String codec,
      required int importedAt,
    });
typedef $$VideoItemsTableUpdateCompanionBuilder =
    VideoItemsCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<String> name,
      Value<int> duration,
      Value<int> width,
      Value<int> height,
      Value<int> fileSize,
      Value<double> frameRate,
      Value<String> codec,
      Value<int> importedAt,
    });

class $$VideoItemsTableFilterComposer
    extends Composer<_$AppDatabase, $VideoItemsTable> {
  $$VideoItemsTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get frameRate => $composableBuilder(
    column: $table.frameRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VideoItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoItemsTable> {
  $$VideoItemsTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get frameRate => $composableBuilder(
    column: $table.frameRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VideoItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoItemsTable> {
  $$VideoItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<double> get frameRate =>
      $composableBuilder(column: $table.frameRate, builder: (column) => column);

  GeneratedColumn<String> get codec =>
      $composableBuilder(column: $table.codec, builder: (column) => column);

  GeneratedColumn<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $$VideoItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideoItemsTable,
          VideoItem,
          $$VideoItemsTableFilterComposer,
          $$VideoItemsTableOrderingComposer,
          $$VideoItemsTableAnnotationComposer,
          $$VideoItemsTableCreateCompanionBuilder,
          $$VideoItemsTableUpdateCompanionBuilder,
          (
            VideoItem,
            BaseReferences<_$AppDatabase, $VideoItemsTable, VideoItem>,
          ),
          VideoItem,
          PrefetchHooks Function()
        > {
  $$VideoItemsTableTableManager(_$AppDatabase db, $VideoItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<double> frameRate = const Value.absent(),
                Value<String> codec = const Value.absent(),
                Value<int> importedAt = const Value.absent(),
              }) => VideoItemsCompanion(
                id: id,
                path: path,
                name: name,
                duration: duration,
                width: width,
                height: height,
                fileSize: fileSize,
                frameRate: frameRate,
                codec: codec,
                importedAt: importedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                required String name,
                required int duration,
                required int width,
                required int height,
                required int fileSize,
                required double frameRate,
                required String codec,
                required int importedAt,
              }) => VideoItemsCompanion.insert(
                id: id,
                path: path,
                name: name,
                duration: duration,
                width: width,
                height: height,
                fileSize: fileSize,
                frameRate: frameRate,
                codec: codec,
                importedAt: importedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VideoItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideoItemsTable,
      VideoItem,
      $$VideoItemsTableFilterComposer,
      $$VideoItemsTableOrderingComposer,
      $$VideoItemsTableAnnotationComposer,
      $$VideoItemsTableCreateCompanionBuilder,
      $$VideoItemsTableUpdateCompanionBuilder,
      (VideoItem, BaseReferences<_$AppDatabase, $VideoItemsTable, VideoItem>),
      VideoItem,
      PrefetchHooks Function()
    >;
typedef $$ExportTasksTableCreateCompanionBuilder =
    ExportTasksCompanion Function({
      Value<int> id,
      required int sourceVideoId,
      required String outputName,
      required int trimStartMs,
      required int trimEndMs,
      Value<int?> cropPresetId,
      Value<String?> cropSnapshot,
      Value<String?> cropPresetName,
      Value<String?> cropRatioLabel,
      Value<String?> sourceVideoName,
      required String status,
      Value<int> progress,
      required int createdAt,
      Value<String?> outputPath,
      Value<int?> completedAt,
      Value<int?> archivedAt,
      Value<String?> errorMessage,
    });
typedef $$ExportTasksTableUpdateCompanionBuilder =
    ExportTasksCompanion Function({
      Value<int> id,
      Value<int> sourceVideoId,
      Value<String> outputName,
      Value<int> trimStartMs,
      Value<int> trimEndMs,
      Value<int?> cropPresetId,
      Value<String?> cropSnapshot,
      Value<String?> cropPresetName,
      Value<String?> cropRatioLabel,
      Value<String?> sourceVideoName,
      Value<String> status,
      Value<int> progress,
      Value<int> createdAt,
      Value<String?> outputPath,
      Value<int?> completedAt,
      Value<int?> archivedAt,
      Value<String?> errorMessage,
    });

class $$ExportTasksTableFilterComposer
    extends Composer<_$AppDatabase, $ExportTasksTable> {
  $$ExportTasksTableFilterComposer({
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

  ColumnFilters<int> get sourceVideoId => $composableBuilder(
    column: $table.sourceVideoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputName => $composableBuilder(
    column: $table.outputName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trimStartMs => $composableBuilder(
    column: $table.trimStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trimEndMs => $composableBuilder(
    column: $table.trimEndMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cropPresetId => $composableBuilder(
    column: $table.cropPresetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropSnapshot => $composableBuilder(
    column: $table.cropSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropPresetName => $composableBuilder(
    column: $table.cropPresetName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropRatioLabel => $composableBuilder(
    column: $table.cropRatioLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceVideoName => $composableBuilder(
    column: $table.sourceVideoName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExportTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $ExportTasksTable> {
  $$ExportTasksTableOrderingComposer({
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

  ColumnOrderings<int> get sourceVideoId => $composableBuilder(
    column: $table.sourceVideoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputName => $composableBuilder(
    column: $table.outputName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trimStartMs => $composableBuilder(
    column: $table.trimStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trimEndMs => $composableBuilder(
    column: $table.trimEndMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cropPresetId => $composableBuilder(
    column: $table.cropPresetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropSnapshot => $composableBuilder(
    column: $table.cropSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropPresetName => $composableBuilder(
    column: $table.cropPresetName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropRatioLabel => $composableBuilder(
    column: $table.cropRatioLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceVideoName => $composableBuilder(
    column: $table.sourceVideoName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExportTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExportTasksTable> {
  $$ExportTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sourceVideoId => $composableBuilder(
    column: $table.sourceVideoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outputName => $composableBuilder(
    column: $table.outputName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trimStartMs => $composableBuilder(
    column: $table.trimStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trimEndMs =>
      $composableBuilder(column: $table.trimEndMs, builder: (column) => column);

  GeneratedColumn<int> get cropPresetId => $composableBuilder(
    column: $table.cropPresetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cropSnapshot => $composableBuilder(
    column: $table.cropSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cropPresetName => $composableBuilder(
    column: $table.cropPresetName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cropRatioLabel => $composableBuilder(
    column: $table.cropRatioLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceVideoName => $composableBuilder(
    column: $table.sourceVideoName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$ExportTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExportTasksTable,
          ExportTask,
          $$ExportTasksTableFilterComposer,
          $$ExportTasksTableOrderingComposer,
          $$ExportTasksTableAnnotationComposer,
          $$ExportTasksTableCreateCompanionBuilder,
          $$ExportTasksTableUpdateCompanionBuilder,
          (
            ExportTask,
            BaseReferences<_$AppDatabase, $ExportTasksTable, ExportTask>,
          ),
          ExportTask,
          PrefetchHooks Function()
        > {
  $$ExportTasksTableTableManager(_$AppDatabase db, $ExportTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExportTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExportTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExportTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sourceVideoId = const Value.absent(),
                Value<String> outputName = const Value.absent(),
                Value<int> trimStartMs = const Value.absent(),
                Value<int> trimEndMs = const Value.absent(),
                Value<int?> cropPresetId = const Value.absent(),
                Value<String?> cropSnapshot = const Value.absent(),
                Value<String?> cropPresetName = const Value.absent(),
                Value<String?> cropRatioLabel = const Value.absent(),
                Value<String?> sourceVideoName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> outputPath = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => ExportTasksCompanion(
                id: id,
                sourceVideoId: sourceVideoId,
                outputName: outputName,
                trimStartMs: trimStartMs,
                trimEndMs: trimEndMs,
                cropPresetId: cropPresetId,
                cropSnapshot: cropSnapshot,
                cropPresetName: cropPresetName,
                cropRatioLabel: cropRatioLabel,
                sourceVideoName: sourceVideoName,
                status: status,
                progress: progress,
                createdAt: createdAt,
                outputPath: outputPath,
                completedAt: completedAt,
                archivedAt: archivedAt,
                errorMessage: errorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sourceVideoId,
                required String outputName,
                required int trimStartMs,
                required int trimEndMs,
                Value<int?> cropPresetId = const Value.absent(),
                Value<String?> cropSnapshot = const Value.absent(),
                Value<String?> cropPresetName = const Value.absent(),
                Value<String?> cropRatioLabel = const Value.absent(),
                Value<String?> sourceVideoName = const Value.absent(),
                required String status,
                Value<int> progress = const Value.absent(),
                required int createdAt,
                Value<String?> outputPath = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => ExportTasksCompanion.insert(
                id: id,
                sourceVideoId: sourceVideoId,
                outputName: outputName,
                trimStartMs: trimStartMs,
                trimEndMs: trimEndMs,
                cropPresetId: cropPresetId,
                cropSnapshot: cropSnapshot,
                cropPresetName: cropPresetName,
                cropRatioLabel: cropRatioLabel,
                sourceVideoName: sourceVideoName,
                status: status,
                progress: progress,
                createdAt: createdAt,
                outputPath: outputPath,
                completedAt: completedAt,
                archivedAt: archivedAt,
                errorMessage: errorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExportTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExportTasksTable,
      ExportTask,
      $$ExportTasksTableFilterComposer,
      $$ExportTasksTableOrderingComposer,
      $$ExportTasksTableAnnotationComposer,
      $$ExportTasksTableCreateCompanionBuilder,
      $$ExportTasksTableUpdateCompanionBuilder,
      (
        ExportTask,
        BaseReferences<_$AppDatabase, $ExportTasksTable, ExportTask>,
      ),
      ExportTask,
      PrefetchHooks Function()
    >;
typedef $$CropPresetsTableCreateCompanionBuilder =
    CropPresetsCompanion Function({
      Value<int> id,
      required String name,
      required String ratioLabel,
      required int ratioW,
      required int ratioH,
      required int outputW,
      required int outputH,
      required int offsetX,
      required int offsetY,
      required bool isBuiltin,
      required int sortOrder,
    });
typedef $$CropPresetsTableUpdateCompanionBuilder =
    CropPresetsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> ratioLabel,
      Value<int> ratioW,
      Value<int> ratioH,
      Value<int> outputW,
      Value<int> outputH,
      Value<int> offsetX,
      Value<int> offsetY,
      Value<bool> isBuiltin,
      Value<int> sortOrder,
    });

class $$CropPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $CropPresetsTable> {
  $$CropPresetsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratioLabel => $composableBuilder(
    column: $table.ratioLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratioW => $composableBuilder(
    column: $table.ratioW,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ratioH => $composableBuilder(
    column: $table.ratioH,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputW => $composableBuilder(
    column: $table.outputW,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputH => $composableBuilder(
    column: $table.outputH,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetX => $composableBuilder(
    column: $table.offsetX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offsetY => $composableBuilder(
    column: $table.offsetY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CropPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CropPresetsTable> {
  $$CropPresetsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratioLabel => $composableBuilder(
    column: $table.ratioLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratioW => $composableBuilder(
    column: $table.ratioW,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ratioH => $composableBuilder(
    column: $table.ratioH,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputW => $composableBuilder(
    column: $table.outputW,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputH => $composableBuilder(
    column: $table.outputH,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetX => $composableBuilder(
    column: $table.offsetX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offsetY => $composableBuilder(
    column: $table.offsetY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CropPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CropPresetsTable> {
  $$CropPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get ratioLabel => $composableBuilder(
    column: $table.ratioLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ratioW =>
      $composableBuilder(column: $table.ratioW, builder: (column) => column);

  GeneratedColumn<int> get ratioH =>
      $composableBuilder(column: $table.ratioH, builder: (column) => column);

  GeneratedColumn<int> get outputW =>
      $composableBuilder(column: $table.outputW, builder: (column) => column);

  GeneratedColumn<int> get outputH =>
      $composableBuilder(column: $table.outputH, builder: (column) => column);

  GeneratedColumn<int> get offsetX =>
      $composableBuilder(column: $table.offsetX, builder: (column) => column);

  GeneratedColumn<int> get offsetY =>
      $composableBuilder(column: $table.offsetY, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CropPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CropPresetsTable,
          CropPreset,
          $$CropPresetsTableFilterComposer,
          $$CropPresetsTableOrderingComposer,
          $$CropPresetsTableAnnotationComposer,
          $$CropPresetsTableCreateCompanionBuilder,
          $$CropPresetsTableUpdateCompanionBuilder,
          (
            CropPreset,
            BaseReferences<_$AppDatabase, $CropPresetsTable, CropPreset>,
          ),
          CropPreset,
          PrefetchHooks Function()
        > {
  $$CropPresetsTableTableManager(_$AppDatabase db, $CropPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CropPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CropPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CropPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ratioLabel = const Value.absent(),
                Value<int> ratioW = const Value.absent(),
                Value<int> ratioH = const Value.absent(),
                Value<int> outputW = const Value.absent(),
                Value<int> outputH = const Value.absent(),
                Value<int> offsetX = const Value.absent(),
                Value<int> offsetY = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CropPresetsCompanion(
                id: id,
                name: name,
                ratioLabel: ratioLabel,
                ratioW: ratioW,
                ratioH: ratioH,
                outputW: outputW,
                outputH: outputH,
                offsetX: offsetX,
                offsetY: offsetY,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String ratioLabel,
                required int ratioW,
                required int ratioH,
                required int outputW,
                required int outputH,
                required int offsetX,
                required int offsetY,
                required bool isBuiltin,
                required int sortOrder,
              }) => CropPresetsCompanion.insert(
                id: id,
                name: name,
                ratioLabel: ratioLabel,
                ratioW: ratioW,
                ratioH: ratioH,
                outputW: outputW,
                outputH: outputH,
                offsetX: offsetX,
                offsetY: offsetY,
                isBuiltin: isBuiltin,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CropPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CropPresetsTable,
      CropPreset,
      $$CropPresetsTableFilterComposer,
      $$CropPresetsTableOrderingComposer,
      $$CropPresetsTableAnnotationComposer,
      $$CropPresetsTableCreateCompanionBuilder,
      $$CropPresetsTableUpdateCompanionBuilder,
      (
        CropPreset,
        BaseReferences<_$AppDatabase, $CropPresetsTable, CropPreset>,
      ),
      CropPreset,
      PrefetchHooks Function()
    >;
typedef $$EditorDraftsTableCreateCompanionBuilder =
    EditorDraftsCompanion Function({
      Value<int> id,
      required int sourceVideoId,
      required String outputName,
      required int trimStartMs,
      required int trimEndMs,
      Value<int?> selectedCropPresetId,
      required int updatedAt,
    });
typedef $$EditorDraftsTableUpdateCompanionBuilder =
    EditorDraftsCompanion Function({
      Value<int> id,
      Value<int> sourceVideoId,
      Value<String> outputName,
      Value<int> trimStartMs,
      Value<int> trimEndMs,
      Value<int?> selectedCropPresetId,
      Value<int> updatedAt,
    });

class $$EditorDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $EditorDraftsTable> {
  $$EditorDraftsTableFilterComposer({
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

  ColumnFilters<int> get sourceVideoId => $composableBuilder(
    column: $table.sourceVideoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputName => $composableBuilder(
    column: $table.outputName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trimStartMs => $composableBuilder(
    column: $table.trimStartMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trimEndMs => $composableBuilder(
    column: $table.trimEndMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get selectedCropPresetId => $composableBuilder(
    column: $table.selectedCropPresetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EditorDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $EditorDraftsTable> {
  $$EditorDraftsTableOrderingComposer({
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

  ColumnOrderings<int> get sourceVideoId => $composableBuilder(
    column: $table.sourceVideoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputName => $composableBuilder(
    column: $table.outputName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trimStartMs => $composableBuilder(
    column: $table.trimStartMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trimEndMs => $composableBuilder(
    column: $table.trimEndMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get selectedCropPresetId => $composableBuilder(
    column: $table.selectedCropPresetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EditorDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EditorDraftsTable> {
  $$EditorDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sourceVideoId => $composableBuilder(
    column: $table.sourceVideoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outputName => $composableBuilder(
    column: $table.outputName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trimStartMs => $composableBuilder(
    column: $table.trimStartMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trimEndMs =>
      $composableBuilder(column: $table.trimEndMs, builder: (column) => column);

  GeneratedColumn<int> get selectedCropPresetId => $composableBuilder(
    column: $table.selectedCropPresetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EditorDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EditorDraftsTable,
          EditorDraft,
          $$EditorDraftsTableFilterComposer,
          $$EditorDraftsTableOrderingComposer,
          $$EditorDraftsTableAnnotationComposer,
          $$EditorDraftsTableCreateCompanionBuilder,
          $$EditorDraftsTableUpdateCompanionBuilder,
          (
            EditorDraft,
            BaseReferences<_$AppDatabase, $EditorDraftsTable, EditorDraft>,
          ),
          EditorDraft,
          PrefetchHooks Function()
        > {
  $$EditorDraftsTableTableManager(_$AppDatabase db, $EditorDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EditorDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EditorDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EditorDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sourceVideoId = const Value.absent(),
                Value<String> outputName = const Value.absent(),
                Value<int> trimStartMs = const Value.absent(),
                Value<int> trimEndMs = const Value.absent(),
                Value<int?> selectedCropPresetId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => EditorDraftsCompanion(
                id: id,
                sourceVideoId: sourceVideoId,
                outputName: outputName,
                trimStartMs: trimStartMs,
                trimEndMs: trimEndMs,
                selectedCropPresetId: selectedCropPresetId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sourceVideoId,
                required String outputName,
                required int trimStartMs,
                required int trimEndMs,
                Value<int?> selectedCropPresetId = const Value.absent(),
                required int updatedAt,
              }) => EditorDraftsCompanion.insert(
                id: id,
                sourceVideoId: sourceVideoId,
                outputName: outputName,
                trimStartMs: trimStartMs,
                trimEndMs: trimEndMs,
                selectedCropPresetId: selectedCropPresetId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EditorDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EditorDraftsTable,
      EditorDraft,
      $$EditorDraftsTableFilterComposer,
      $$EditorDraftsTableOrderingComposer,
      $$EditorDraftsTableAnnotationComposer,
      $$EditorDraftsTableCreateCompanionBuilder,
      $$EditorDraftsTableUpdateCompanionBuilder,
      (
        EditorDraft,
        BaseReferences<_$AppDatabase, $EditorDraftsTable, EditorDraft>,
      ),
      EditorDraft,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideoItemsTableTableManager get videoItems =>
      $$VideoItemsTableTableManager(_db, _db.videoItems);
  $$ExportTasksTableTableManager get exportTasks =>
      $$ExportTasksTableTableManager(_db, _db.exportTasks);
  $$CropPresetsTableTableManager get cropPresets =>
      $$CropPresetsTableTableManager(_db, _db.cropPresets);
  $$EditorDraftsTableTableManager get editorDrafts =>
      $$EditorDraftsTableTableManager(_db, _db.editorDrafts);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
