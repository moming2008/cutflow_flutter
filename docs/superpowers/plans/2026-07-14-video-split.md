# 视频分割功能实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `/split` tab 落地视频分割:导入视频 → cut 弹窗按时间戳切多段 → 批量/单独命名 → split tab 自带转码,结果以可展开子列表挂在原视频下。

**Architecture:** MVVM(Screen ↔ ViewModel ↔ Repository ↔ DAO/Service)。新增 `features/split/` 模块 + `SplitSegment` 单表(段行即持久化)。cut 弹窗照搬 `EditorDialog`,进度条复用 `_RangeSlider`,转码复用 `FfmpegEngine` + `buildTrimOnly`。交互状态机抽成纯逻辑类并充分单测。

**Tech Stack:** Flutter 3.35+ / Dart 3.9+ / Riverpod / GoRouter / Drift (SQLite) / media_kit / FFmpeg。

> **本计划为存档,暂不执行。** 包名以 `lib/` 下现有文件的 `package:` 声明为准(文中写作 `package:cutflow/...`,执行时统一替换)。

## Global Constraints

- 所有面向用户文本中文;缩进 2 空格;禁止 `dart format`;禁止局部 analyze。
- 颜色统一 `AppColors.*`,禁止硬编码 `Color(0xFF...)`;透明度用 `withValues(alpha:)`,禁止 `withOpacity`。
- Drift 表改动后必须 `dart run build_runner build --delete-conflicting-outputs`。
- 改 `*.dart` 后验证顺序:① 若改表先 build_runner → ② `dart analyze` → ③ `flutter analyze` → ④ `flutter build windows --debug`。任一步失败先修复。
- 数据库 `schemaVersion = 3`;路径用 `p.join`;命名规范:`xxxProvider` / `XxxState` / `XxxViewModel`;Model 用 `Equatable` + `copyWith`。
- `TaskStatus` 枚举复用 `lib/core/model/export_task.dart` 现有定义(`pending/preparing/exporting/done/failed`,DB 存大写串)。
- `DB 文件:~/Documents/cutflow.db`;导出目录复用 `AppSettings.exportDirectory`。

---

## File Structure

**新建:**
| 文件 | 职责 |
|---|---|
| `lib/core/model/video_source.dart` | `enum VideoSource { clip, split }` + 串化 |
| `lib/core/model/split_segment.dart` | `SplitSegment` model(Equatable+copyWith) |
| `lib/core/repository/split_repository.dart` | 段 CRUD + `getSegmentsByVideo` + `deleteByVideo` |
| `lib/core/services/split_service.dart` | 串行转码状态机 + 进度广播 |
| `lib/features/split/logic/split_state_machine.dart` | Mark In/Out 纯逻辑(无 Flutter) |
| `lib/features/split/logic/segment_namer.dart` | 默认名/批量命名 + sortOrder 重算(纯逻辑) |
| `lib/features/split/split_viewmodel.dart` | 列表状态 |
| `lib/features/split/split_cut_viewmodel.dart` | cut 弹窗状态 |
| `lib/features/split/widgets/split_timeline.dart` | 多段进度条 |
| `lib/features/split/widgets/split_cut_dialog.dart` | cut 弹窗 |
| `lib/features/split/widgets/split_segment_tile.dart` | 段行 |
| `lib/features/split/widgets/split_video_card.dart` | 视频卡 + 可展开子列表 |

**修改:**
| 文件 | 改动 |
|---|---|
| `lib/core/database/app_database.dart` | +`SplitSegments` 表;`VideoItems` +`source` 列;`schemaVersion` 2→3;`onUpgrade`;索引 |
| `lib/core/model/video_item.dart` | +`final VideoSource source` |
| `lib/core/repository/video_repository.dart` | +`getVideosBySource`;`getUnconfiguredVideos` 按 `clip` 过滤;删除级联 |
| `lib/ui/theme/colors.dart` | +`segmentPalette` |

---

## Task 1: 数据库 schema 迁移 + 基础模型

**Files:**
- Create: `lib/core/model/video_source.dart`
- Create: `lib/core/model/split_segment.dart`
- Modify: `lib/core/database/app_database.dart`
- Modify: `lib/core/model/video_item.dart`
- Test: `test/core/model/split_segment_test.dart`

**Interfaces:**
- Produces: `VideoSource`(`clip`/`split`,带 `name`/`fromName`);`SplitSegment`(字段同 spec §3.2);`VideoItem.source`;`SplitSegments` 表;schemaVersion 3。

- [ ] **Step 1: 写 `video_source.dart`**

```dart
/// 视频导入来源,区分裁剪 tab 与分割 tab。
enum VideoSource {
  clip,
  split;

  String get name => name; // 注意:枚举值小写存库
  static VideoSource fromName(String? value) =>
      VideoSource.values.firstWhere((e) => e.name == value, orElse: () => VideoSource.clip);
}
```

> 说明:DB 列以小写枚举名(`clip`/`split`)存储,与现有 `status` 用大写串的约定区分开(本字段语义独立)。

- [ ] **Step 2: 写 `split_segment.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:cutflow/core/model/export_task.dart';

/// 一个分割分段。endMs 为 null 表示「定义中、只有起点」,不参与转码。
class SplitSegment extends Equatable {
  final int id;
  final int sourceVideoId;
  final int sortOrder;
  final String name;
  final int startMs;
  final int? endMs;
  final TaskStatus status;
  final int progress;
  final String? outputPath;
  final int? completedAt;
  final String? errorMessage;
  final int updatedAt;

  const SplitSegment({
    required this.id,
    required this.sourceVideoId,
    required this.sortOrder,
    required this.name,
    required this.startMs,
    this.endMs,
    required this.status,
    this.progress = 0,
    this.outputPath,
    this.completedAt,
    this.errorMessage,
    required this.updatedAt,
  });

  bool get isComplete => endMs != null && endMs! > startMs;
  String get rangeLabel => '${_fmt(startMs)} → ${endMs == null ? '—' : _fmt(endMs!)}';
  static String _fmt(int ms) => Duration(milliseconds: ms).toString().split('.').first.padLeft(8, '0');

  @override
  List<Object?> get props => [id, sourceVideoId, sortOrder, name, startMs, endMs, status, progress, outputPath, completedAt, errorMessage, updatedAt];

  SplitSegment copyWith({
    int? id, int? sourceVideoId, int? sortOrder, String? name, int? startMs, Object? endMs = _sentinel,
    TaskStatus? status, int? progress, Object? outputPath = _sentinel, Object? completedAt = _sentinel,
    Object? errorMessage = _sentinel, int? updatedAt,
  }) => SplitSegment(
    id: id ?? this.id, sourceVideoId: sourceVideoId ?? this.sourceVideoId, sortOrder: sortOrder ?? this.sortOrder,
    name: name ?? this.name, startMs: startMs ?? this.startMs,
    endMs: endMs == _sentinel ? this.endMs : endMs as int?,
    status: status ?? this.status, progress: progress ?? this.progress,
    outputPath: outputPath == _sentinel ? this.outputPath : outputPath as String?,
    completedAt: completedAt == _sentinel ? this.completedAt : completedAt as int?,
    errorMessage: errorMessage == _sentinel ? this.errorMessage : errorMessage as String?,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  static const _sentinel = Object();
}
```

- [ ] **Step 3: 写 `split_segment_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/export_task.dart';

void main() {
  test('isComplete 仅当 endMs 大于 startMs', () {
    final base = SplitSegment(id: 1, sourceVideoId: 1, sortOrder: 1, name: 'a', startMs: 0, endMs: 1000, status: TaskStatus.pending, updatedAt: 0);
    expect(base.isComplete, true);
    expect(base.copyWith(endMs: null).isComplete, false);
    expect(base.copyWith(endMs: 0).isComplete, false);
  });
  test('copyWith 可清空可空字段', () {
    final s = SplitSegment(id: 1, sourceVideoId: 1, sortOrder: 1, name: 'a', startMs: 0, endMs: 1000, status: TaskStatus.pending, outputPath: '/x', updatedAt: 0);
    expect(s.copyWith(endMs: null).endMs, isNull);
    expect(s.copyWith(errorMessage: 'err').errorMessage, 'err');
  });
}
```

- [ ] **Step 4: 修改 `app_database.dart` — 加表与列**

在 `VideoItems` 表类内末尾加:
```dart
  TextColumn get source => text().withDefault(const Constant('clip'))();
```

新增表类(放在其它表类同级):
```dart
class SplitSegments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceVideoId => integer()();
  IntColumn get sortOrder => integer()();
  TextColumn get name => text()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  TextColumn get outputPath => text().nullable()();
  IntColumn get completedAt => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get updatedAt => integer()();
}
```

