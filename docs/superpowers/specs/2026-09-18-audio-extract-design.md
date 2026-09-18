# 音频提取功能设计文档（视频 → MP3 + ID3 标签）

**版本**: v1.0.0(音频版)
**日期**: 2026-09-18
**分支**: `feature/video-to-mp3`
**状态**: 设计中（待确认）

---

## 概述

在 CutFlow 中衍生一个**纯音频版本**：把视频的音轨提取为 MP3，并封装封面图、歌名、歌手名、专辑名四项 ID3 标签。支持在视频预览窗口或时间码输入框里精确选取要提取的区间。

本设计严格遵循现有 MVVM 分层、Riverpod/GoRouter/Drift 技术栈与命名规范，最大化复用 `TrimRangeControl`（入/出点交互）、`VideoPreviewPanel`（media_kit 播放器）、`FfmpegEngine`（进度/取消）与 `FfmpegCommandBuilder`。

**关键定位**：这是一个**衍生实验版本**，测试通过后音频能力会拉回 `main` 原版。因此本分支只**隐藏**视频相关页签，**不删除**任何视频侧代码，并保证数据库迁移对视频侧零影响。

---

## 一、需求决策汇总（已与用户确认）

| # | 决策点 | 结论 |
|---|--------|------|
| 1 | 信息填充方式 | **纯手动填写**：歌名/歌手/专辑为输入框，封面由用户选择本地图片 |
| 2 | 处理粒度 | **单个文件**：一次处理一个视频，单页表单 |
| 3 | 区间选择 | **复用编辑器起止能力**：预览窗口调位置 + 时间码输入框，两条路径都要 |
| 4 | 画面裁切 | **不涉及**：只用音频轨，不读也不写 crop 数据 |
| 5 | 码率 | 展示**源音轨码率**供参考，用户**自选目标码率** |
| 6 | 页签范围 | 音频版**只显示「音频」一个页签**（设置页也隐藏） |
| 7 | 视频代码处理 | **只隐藏，不删代码**，用开关常量控制 |
| 8 | 持久化 | **新增独立音频表**，与视频表区分 |
| 9 | ID3 版本 | **ID3v2.3**（Windows 资源管理器/车机/老播放器兼容性最优） |
| 10 | 封面处理 | 统一**重编码为 JPEG**，最长边**限 600px 不放大** |

### 关键决策说明

- **决策 8 的落地边界**：音频表建在**同一个 `cutflow.db` 文件**里，通过**独立表 + 独立 Repository** 与视频侧区分，而非新建独立数据库文件。理由：避免第二个 Drift 连接的生命周期管理开销；视频侧表结构完全不动；拉回 `main` 时只需带上新表定义与迁移分支。若你希望物理隔离成独立 db 文件，这是一处改动点。
- **决策 10 的理由**：MP3 的 APIC 帧规范上只保证 JPEG/PNG 被识别，实测多数播放器不认 PNG，强制 `mjpeg` 重编码可保证格式安全；同时 4000×4000 的原图会让 mp3 凭空增大几十 MB，600px 是通用播放器都吃到的尺寸。

---

## 二、架构总览

新增 `features/audio/` 模块，分层与现有 `features/editor/`、`features/transcode/` 一致：

```
features/audio/
├── audio_screen.dart              # 单页：表单区（预览+标签+区间+码率+输出） + 记录列表
├── audio_viewmodel.dart           # 页面状态：选中文件/区间/标签/封面/码率/进度/记录
└── widgets/
    ├── audio_tag_panel.dart       # 歌名/歌手/专辑输入框 + 封面选择与缩略图
    ├── audio_bitrate_selector.dart# 源码率展示 + 目标码率档位下拉
    └── audio_record_tile.dart     # 历史记录单行：标签摘要/时长/大小/打开/删除

core/
├── app_mode.dart                  # kAudioOnlyMode 开关常量
├── model/audio_task.dart          # AudioTask (Equatable + copyWith) + AudioTaskStatus
├── model/audio_source_info.dart   # 源音轨探测结果（码率/编码/声道/采样率/是否含音轨）
├── database/app_database.dart     # +AudioTasks 表；schemaVersion 2→3
├── repository/audio_repository.dart        # 音频任务 CRUD + 响应式监听
├── ffmpeg/audio_metadata_probe.dart        # ffprobe 探测源音轨信息
└── ffmpeg/command_builder.dart    # +buildExtractMp3(...)

navigation/
├── nav_destinations.dart          # 新增：集中定义导航目标（router/sidebar 共用）
├── app_router.dart                # 改为按模式从 nav_destinations 构建 branches
└── app_sidebar.dart               # 改为按模式从 nav_destinations 构建导航项
```

