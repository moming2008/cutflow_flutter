# 视频分割功能设计文档

**版本**: v2.0.0(视频分割)
**日期**: 2026-07-14
**状态**: 设计中（待确认）

---

## 概述

为「视频分割」tab(`/split`)落地完整功能:导入视频 → 在 cut 弹窗里把一个视频按时间戳切成多段 → 每段可批量命名(`源名_序号`)或单独改名 → 在 split tab 内自带转码(复用底层 FFmpeg),分段结果以可展开子列表挂在原视频下。

本设计严格遵循现有 MVVM 分层、Riverpod/GoRouter/Drift 技术栈与命名规范,最大化复用 `EditorDialog` 弹窗模式、`_RangeSlider` 进度条模式、`FfmpegCommandBuilder.buildTrimOnly` 命令与 `FfmpegEngine` 执行引擎。

---

## 一、需求决策汇总（已与用户确认）

| # | 决策点 | 结论 |
|---|--------|------|
| 1 | 画面裁切 | 仅时间分割,纯 `-c copy`,不裁切画面 |
| 2 | 视频来源隔离 | `VideoItem` 加 `source` 字段(`clip`/`split`),裁剪 tab 与分割 tab 完全隔离 |
| 3 | 转码归属 | split tab 自带 `SplitService`(复用 `FfmpegEngine`),不进裁剪的 `/queue` |
| 4 | 命名格式 | `源名_序号`,序号=段在时间轴上的顺序(1-based);支持批量命名 + 单独改名 |
| 5 | 段重叠 | 完全允许,无任何提示或阻止,各段独立转码 |
| 6 | 重置语义 | 再次进入 cut 编辑、且存在已转码段时,提示清除转码结果(删文件 + 状态重置为 PENDING,保留分段定义) |
| 7 | 进度条 | 纯进度条 + 多段标记(复用 `_RangeSlider` 的 Stack 模式),不做缩略图条 |
| 8 | 转码触发 | 每段单独转码 + 顶部「全部转码」,串行处理,支持暂停/取消 |
| 9 | 数据模型 | 方案 A 单表 `SplitSegment`:段行即持久化,按 `sourceVideoId` 聚合,无独立草稿表/项目表 |
| 10 | 设起点歧义 | 已完成焦点段上「设起点」用位置区分:P 在区间内 → 缩起点;P 在段外 → 开新段 |

---

## 二、架构总览

新增 `features/split/` 模块,分层与现有 `features/editor/`、`features/preparation/` 一致:

```
features/split/
├── split_screen.dart              # tab 页:AppBar 导入按钮 + 视频列表(可展开子分段列表)
├── split_viewmodel.dart           # 列表状态:source=split 的视频 + 各视频段聚合
├── split_cut_viewmodel.dart       # cut 弹窗状态:段列表/焦点段/当前位置
└── widgets/
    ├── split_video_card.dart      # 视频卡片(剪刀按钮 + 可展开子列表)
    ├── split_segment_tile.dart    # 单段行:名称/起止/转码状态/单独转码按钮
    ├── split_cut_dialog.dart      # cut 弹窗(照搬 EditorDialog 模式)
    └── split_timeline.dart        # 底部多段进度条(复用 _RangeSlider 的 Stack 模式)

core/
├── model/split_segment.dart       # SplitSegment (Equatable + copyWith)
├── model/video_source.dart        # enum VideoSource { clip, split }
├── database/app_database.dart     # +SplitSegments 表; VideoItems +source 列; schemaVersion 2→3
├── repository/split_repository.dart   # 段 CRUD + getSegmentsByVideo
└── services/split_service.dart    # 串行转码 + 进度广播(复用 FfmpegEngine + buildTrimOnly)
```

### 数据流

```
SplitScreen ─→ SplitViewModel ─→ VideoRepository(source=split) + SplitRepository
SplitCutDialog ─→ SplitCutViewModel ─→ SplitRepository + VideoRepository
SplitService ─→ SplitRepository + FfmpegEngine + FfmpegCommandBuilder + AppSettingsRepository
```

### Provider

- `splitProvider` → `StateNotifierProvider`(列表,非 autoDispose,全局单例)
- `splitCutProvider(videoId)` → `StateNotifierProvider.autoDispose.family`(弹窗,参数 videoId)
- `splitServiceProvider` → 注入 `SplitRepository` + `VideoRepository` + `AppSettingsRepository`

### 复用点