`@DriftDatabase` 注解 `tables:` 列表追加 `SplitSegments`;`schemaVersion` 改为 `3`;在 `indexes` getter 追加:
```dart
      Index('idx_split_segments_video', 'CREATE INDEX idx_split_segments_video ON split_segments (source_video_id)'),
```
`migration.onUpgrade` 追加:
```dart
      if (from < 3) {
        await m.addColumn(videoItems, videoItems.source);
        await m.createTable(splitSegments);
        await m.customStatement('CREATE INDEX idx_split_segments_video ON split_segments (source_video_id)');
      }
```

- [ ] **Step 5: 修改 `video_item.dart` — 加 source 字段**

在字段列表加 `final VideoSource source;`,构造函数加 `this.source = VideoSource.clip`,props 列表加 `source`,import `video_source.dart`。

- [ ] **Step 6: build_runner 重新生成**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: 成功生成 `app_database.g.dart`,无错误。

- [ ] **Step 7: 运行测试与静态分析**

Run: `flutter test test/core/model/split_segment_test.dart` → PASS
Run: `dart analyze` → no issues
Run: `flutter analyze` → no issues

- [ ] **Step 8: Commit**

```bash
git add lib/core/model/video_source.dart lib/core/model/split_segment.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart lib/core/model/video_item.dart test/core/model/split_segment_test.dart
git commit -m "添加视频分割数据模型与数据库表"
```

---

## Task 2: Repository 层

**Files:**
- Create: `lib/core/repository/split_repository.dart`
- Modify: `lib/core/repository/video_repository.dart`
- Test: `test/core/repository/split_repository_test.dart`

**Interfaces:**
- Consumes: `SplitSegment`、`TaskStatus`、全局 `database`(`AppDatabase`)。
- Produces: `SplitRepository.{insertSegment, updateSegment, deleteSegment, getSegmentsByVideo, deleteByVideo, getDoneCountByVideo}`;`VideoRepository.{getVideosBySource(VideoSource)}`;`getUnconfiguredVideos` 改为仅 `clip`;`deleteVideo` 级联删段。

- [ ] **Step 1: 写 `split_repository.dart`**

```dart
import 'package:cutflow/core/database/app_database.dart';
import 'package:cutflow/core/model/export_task.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:drift/drift.dart';

class SplitRepository {
  final AppDatabase _db;
  SplitRepository(this._db);

  Future<int> insertSegment(SplitSegment s) =>
      _db.into(_db.splitSegments).row(SplitSegmentsCompanion.insert(
            sourceVideoId: s.sourceVideoId,
            sortOrder: s.sortOrder,
            name: s.name,
            startMs: s.startMs,
            endMs: Value(s.endMs),
            status: s.status.name.toUpperCase(),
            progress: Value(s.progress),
            outputPath: Value(s.outputPath),
            completedAt: Value(s.completedAt),
            errorMessage: Value(s.errorMessage),
            updatedAt: s.updatedAt,
          ));

  Future<void> updateSegment(SplitSegment s) =>
      _db.update(_db.splitSegments).replace(SplitSegmentsCompanion(
            id: Value(s.id), sourceVideoId: Value(s.sourceVideoId), sortOrder: Value(s.sortOrder),
            name: Value(s.name), startMs: Value(s.startMs), endMs: Value(s.endMs),
            status: Value(s.status.name.toUpperCase()), progress: Value(s.progress),
            outputPath: Value(s.outputPath), completedAt: Value(s.completedAt),
            errorMessage: Value(s.errorMessage), updatedAt: Value(s.updatedAt),
          ));

  Future<void> deleteSegment(int id) =>
      (_db.delete(_db.splitSegments)..where((t) => t.id.equals(id))).go();

  Future<List<SplitSegment>> getSegmentsByVideo(int videoId) async {
    final rows = await (_db.select(_db.splitSegments)
          ..where((t) => t.sourceVideoId.equals(videoId))
          ..orderBy([(t) => OrderingTerm(expression: t.startMs)]))
        .get();
    return rows.map(_toModel).toList();
  }

  Future<void> deleteByVideo(int videoId) async {
    final segs = await getSegmentsByVideo(videoId);
    await (_db.delete(_db.splitSegments)..where((t) => t.sourceVideoId.equals(videoId))).go();
    // 已生成产物文件由调用方(SplitRepository.clearOutputsByVideo)清理
    for (final s in segs) {
      // 占位:文件清理在 Service 层做(需要文件 IO 与导出目录)
    }
  }

  Future<int> getDoneCountByVideo(int videoId) async {
    final cnt = await (_db.selectOnly(_db.splitSegments)
          ..addColumns([_db.splitSegments.id.count()])
          ..where(_db.splitSegments.sourceVideoId.equals(videoId) &
              _db.splitSegments.status.equals('DONE')))
        .map((row) => row.read(_db.splitSegments.id.count()) ?? 0)
        .getSingle();
    return cnt;
  }

  SplitSegment _toModel(SplitSegmentData r) => SplitSegment(
        id: r.id, sourceVideoId: r.sourceVideoId, sortOrder: r.sortOrder, name: r.name,
        startMs: r.startMs, endMs: r.endMs, status: TaskStatus.values.firstWhere(
            (e) => e.name.toUpperCase() == r.status, orElse: () => TaskStatus.pending),
        progress: r.progress, outputPath: r.outputPath, completedAt: r.completedAt,
        errorMessage: r.errorMessage, updatedAt: r.updatedAt,
      );
}
```

> 注:文件清理(删已转码产物)放在 `SplitService` 中,因为需要导出目录上下文;`deleteByVideo` 仅清 DB 行。

- [ ] **Step 2: 修改 `video_repository.dart`**

新增方法:
```dart
Future<List<VideoItem>> getVideosBySource(VideoSource source) async {
  final rows = await (_db.select(_db.videoItems)
        ..where((t) => t.source.equals(source.name))
        ..orderBy([(t) => OrderingTerm(desc: true, expression: t.importedAt)]))
      .get();
  return rows.map(_toModel).toList();
}
```
将现有 `getUnconfiguredVideos()` 主体改为:先 `getVideosBySource(VideoSource.clip)`,再叠加「无 ExportTask」过滤(保持原过滤逻辑,但源限定 `clip`)。`importVideo` 时确保写入 `source` 字段(签名增加可选参数 `VideoSource source = VideoSource.clip`,或新增 `importVideoAs`)。`deleteVideo` 内追加 `await (_db.delete(_db.splitSegments)..where((t)=>t.sourceVideoId.equals(id))).go();` 做级联删段(产物文件清理由调用方/Service 处理)。import `video_source.dart`、`splitSegments`。

- [ ] **Step 3: 写 `split_repository_test.dart`**

```dart
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow/core/database/app_database.dart';
import 'package:cutflow/core/repository/split_repository.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/export_task.dart';

void main() {
  late AppDatabase db;
  late SplitRepository repo;
  setUp(() { db = AppDatabase.forTesting(NativeDatabase.memory()); repo = SplitRepository(db); });
  tearDown(() => db.close());

  Future<int> seedVideo() => db.into(db.videoItems).insert(VideoItemsCompanion.insert(
        path: '/v.mp4', name: 'v', duration: 10000, width: 1920, height: 1080,
        fileSize: 1, frameRate: 30.0, codec: 'h264', importedAt: 1, source: const Value('clip')));

  test('增删改查与按视频聚合', () async {
    final vid = await seedVideo();
    final id = await repo.insertSegment(SplitSegment(
        id: 0, sourceVideoId: vid, sortOrder: 1, name: 'v_1', startMs: 0, endMs: 1000,
        status: TaskStatus.pending, updatedAt: 1));
    expect((await repo.getSegmentsByVideo(vid)).length, 1);
    await repo.updateSegment((await repo.getSegmentsByVideo(vid)).first.copyWith(name: 'renamed'));
    expect((await repo.getSegmentsByVideo(vid)).first.name, 'renamed');
    await repo.deleteSegment(id);
    expect((await repo.getSegmentsByVideo(vid)), isEmpty);
  });
}
```

> `AppDatabase.forTesting` 若不存在,在 `app_database.dart` 增加命名构造 `AppDatabase.forTesting(QueryExecutor e) : super(e)`(若已有 `AppDatabase(QueryExecutor)` 可直接用)。

- [ ] **Step 4: 运行测试与分析**

Run: `flutter test test/core/repository/split_repository_test.dart` → PASS
Run: `dart analyze`、`flutter analyze` → no issues

- [ ] **Step 5: Commit**

```bash
git add lib/core/repository/split_repository.dart lib/core/repository/video_repository.dart test/core/repository/split_repository_test.dart
git commit -m "添加分割仓库层并隔离裁剪视频来源"
```

---

## Task 3: 交互状态机纯逻辑(Mark In / Mark Out)

**Files:**
- Create: `lib/features/split/logic/split_state_machine.dart`
- Test: `test/features/split/logic/split_state_machine_test.dart`

