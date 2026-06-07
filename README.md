# CutFlow

Windows 桌面视频裁剪与转码工具，基于 Flutter 构建。

## 功能

- **视频裁剪** — 精确设定起点和终点，快速剪切视频片段
- **画面裁切** — 支持自定义裁切参数（W/H/X/Y），可保存为预设复用
- **批量转码** — 多任务排队，顺序执行 FFmpeg 转码
- **裁切预设管理** — 自由添加、编辑、删除裁切预设
- **导出目录配置** — 自选输出文件夹，文件重名自动加序号
- **本地数据库** — 基于 Drift (SQLite) 存储任务、预设和设置

## 技术栈

| 层级 | 技术 |
|------|------|
| UI | Flutter, Material 3 |
| 状态管理 | Riverpod |
| 路由 | GoRouter (StatefulShellRoute 侧栏布局) |
| 数据库 | Drift + SQLite |
| 视频播放 | media_kit (libmpv) |
| 视频转码 | FFmpeg (系统安装) |
| 视频缩略图 | video_thumbnail |

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
│   ├── video_list/     # 视频导入与列表
│   ├── preparation/    # 待编辑列表
│   ├── editor/         # 裁剪编辑器（弹窗式）
│   ├── queue/          # 转码队列
│   ├── completed/      # 已转码列表
│   ├── export/         # 导出管理
│   └── settings/       # 设置页
├── navigation/     # 路由与侧栏导航
└── ui/theme/       # Material 3 主题配置
```

## 环境要求

- Flutter 3.35+
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

## License

MIT