- **cut 弹窗**照搬 `EditorDialog`:`static show(context, videoId)` 返回 `Future<bool>`,Dialog 0.8×0.8,`GlobalKey<VideoPreviewPanelState>` 取播放器实例,位置回调 100ms 节流。
- **进度条**照搬 `_RangeSlider`:Stack + Positioned + GestureDetector,内部以毫秒整数存储,扩展为多段标记渲染。
- **裁剪命令**直接复用现成的 `FfmpegCommandBuilder.buildTrimOnly(input, output, startMs, endMs)`(已有,`-ss -i -t -c copy -avoid_negative_ts make_zero`)。

---

## 三、数据模型

### 3.1 VideoItems 表加列(migration 加列)

```
source  text  NOT NULL DEFAULT 'clip'    -- 'clip' | 'split'
```

- `VideoItem` model 增加 `final VideoSource source`,默认 `clip`。
- `VideoRepository` 新增 `getVideosBySource(VideoSource)`;裁剪列表继续用 `clip`,分割列表用 `split`,彻底隔离。
- 现有 `getUnconfiguredVideos()` 保持按 `clip` 过滤的语义(裁剪准备列表不受影响)。

### 3.2 新增 SplitSegments 表(方案 A 单表)

| 列 | 类型 | 说明 |
|---|---|---|
| id | integer PK autoIncrement | |
| sourceVideoId | integer NOT NULL | 关联 VideoItem.id(普通索引 `idx_split_segments_video`) |
| sortOrder | integer NOT NULL | 段在时间轴上的序号(= 命名后缀,1-based) |
| name | text NOT NULL | 段名,默认 `源名_序号` |
| startMs | integer NOT NULL | 起点(毫秒) |
| endMs | integer **nullable** | 终点(毫秒);**null = 定义中(只有起点),不参与转码** |
| status | text NOT NULL DEFAULT 'PENDING' | 复用 TaskStatus: PENDING/PREPARING/EXPORTING/DONE/FAILED |
| progress | integer NOT NULL DEFAULT 0 | 0–100 |
| outputPath | text nullable | 转码产物完整路径 |
| completedAt | integer nullable | 完成时间戳 |
| errorMessage | text nullable | 失败原因 |
| updatedAt | integer NOT NULL | 防抖自动保存时间戳 |

- `SplitSegment` model `extends Equatable`,带 `copyWith`,字段一一对应;`TaskStatus` 枚举直接复用现有 `export_task.dart` 中的定义。
- `endMs` 可空用于表达「正在定义、只有起点的段」,它会被持久化(关闭弹窗再开可恢复);转码与「全部转码」均跳过 `end==null` 的段。

### 3.3 数据库迁移

- `schemaVersion` 由 2 升到 3。
- `onUpgrade`:`if (from < 3)` 执行 `m.addColumn(VideoItems, VideoItems.source)`(默认 clip)+ `m.createTable(SplitSegments)` + 创建索引。
- 改完表定义后运行 `dart run build_runner build --delete-conflicting-outputs` 重新生成 `app_database.g.dart`。

### 3.4 路径与命名

- **源名** = 源视频文件名去掉扩展名(用 `RegExp(r'\.[^.]+$')` 替换为空,沿用 `EditorViewModel` 的 outputName 默认逻辑)。
- **段默认名** = `源名_序号`(序号 = `sortOrder`)。
- 导出路径:`p.join(exportDir, '${name}.mp4')`,重名自动加 `_1`/`_2`(沿用 ExportService 现有逻辑)。
- 导出目录复用 `AppSettings` 的 `exportDirectory`(`~/Documents/CutFlow/exports`)。

---

## 四、交互状态机(cut 弹窗核心)

### 4.1 实体

- `currentPositionMs`:进度条游标(= 播放器当前位置)。
- 段列表:每段 `{ id, startMs, endMs? }`,`endMs == null` 表示「定义中、只有起点」。
- `focusedSegmentId`:当前焦点段(可为空)。
- 两个操作按钮:**「设起点」(Mark In)** 与 **「设出点」(Mark Out)**,均作用于当前焦点段。

### 4.2 「设起点」(Mark In)@ 位置 P

| 焦点段状态 | 位置 P | 结果 |
|---|---|---|
| 无焦点段 | 任意 | 新建段 `{start:P, end:null}`,焦点→新段(新配色) |
| 定义中(end=null) | 任意 | 该段 `start←P`(移动起点) |
| 已完成(end≠null) | P 落在 **(start, end) 区间内** | 该段 `start←P`(区间内**缩起点**) |
| 已完成(end≠null) | P 落在段外(≤start 或 ≥end) | **新建段** `{start:P, end:null}`,焦点→新段,旧段失焦但保留 |