**Interfaces:**
- Produces: `SplitSegmentDraft`(`id:String`、`startMs:int`、`endMs:int?`);`SplitEditorState`(`segments:List<SplitSegmentDraft>`、`focusedSegmentId:String?`);纯函数 `markIn(state, positionMs, generateId)`、`markOut(state, positionMs)`。

- [ ] **Step 1: 写 `split_state_machine.dart`**

```dart
import 'package:equatable/equatable.dart';

/// cut 弹窗内存中的段草稿(endMs 为 null = 定义中)。
class SplitSegmentDraft extends Equatable {
  final String id;
  final int startMs;
  final int? endMs;
  const SplitSegmentDraft({required this.id, required this.startMs, this.endMs});
  bool get isComplete => endMs != null && endMs! > startMs;
  SplitSegmentDraft copyWith({int? startMs, int? endMs, bool clearEnd = false}) =>
      SplitSegmentDraft(id: id, startMs: startMs ?? this.startMs, endMs: clearEnd ? null : (endMs ?? this.endMs));
  @override
  List<Object?> get props => [id, startMs, endMs];
}

/// 状态机的输入/输出快照。currentPositionMs 不在状态内,由调用方按操作传入。
class SplitEditorState extends Equatable {
  final List<SplitSegmentDraft> segments;
  final String? focusedSegmentId;
  const SplitEditorState({this.segments = const [], this.focusedSegmentId});
  SplitSegmentDraft? get focused =>
      segments.isEmpty == false ? segments.firstWhere((s) => s.id == focusedSegmentId, orElse: () => segments.last) : null;
  @override
  List<Object?> get props => [segments, focusedSegmentId];
}

/// 「设起点」:按焦点段状态与位置 P 分支(详见 spec §4.2)。
SplitEditorState markIn(SplitEditorState state, int positionMs, {required String Function() generateId}) {
  final list = state.segments.toList();
  final fid = state.focusedSegmentId;
  final idx = list.indexWhere((s) => s.id == fid);
  if (idx == -1) {
    final n = SplitSegmentDraft(id: generateId(), startMs: positionMs);
    return SplitEditorState(segments: [...list, n], focusedSegmentId: n.id);
  }
  final seg = list[idx];
  if (seg.endMs == null) {
    list[idx] = seg.copyWith(startMs: positionMs);
    return SplitEditorState(segments: list, focusedSegmentId: fid);
  }
  // 已完成段
  final inside = positionMs > seg.startMs && positionMs < seg.endMs!;
  if (inside) {
    list[idx] = seg.copyWith(startMs: positionMs); // 区间内:缩起点
    return SplitEditorState(segments: list, focusedSegmentId: fid);
  }
  final n = SplitSegmentDraft(id: generateId(), startMs: positionMs); // 段外:开新段
  return SplitEditorState(segments: [...list, n], focusedSegmentId: n.id);
}

/// 「设出点」:作用于焦点段(详见 spec §4.3)。
SplitEditorState markOut(SplitEditorState state, int positionMs) {
  final list = state.segments.toList();
  final fid = state.focusedSegmentId;
  final idx = list.indexWhere((s) => s.id == fid);
  if (idx == -1) return state; // 无焦点:忽略
  final seg = list[idx];
  if (seg.endMs == null) {
    if (positionMs > seg.startMs) {
      list[idx] = seg.copyWith(endMs: positionMs);
    } else {
      list[idx] = seg.copyWith(startMs: positionMs); // 出点不可用,起点拉到 P
    }
    return SplitEditorState(segments: list, focusedSegmentId: fid);
  }
  // 已完成段
  if (positionMs < seg.startMs) {
    list[idx] = seg.copyWith(startMs: positionMs);
  } else if (positionMs <= seg.endMs!) {
    list[idx] = seg.copyWith(endMs: positionMs); // 区间内:缩终点
  } else {
    list[idx] = seg.copyWith(endMs: positionMs); // 晚于出点:扩终点
  }
  return SplitEditorState(segments: list, focusedSegmentId: fid);
}
```

- [ ] **Step 2: 写完整单测 `split_state_machine_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow/features/split/logic/split_state_machine.dart';

void main() {
  int counter = 0;
  String gen() => 's${counter++}';
  setUp(() => counter = 0);

  test('无焦点 markIn 新建段并聚焦', () {
    final s = markIn(const SplitEditorState(), 100, generateId: gen);
    expect(s.segments.single.startMs, 100);
    expect(s.segments.single.endMs, isNull);
    expect(s.focusedSegmentId, s.segments.single.id);
  });

  test('定义中段 markIn 更新起点', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markIn(s, 50, generateId: gen);
    expect(s.segments.single.startMs, 50);
    expect(s.segments.single.endMs, isNull);
  });

  test('定义中段 markOut P>start 完成段', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markOut(s, 500);
    expect(s.segments.single.endMs, 500);
    expect(s.segments.single.isComplete, true);
  });

  test('定义中段 markOut P<=start 把起点拉到 P', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markOut(s, 30);
    expect(s.segments.single.startMs, 30);
    expect(s.segments.single.endMs, isNull);
  });

  test('无焦点 markOut 忽略', () {
    final s = markOut(const SplitEditorState(), 500);
    expect(s.segments, isEmpty);
  });

  test('已完成段 markIn 区间内缩起点', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markOut(s, 500);
    s = markIn(s, 300, generateId: gen);
    expect(s.segments.single.startMs, 300);
    expect(s.segments.single.endMs, 500);
    expect(s.segments.length, 1);
  });

  test('已完成段 markIn 段外开新段并转移焦点', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markOut(s, 500);
    s = markIn(s, 800, generateId: gen);
    expect(s.segments.length, 2);
    expect(s.focusedSegmentId, s.segments.last.id);
    expect(s.segments.last.startMs, 800);
  });

  test('已完成段 markOut 区间内缩终点', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markOut(s, 500);
    s = markOut(s, 300);
    expect(s.segments.single.endMs, 300);
  });

  test('已完成段 markOut 晚于出点扩终点', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markOut(s, 500);
    s = markOut(s, 900);
    expect(s.segments.single.endMs, 900);
  });

  test('已完成段 markOut 早于起点左扩起点', () {
    var s = markIn(const SplitEditorState(), 100, generateId: gen);
    s = markOut(s, 500);
    s = markOut(s, 20);
    expect(s.segments.single.startMs, 20);
  });

  test('焦点 B、位置落在 A 区间内,操作只动 B(允许重合)', () {
    var s = markIn(const SplitEditorState(), 0, generateId: gen);   // A: 0..100
    s = markOut(s, 100);
    s = markIn(s, 200, generateId: gen);                            // B: 200..(定义中)
    s = markOut(s, 50);                                              // P=50 在 A 内,但焦点是 B
    final b = s.segments.firstWhere((g) => g.startMs == 200);
    expect(b.startMs, 50);                                          // B 起点被拉到 50,与 A 重合,不报错
  });
}
```

- [ ] **Step 3: 运行测试**

Run: `flutter test test/features/split/logic/split_state_machine_test.dart` → PASS(全部)

- [ ] **Step 4: Commit**

```bash
git add lib/features/split/logic/split_state_machine.dart test/features/split/logic/split_state_machine_test.dart
git commit -m "添加分割交互状态机纯逻辑与单测"
```

---

## Task 4: 命名与排序逻辑

**Files:**
- Create: `lib/features/split/logic/segment_namer.dart`
- Test: `test/features/split/logic/segment_namer_test.dart`

**Interfaces:**
- Produces: `sourceNameOf(fileName)` 去扩展名;`assignSortOrders(List<({int id,int startMs})>) → Map<int,int>`(按 startMs 升序得 1-based 序号);`defaultSegmentName(sourceName, sortOrder)`;`batchRename(segments, sourceName)`。

- [ ] **Step 1: 写 `segment_namer.dart`**

```dart
final _extRe = RegExp(r'\.[^.]+$');

/// 源名 = 文件名去扩展名。
String sourceNameOf(String fileName) => fileName.replaceAll(_extRe, '');

/// 按 startMs 升序,返回 id -> 1-based 序号。
Map<int, int> assignSortOrders(List<({int id, int startMs})> segments) {
  final sorted = [...segments]..sort((a, b) => a.startMs.compareTo(b.startMs));
  final out = <int, int>{};
  for (var i = 0; i < sorted.length; i++) {
    out[sorted[i].id] = i + 1;
  }
  return out;
}

String defaultSegmentName(String sourceName, int sortOrder) => '${sourceName}_$sortOrder';

/// 批量命名:所有段重置为 `源名_序号`(序号按 startMs 排序后重算)。
/// 返回 id -> 新 name。
Map<int, String> batchRename(List<({int id, int startMs})> segments, String sourceName) {
  final orders = assignSortOrders(segments);
  return {for (final e in segments) e.id: defaultSegmentName(sourceName, orders[e.id]!)};
}
```