### 数据流

```
AudioScreen ─→ AudioViewModel ─→ AudioRepository ─→ AppDatabase
                    │
                    ├─→ AudioMetadataProbe   (选中文件后探测源音轨码率/有无音轨)
                    ├─→ FfmpegCommandBuilder.buildExtractMp3
                    └─→ FfmpegEngine.executeWithProgress
```

### Provider

- `audioProvider` → `StateNotifierProvider`（页面状态，全局单例，非 autoDispose）
- `audioRepositoryProvider` → 注入 `AppDatabase`
- `audioRecordsProvider` → `StreamProvider`，监听 `AudioRepository.watchAllTasks()`

### 复用点（均**不修改**的原样复用）

- **`TrimRangeControl`**：入点/出点/时长显示、时间码点击编辑、范围进度条拖拽、设定入点/出点按钮，全部直接复用。
- **`VideoPreviewPanel`**：media_kit 播放器 + 位置回调 + `seekTo()`，通过 `GlobalKey<VideoPreviewPanelState>` 取实例，用于「预览窗口调整时间」这条路径。
- **`FfmpegEngine`**：进度解析与取消机制原样复用。
- **`ExplorerService`**：转换完成后「打开所在文件夹」。
- **`TimeFormatter`**：时间码格式化与解析语义。
- **`FilePicker`**：选视频文件、选封面图片（沿用 `file_picker` 依赖，不新增包）。

### 复用点的三处适配（需小幅改动共享组件）

| 组件 | 改动 | 理由 |
|---|---|---|
| `TrimRangeControl` | 新增两个**可选**参数 `stepBackwardLabel` / `stepForwardLabel`，默认值保持现有文案「逐帧向前」「逐帧向后」 | 音频场景下「逐帧」无意义，需要显示为「快退 1s」「快进 1s」。可选参数默认值不变，现有调用方零感知 |
| `TrimRangeControl` | 调用时传 `frameRate: 0` | 组件内部**从未使用** `frameRate`（仅声明未引用），传 0 无影响；步进逻辑由 ViewModel 实现为 ±1000ms |
| `VideoPreviewPanel` | 补实现 `didUpdateWidget`：`video.path` 变化时重建播放器；`_player` 由 `late final` 改为 `late` 以便释放旧实例；加 `_loadToken` 防止快速切换时的异步竞态 | **勘察发现的既有缺陷**：该组件未实现 `didUpdateWidget`，换视频文件时 `initState` 不会重跑，预览不刷新。音频页需反复换文件，不修则功能不可用。同时修掉 `dispose()` 在从未初始化时抛 `LateInitializationError` 的隐患 |

---

## 三、数据模型

### 3.1 新增 AudioTasks 表（单表方案）

音频版只有一个页签，普通视频侧的「导入源表 + 任务表」双表结构在这里没有承载位置。因此采用**单表**：一条记录 = 一次音频转换，输入参数与输出结果同存。

| 列 | 类型 | 说明 |
|---|---|---|
| id | integer PK autoIncrement | |
| sourcePath | text NOT NULL | 源视频完整路径 |
| sourceName | text NOT NULL | 源视频文件名（含扩展名） |
| sourceDurationMs | integer NOT NULL | 源视频总时长（毫秒） |
| sourceBitrateKbps | integer **nullable** | 源音轨码率；null = 探测不到（VBR 常见） |
| trimStartMs | integer NOT NULL | 入点（毫秒） |
| trimEndMs | integer NOT NULL | 出点（毫秒） |
| title | text nullable | 歌名，空 = 不写入该 ID3 标签 |
| artist | text nullable | 歌手名，空 = 不写入 |
| album | text nullable | 专辑名，空 = 不写入 |
| coverPath | text nullable | 用户选择的封面原图路径，空 = 不嵌入封面 |
| targetBitrateKbps | integer NOT NULL | 目标 MP3 码率 |
| outputName | text NOT NULL | 输出文件名（含 `.mp3`） |
| outputPath | text nullable | 转换产物完整路径 |
| status | text NOT NULL DEFAULT 'PENDING' | PENDING / EXPORTING / DONE / FAILED |
| progress | integer NOT NULL DEFAULT 0 | 0–100 |
| errorMessage | text nullable | 失败原因 |
| createdAt | integer NOT NULL | 创建时间戳 |
| completedAt | integer nullable | 完成时间戳 |