### 4.3 「设出点」(Mark Out)@ 位置 P,作用于焦点段

| 焦点段状态 | 位置 P | 结果 |
|---|---|---|
| 无焦点段 | 任意 | 忽略(提示「请先设起点」) |
| 定义中(end=null) | P > start | `end←P`,段完成 |
| 定义中(end=null) | P ≤ start | `start←P`(出点不可用,起点拉到 P) |
| 已完成(end≠null) | P < start | `start←P`(起点左扩) |
| 已完成(end≠null) | start ≤ P ≤ end | `end←P`(区间内**缩终点**) |
| 已完成(end≠null) | P > end | `end←P`(终点右扩) |

### 4.4 其它规则

- **点击右侧列表项** → 焦点切换到该项(对应需求「重新聚焦需点击右侧段落列表」)。
- **操作只动焦点段**:无论游标 P 落在哪个段的区间,Mark In/Out 只修改焦点段,因此可能与别的段重合(已确认:允许、无提示)。
- 完成一段后焦点仍留在该段(已完成态),所以段外下一次 Mark In 自然「开新段、旧段失焦、进入第二段」。
- 位置区分消歧(决策 10):P 在焦点段区间内 → Mark In 缩起点、Mark Out 缩终点(完整实现「缩小」);P 在段外 → Mark In 开新段。两条原始规则用位置区分,均成立。

### 4.5 段排序与命名联动

- 段在列表/进度条按 `startMs` 升序显示;`sortOrder` = 排序后的 1-based 序号 = 命名后缀。
- 调整某段起点导致顺序变化时,`sortOrder` 重新计算。
- 「批量命名」按钮:按当前 `sortOrder` 把所有段重置为 `源名_序号`;手动改名只改那一段的 `name`,不被批量命名之外的逻辑覆盖。

### 4.6 进度条多段渲染

```
0:00 ├─────[██段1██]────[████段2████]──[▮段3▮]──────────────┤ 12:34
                                ▲游标(当前位置)
     [已完成段:段色实心填充]   [定义中段(end=null):段色半透明+入点竖条]
     焦点段:边框加粗提亮;非焦点段:降低不透明度
```

- 复用 `_RangeSlider` 的 `LayoutBuilder` + `Stack` + `Positioned` + `GestureDetector`,游标拖动 = seek 播放器。
- **段配色**:在 `ui/theme/colors.dart` 新增 `segmentPalette`(`List<Color>`,不硬编码 `0xFF`),按段 index 循环取色;焦点段用 `withValues(alpha:)` 提亮 + 加边框。

---

## 五、UI 布局

### 5.1 SplitScreen(tab 页)

- AppBar:title「视频分割」+ 右上「导入视频」按钮(`FilePicker.pickFiles(type: video, allowMultiple: true)` → 循环调 `MetadataExtractor.extractMetadata` → 插入 `source = split` 的 VideoItem → 刷新列表)。
- body:视频列表(`ListView.builder`);空态提示「导入视频开始分割」。

### 5.2 SplitVideoCard(视频卡片)

- 复用 `PreparationVideoCard` 结构:缩略图 + 名称 + 属性行(时长/分辨率/文件大小)。
- 右侧:剪刀按钮 `Icons.content_cut`(`SplitCutDialog.show(context, video.id)`,返回 true 刷新列表)+ 删除按钮。
- 整卡可展开/收起,展开后显示子分段列表 + 摘要(如「3 段 · 已转码 1」);子列表顶部提供「全部转码」按钮(该视频所有 `end!=null` 且 `status∈{PENDING,FAILED}` 的段入队)与「暂停/取消」入口。

### 5.3 SplitSegmentTile(段行)

- 段色点 + 段名(点击进入行内编辑)+ `start→end` 时间码 + 转码状态徽章(待转码/转码中 N%/已完成/失败,颜色复用 `AppColors.success/error/primary`)。
- 待转码/失败段:显示「转码」按钮(单段转码)。
- 已完成段:显示「打开位置」「播放」(复用 `ExplorerService`)。

### 5.4 SplitCutDialog(cut 弹窗)

- 照搬 `EditorDialog`:`static show(context, videoId)` 返回 `Future<bool>`,Dialog `insetPadding: 24`,`elevation: 0`,圆角 12,`BorderSide(AppColors.outline)`,尺寸 `screenWidth*0.8 × screenHeight*0.8`。
- 布局 `Row(flex:3 左 | flex:1 右)`:

```
┌──────────────────────────────┬──────────────┐
│  VideoPreviewPanel(media_kit) │ 批量命名按钮   │
│                              │ 源名:xxx     │
├──────────────────────────────┤ 段列表(List)  │
│ SplitTimeline 多段进度条       │  ●段1 名▼ 起止 │
│ [设起点][设出点][◁帧][帧▷] 时间码│  ●段2(焦点高亮)│
└──────────────────────────────┴──────────────┘
```

- **进入时检测**:若该视频存在 `status == DONE` 的段 → 弹「检测到 N 个已转码分段,继续编辑将使其失效,是否清除转码结果?」。选「清除」→ 这些段删文件 + status→PENDING;选「保留」→ 照常加载(对应需求「已转码则提示重置」)。
- **段即时持久化**:编辑过程防抖(500ms)直接写 `SplitSegments` 表(无独立草稿表)。弹窗只有「完成」按钮(关闭 + 返回 true 刷新列表)。

### 5.5 SplitTimeline(进度条)

- 复用 `_RangeSlider` 的 `Stack`+`Positioned`+`GestureDetector`;游标拖动 seek 播放器。
- 下方控件:「设起点」「设出点」「逐帧向前/向后」(逐帧步长 = `(1000 / frameRate).round()`)+ 当前时间码。

---

## 六、转码流程(SplitService)

仿 `ExportService` 的状态机与进度广播,串行处理:

- `WorkerState { idle, running, paused }` 状态机。
- **单段转码** `enqueueSegment(int segmentId)` / **全部转码** `enqueueAll(int videoId)`(该视频所有 `end != null` 且 `status ∈ {PENDING, FAILED}` 的段入队)。
- **处理循环**(串行,每次取一个段):
  1. status → PREPARING
  2. 取源视频(`getVideoById`)、导出目录(`getExportDirectory`);缺失则 FAILED
  3. `p.join(exportDir, '${name}.mp4')`,重名加序号
  4. `FfmpegCommandBuilder.buildTrimOnly(input, output, startMs, endMs)`
  5. status → EXPORTING
  6. `FfmpegEngine.executeWithProgress(command, totalDurationMs = endMs - startMs)` → 按段更新 progress + 广播
  7. 成功:status → DONE / progress 100 / outputPath / completedAt
- **进度广播**:实例级 `StreamController<SplitProgressEvent>.broadcast()`(事件含 `segmentId`、`progress`、`error?`)+ 静态 `segmentsChangedStream`(列表刷新)。
- **暂停/取消**:`pauseProcessing()` / `cancel()` 杀当前 ffmpeg 进程。

---

## 七、错误处理与边界

- 源视频文件丢失 / 导出目录不可写 / ffmpeg 失败(exitCode≠0,取 stderr 尾部)→ 段 status → FAILED + errorMessage。
- 重名输出:自动 `_1`/`_2`(沿用 ExportService 逻辑)。
- `end <= start` 或 `end == null` 的段:不参与转码,列表标记「未完成」。
- 取消:当前段回到 PENDING、progress 归零。
- **删除视频(级联清理)**:删除一个 VideoItem 时,一并删除其所有 `SplitSegment` 行,并删除已生成(`outputPath` 非空)的转码产物文件。

---

## 八、测试

- **交互状态机单测**(纯逻辑,最高优先级):覆盖 Mark In/Out 在「无焦点 / 定义中 / 已完成」×「P 早于起点 / 区间内 / 晚于终点」的所有组合,断言段结果。
- 命名:批量命名按 sortOrder 重算;手动改名保留不被覆盖。
- 段排序:改起点导致顺序变化后 sortOrder 重算正确。
- `SplitRepository` CRUD + `getSegmentsByVideo` 聚合。
- 重叠:两段区间重合时转码各自独立、无异常。
- 数据库 migration v2→v3:旧 VideoItems.source 默认 clip;SplitSegments 表创建。

---

## 九、影响范围与风险

- **数据库 schema 升级**:v2→v3,需保证旧数据(`source` 默认 clip)迁移无误,裁剪流程零感知。
- **裁剪 tab 隔离**:`getUnconfiguredVideos` 改为按 `clip` 过滤,需回归验证裁剪准备列表行为不变。
- **交互复杂度**:状态机分支多,以纯逻辑函数实现并充分单测,降低回归风险。
- **不引入新依赖**:全部基于现有 `flutter_riverpod`/`drift`/`media_kit`/`ffmpeg` 技术栈。