- [ ] **Step 2: 写单测 `segment_namer_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow/features/split/logic/segment_namer.dart';

void main() {
  test('sourceNameOf 去扩展名', () {
    expect(sourceNameOf('meeting.mp4'), 'meeting');
    expect(sourceNameOf('a.b.c.mov'), 'a.b.c');
  });
  test('assignSortOrders 按 startMs 升序 1-based', () {
    final m = assignSortOrders([
      (id: 10, startMs: 500),
      (id: 20, startMs: 100),
      (id: 30, startMs: 300),
    ]);
    expect(m[20], 1);
    expect(m[30], 2);
    expect(m[10], 3);
  });
  test('batchRename 重算序号', () {
    final m = batchRename([
      (id: 10, startMs: 500),
      (id: 20, startMs: 100),
    ], 'vid');
    expect(m[20], 'vid_1');
    expect(m[10], 'vid_2');
  });
}
```

- [ ] **Step 3: 运行测试并提交**

Run: `flutter test test/features/split/logic/segment_namer_test.dart` → PASS
```bash
git add lib/features/split/logic/segment_namer.dart test/features/split/logic/segment_namer_test.dart
git commit -m "添加分段命名与排序逻辑"
```

## Task 5: SplitService(串行转码引擎)

**Files:**
- Create: `lib/core/services/split_service.dart`
- Test: `test/core/services/split_service_test.dart`

**Interfaces:**
- Consumes: `SplitRepository`、`VideoRepository`、`AppSettingsRepository`、`FfmpegEngine`、`FfmpegCommandBuilder.buildTrimOnly`、`p.join`。
- Produces: `SplitService.{enqueueSegment, enqueueAll, pauseProcessing, cancel, progressStream, segmentsChangedStream}`、`SplitWorkerState`、`SplitProgressEvent`、静态 `selectEnqueueable(List<SplitSegment>) → List<int>`、静态 `notifySegmentsChanged()`。

- [ ] **Step 1: 写 `split_service.dart`**

```dart
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:cutflow/core/ffmpeg/command_builder.dart';
import 'package:cutflow/core/ffmpeg/ffmpeg_engine.dart';
import 'package:cutflow/core/model/export_task.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/repository/app_settings_repository.dart';
import 'package:cutflow/core/repository/split_repository.dart';
import 'package:cutflow/core/repository/video_repository.dart';
import 'package:path/path.dart' as p;

enum SplitWorkerState { idle, running, paused }

class SplitProgressEvent {
  final int segmentId;
  final int progress;
  final String? error;
  const SplitProgressEvent(this.segmentId, this.progress, {this.error});
}

class SplitService {
  final SplitRepository _repo;
  final VideoRepository _videoRepo;
  final AppSettingsRepository _settingsRepo;
  final FfmpegEngine _engine;

  SplitService(this._repo, this._videoRepo, this._settingsRepo, this._engine);

  final _progress = StreamController<SplitProgressEvent>.broadcast();
  final _changed = StreamController<void>.broadcast();
  static final _staticChanged = StreamController<void>.broadcast();

  Stream<SplitProgressEvent> get progressStream => _progress.stream;
  Stream<void> get segmentsChangedStream => _changed.stream;
  static Stream<void> get staticChangedStream => _staticChanged.stream;
  static void notifySegmentsChanged() => _staticChanged.add(null);

  SplitWorkerState _state = SplitWorkerState.idle;
  bool _pauseRequested = false;
  bool _cancelRequested = false;
  final Queue<int> _queue = Queue<int>();

  /// 纯逻辑:从全部段中筛选可转码的(end!=null 且 pending/failed)。
  static List<int> selectEnqueueable(List<SplitSegment> all) => [
        for (final s in all)
          if (s.endMs != null && (s.status == TaskStatus.pending || s.status == TaskStatus.failed)) s.id,
      ];

  Future<List<int>> enqueueSegment(int id) async {
    _queue.add(id);
    _kick();
    return [id];
  }

  Future<List<int>> enqueueAll(int videoId) async {
    final all = await _repo.getSegmentsByVideo(videoId);
    final ids = selectEnqueueable(all);
    for (final id in ids) {
      _queue.add(id);
    }
    _kick();
    return ids;
  }

  void pauseProcessing() => _pauseRequested = true;
  void cancel() {
    _cancelRequested = true;
    _engine.cancel();
  }

  void _kick() {
    if (_state == SplitWorkerState.idle) {
      _processLoop();
    }
  }

  Future<void> _processLoop() async {
    _state = SplitWorkerState.running;
    _pauseRequested = false;
    _cancelRequested = false;
    while (_state == SplitWorkerState.running && _queue.isNotEmpty) {
      if (_pauseRequested) {
        _state = SplitWorkerState.paused;
        return;
      }
      final id = _queue.removeFirst();
      await _processSegment(id);
      _changed.add(null);
      if (_cancelRequested) {
        _state = SplitWorkerState.idle;
        _queue.clear();
        return;
      }
    }
    _state = SplitWorkerState.idle;
    notifySegmentsChanged();
  }

  Future<void> _processSegment(int id) async {
    final seg = (await _repo.getSegmentsByVideo(/* 需要视频id,见下 */ 0));
    // 直接按 id 读取更优:在 SplitRepository 增加 getById;此处用过滤实现
    // 见 Step 2 补充 SplitRepository.getById。
    await _runOne(id);
  }

  Future<void> _runOne(int id) async {
    final seg = await _repo.getById(id);
    if (seg == null || seg.endMs == null) return;
    final video = await _videoRepo.getVideoById(seg.sourceVideoId);
    if (video == null) {
      await _markFailed(id, '源视频不存在');
      return;
    }
    final dir = await _settingsRepo.getExportDirectory();
    if (dir == null) {
      await _markFailed(id, '未设置导出目录');
      return;
    }
    await Directory(dir).create(recursive: true);
    final output = _uniquePath(dir, seg.name);
    await _repo.updateSegment(seg.copyWith(status: TaskStatus.preparing, updatedAt: _now));
    final cmd = FfmpegCommandBuilder.buildTrimOnly(
        inputPath: video.path, outputPath: output, startMs: seg.startMs, endMs: seg.endMs!);
    await _repo.updateSegment(seg.copyWith(status: TaskStatus.exporting, outputPath: output, updatedAt: _now));
    try {
      await for (final prog in _engine.executeWithProgress(cmd, seg.endMs! - seg.startMs)) {
        await _repo.updateSegment(seg.copyWith(progress: prog.progress, updatedAt: _now));
        _progress.add(SplitProgressEvent(id, prog.progress));
      }
      await _repo.updateSegment(seg.copyWith(
          status: TaskStatus.done, progress: 100, completedAt: _now, errorMessage: null, updatedAt: _now));
      _progress.add(const SplitProgressEvent(id, 100));
    } catch (e) {
      await _markFailed(id, e.toString());
    }
  }

  Future<void> _markFailed(int id, String msg) async {
    final seg = await _repo.getById(id);
    if (seg != null) {
      await _repo.updateSegment(seg.copyWith(status: TaskStatus.failed, errorMessage: msg, updatedAt: _now));
    }
    _progress.add(SplitProgressEvent(id, 0, error: msg));
  }

  String _uniquePath(String dir, String name) {
    var path = p.join(dir, '$name.mp4');
    var i = 1;
    while (File(path).existsSync()) {
      path = p.join(dir, '${name}_$i.mp4');
      i++;
    }
    return path;
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;
}
```

- [ ] **Step 2: 补充 `SplitRepository.getById`**

在 `SplitRepository` 增加:
```dart
Future<SplitSegment?> getById(int id) async {
  final r = await (_db.select(_db.splitSegments)..where((t) => t.id.equals(id))).getSingleOrNull();
  return r == null ? null : _toModel(r);
}
```
并把 `_processSegment` 简化为直接 `await _runOne(id);`(删去无效占位查询)。

- [ ] **Step 3: 写 `split_service_test.dart`(纯逻辑部分)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow/core/services/split_service.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/export_task.dart';

SplitSegment _seg(int id, {int? end, TaskStatus status = TaskStatus.pending}) => SplitSegment(
    id: id, sourceVideoId: 1, sortOrder: 1, name: 'x', startMs: 0, endMs: end,
    status: status, updatedAt: 0);

void main() {
  test('selectEnqueueable 只选 end!=null 且 pending/failed', () {
    final all = [
      _seg(1, end: 100, status: TaskStatus.pending),
      _seg(2, end: 100, status: TaskStatus.done),
      _seg(3, end: null),                        // 定义中
      _seg(4, end: 100, status: TaskStatus.failed),
      _seg(5, end: 100, status: TaskStatus.exporting),
    ];
    expect(SplitService.selectEnqueueable(all), [1, 4]);
  });
}
```

> ffmpeg 实际执行依赖系统 ffmpeg,属集成行为,通过手动验证(Task 11)覆盖。

- [ ] **Step 4: 运行测试与分析**

Run: `flutter test test/core/services/split_service_test.dart` → PASS
Run: `dart analyze`、`flutter analyze` → no issues

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/split_service.dart lib/core/repository/split_repository.dart test/core/services/split_service_test.dart
git commit -m "添加分割转码服务"
```