索引：本表不声明自定义索引 —— 项目既有的 `Set<Index> get indexes` 写法并非 drift API、实际从未建出索引，且本功能没有需要索引的查询。

### 3.2 AudioTaskStatus 枚举

```dart
enum AudioTaskStatus { pending, exporting, done, failed }
```

**刻意不复用** `export_task.dart` 里的 `TaskStatus`：后者含 `preparing`（导出前的准备阶段），音频转换无需该阶段。视频与音频各自持有领域枚举，符合「与视频区分」的要求。

### 3.3 数据库迁移

- `schemaVersion` 由 **2 升到 3**。
- `onUpgrade`：`if (from < 3) { await m.createTable(audioTasks); }`
- **视频侧表结构完全不改动**，现有 `VideoItems` / `ExportTasks` / `CropPresets` / `EditorDrafts` / `AppSettings` 五个表逐字不动，迁移对视频流程零影响。
- 改完表定义后运行 `dart run build_runner build --delete-conflicting-outputs` 重新生成 `app_database.g.dart`。

---

## 四、FFmpeg 管线

### 4.1 源音轨探测（`audio_metadata_probe.dart`，新增）

```dart
class AudioSourceInfo {
  final bool hasAudio;        // 是否存在音频轨
  final int? bitrateKbps;     // 音轨码率，null = 未知
  final String? codec;        // 如 aac / mp3 / ac3
  final int? channels;        // 声道数
  final int? sampleRate;      // 采样率
  final int durationMs;       // 总时长
}
```

探测命令：

```
ffprobe -v error -select_streams a:0
        -show_entries stream=bit_rate,codec_name,channels,sample_rate
        -show_entries format=duration,bit_rate
        -of json <source>
```

**码率回退链**（重要，VBR 源普遍缺失 `stream.bit_rate`）：

1. `streams[0].bit_rate`（音轨精确码率）
2. → `format.bit_rate`（容器总码率，含视频轨，**明显高于音频实际码率**）
3. → `null`，界面显示「源码率：未知」

回退到第 2 步时必须**标注为参考值**（界面显示「源码率：约 3200 kbps（容器总码率，仅供参考）」），不能伪装成音轨码率——否则用户会被误导选错目标码率。

复用现有 `MetadataExtractor._findFfprobePath()` 的查找逻辑（PATH → 可执行文件目录 → ffmpeg 同目录）。

### 4.2 转换命令（`FfmpegCommandBuilder.buildExtractMp3`，新增）

```dart
static List<String> buildExtractMp3({
  required String inputPath,
  required String outputPath,
  required int startMs,
  required int endMs,
  required int targetBitrateKbps,
  String? coverPath,      // null = 不嵌入封面
  String? title,          // null/空 = 不写入
  String? artist,
  String? album,
})
```

**带封面**：

```
-y
-ss <start>                        # 输入 seek，放在 -i 前（快速定位）
-i <input>
-i <cover>
-t <duration>                      # 输出时长限制
-map 0:a:0
-map 1:v:0
-c:a libmp3lame
-b:a <N>k
-c:v mjpeg
-vf scale=w=min(600\,iw):h=min(600\,ih):force_original_aspect_ratio=decrease
                                   # 最长边限 600，不放大（竖图同样受限）
-q:v 3
-disposition:v attached_pic
-id3v2_version 3
-metadata title=<歌名>
-metadata artist=<歌手>
-metadata album=<专辑>
-metadata:s:v title=Album cover
-metadata:s:v comment=Cover (front)
<output.mp3>
```

**不带封面**：去掉 `-i <cover>` / `-map 1:v:0` / `-c:v mjpeg` / `-vf ...` / `-q:v 3` / `-disposition:v attached_pic` / 两个 `-metadata:s:v`，其余不变。

**参数顺序约束**（单测必须断言）：

- `-ss` 必须在 `-i <input>` **之前**（输入 seek，避免解码丢弃前的全部帧）
- `-t` 必须在所有输入之后（作为输出时长限制）
- 沿用现有 `buildTrimOnly` 的参数风格，与项目既有约定一致

