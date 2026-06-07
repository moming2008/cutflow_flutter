# CutFlow

Windows 桌面视频裁剪与转码工具，基于 Flutter 构建。

## 功能

- **视频裁剪** — 精确设定起点和终点，快速剪切视频片段
- **画面裁切** — 支持自定义裁切参数（W/H/X/Y），可保存为预设复用
- **可视化裁切** — 全分辨率帧预览，鼠标拖拽参考线精确定位裁切区域，支持缩放平移
- **裁切预设管理** — 自由添加、编辑、删除裁切预设，编辑器中动态加载
- **输出文件名 + 后缀** — 独立设置文件名和后缀（默认 `-crop`），灵活命名
- **批量转码** — 多任务排队，顺序执行 FFmpeg 转码
- **草稿自动保存** — 编辑过程自动保存，关闭后重新打开恢复上次进度
- **导出目录配置** — 自选输出文件夹，文件重名自动加序号
- **本地数据库** — 基于 Drift (SQLite) 存储任务、预设和设置

## 界面预览

- **准备列表** — 导入视频，点击打开编辑器弹窗
- **裁剪编辑器** — 左右分栏：左侧视频预览（media_kit），右侧参数表单
- **可视化裁切面板** — 全分辨率帧 + 可拖拽参考线 + 缩放平移
- **转码队列** — 任务列表 + 总进度条，支持暂停/重置/删除
- **已转码** — 完成列表，支持打开文件位置、系统播放器播放
- **设置** — 导出目录 + 裁切预设管理

## 技术栈

| 层级 | 技术 |
|------|------|
| UI | Flutter, Material 3 |
| 状态管理 | Riverpod |
| 路由 | GoRouter (StatefulShellRoute 侧栏布局) |
| 数据库 | Drift + SQLite |
| 视频播放 | media_kit (libmpv) |
| 视频转码 | FFmpeg (系统安装) |

## 项目结构

```
lib/
├── core/           # 核心层
│   ├── database/   # Drift 数据库定义与 DAO
│   ├── ffmpeg/     # FFmpeg 命令构建与引擎
│   ├── init/       # 应用初始化
│   ├── model/      # 数据模型
│   ├── repository/ # 数据仓库
│   ├── services/   # 业务服务（导出、资源管理器）
│   └── util/       # 工具类
├── features/       # 功能模块
│   ├── preparation/    # 待编辑列表
│   ├── editor/         # 裁剪编辑器（弹窗式）
│   ├── queue/          # 转码队列
│   ├── completed/      # 已转码列表
│   └── settings/       # 设置页
├── navigation/     # 路由与侧栏导航
└── ui/theme/       # Material 3 主题配置
```

## 环境要求

- Flutter 3.35+ / Dart 3.9+
- Windows 10/11
- [FFmpeg](https://ffmpeg.org/download.html) 已安装并加入系统 PATH

## 构建与运行

```bash
# 获取依赖
flutter pub get

# 生成 Drift 代码
dart run build_runner build --delete-conflicting-outputs

# 开发运行
flutter run -d windows

# Release 构建
flutter build windows --release
```

Release 产物位于 `build/windows/x64/runner/Release/`，将整个文件夹复制到目标机器即可运行。

## 更新日志

### v1.5.0
- 新增可视化裁切面板（全分辨率帧预览 + 参考线拖拽 + 缩放平移）
- 新增输出后缀输入框（默认 `-crop`，可修改）
- 修复中文 IME 输入重复 bug（持久化 TextEditingController）
- 选中预设/原始时展示只读裁切数据（W/H/X/Y）
- 保存预设后自动切换到新增预设 tab
- 视频预览默认暂停，不自动播放

### v1.0.0
- 初始版本：视频裁剪、画面裁切、批量转码、预设管理

## License

MIT