---

## Task 6: SplitCutViewModel(cut 弹窗状态)

**Files:**
- Create: `lib/features/split/split_cut_viewmodel.dart`
- Test: `test/features/split/split_cut_viewmodel_test.dart`

**Interfaces:**
- Consumes: 状态机 `markIn/markOut`、`segment_namer`、`SplitRepository`、`VideoRepository`。
- Produces: `splitCutProvider(videoId)`(autoDispose family);`SplitCutState{video, segments:List<SplitSegment>, focusedSegmentId, currentPositionMs, sourceName, hasDoneSegments, isLoading}`;方法 `initialize`、`confirmResetDone`、`applyMarkIn`、`applyMarkOut`、`focusSegment`、`renameSegment`、`deleteSegment`、`applyBatchRename`、`setCurrentPosition`。

- [ ] **Step 1: 写 `split_cut_viewmodel.dart`**

```dart
import 'dart:async';
import 'package:cutflow/core/model/export_task.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/video_item.dart';
import 'package:cutflow/core/repository/split_repository.dart';
import 'package:cutflow/core/repository/video_repository.dart';
import 'package:cutflow/features/split/logic/segment_namer.dart';
import 'package:cutflow/features/split/logic/split_state_machine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitCutState {
  final VideoItem? video;
  final List<SplitSegment> segments;
  final String? focusedSegmentId;
  final int currentPositionMs;
  final String sourceName;
  final bool hasDoneSegments;
  final bool isLoading;
  const SplitCutState({
    this.video,
    this.segments = const [],
    this.focusedSegmentId,
    this.currentPositionMs = 0,
    this.sourceName = '',
    this.hasDoneSegments = false,
    this.isLoading = true,
  });
  SplitCutState copyWith({
    VideoItem? video, List<SplitSegment>? segments, String? focusedSegmentId,
    int? currentPositionMs, String? sourceName, bool? hasDoneSegments, bool? isLoading,
  }) => SplitCutState(
    video: video ?? this.video, segments: segments ?? this.segments,
    focusedSegmentId: focusedSegmentId ?? this.focusedSegmentId,
    currentPositionMs: currentPositionMs ?? this.currentPositionMs,
    sourceName: sourceName ?? this.sourceName,
    hasDoneSegments: hasDoneSegments ?? this.hasDoneSegments,
    isLoading: isLoading ?? this.isLoading,
  );
}

class SplitCutViewModel extends StateNotifier<SplitCutState> {
  final int _videoId;
  final VideoRepository _videoRepo;
  final SplitRepository _splitRepo;
  Timer? _saveTimer;
  int _idCounter = 0;

  SplitCutViewModel(this._videoId, this._videoRepo, this._splitRepo) : super(const SplitCutState());

  Future<void> initialize() async {
    final video = await _videoRepo.getVideoById(_videoId);
    final segs = await _splitRepo.getSegmentsByVideo(_videoId);
    state = SplitCutState(
      video: video,
      segments: segs,
      focusedSegmentId: segs.isEmpty ? null : segs.last.id.toString(),
      currentPositionMs: segs.isNotEmpty ? segs.last.startMs : 0,
      sourceName: video == null ? '' : sourceNameOf(video.name),
      hasDoneSegments: segs.any((s) => s.status == TaskStatus.done),
      isLoading: false,
    );
  }

  /// 进入弹窗时,用户确认清除已转码结果。
  Future<void> confirmResetDone() async {
    for (final s in state.segments.where((s) => s.status == TaskStatus.done)) {
      // 删产物文件
      if (s.outputPath != null) {
        final f = io.File(s.outputPath!);
        if (await f.exists()) await f.delete();
      }
      await _splitRepo.updateSegment(s.copyWith(
          status: TaskStatus.pending, progress: 0, outputPath: null, completedAt: null, updatedAt: _now));
    }
    final fresh = await _splitRepo.getSegmentsByVideo(_videoId);
    state = state.copyWith(segments: fresh, hasDoneSegments: false);
  }

  void setCurrentPosition(int ms) => state = state.copyWith(currentPositionMs: ms);

  Future<void> applyMarkIn() async {
    final draft = _toEditorState();
    final next = markIn(draft, state.currentPositionMs, generateId: _genId);
    await _persistFromEditor(next);
  }

  Future<void> applyMarkOut() async {
    final draft = _toEditorState();
    final next = markOut(draft, state.currentPositionMs);
    await _persistFromEditor(next);
  }

  void focusSegment(String id) => state = state.copyWith(focusedSegmentId: id);

  Future<void> renameSegment(int id, String name) async {
    final segs = state.segments.map((s) => s.id == id ? s.copyWith(name: name, updatedAt: _now) : s).toList();
    state = state.copyWith(segments: segs);
    await _splitRepo.updateSegment(segs.firstWhere((s) => s.id == id));
    SplitService.notifySegmentsChanged();
  }

  Future<void> deleteSegment(int id) async {
    await _splitRepo.deleteSegment(id);
    final segs = state.segments.where((s) => s.id != id).toList();
    state = state.copyWith(segments: segs, focusedSegmentId: segs.isEmpty ? null : segs.last.id.toString());
  }

  Future<void> applyBatchRename() async {
    final tuples = [for (final s in state.segments) (id: s.id, startMs: s.startMs)];
    final names = batchRename(tuples, state.sourceName);
    final orders = assignSortOrders(tuples);
    final segs = state.segments.map((s) => s.copyWith(
        name: names[s.id]!, sortOrder: orders[s.id]!, updatedAt: _now)).toList();
    state = state.copyWith(segments: segs);
    _scheduleSave();
  }

  // --- 内部:状态机↔DB 同步 ---

  SplitEditorState _toEditorState() {
    final drafts = state.segments.map((s) => SplitSegmentDraft(id: s.id.toString(), startMs: s.startMs, endMs: s.endMs)).toList();
    return SplitEditorState(segments: drafts, focusedSegmentId: state.focusedSegmentId);
  }

  String _genId() {
    _idCounter += 1;
    return 'new_${_idCounter}';
  }

  Future<void> _persistFromEditor(SplitEditorState next) async {
    final drafts = next.segments;
    final existing = {for (final s in state.segments) s.id.toString(): s};
    final out = <SplitSegment>[];
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      final base = existing[d.id];
      final sortOrder = i + 1;
      if (base == null) {
        // 新段:插入
        final toInsert = SplitSegment(
            id: 0, sourceVideoId: _videoId, sortOrder: sortOrder,
            name: defaultSegmentName(state.sourceName, sortOrder),
            startMs: d.startMs, endMs: d.endMs, status: TaskStatus.pending, updatedAt: _now);
        final newId = await _splitRepo.insertSegment(toInsert);
        out.add(toInsert.copyWith(id: newId));
      } else {
        final updated = base.copyWith(startMs: d.startMs, endMs: d.endMs, sortOrder: sortOrder, updatedAt: _now);
        await _splitRepo.updateSegment(updated);
        out.add(updated);
      }
    }
    state = state.copyWith(segments: out, focusedSegmentId: next.focusedSegmentId);
    SplitService.notifySegmentsChanged();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      for (final s in state.segments) {
        await _splitRepo.updateSegment(s);
      }
      SplitService.notifySegmentsChanged();
    });
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

// 文件顶部需 import '../../main.dart'; 以引用全局 database(与 editorProvider 一致)
final splitCutProvider =
    StateNotifierProvider.autoDispose.family<SplitCutViewModel, SplitCutState, int>(
  (ref, videoId) => SplitCutViewModel(
    videoId,
    VideoRepository(database),
    SplitRepository(database),
  ),
);
```

> 注:`io.File` 需 `import 'dart:io' as io;`。`database` 的获取方式与现有 `editorProvider` 一致(通过 `ref.watch(databaseProvider)` 或全局 `database`,以现有代码为准)。