**命令注入安全性**：全部经由 `Process.start` 传 argv 数组，**不经过 shell**，因此歌名含 `"` `&` `|` 等字符无需转义，也不会被解释。但 ID3 写入是 ffmpeg 的 `-metadata` 键值解析，含**换行符**的标签会被截断——实现时对标签做空白规整（去首尾空格、换行折为空格）。

### 4.3 进度基准（与现有转码不同，必须改）

`TranscodeViewModel` 传入的 `totalDurationMs` 是**源视频总时长**——因为它不做裁剪，这是对的。音频这里**必须传 `trimEndMs - trimStartMs`（输出时长）**，因为 `-ss` 输入 seek 后 ffmpeg 的 `time=` 从 0 起算。

**这一做法在代码库中已有先例**：`ExportService._processTask()` 计算 `final trimDuration = task.trimEndMs - task.trimStartMs;` 并作为 `totalDurationMs` 传入，与裁剪工作流（`editor_form_panel` / `buildTrimAndCrop`）配合正常。音频沿用同一基准，与既有实现保持一致。

仍需**用真实素材实测校准**（不同 ffmpeg 版本对 seek 后时间戳的处理存在差异）。校准方法：转一个已知时长的区间，观察进度条能否在结束时到达 100%。若实测发现 `time=` 仍以源时间轴计，则改回传 `trimEndMs`。

### 4.4 输出路径与命名

- **输出目录**：复用现有 `AppSettings` 的 `exportDirectory`（默认 `~/Documents/CutFlow/exports`），用户可在界面点「更改」手选。
- **输出文件名**：
  - 歌名非空 → `{歌名}.mp3`
  - 歌名为空 → `{源文件名去扩展名}.mp3`
  - 重名 → 追加 `_1` / `_2`（沿用 `ExportService` 现有逻辑）
- **文件名清洗**（必须）：Windows 文件名禁止 `\ / : * ? " < > |`，而歌名极易含 `/`（如 `AC/DC`）或 `:`。清洗规则：非法字符替换为 `_`，去首尾空格与点号，空结果回退为 `audio`。

---

## 五、UI 布局

### 5.1 AudioScreen（单页，上下两段）

```
┌────────────────────────────────────────────────────────────┐
│ 音频提取                                      [选择视频]     │
├────────────────────────────────────────────────────────────┤
│ ┌──────────────────────┬─────────────────────────────────┐ │
│ │  VideoPreviewPanel    │  歌曲信息                        │ │
│ │  (media_kit 播放器)    │  歌名 [__________________]      │ │
│ │                       │  歌手 [__________________]      │ │
│ │                       │  专辑 [__________________]      │ │
│ │                       │  封面 [选择图片] [缩略图][清除] │ │
│ └──────────────────────┴─────────────────────────────────┘ │
│                                                             │
│  剪辑范围（复用 TrimRangeControl）                           │
│  入点 00:00.000   时长 02:45.000   出点 02:45.000           │
│  [设定入点] [设定出点]   [◀ 快退 1s] [快进 1s ▶]            │
│                                                             │
│  音频码率   源: 192 kbps        目标 [320 kbps ▼]           │
│  输出到     ~/Documents/CutFlow/exports/歌名.mp3   [更改]   │
│                                                             │
│  [开始转换]                          ████████░░ 82%         │
├────────────────────────────────────────────────────────────┤
│  转换记录                                                    │
│  ♪ 歌名 · 歌手 · 专辑 · 02:45 · 6.3 MB   [打开] [删除]      │
└────────────────────────────────────────────────────────────┘
```

### 5.2 空态

未选择视频时，预览区与表单区禁用，中央提示「选择一个视频开始提取音频」。

### 5.3 无音轨拦截（关键路径）

选中文件 → `AudioMetadataProbe` 探测 → 若 `hasAudio == false`：

- 预览区正常显示视频
- 表单区顶部显示醒目错误条：「该视频没有音频轨道，无法提取音频」
- **「开始转换」按钮禁用**（不进入 ffmpeg，避免用户等到进程失败）

### 5.4 标签面板（`audio_tag_panel.dart`）

