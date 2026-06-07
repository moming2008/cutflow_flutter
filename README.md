# CutFlow

Windows 桌面录屏视频裁剪（Cut）与画面裁切（Crop）批量导出工具，基于 Flutter 构建。

## 功能

- **视频裁剪** — 毫秒级精度设定起点和终点，逐帧预览精确定位
- **画面裁切** — 支持自定义裁切参数（W/H/X/Y），可保存为预设复用
- **可视化裁切** — 全分辨率帧预览，鼠标拖拽参考线精确定位裁切区域，支持缩放平移
- **裁切预设管理** — 自由添加、编辑、删除裁切预设，编辑器中动态加载
- **输出文件名 + 后缀** — 独立设置文件名和后缀（默认 `-crop`），灵活命名
- **批量转码** — 多任务排队，顺序执行 FFmpeg 转码，支持单独执行指定任务
- **任务交互** — 右键菜单（移除/重置/开始）、悬浮详情、右侧抽屉面板
- **草稿自动保存** — 编辑过程自动保存，关闭后重新打开恢复上次进度
- **导出目录配置** — 自选输出文件夹，文件重名自动加序号
- **本地数据库** — 基于 Drift (SQLite) 存储任务、预设和设置

## 界面预览

<table>
  <tr>
    <td align="center"><b>准备列表</b></td>
    <td align="center"><b>编辑器</b></td>
  </tr>
  <tr>
    <td><img src="https://private-user-images.githubusercontent.com/11555380/604067898-98d83d7e-bcc7-4c69-aeb1-b4e373082695.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3ODA4MzkyNzIsIm5iZiI6MTc4MDgzODk3MiwicGF0aCI6Ii8xMTU1NTM4MC82MDQwNjc4OTgtOThkODNkN2UtYmNjNy00YzY5LWFlYjEtYjRlMzczMDgyNjk1LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjA2MDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwNjA3VDEzMjkzMlomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTA0OGU1YWI0MTIwOWQ3YTU1OGNiZGIyN2MzZmMyYmQzMjFlNTdiZjZhYWJmYzY0YzY4ZDllZGYwYWYxMzUyMzEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JnJlc3BvbnNlLWNvbnRlbnQtdHlwZT1pbWFnZSUyRnBuZyJ9.tVoSpcqoEhZse7FNy3Ii4VJzJFWwQCOvr8mRc1tEsVc" alt="准备列表" /></td>
    <td><img src="https://private-user-images.githubusercontent.com/11555380/604067899-a66f56e0-08b0-459e-8d17-7fd38f89c499.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3ODA4MzkzOTEsIm5iZiI6MTc4MDgzOTA5MSwicGF0aCI6Ii8xMTU1NTM4MC82MDQwNjc4OTktYTY2ZjU2ZTAtMDhiMC00NTllLThkMTctN2ZkMzhmODljNDk5LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjA2MDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwNjA3VDEzMzEzMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTM4YjQyODQwNmJiMDk0MjE1YzJmYzgyZTg1MTQ4MmM3MWQ5Zjc4ZWVmYjRmNmY5MTRlYmQyNjJjM2ZiY2VjNzImWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JnJlc3BvbnNlLWNvbnRlbnQtdHlwZT1pbWFnZSUyRnBuZyJ9.K86bNI267EZW-eQlmvzHnHAbMo3S-4xi39SB-nkegQs" alt="编辑器" /></td>
  </tr>
  <tr>
    <td align="center"><b>可视化裁切</b></td>
    <td align="center"><b>待转码队列</b></td>
  </tr>
  <tr>
    <td><img src="https://private-user-images.githubusercontent.com/11555380/604067897-b0b9af22-9c33-4d65-a880-0484430ba756.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3ODA4MzkzOTEsIm5iZiI6MTc4MDgzOTA5MSwicGF0aCI6Ii8xMTU1NTM4MC82MDQwNjc4OTctYjBiOWFmMjItOWMzMy00ZDY1LWE4ODAtMDQ4NDQzMGJhNzU2LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjA2MDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwNjA3VDEzMzEzMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTc0ZjY3MjJkNGVmM2ViZjQyMTk5NDQwNzEyOWRjZjYxMTE5ZTZlYTRkYTRiOWUwNjgwZTM2YmQ4NjdmMmM4ODEmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JnJlc3BvbnNlLWNvbnRlbnQtdHlwZT1pbWFnZSUyRnBuZyJ9.HNwW_i0Be29NatpvK4LO3p5EJ-bIKZNS5XEddkaAVBM" alt="可视化裁切" /></td>
    <td><img src="https://private-user-images.githubusercontent.com/11555380/604067902-c7d68e23-a2d5-484e-8780-779832e50762.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3ODA4MzkzOTEsIm5iZiI6MTc4MDgzOTA5MSwicGF0aCI6Ii8xMTU1NTM4MC82MDQwNjc5MDItYzdkNjhlMjMtYTJkNS00ODRlLTg3ODAtNzc5ODMyZTUwNzYyLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjA2MDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwNjA3VDEzMzEzMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTgyYWUxZDg3NTU4YmUzZWRiM2U1NDQ0NjRjZjExMjVkZTVlNTc1MzU3ODliMGQ3MzE1ZGJhODZjYTFkZWVlYmImWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JnJlc3BvbnNlLWNvbnRlbnQtdHlwZT1pbWFnZSUyRnBuZyJ9.YPYagIBtTSCJDV0TM9OKEo_uLvueIo5kE-rbxA2ODdU" alt="待转码队列" /></td>
  </tr>
  <tr>
    <td align="center"><b>已转码队列</b></td>
    <td align="center"><b>设置</b></td>
  </tr>
  <tr>
    <td><img src="https://private-user-images.githubusercontent.com/11555380/604067900-1d3014b4-5094-46d8-a1ac-89915f2ecd08.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3ODA4MzkzOTEsIm5iZiI6MTc4MDgzOTA5MSwicGF0aCI6Ii8xMTU1NTM4MC82MDQwNjc5MDAtMWQzMDE0YjQtNTA5NC00NmQ4LWExYWMtODk5MTVmMmVjZDA4LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjA2MDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwNjA3VDEzMzEzMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTExYzU4Y2E0YzRjM2VlMjc1NmNkNTI3ZmUyMzMwZDgyM2FkMzMxNWJiN2VkZTZlOGYyN2ZkYjAwYmZkZTUwZTUmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JnJlc3BvbnNlLWNvbnRlbnQtdHlwZT1pbWFnZSUyRnBuZyJ9.t0wQ99l_zBmmSK0ifql4JeoxgTl6twDtD7izGva1WtA" alt="已转码队列" /></td>
    <td><img src="https://private-user-images.githubusercontent.com/11555380/604067904-7b842560-0ac8-4503-bb02-249adf70acfa.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3ODA4MzkzOTEsIm5iZiI6MTc4MDgzOTA5MSwicGF0aCI6Ii8xMTU1NTM4MC82MDQwNjc5MDQtN2I4NDI1NjAtMGFjOC00NTAzLWJiMDItMjQ5YWRmNzBhY2ZhLnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjA2MDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwNjA3VDEzMzEzMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTE1OTJjOTJkY2M5NTI3ZDc0M2FlODM2ZTBkZGQwODQ2ZDAxODNlZjg4OGRiNWRhYzgwZDE0MGRiNGEzMjFhMTQmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JnJlc3BvbnNlLWNvbnRlbnQtdHlwZT1pbWFnZSUyRnBuZyJ9.8cV4HGxJjeYyJ2NcQ2TwjLiUA1yKbsyquTPqXSnlrUo" alt="设置" /></td>
  </tr>
  <tr>
    <td align="center" colspan="2"><b>添加预设</b></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img src="https://private-user-images.githubusercontent.com/11555380/604067903-a26a5772-2ca0-476f-8d04-47ae6577cf67.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3ODA4MzkzOTEsIm5iZiI6MTc4MDgzOTA5MSwicGF0aCI6Ii8xMTU1NTM4MC82MDQwNjc5MDMtYTI2YTU3NzItMmNhMC00NzZmLThkMDQtNDdhZTY1NzdjZjY3LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjA2MDclMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwNjA3VDEzMzEzMVomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPWMwZjNhYWYxMjk4ZTU1Yjk4MGQwNzRmMzUzOWEzMDI4MmRmOTI2MjYwZDQzMDc1MDllY2JiZDljNTA5NjdlZGImWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JnJlc3BvbnNlLWNvbnRlbnQtdHlwZT1pbWFnZSUyRnBuZyJ9.e5IPyTEaPCF9VNnKT8LeG0i4f6-EA8YEnl3miXxyzgM" alt="添加预设" /></td>
  </tr>
</table>

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

### v1.6.0
- 修复裁剪范围不生效的关键 Bug（FFmpeg -t 参数单位错误）
- 修复 FFmpeg 定位模式（-ss 移到 -i 之前）
- 统一所有导出使用重编码（libx264），确保帧级精度
- 新增逐帧预览按钮，精确定位入点/出点
- 时间显示精度提升至毫秒
- 转码队列：悬停详情、右键菜单、右侧详情抽屉
- 已转码列表：右侧详情抽屉
- 设置最小窗口尺寸 1280×720
- 版本号联动侧栏显示

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