- [ ] **Step 2: 写 ViewModel 单测(状态机联动,用 fake repos)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow/core/model/export_task.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/video_item.dart';
// 用内存 fake 仓库替代 DB;或在测试中构造 in-memory AppDatabase
void main() {
  // 重点验证:applyMarkIn→applyMarkOut 形成一段;批量命名;rename 保留
  // 因 ViewModel 依赖 Repository,建议注入 in-memory AppDatabase 的真实 SplitRepository/VideoRepository
  // 复用 Task 2 的 AppDatabase.forTesting 模式。
  test('markIn 后 markOut 形成一段并落库', () async {
    // arrange: in-memory db, 插入 video
    // final vm = SplitCutViewModel(vid, VideoRepository(db), SplitRepository(db));
    // await vm.initialize();
    // vm.setCurrentPosition(100); await vm.applyMarkIn();
    // vm.setCurrentPosition(500); await vm.applyMarkOut();
    // expect(vm.state.segments.single.endMs, 500);
  });
}
```

> 因 ViewModel 与 DB 强耦合,该测试需 in-memory `AppDatabase`(Task 2 已具备)。实现时把注释替换为真实 arrange/act/assert,断言:① markIn+markOut 落库一段、endMs 正确;② `applyBatchRename` 后段名为 `源名_1`;③ `renameSegment` 后单段名被保留且其它段名不变。

- [ ] **Step 3: 运行测试与分析**

Run: `flutter test test/features/split/split_cut_viewmodel_test.dart` → PASS
Run: `dart analyze`、`flutter analyze` → no issues

- [ ] **Step 4: Commit**

```bash
git add lib/features/split/split_cut_viewmodel.dart test/features/split/split_cut_viewmodel_test.dart
git commit -m "添加分割编辑弹窗 ViewModel"
```

---

## Task 7: SplitTimeline(多段进度条)

**Files:**
- Create: `lib/features/split/widgets/split_timeline.dart`
- Modify: `lib/ui/theme/colors.dart`(加 `segmentPalette`)
- Test: `test/features/split/widgets/split_timeline_test.dart`

**Interfaces:**
- Consumes: `AppColors.segmentPalette`、`durationMs`、`currentPositionMs`、`List<({String id,int startMs,int? endMs,bool focused})> segments`。
- Produces: `SplitTimeline` Widget,回调 `onSeek(double ratio)`。

- [ ] **Step 1: `colors.dart` 加调色板**

```dart
/// 分割段配色(按段 index 循环)。不使用硬编码 0xFF,统一在此维护。
static const List<Color> segmentPalette = [
  Color(0xFF2563EB), // primary - 替换为 AppColors.primary 引用
  Color(0xFF16A34A), // success
  Color(0xFFEA580C), // orange
  Color(0xFF9333EA), // purple
  Color(0xFF0891B2), // cyan
  Color(0xFFDB2777), // pink
];
```
> 执行时把每个字面量替换为对现有 `AppColors` 常量的引用(如 `AppColors.primary`),保持「禁止硬编码 0xFF」;若现有色板无对应色,在 `AppColors` 中新增具名常量后再在此引用。

- [ ] **Step 2: 写 `split_timeline.dart`(复用 `_RangeSlider` 的 Stack 模式)**

```dart
import 'package:flutter/material.dart';
import 'package:cutflow/ui/theme/colors.dart';

class _SegView {
  final String id;
  final int startMs;
  final int? endMs;
  final bool focused;
  const _SegView({required this.id, required this.startMs, this.endMs, required this.focused});
}

class SplitTimeline extends StatelessWidget {
  final int durationMs;
  final int currentPositionMs;
  final List<_SegView> segments;
  final void Function(double ratio) onSeek;

  const SplitTimeline({
    super.key,
    required this.durationMs,
    required this.currentPositionMs,
    required this.segments,
    required this.onSeek,
  });