- 三个 `TextField`，均允许为空。`hintText` 明确空值语义：歌名框提示「留空则不写入标签，文件名用源文件名」。
- 封面区：选择后显示 64×64 缩略图 + 文件名 + 「清除」按钮。用 `Image.file` 加载，`errorBuilder` 兜底为「无法预览」图标（防止用户选了非图片文件时崩溃）。
- **封面格式校验前置**：选择文件时用 `file_picker` 限定 `jpg/jpeg/png/webp/bmp`，不做解码校验（交给 ffmpeg 报错）。

### 5.5 码率选择器（`audio_bitrate_selector.dart`）

- 左侧只读展示源码率：`源: 192 kbps` / `源: 未知` / `源: 约 3200 kbps（容器总码率，仅供参考）`
- 右侧 `DropdownButton` 档位：**128 / 160 / 192 / 256 / 320 kbps**，默认 **320**。
- 上次选择经 `AppSettings`（key: `audio_target_bitrate`）记忆，下次进入自动带出。

### 5.6 记录列表（`audio_record_tile.dart`）

- 数据源 `audio_recordsProvider`（`watchAllTasks()` 响应式流，`createdAt` 倒序）。
- 单行：状态徽章 + 歌名/歌手/专辑摘要（空值显示「—」）+ 时长 + 文件大小 + 操作按钮。
- 状态为 `DONE` 且 `outputPath` 文件存在 → 显示「打开」（`ExplorerService` 定位文件）、「删除」（删记录 + 删产物文件，删文件前二次确认）。
- 状态为 `FAILED` → 显示 `errorMessage`（可展开）+ 「重试」。「重试」的语义是**把该条记录的参数回填到上方表单区**（源文件、区间、标签、封面、码率全部还原），由用户确认或修改后手动点「开始转换」重新执行；**不是**一键后台重跑。理由：失败多为参数或环境问题（封面失效、输出被占用），静默重跑大概率再失败一次，回填表单让用户能就地修正。
- **不做**暂停/继续队列：单文件场景下串行执行，同一时刻至多一个任务在跑。

---

## 六、页签隐藏机制

### 6.1 现状隐患

`app_router.dart` 以数组下标定义 4 个 `StatefulShellBranch`，`app_sidebar.dart` 独立定义 4 个 `_NavItem`，两者靠**下标约定**对齐。直接在其中一侧加过滤会让下标错位，导致点击「音频」跳到「裁剪」。

### 6.2 方案：集中式导航目标定义

新增 `lib/navigation/nav_destinations.dart`：

```dart
class NavDestination {
  final String label;
  final IconData icon;
  final IconData iconFilled;
  final String path;
  final Widget Function(BuildContext, GoRouterState) builder;
  final bool audioOnly;   // true = 音频阽也保留
}

const kNavDestinations = <NavDestination>[
  NavDestination(label: '裁剪',      path: '/clip',      audioOnly: false, ...),
  NavDestination(label: 'H264 转码', path: '/transcode', audioOnly: false, ...),
  NavDestination(label: '视频分割',  path: '/split',     audioOnly: false, ...),
  NavDestination(label: '设置',      path: '/settings',  audioOnly: false, ...),
  NavDestination(label: '音频',      path: '/audio',     audioOnly: true,  ...),
];

List<NavDestination> get activeDestinations =>
    kAudioOnlyMode ? kNavDestinations.where((d) => d.audioOnly).toList() : kNavDestinations;
```

**顺序约定**：`kNavDestinations` 的顺序**即完整版侧栏顺序**，音频页排在列表末尾。四项视频页签保持改造前的相对顺序（下标 0–3），音频页追加在末尾；`destinationsFor` 是**纯过滤**，不重排列表。这样 `activeDestinations.first.path` 在完整版下是 `/clip`（与现有 `initialLocation` 一致），在音频版下过滤后只剩音频一项、即 `/audio`，两种模式共用一个表达式，无需分支判断。每一项的 `icon` / `iconFilled` / `builder` 逐字搬移现有 `app_sidebar.dart` 的 `_navItems` 与 `app_router.dart` 的 `builder`，不改动任何图标与页面构造。

`app_router.dart` 与 `app_sidebar.dart` **都**从 `activeDestinations` 构建，下标天然一致。

### 6.3 开关与初始路由

```dart
// lib/core/app_mode.dart
const bool kAudioOnlyMode = true;   // ← 一个常量切换完整版 / 音频版
```