  Color _color(int index) {
    final palette = AppColors.segmentPalette;
    return palette[index % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      double ratio(int ms) => durationMs == 0 ? 0.0 : (ms / durationMs).clamp(0.0, 1.0);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => onSeek((d.localPosition.dx / w).clamp(0.0, 1.0)),
        onTapUp: (d) => onSeek((d.localPosition.dx / w).clamp(0.0, 1.0)),
        child: SizedBox(
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 轨道
              Positioned(
                left: 0, right: 0, top: 22,
                child: Container(height: 4, color: AppColors.outline),
              ),
              // 各段区间
              for (var i = 0; i < segments.length; i++)
                () {
                  final s = segments[i];
                  final col = _color(i);
                  final left = ratio(s.startMs) * w;
                  final rightEdge = s.endMs == null ? ratio(currentPositionMs) * w : ratio(s.endMs!) * w;
                  final def = s.endMs == null ? 0.35 : (s.focused ? 1.0 : 0.7);
                  return Positioned(
                    left: left,
                    top: 16,
                    width: (rightEdge - left).abs(),
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: def),
                        borderRadius: BorderRadius.circular(3),
                        border: s.focused ? Border.all(color: col, width: 2) : null,
                      ),
                    ),
                  );
                }(),
              // 当前位置游标
              Positioned(
                left: ratio(currentPositionMs) * w - 4,
                top: 12,
                child: Container(
                  width: 8, height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
```

> 段视图类型 `_SegView` 设为公开 `SplitSegmentView`(带 `id/startMs/endMs/focused`)以便测试与 ViewModel 构造,执行时改为 public 类。

- [ ] **Step 3: 写 widget 测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow/features/split/widgets/split_timeline.dart';

void main() {
  testWidgets('点击进度条触发 onSeek 比例回调', (tester) async {
    double? got;
    await tester.pumpWidget(MaterialApp(home: SizedBox(
      width: 400, height: 60,
      child: SplitTimeline(
        durationMs: 1000, currentPositionMs: 0,
        segments: const [], onSeek: (r) => got = r,
      ),
    )));
    await tester.tapAt(const Offset(200, 30));
    expect(got, closeTo(0.5, 0.05));
  });
}
```

- [ ] **Step 4: 运行测试与提交**

Run: `flutter test test/features/split/widgets/split_timeline_test.dart` → PASS
```bash
git add lib/features/split/widgets/split_timeline.dart lib/ui/theme/colors.dart test/features/split/widgets/split_timeline_test.dart
git commit -m "添加分割多段进度条"
```

## Task 8: SplitCutDialog(cut 弹窗)

**Files:**
- Create: `lib/features/split/widgets/split_cut_dialog.dart`

**Interfaces:**
- Consumes: `splitCutProvider(videoId)`、`VideoPreviewPanel`(复用 `features/editor/widgets/video_preview_panel.dart`)、`SplitTimeline`、`AppColors`。
- Produces: `SplitCutDialog.show(context, videoId) → Future<bool>`。

- [ ] **Step 1: 写 `split_cut_dialog.dart`**

```dart
import 'dart:async';
import 'package:cutflow/core/model/video_item.dart';
import 'package:cutflow/core/model/export_task.dart';
import 'package:cutflow/features/editor/widgets/video_preview_panel.dart';
import 'package:cutflow/features/split/split_cut_viewmodel.dart';
import 'package:cutflow/features/split/widgets/split_timeline.dart';
import 'package:cutflow/ui/theme/colors.dart';
import 'package:cutflow/core/util/time_formatter.dart'; // 复用现有时间格式化
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitCutDialog extends ConsumerStatefulWidget {
  final int videoId;
  const SplitCutDialog({super.key, required this.videoId});
  static Future<bool> show(BuildContext context, int videoId) => showDialog<bool>(
        context: context, barrierColor: Colors.black54,
        builder: (_) => SplitCutDialog(videoId: videoId),
      ).then((r) => r ?? false);
  @override
  ConsumerState<SplitCutDialog> createState() => _SplitCutDialogState();
}

class _SplitCutDialogState extends ConsumerState<SplitCutDialog> {
  final _previewKey = GlobalKey<VideoPreviewPanelState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final vm = ref.read(splitCutProvider(widget.videoId).notifier);
      await vm.initialize();
      if (!mounted) return;
      final st = ref.read(splitCutProvider(widget.videoId));
      if (st.hasDoneSegments && await _confirmReset()) {
        await vm.confirmResetDone();
      }
    });
  }

  void _onPosition(int ms) => ref.read(splitCutProvider(widget.videoId).notifier).setCurrentPosition(ms);

  Future<bool> _confirmReset() async => await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('检测到已转码分段'),
          content: const Text('继续编辑将使原转码结果失效。是否清除转码结果?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('保留')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('清除')),
          ],
        ),
      ) ?? false;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(splitCutProvider(widget.videoId));
    final vm = ref.read(splitCutProvider(widget.videoId).notifier);
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.outline)),
      child: SizedBox(
        width: screen.width * 0.8, height: screen.height * 0.8,
        child: st.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(children: [
                Expanded(flex: 3, child: _buildLeft(st, vm)),
                const VerticalDivider(width: 1),
                Expanded(flex: 1, child: _buildRight(st, vm)),
              ]),
      ),
    );
  }

  Widget _buildLeft(SplitCutState st, SplitCutViewModel vm) {
    final frameMs = (st.video == null || st.video!.frameRate == 0) ? 33 : (1000 / st.video!.frameRate).round();
    return Column(children: [
      Expanded(child: VideoPreviewPanel(video: st.video!, onPositionChanged: _onPosition, key: _previewKey)),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SplitTimeline(
            durationMs: st.video!.duration,
            currentPositionMs: st.currentPositionMs,
            segments: [for (var i = 0; i < st.segments.length; i++)
              SplitSegmentView(id: st.segments[i].id.toString(), startMs: st.segments[i].startMs,
                  endMs: st.segments[i].endMs, focused: st.segments[i].id.toString() == st.focusedSegmentId)],
            onSeek: (r) {
              final ms = (r * st.video!.duration).round();
              _previewKey.currentState?.seekTo(ms);
              vm.setCurrentPosition(ms);
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            FilledButton.icon(onPressed: vm.applyMarkIn, icon: const Icon(Iconsflag), label: const Text('设起点')),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: vm.applyMarkOut, icon: const Icon(Icons.flag_outlined), label: const Text('设出点')),
            const SizedBox(width: 8),
            IconButton(onPressed: () => _seekBy(vm, -frameMs), icon: const Icon(Icons.skip_previous)),
            IconButton(onPressed: () => _seekBy(vm, frameMs), icon: const Icon(Icons.skip_next)),
            const Spacer(),
            Text(formatMs(st.currentPositionMs)),
          ]),
        ]),
      ),
    ]);
  }

  void _seekBy(SplitCutViewModel vm, int delta) {
    final cur = _previewKey.currentState?.currentPositionMs ?? 0;
    final next = (cur + delta).clamp(0, ref.read(splitCutProvider(widget.videoId)).video!.duration);
    _previewKey.currentState?.seekTo(next);
    vm.setCurrentPosition(next);
  }

  Widget _buildRight(SplitCutState st, SplitCutViewModel vm) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Text('源名:${st.sourceName}', style: TextStyle(color: AppColors.textSecondary))),
          TextButton.icon(onPressed: vm.applyBatchRename, icon: const Icon(Icons.numbers), label: const Text('批量命名')),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView.builder(
          itemCount: st.segments.length,
          itemBuilder: (_, i) {
            final s = st.segments[i];
            final focused = s.id.toString() == st.focusedSegmentId;
            final color = AppColors.segmentPalette[i % AppColors.segmentPalette.length];
            return ListTile(
              tileColor: focused ? color.withValues(alpha: 0.12) : null,
              leading: CircleAvatar(backgroundColor: color, radius: 6),
              title: TextField(
                controller: TextEditingController(text: s.name),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                onSubmitted: (v) => vm.renameSegment(s.id, v),
              ),
              subtitle: Text('${formatMs(s.startMs)} → ${s.endMs == null ? '—' : formatMs(s.endMs!)}'),
              trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => vm.deleteSegment(s.id)),
              onTap: () => vm.focusSegment(s.id.toString()),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('完成')),
      ),
    ]);
  }
}
```

> `Iconsflag` 笔误,执行时用 `Icons.flag`;`formatMs` 用项目现有时间格式化(如 `time_formatter.dart` 的函数,以现有签名为准)。`VideoPreviewPanel` 的具名参数以现有定义为准。

- [ ] **Step 2: 分析与提交**

Run: `dart analyze`、`flutter analyze` → no issues
```bash
git add lib/features/split/widgets/split_cut_dialog.dart
git commit -m "添加分割 cut 弹窗"
```

---

## Task 9: SplitSegmentTile + SplitVideoCard

**Files:**
- Create: `lib/features/split/widgets/split_segment_tile.dart`
- Create: `lib/features/split/widgets/split_video_card.dart`

**Interfaces:**
- Consumes: `SplitSegment`、`splitServiceProvider`(`enqueueSegment`/`enqueueAll`)、`ExplorerService`、`SplitRepository`(刷新回调)。
- Produces: `SplitSegmentTile`、`SplitVideoCard`(含剪刀按钮、可展开子列表、全部转码按钮)。

- [ ] **Step 1: 写 `split_segment_tile.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/export_task.dart';
import 'package:cutflow/core/services/explorer_service.dart';
import 'package:cutflow/core/services/split_service.dart';
import 'package:cutflow/ui/theme/colors.dart';

class SplitSegmentTile extends ConsumerWidget {
  final SplitSegment segment;
  final int paletteIndex;
  final VoidCallback onChanged;
  const SplitSegmentTile({super.key, required this.segment, required this.paletteIndex, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.segmentPalette[paletteIndex % AppColors.segmentPalette.length];
    final canTranscode = segment.endMs != null &&
        (segment.status == TaskStatus.pending || segment.status == TaskStatus.failed);
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 5),
      title: Text(segment.name),
      subtitle: Text('${_statusText(segment.status)}${segment.status == TaskStatus.exporting ? " ${segment.progress}%" : ""}'),
      trailing: _trailing(context, ref, canTranscode),
    );
  }

  Widget _trailing(BuildContext context, WidgetRef ref, bool canTranscode) {
    if (segment.status == TaskStatus.done && segment.outputPath != null) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.folder_open), onPressed: () => ExplorerService.openFileLocation(segment.outputPath!)),
        IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => ExplorerService.playWithSystemPlayer(segment.outputPath!)),
      ]);
    }
    if (canTranscode) {
      return FilledButton.tonal(
        onPressed: () async {
          await ref.read(splitServiceProvider).enqueueSegment(segment.id);
          onChanged();
        },
        child: const Text('转码'),
      );
    }
    return const SizedBox.shrink();
  }

  String _statusText(TaskStatus s) => switch (s) {
    TaskStatus.pending => '待转码',
    TaskStatus.preparing => '准备中',
    TaskStatus.exporting => '转码中',
    TaskStatus.done => '已完成',
    TaskStatus.failed => '失败',
  };
}
```

- [ ] **Step 2: 写 `split_video_card.dart`(复用 PreparationVideoCard 结构 + 展开)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/video_item.dart';
import 'package:cutflow/core/repository/split_repository.dart';
import 'package:cutflow/core/services/split_service.dart';
import 'package:cutflow/features/split/widgets/split_cut_dialog.dart';
import 'package:cutflow/features/split/widgets/split_segment_tile.dart';
import 'package:cutflow/ui/theme/colors.dart';

class SplitVideoCard extends ConsumerStatefulWidget {
  final VideoItem video;
  final List<SplitSegment> segments;
  final VoidCallback onChanged;
  const SplitVideoCard({super.key, required this.video, required this.segments, required this.onChanged});
  @override
  ConsumerState<SplitVideoCard> createState() => _SplitVideoCardState();
}

class _SplitVideoCardState extends ConsumerState<SplitVideoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final done = widget.segments.where((s) => s.status == TaskStatus.done).length;
    return Card(
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: AppColors.outline),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width: 80, height: 60, color: AppColors.surfaceVariant, child: const Icon(Icons.video_file_outlined)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.video.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${widget.video.formattedDuration} · ${widget.video.resolution} · ${widget.video.formattedFileSize}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                if (widget.segments.isNotEmpty)
                  Text('${widget.segments.length} 段 · 已转码 $done',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ])),
              IconButton(
                icon: const Icon(Icons.content_cut),
                tooltip: '剪辑',
                onPressed: () async {
                  final ok = await SplitCutDialog.show(context, widget.video.id);
                  if (ok) widget.onChanged();
                },
              ),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textTertiary),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1),
          if (widget.segments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Align(alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    await ref.read(splitServiceProvider).enqueueAll(widget.video.id);
                    widget.onChanged();
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('全部转码'),
                )),
            ),
          for (var i = 0; i < widget.segments.length; i++)
            SplitSegmentTile(segment: widget.segments[i], paletteIndex: i, onChanged: widget.onChanged),
          if (widget.segments.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('暂无分段,点击剪刀按钮开始剪辑', textAlign: TextAlign.center)),
        ],
      ]),
    );
  }
}
```

> `TaskStatus` 与 `VideoItem.formattedDuration/resolution/formattedFileSize` 来自现有 model;`ExplorerService` 静态方法签名以现有定义为准。

- [ ] **Step 3: 分析与提交**

Run: `dart analyze`、`flutter analyze` → no issues
```bash
git add lib/features/split/widgets/split_segment_tile.dart lib/features/split/widgets/split_video_card.dart
git commit -m "添加分割视频卡片与段列表项"
```

---

## Task 10: SplitScreen(tab 页) + SplitViewModel + Provider 接线

**Files:**
- Create: `lib/features/split/split_viewmodel.dart`
- Modify: `lib/features/split/split_screen.dart`(替换占位页)

**Interfaces:**
- Consumes: `VideoRepository.getVideosBySource(VideoSource.split)`、`SplitRepository.getSegmentsByVideo`、`SplitService.staticChangedStream`、`FilePicker`、`MetadataExtractor`。
- Produces: `splitProvider`;`SplitViewModel.{loadVideos, importVideo}`;`SplitScreen`。

- [ ] **Step 1: 写 `split_viewmodel.dart`**

```dart
import 'dart:async';
import 'package:cutflow/core/ffmpeg/metadata_extractor.dart';
import 'package:cutflow/core/model/split_segment.dart';
import 'package:cutflow/core/model/video_item.dart';
import 'package:cutflow/core/model/video_source.dart';
import 'package:cutflow/core/repository/split_repository.dart';
import 'package:cutflow/core/repository/video_repository.dart';
import 'package:cutflow/core/services/split_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitState {
  final List<VideoItem> videos;
  final Map<int, List<SplitSegment>> segmentsByVideo;
  final bool isLoading;
  final String? error;
  const SplitState({this.videos = const [], this.segmentsByVideo = const {}, this.isLoading = true, this.error});
  SplitState copyWith({List<VideoItem>? videos, Map<int, List<SplitSegment>>? segmentsByVideo, bool? isLoading, String? error}) =>
    SplitState(videos: videos ?? this.videos, segmentsByVideo: segmentsByVideo ?? this.segmentsByVideo,
        isLoading: isLoading ?? this.isLoading, error: error);
}