- 音频版下 `initialLocation` 必须从 `/clip` 变为 `activeDestinations.first.path`（即 `/audio`），**否则启动即白屏**（`/clip` 的路由已不存在）。
- 音频版的 `kNavDestinations` 中 `audioOnly: true` 的**只有音频页**（设置页按决策 6 一并隐藏）。

### 6.4 视频侧代码处置

**一律保留，不做删除、不做 `@Deprecated` 标注**：`features/clip/`、`features/transcode/`、`features/split/`、`features/preparation/`、`features/queue/`、`features/completed/`、`features/editor/` 及其 ViewModel/Repository/数据库表全部原样保留。切回 `kAudioOnlyMode = false` 即恢复完整版，用于对照测试。

---

## 七、错误处理与边界

| 场景 | 处理 |
|---|---|
| 源视频无音频轨 | 探测阶段拦截，「开始转换」禁用，提示「该视频没有音频轨道」 |
| 源文件不存在 / 被外部删除 | 转换前二次校验 `File.exists()`，失败则 `FAILED` + 「源文件不存在」 |
| 源码率探测失败 | 不阻断流程，界面显示「未知」，用户自行选档位 |
| 封面文件不存在 | 构建命令前校验，提示「封面图片不存在」，让用户重选或清除 |
| 封面不是有效图片 | ffmpeg 报错回传，`FAILED` + stderr 尾部信息 |
| `trimEndMs <= trimStartMs` | 「开始转换」禁用，提示「出点必须大于入点」 |
| 输出目录不可写 | 转换前 `Directory.exists()` / 创建，失败则 `FAILED` + 明确路径 |
| 输出文件被占用（Windows 常见） | ffmpeg exitCode≠0 → `FAILED` + 「输出文件可能被其他程序占用，请关闭后重试」 |
| ffmpeg 未安装 | 沿用 `FfmpegEngine` 现有处理（「FFmpeg not found」） |
| 转换中用户取消 | `FfmpegEngine.cancel()` 杀进程；**删除半成品 mp3 文件 + 删除该任务记录**（不留 PENDING 残留） |
| 标签含换行/首尾空格 | 写入前规整（见 4.2） |
| 歌名含 Windows 非法字符 | 文件名清洗（见 4.4），但 **ID3 标签保留原样**（只清文件名，不清标签） |

---

## 八、测试

### 8.1 单元测试（纯逻辑，最高优先级）

**`buildExtractMp3` 命令构建**：
- 带封面 / 不带封面两种形态的完整 argv 断言
- 参数顺序：`-ss` 在 `-i <input>` 前；`-t` 在所有输入后
- 无封面时**不出现** `-i <cover>` / `-map 1:v:0` / `-c:v mjpeg` / `-disposition:v attached_pic`
- 标签含中文、空格、引号、`&`、`|` 时，`-metadata` 值原样传递（不转义、不截断）
- 标签含换行符时被规整为空格
- 空标签（null 或空串）**不生成**对应 `-metadata`
- 封面缩放滤镜字符串正确：`scale=w=min(600\,iw):h=min(600\,ih):force_original_aspect_ratio=decrease`
- `-id3v2_version 3` 始终存在
- `-b:a <N>k` 与传入码率一致

**进度基准**：
- `buildExtractMp3(startMs: 30000, endMs: 195000)` 产出的 `-t` 为 `00:02:45.000`

**文件名清洗**：
- `AC/DC - Back in Black` → `AC_DC - Back in Black.mp3`
- `Song: Live` → `Song_ Live.mp3`
- 首尾空格、结尾点号被去除
- 清洗后为空 → 回退 `audio.mp3`
- 重名 → 追加 `_1` / `_2`

**音轨探测解析**：
- `stream.bit_rate` 存在 → 取流码率，标记为精确值
- `stream.bit_rate` 缺失、`format.bit_rate` 存在 → 取容器码率，**标记为 `isApproximate = true`**
- 两者都缺失 → `bitrateKbps = null`，界面文案为「未知」
- `streams` 中无 `codec_type == audio` → `hasAudio = false`

**`AudioTasks` 数据层**（沿用现有 `AppDatabase.forTest` 内存库）：
- CRUD：插入 / 按状态查询 / 更新进度 / 更新完成信息 / 删除
- `watchAllTasks()` 响应式流在插入后发出新值
- **迁移测试 v2→v3**：构造 v2 结构的库并写入视频数据 → 升级 → 断言 `AudioTasks` 表存在、**且原有视频数据完好无损**

### 8.2 手动验收清单

- [ ] 选一个有音轨的视频 → 源码率正确显示 → 填三个标签 + 选一张 JPG 封面 → 转出的 mp3 用 `ffprobe -show_format -show_streams` 验回 title/artist/album 三项 + 存在 `attached_pic` 视频流
- [ ] **Windows 资源管理器**能看到封面缩略图（这是 ID3v2.3 决策的核心验证点）
- [ ] 在预览窗口拖动进度条调区间 → 入/出点同步更新 → 时间码输入框手动改 → 进度条高亮同步
- [ ] 选视频 A → 播放几秒 → 再选视频 B → 预览正确切到 B（不残留 A、不崩溃）；快速连切 3 个文件最终停在第 3 个
- [ ] 「快退 1s」「快进 1s」按 1 秒步进，不是按帧
- [ ] 不选封面转换 → mp3 无封面流，标签正常
- [ ] 标签全部留空转换 → 无 ID3 标签，文件名用源名
- [ ] 歌名填 `AC/DC: Live` → 文件名被清洗，但 mp3 内的 title 标签**保持原样**
- [ ] 选一个纯音频无音轨的异常文件（如静音视频/纯图）→ 错误条正确提示且按钮禁用
- [ ] 转换中途点取消 → 进程被杀、半成品文件被清理、历史列表不留该条记录
- [ ] 转换完成 → 记录列表出现 → 「打开」正确定位文件 → 删除时二次确认
- [ ] 关闭 App 重开 → 记录列表仍在（持久化生效）
- [ ] 侧栏**只有「音频」一项**，启动落在 `/audio` 不白屏
- [ ] 把 `kAudioOnlyMode` 改回 `false` → 完整版 4+1 个页签全部恢复正常，视频功能无回归

---

## 九、影响范围与风险

| 风险 | 说明与缓解 |
|---|---|
| **数据库 schema 升级 2→3** | 新增表而非改表，视频侧五张表逐字不动；迁移测试专门覆盖「v2 数据升级后完好」 |
| **导航下标错位** | 抽 `nav_destinations.dart` 集中定义，router 与 sidebar 共用同一列表，从结构上消除下标耦合 |
| **初始路由白屏** | 音频版初始路由取 `activeDestinations.first.path` 而非硬编码 `/clip`；列入验收清单 |
| **进度基准判断可能有偏差** | `-ss` 输入 seek 后 `time=` 起算点的推演需实测校准，已在 4.3 写明校准方法与回退方案 |
| **共享组件改动** | `TrimRangeControl` 仅新增两个带默认值的可选参数，现有调用方（`editor_form_panel`、split 设计侧）零感知。`VideoPreviewPanel` 的 `didUpdateWidget` 补实现是行为修复：既有调用方（`EditorDialog`）每次只加载一个视频、不换文件，不受影响 |
| **libmp3lame 可用性** | `libmp3lame` 是 ffmpeg 默认编译项，主流 Windows/Android 构建均包含；仅在极简构建中缺失，届时 ffmpeg 会明确报「Unknown encoder」 |
| **拉回 `main` 的合并成本** | 纯新增文件为主；对现有文件的改动集中在 `app_database.dart`（加表+迁移）、`command_builder.dart`（加方法）、`app_router.dart` / `app_sidebar.dart`（改为读集中定义）、`trim_range_control.dart`（加可选参数）四处，`kAudioOnlyMode` 默认值在合并时改为 `false` 即可 |
| **不引入新依赖** | 全部基于现有 `flutter_riverpod` / `drift` / `media_kit` / `file_picker` / 系统 ffmpeg+ffprobe |

---

## 十、实施顺序建议

1. `app_mode.dart` + `nav_destinations.dart` + router/sidebar 改造 + 空壳 `audio_screen.dart` → 先跑通「只有音频一个页签且不白屏」
2. `AudioTasks` 表 + 迁移 + `build_runner` 重新生成 → 迁移测试
3. `audio_metadata_probe.dart` + 单测
4. `buildExtractMp3` + 单测（含文件名清洗）
5. `audio_viewmodel.dart` + 完整 UI → 接通转换全流程
6. 手动验收清单逐条过 → 实测校准进度基准