class SplitViewModel extends StateNotifier<SplitState> {
  final VideoRepository _videoRepo;
  final SplitRepository _splitRepo;
  StreamSubscription? _sub;

  SplitViewModel(this._videoRepo, this._splitRepo) : super(const SplitState()) {
    _sub = SplitService.staticChangedStream.listen((_) => loadVideos());
  }

  Future<void> loadVideos() async {
    try {
      final videos = await _videoRepo.getVideosBySource(VideoSource.split);
      final byVideo = <int, List<SplitSegment>>{};
      for (final v in videos) {
        byVideo[v.id] = await _splitRepo.getSegmentsByVideo(v.id);
      }
      state = SplitState(videos: videos, segmentsByVideo: byVideo, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 导入视频到分割 tab(source=split)。字段映射与 preparation_viewmodel.importVideo 一致。
  Future<bool> importVideo(String filePath) async {
    try {
      final metadata = await MetadataExtractor.extractMetadata(filePath);
      if (metadata == null) {
        state = state.copyWith(error: '无法提取视频元数据');
        return false;
      }
      final video = VideoItem(
        id: 0,
        path: metadata.path,
        name: metadata.name,
        duration: metadata.duration,
        width: metadata.width,
        height: metadata.height,
        fileSize: metadata.fileSize,
        frameRate: metadata.frameRate,
        codec: metadata.codec,
        importedAt: DateTime.now().millisecondsSinceEpoch,
        source: VideoSource.split,
      );
      await _videoRepo.insertVideo(video);
      await loadVideos();
      return true;
    } catch (e) {
      state = state.copyWith(error: '导入视频失败: $e');
      return false;
    }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}

// 文件顶部需 import '../../main.dart'; 以引用全局 database(与 preparationProvider 一致)
final splitProvider = StateNotifierProvider<SplitViewModel, SplitState>(
  (ref) => SplitViewModel(VideoRepository(database), SplitRepository(database)),
);
```

> `MetadataExtractor.extractMetadata` 的返回结构与 `VideoItem` 必填字段以现有定义为准(沿用 `preparation_viewmodel.dart` 的 importVideo 写法)。

- [ ] **Step 2: 重写 `split_screen.dart`**

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cutflow/features/split/split_viewmodel.dart';
import 'package:cutflow/features/split/widgets/split_video_card.dart';
import 'package:cutflow/ui/theme/colors.dart';

class SplitScreen extends ConsumerStatefulWidget {
  const SplitScreen({super.key});
  @override
  ConsumerState<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends ConsumerState<SplitScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(splitProvider.notifier).loadVideos());
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: true);
    if (result == null) return;
    for (final f in result.files) {
      if (f.path != null) await ref.read(splitProvider.notifier).importVideo(f.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(splitProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频分割'),
        actions: [TextButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file), label: const Text('导入视频'))],
      ),
      body: _body(st),
    );
  }

  Widget _body(SplitState st) {
    if (st.isLoading) return const Center(child: CircularProgressIndicator());
    if (st.error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('加载失败:${st.error}'),
      TextButton(onPressed: () => ref.read(splitProvider.notifier).loadVideos(), child: const Text('重试')),
    ]));
    if (st.videos.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.call_split, size: 64, color: AppColors.textTertiary),
      const SizedBox(height: 12),
      Text('导入视频开始分割', style: TextStyle(color: AppColors.textTertiary)),
    ]));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: st.videos.length,
      itemBuilder: (_, i) {
        final v = st.videos[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SplitVideoCard(
            video: v,
            segments: st.segmentsByVideo[v.id] ?? const [],
            onChanged: () => ref.read(splitProvider.notifier).loadVideos(),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 3: 分析与提交**

Run: `dart analyze`、`flutter analyze` → no issues
```bash
git add lib/features/split/split_viewmodel.dart lib/features/split/split_screen.dart
git commit -m "实现视频分割 tab 列表与导入"
```

---

## Task 11: splitProvider/Service 接线、隔离回归与全量验证

**Files:**
- Modify: `lib/main.dart` 或现有 Provider 注册处(提供 `database` 给 `splitProvider`/`splitCutProvider`/`splitServiceProvider`,方式与 `editorProvider`/`preparationProvider` 一致)
- Modify: `lib/core/repository/video_repository.dart`(`getUnconfiguredVideos` 已在 Task 2 改为 clip 过滤,此处回归)

**Interfaces:** 接通三个 Provider 的依赖;完成全量编译与回归。

- [ ] **Step 1: 接线 Provider 依赖**

`splitProvider`(Task 10)、`splitCutProvider(videoId)`(Task 6)已用全局 `database` 声明。新增 `splitServiceProvider`,放在 `lib/core/services/split_service.dart` 末尾(import `'../../main.dart'` 及各依赖):

```dart
final splitServiceProvider = Provider<SplitService>((ref) => SplitService(
      SplitRepository(database),
      VideoRepository(database),
      AppSettingsRepository(database),
      FfmpegEngine(),
    ));
```

> `FfmpegEngine()` 为无参构造,沿用 `exportServiceProvider` 的写法。

- [ ] **Step 2: 隔离回归测试**

```dart
// test/core/repository/video_repository_test.dart (新增或追加)
test('getUnconfiguredVideos 仅返回 clip 来源', () async {
  // 插入 clip 视频 A、split 视频 B,均无 ExportTask
  final result = await repo.getUnconfiguredVideos();
  expect(result.map((v) => v.id), contains(A));
  expect(result.map((v) => v.id), isNot(contains(B)));
});
test('getVideosBySource(split) 仅返回 split 来源', () async {
  final result = await repo.getVideosBySource(VideoSource.split);
  expect(result.map((v) => v.id), contains(B));
  expect(result.map((v) => v.id), isNot(contains(A)));
});
```

- [ ] **Step 3: 运行全量测试与静态分析**

Run: `flutter test` → 全部 PASS
Run: `dart analyze` → no issues
Run: `flutter analyze` → no issues

- [ ] **Step 4: 构建**

Run: `flutter build windows --debug` → 成功

- [ ] **Step 5: 手动验证清单(在 app 内)**

- [ ] 裁剪 tab 准备列表仍正常显示 clip 视频(隔离未破坏)
- [ ] split tab 导入视频 → 出现在列表(仅 split)
- [ ] 点剪刀 → cut 弹窗:设起点→设出点形成一段;段外设起点开新段;区间内设起点缩起点
- [ ] 批量命名 → `源名_序号`;手动改名单段保留
- [ ] 完成 → 子列表出现分段 + 待转码状态
- [ ] 单段转码 / 全部转码 → 进度推进 → 已完成 → 打开位置/播放可用
- [ ] 已转码段再次进入 cut → 弹「清除转码结果」→ 清除后状态回到待转码
- [ ] 重叠段各自独立转码无异常

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart test/core/repository/video_repository_test.dart
git commit -m "接通分割 Provider 依赖并补充来源隔离回归测试"
```

---

## 自审备注

- **Spec 覆盖**:§1 架构(Task 1-10 全部模块)✓;§2 数据模型(Task 1)✓;§3 状态机(Task 3,含 10 组合单测)✓;§4 UI(Task 7-10)✓;§5 转码(Task 5)✓;§6 错误处理(Task 5 `_markFailed`/重名/`end≤start` 跳过)✓;§7 测试(Task 3/4/5/11 + 各 widget)✓;§9 风险(隔离回归 Task 11)✓。
- **类型一致性**:`SplitSegment`/`SplitSegmentDraft`/`SplitSegmentView` 三者字段(`startMs`/`endMs`/`focused`)跨任务命名一致;`TaskStatus` 全程复用;`markIn/markOut` 签名在 Task 3 定义、Task 6 消费,一致。
- **待执行时统一确认项**(非占位,是项目特定签名):`database` 注入方式、`VideoPreviewPanel`/`ExplorerService`/`MetadataExtractor` 具名参数、`time_formatter` 的函数名、`AppColors` 段色具名常量替换。
